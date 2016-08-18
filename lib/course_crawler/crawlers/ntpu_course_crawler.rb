# 國立臺北大學
# 選課網址： https://sea.cc.ntpu.edu.tw/pls/dev_stud/course_query_all.chi_main

module CourseCrawler::Crawlers
class NtpuCourseCrawler < CourseCrawler::Base
  include ::CourseCrawler::DSL

  DAYS = {
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6,
    "日" => 7,
  }

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil
    # @query_url = "https://sea.cc.ntpu.edu.tw/pls/dev_stud/course_query_all.CHI_query_keyword"
    # @query_url = "https://sea.cc.ntpu.edu.tw/pls/dev_stud/course_query_all.queryByKeyword"
    @query_url = "https://sea.cc.ntpu.edu.tw/pls/dev_stud/course_query_all.CHI_query_common"
    @result_url = "https://sea.cc.ntpu.edu.tw/pls/dev_stud/course_query_all.queryByAllConditions"
    @base_url = "https://sea.cc.ntpu.edu.tw/pls/dev_stud/"

    @year = year || current_year
    @term = term || current_term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @ic = Iconv.new("utf-8//translit//IGNORE", "big5")
  end

  def courses
    @courses = []
    @threads = []

    visit @query_url

    # 幹不是我自己要說
    # 這樣寫帥炸天啊 XDDD
    @post_datas = @doc.css('select[name="qdept"] optgroup').map do |optgroup|
      optgroup.css('option').map do |opt|
        {
          qCollege: optgroup[:label].encode('big5'),
          dep_c: opt[:value],
          dep_n: opt.text
        }
      end
    end.inject { |arr, nxt| arr.concat nxt }

    done_departments = 0
    @post_datas.each do |post_data|
      sleep(1) until (
        @threads.delete_if { |t| !t.status };  # remove dead (ended) threads
        @threads.count < (ENV['MAX_THREADS'] || 10)
      )
      @threads << Thread.new do
        r = RestClient.post @result_url, {
          qEdu: '',
          qCollege: post_data[:qCollege],
          qdept: post_data[:dep_c],
          qYear: @year-1911,
          qTerm: @term,
          qGrade: '',
          qClass: '',
          cour: '',
          teach: '',
          qMemo: '',
          week: '',
          seq1: 'A',
          seq2: 'M'
        }
        parse_course(Nokogiri::HTML(@ic.iconv r), post_data[:dep_c], post_data[:dep_n])
        # print "#{@ic.iconv post_data[:qCollege]}-#{post_data[:dep_n]}\n"
        done_departments += 1
        set_progress "#{done_departments} / #{@post_datas.count}"
      end
    end
    ThreadsWait.all_waits(*@threads)

    @courses
  end

  def parse_course(doc, dep_c, dep_n)
    list_threads = []

    doc.css('table tr[bgcolor="#E3EFC1"]').each do |row|
      datas = row.css('td')
      datas[4] && datas[4].search('br').each {|d| d.replace("\n") }
      datas[5] && datas[5].search('br').each {|d| d.replace("\n") }
      datas[6] && datas[6].search('br').each {|d| d.replace("\n") }
      datas[12] && datas[12].search('br').each {|d| d.replace("\n") }

      # normalize timetable
      course_days = []
      course_periods = []
      course_locations = []
      # Todos: 可能需要獨立出實習課
      if not ( datas[12] && datas[12].text.include?("未維護") )
        datas[12].text.split("\n").each do |p_raw|
          m = p_raw.match(/(實習)?每週(?<d>.)(?<s>\d+)~(?<e>\d+)\s(?<loc>.+)?/)
          if !!m
            (m[:s].to_i..m[:e].to_i).each do |period|
               course_days << DAYS[m[:d]]
               course_periods << period
               course_locations << m[:loc]
            end
          end
        end
      end

      general_code = datas[3] && datas[3].text
      # code must be unique every term
      # code = datas[3] && "#{@year}-#{@term}-#{general_code}-#{dep_c}"
      code = datas[3] && "#{@year}-#{@term}-#{general_code}"

      # run following snippets fix old UserCourse
      # UserCourse.joins(:user).where('users.organization_code = ?', 'NTPU').each do |uc|
      #   uc.course_code = uc.course_code.split('-')[0..2].join('-')
      #   begin
      #     uc.save!
      #   rescue Exception => e
      #   end
      # end

      dep_regex = /(\(進修\))?(?<dep>[^(\s|\d)]+)(?<group>(\d?[A-Z]?)+)?(\s+)?(有擋修)?/
      dep = nil;
      deps = datas[4] && datas[4].text.strip.gsub(/\u{a0}/, '').split("\n")
      if deps
        dep = deps.find do |arr|
          arr.match(dep_regex) {|m| contains_call(dep_n, m[:dep].split(""))}
        end
      end

      requires = datas[5].text.strip.gsub(/\u{a0}/, '').split("\n")

      required_index = 0
      required_index = deps.index(dep) if dep
      required = requires[required_index].include?('必')

      # m = datas[4] && datas[4].text.strip.scan(/(?<dep>(\(進修\))?[^(\s|\d)]+)(?<group>(\d?[A-Z]?)+)?(\s+)?(有擋修)?/)
      # department = []
      # if !!m
      #   department = m.map { |d| d[0] }
      # end
      # department.delete(" ")
      # department.uniq!

      year = datas[1] && datas[1].text.to_i + 1911
      term = datas[2] && datas[2].text.to_i

      course = {
        year: year,
        term: term,
        code: code,
        general_code: general_code,
        department: dep_n,
        department_code: dep_c,
        # required: datas[5] && datas[5].text.include?('必'),
        required: required,
        name: datas[6] && datas[6].text.split("\n")[0].gsub(/ /, ''),
        lecturer: datas[7] && datas[7].text.strip.split("\n").uniq.join(','),
        credits: datas[9] && datas[9].text.to_i,
        day_1: course_days[0],
        day_2: course_days[1],
        day_3: course_days[2],
        day_4: course_days[3],
        day_5: course_days[4],
        day_6: course_days[5],
        day_7: course_days[6],
        day_8: course_days[7],
        day_9: course_days[8],
        period_1: course_periods[0],
        period_2: course_periods[1],
        period_3: course_periods[2],
        period_4: course_periods[3],
        period_5: course_periods[4],
        period_6: course_periods[5],
        period_7: course_periods[6],
        period_8: course_periods[7],
        period_9: course_periods[8],
        location_1: course_locations[0],
        location_2: course_locations[1],
        location_3: course_locations[2],
        location_4: course_locations[3],
        location_5: course_locations[4],
        location_6: course_locations[5],
        location_7: course_locations[6],
        location_8: course_locations[7],
        location_9: course_locations[8],
      }
      sleep(1) until (
        list_threads.delete_if { |t| !t.status };  # remove dead (ended) threads
        list_threads.count < (ENV['MAX_THREADS'] || 20)
      )
      list_threads << Thread.new do
        @after_each_proc.call(course: course) if @after_each_proc
      end
      @courses << course
    end # each row
    ThreadsWait.all_waits(*list_threads)
  end # end parse_course method

  def contains_call(str, arrs)
    arrs.each {|arr| return false if not str.include?(arr) }
    true
  end

end # end class NtpuCourseCrawler
end
