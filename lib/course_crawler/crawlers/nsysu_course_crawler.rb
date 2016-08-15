##
# 中山課程爬蟲
# http://selcrs.nsysu.edu.tw/menu1/qrycrsfrm.asp?HIS=2&eng=0
#

module CourseCrawler::Crawlers
class NsysuCourseCrawler < CourseCrawler::Base
  include DSL

  DAYS = %w(一 二 三 四 五 六 日)

  PERIODS = {
    "A" => 1,
    "1" => 2,
    "2" => 3,
    "3" => 4,
    "4" => 5,
    "B" => 6,
    "5" => 7,
    "6" => 8,
    "7" => 9,
    "8" => 10,
    "9" => 11,
    "C" => 12,
    "D" => 13,
    "E" => 14,
    "F" => 15
  }

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil

    @query_url = "http://selcrs.nsysu.edu.tw/menu1/dplycourse.asp"
    @form_url = "http://selcrs.nsysu.edu.tw/menu1/qrycourse.asp?HIS=2&eng=&in_eng=&IDNO=&ITEM="

    @year = year || current_year
    @term = term || current_term

    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @ic = Iconv.new("utf-8//translit//IGNORE","big5")
  end

  def courses
    @courses = []
    @threads = []

    r = RestClient.get @form_url
    doc = Nokogiri::HTML(@ic.iconv r)

    deps_h = Hash[ doc.css('select[name="D1"] option:not(:first-child)').map{|opt| [opt[:value], opt.text]} ]

    deps_h.each_key do |key|
      set_progress "#{deps_h[key]}"
      begin
        doc = search_by(key, 1)

      rescue Exception => e
        next
      end

      page_num = 0
      doc.text.match(/第\ \d+\ \/\ (?<pn>\d+)\ 頁/) do |m| # 第 1 / 3 頁
        page_num = m[:pn].to_i
      end
      next if page_num.zero?

      (1..page_num).each do |i|
        sleep(1) until (
          @threads.delete_if { |t| !t.status };  # remove dead (ended) threads
          @threads.count < (ENV['MAX_THREADS'] || 20)
        )
        @threads << Thread.new do
          begin
          # print "#{i},"

          document = search_by(key, i)
          document.css('html table tr:nth-child(n+4)')[0..-3].each do |row|
            datas = row.css("td")

            general_code = datas[4] && datas[4].text
            code = "#{@year}-#{@term}-#{general_code}"

            course_days = []
            course_periods = []
            course_locations = []
            location = datas[16] && datas[16].text

            times = datas[17..23]
            times_arr = (0..6).select {|i| !times[i].text.strip.gsub("&nbsp", '').empty?}.map{|i| [(i+1).to_s, times[i].text.strip.gsub("&nbsp", '')]}
            times_h = Hash[times_arr]
            times_h.keys.each do |k|
              times_h[k].split('').each do |p|
                course_days << k.to_i
                course_periods << PERIODS[p].to_i
                course_locations << location
              end
            end

            course = {
              year: @year,
              term: @term,
              department: datas[3] && datas[3].text,
              # serial: datas[3] && datas[3].text,
              code: code,
              general_code: general_code,
              grade: datas[5] && datas[5].text,
              # class_name: datas[5] && datas[5].text,
              name: datas[7] && datas[7].text,
              url: datas[7] && datas[7].css('a')[0] && URI.encode(datas[7].css('a')[0][:href]),
              credits: datas[8] && datas[8].text.to_i,
              # semester: datas[8] && datas[8].text,
              required:datas[10] && datas[10].text.include?('必'),
              lecturer:datas[15] && datas[15].text,
              # note: datas[20] && datas[20].text,
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
          end # end each row
          rescue Exception => e

            print e.backtrace
            print "#{e}\n"
            print "Error department: #{deps_h[key]}\n"
            sleep 3
            redo
          end
        end # end thread do
      end # each page
    end # end each deps
    ThreadsWait.all_waits(*@threads)

    @courses
  end # end courses

  def search_by dep_c, page_num
    r = RestClient.get(@query_url + "?" + {
      "a" => '1',
      "D0" => "#{@year-1911}#{@term}",
      "D1" => dep_c,
      "D2" => '',
      "CLASS_COD" => '',
      "T3" => '',
      "teacher" => '',
      "crsname" => '',
      "WKDAY" => '',
      "SECT" => '',
      "SECT_COD" => '',
      "ALL" => '',
      "CB1" => '',
      "SPEC" => '',
      "HIS" => '1',
      "IDNO" => '',
      "ITEM" => '',
      "TYP" => '1',
      "bottom_per_page" => '10',
      "data_per_page" => '20',
      "page" => page_num,
    }.map{|k, v| "#{k}=#{v}"}.join('&'))

    Nokogiri::HTML(@ic.iconv r)
  end
end
end
