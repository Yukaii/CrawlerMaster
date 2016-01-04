# 國立中興大學
# 選課網址: https://onepiece.nchu.edu.tw/cofsys/plsql/crseqry_home

module CourseCrawler::Crawlers
class NchuCourseCrawler < CourseCrawler::Base
  include CrawlerRocks::DSL

  PERIODS = {
    # Note:
    # 1st period start from 8:00 am
    # may need to change period code
    "1" => 1,
    "2" => 2,
    "3" => 3,
    "4" => 4,
    "5" => 5,
    "6" => 6,
    "7" => 7,
    "8" => 8,
    "9" => 9,
    "A" => 10,
    "B" => 11,
    "C" => 12,
    "D" => 13,
  }

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil

    # @query_url = "https://onepiece.nchu.edu.tw/cofsys/plsql/crseqry_all"
    @query_url = "https://onepiece.nchu.edu.tw/cofsys/plsql/crseqry_home"
    @base_url = "https://onepiece.nchu.edu.tw/cofsys/plsql/"

    @year = year || current_year
    @term = term || current_term

    @update_progress_proc = update_progress
    @after_each_proc = after_each
  end

  def courses
    @courses = []
    year_term = "#{@year-1911}#{@term}"

    visit @query_url + "?v_year=#{year_term}"
    @deps_h = Hash[@doc.css('select[name="v_dept"] option').map{ |opt| [opt[:value], opt.text.delete(opt[:value]).strip] }]
    @deps_h_rev = Hash[@deps_h.map{|k, v| [v, k]}]

    @threads = []
    @deps_h.each_key do |dep_c|
      sleep(1) until (
        @threads.delete_if { |t| !t.status };  # remove dead (ended) threads
        @threads.count < (ENV['MAX_THREADS'] || 20)
      )
      @threads << Thread.new do
        r = RestClient.post @query_url, {
          v_year: year_term,
          v_career: 'U', # 學士班
          v_dept: dep_c
        }
        parse_courses(Nokogiri::HTML(r.to_s))
        print "#{@deps_h[dep_c]}\n"
      end
    end
    ThreadsWait.all_waits(*@threads)

    @courses
  end

  def parse_courses(doc)
    # dep_regex = /選課系所:(?<dep_c>.*?)\s+(?<dep_n>.*?)\s*?年級：(?<g>\d)\s+班別：(?<c>.?)\s*?/
    dep_regex = /系所名稱:(?<dep_n>.+?)\s*?年級:(?<g>\d)?\s+班別:(?<c>.?)\s*?/
    dep_matches = doc.css('strong').map{ |strong| strong.text.strip.gsub(/\&nbsp/, ' ') }.select{|strong| strong.match(dep_regex)}.map{|strong| strong.match(dep_regex)}

    _tables =  doc.css('table.word_13')[1..-1]
    _tables.each_with_index do |table, index|
      table.css('tr')[1..-1].map do |row|
        datas = row.css('td')
        url = "#{@base_url}#{datas[1] && datas[1].css('a')[0] && datas[1].css('a')[0][:href]}"

        # 決定是否為實習課
        normal = datas[7] && datas[7].text.gsub(/\u3000/, '').empty?

        time_index = normal ? 8 :  9
        loc_index  = normal ? 10 : 11
        lec_index  = normal ? 12 : 13

        times = datas[time_index] && datas[time_index].text
        location = datas[loc_index] && datas[loc_index].text.gsub(/\u3000/, '')

        course_days = []
        course_periods = []
        course_locations = []

        # normalize periods
        if times && location
          _splt = times.strip.include?(',') ? ',' : ' '
          times.strip.split(_splt).each do |time|
            time.match(/(?<d>\d)(?<p>.+)/) do |m|
              m[:p].split('').each do |period|
                next if PERIODS[period].nil?
                course_days << m[:d].to_i
                course_periods << PERIODS[period]
                course_locations << location.gsub(/\u3000/, '')
              end
            end
          end
        end

        department = dep_matches[index][:dep_n]
        department_code = @deps_h_rev[department]

        general_code = datas[1].text.strip

        course = {
          year: @year,
          term: @term,
          required: datas[0] && datas[0].text.include?('必'),
          code: datas[1] && datas[1].text && "#{@year}-#{@term}-#{general_code}-#{department_code}",
          general_code: general_code,
          url: url,
          name: datas[2] && datas[2].text,
          semester: datas[4] && datas[4].text,
          credits: datas[5] && datas[5].text && datas[5].text.to_i,
          hour: datas[6] && datas[6].text,
          lecturer: datas[lec_index] && datas[lec_index].text,
          # department: datas[14] && datas[14].text,
          department: department,
          department_code: department_code,
          note: datas[19] && datas[19].text,
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
        @after_each_proc.call(course: course) if @after_each_proc
        @courses << course
      end # table.css('tr')
    end # .inject {|arr, nxt| arr.concat(nxt)} # _tables.map
  end # parse_courses
end
end
