# 台灣首府大學
# 課程查詢網址：http://erp1.tsu.edu.tw/dwu/

module CourseCrawler::Crawlers
class TsuCourseCrawler < CourseCrawler::Base

  # PERIODS = {
  #   "1" => 1,
  #   "2" => 2,
  #   "3" => 3,
  #   "4" => 4,
  #   "N" => 5,
  #   "5" => 6,
  #   "6" => 7,
  #   "7" => 8,
  #   "8" => 9,
  #   "9" => 10,
  #   "10" => 11,
  #   "11" => 12,
  #   "12" => 13,
  #   "13" => 14
  #   }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://erp1.tsu.edu.tw/dwu/'
  end

  def courses
    @courses = []
    course_id = 0

    cookie = RestClient.get(@query_url+"choice.jsp").cookies

    r = %x(curl -s '#{@query_url}perchk.jsp' -H 'Cookie: JSESSIONID=#{cookie["JSESSIONID"]}' --data 'uid=GUEST&pwd=123123&ls_chochk=N&myway=yes&sys_name=web&myway=yes&sys_name=web' --compressed)

    r = %x(curl -s '#{@query_url}ag_pro/ag304_01.jsp' -H 'Cookie: JSESSIONID=#{cookie["JSESSIONID"]}' --compressed)
    doc = Nokogiri::HTML(r)

    doc.css('select[name="rtxt_untid"] option:nth-child(n+2)').map{|opt| [opt[:value],opt.text]}.each do |dept_v,dept_n|
      r = %x(curl -s '#{@query_url}ag_pro/ag304_02.jsp' -H 'Cookie: JSESSIONID=#{cookie["JSESSIONID"]}' --data 'yms_yms=#{@year-1911}%23#{@term}&rtxt_untid=#{dept_v}&unit_serch=%E6%9F%A5+%E8%A9%A2' --compressed)
      doc = Nokogiri::HTML(r)
      next if doc.css('table td[width="50%"]').count == 0  # 沒有課程就略過

      doc.css('table td[width="50%"]').map{|td| td[:onclick].split("'")[1]}.each do |cla_url|
        # 進入課表
        r = %x(curl -s '#{@query_url}ag_pro/#{cla_url}' -H 'Cookie: JSESSIONID=#{cookie["JSESSIONID"]}' --compressed)
        doc = Nokogiri::HTML(r)

        courses_data_temp = course_time_table(doc.css('table:nth-child(5) tr:nth-child(n+2) td:nth-child(n+2)').map{|table| table.text})
        courses_data_temp.each do |course_code,data|
# puts "#{course_code},#{@query_url}ag_pro/#{cla_url}"

          course_id += 1

          course_days, course_periods, course_locations = [], [], []
          data['time'].each do |day, period, loc|
            course_days << day
            course_periods << period
            course_locations << loc
          end

          course = {
            year: @year,    # 西元年
            term: @term,    # 學期 (第一學期=1，第二學期=2)
            name: data['name'],    # 課程名稱
            lecturer: data['teacher'],    # 授課教師
            credits: data['credits'],    # 學分數
            code: "#{@year}-#{@term}-#{course_id}_#{course_code}",
            general_code: course_code,    # 選課代碼
            url: nil,    # 課程大綱之類的連結
            required: nil, #course_type.include?('必'),    # 必修或選修
            department: dept_n,    # 開課系所
            # department_code: dept_v,
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
        end
      end
    end
    @courses
  end

# 分析課表
  def course_time_table table_data
    day = 0
    period = 1
    courses_data_temp = {}

    table_data.each do |block|
      if day < 7
        day += 1
      else
        day = 1
        period += 1
        period = 6 if period == 5
        period = 5 if period == 15
      end
      next if block == " "

      course_temp = block.split("選課代碼 - ")
      course_temp.each do |cor|
        next if cor == ""

        cor.scan(/(\d\d\d\d)(.*?) (.+)/).each do |course_code,name,loc|
          if courses_data_temp[course_code] == nil
            if name.scan(/([\W\w\(\)]+\d\d)(\W+)/)[0] != nil
              c_name = name.scan(/([\W\w\(\)]+\d\d)(\W+)/)[0][0]
              t_name = name.scan(/([\W\w\(\)]+\d\d)(\W+)/)[0][1]
            else
              c_name = name
              t_name = nil
            end
            courses_data_temp[course_code] = {}
            courses_data_temp[course_code]['time'] = []
            courses_data_temp[course_code]['teacher'] = t_name
            courses_data_temp[course_code]['name'] = c_name
            courses_data_temp[course_code]['credits'] = 0
          end
          courses_data_temp[course_code]['time'] << [day,period,loc]
          courses_data_temp[course_code]['credits'] += 1
        end
      end
    end
    courses_data_temp
  end

end
end
