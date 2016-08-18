# 致理技術學院
# 課程查詢網址：http://coursequery.chihlee.edu.tw/CourseQuery/CourseList/qCourseList.aspx

module CourseCrawler::Crawlers
class ChihleeCourseCrawler < CourseCrawler::Base

  DAYS = {
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6,
    "日" => 7
    }

# 星期六的上課時間與平日不同
# http://140.131.78.101/CSSystem/generalDesc/timeKH.aspx
# 星期六的節次 : A01 => 1+14 = 15 , ... , A04 => 4+14 = 18, ... , C08 => 12+14 = 26
  PERIODS = {
    "A01" => 1,
    "A02" => 2,
    "A03" => 3,
    "A04" => 4,
    "A05" => 5,
    "A06" => 6,
    "A07" => 7,
    "A08" => 8,
    "A09" => 9,
    "X01" => 10,
    "B01" => 11,
    "B02" => 12,
    "B03" => 13,
    "B04" => 14,
    "C01" => 19,
    "C02" => 20,
    "C03" => 21,
    "C04" => 22,
    "C05" => 23,
    "C06" => 24,
    "C07" => 25,
    "C08" => 26
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://coursequery.chihlee.edu.tw/CourseQuery/CourseList/qCourseList.aspx'
    @ic = Iconv.new('utf-8//IGNORE//translit', 'big5')  # 如果遇到utf-8轉HTML有錯誤，可以先utf-8轉utf-8(可以除錯)
  end

  def courses
    @courses = []
    course_id = 0
    puts "get url ..."
    r = %x(curl -s '#{@query_url}' --compressed)
    doc = Nokogiri::HTML(r)

    hidden = Hash[Nokogiri::HTML(r).css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    r = %x(curl -s '#{@query_url}' --data 'ScriptManager1=UpdatePanel1|cboxDName&__EVENTTARGET=cboxDName&__EVENTARGUMENT=&__LASTFOCUS=&__VIEWSTATE=#{URI.escape(hidden['__VIEWSTATE'],"/=+")}&__VIEWSTATEGENERATOR=#{URI.escape(hidden['__VIEWSTATEGENERATOR'],"/=+")}&__VIEWSTATEENCRYPTED=#{URI.escape(hidden['__VIEWSTATEENCRYPTED'],"/=+")}&__EVENTVALIDATION=#{URI.escape(hidden['__EVENTVALIDATION'],"/=+")}&dlYT=#{@year-1911}#{@term}&cboxDName=on&week_list=0&dlOpenClass=&CoursePlan_list=&' --compressed)
    doc = Nokogiri::HTML(r)

    hidden = Hash[Nokogiri::HTML(r).css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    doc.css('select[name="deptID_list"] option:nth-child(n+2)').map{|opt| [opt[:value],opt.text]}.each do |dept_v,dept_n|
      r = %x(curl -s '#{@query_url}' --data '__EVENTTARGET=&__EVENTARGUMENT=&__LASTFOCUS=&__VIEWSTATE=#{URI.escape(hidden['__VIEWSTATE'],"/=+")}&__VIEWSTATEGENERATOR=#{URI.escape(hidden['__VIEWSTATEGENERATOR'],"/=+")}&__VIEWSTATEENCRYPTED=#{URI.escape(hidden['__VIEWSTATEENCRYPTED'],"/=+")}&__EVENTVALIDATION=#{URI.escape(hidden['__EVENTVALIDATION'],"/=+")}&dlYT=#{@year-1911}#{@term}&cboxDName=on&deptID_list=#{dept_v}&week_list=0&dlOpenClass=&CoursePlan_list=&btnQuery=%E6%9F%A5%E8%A9%A2' --compressed)
      doc = Nokogiri::HTML(r)

      doc.css('table[id="gvCourseDetails1"] tr:nth-child(n+2)').each do |tr|
        data = tr.css('td').map{|td| td.text.gsub(/[\r\n\s]/,"")}
        syllabus_url = tr.css('td a')[-1][:href]

        course_time_location = data[11].scan(/(?<day>[一二三四五六日])(?<period>\w+)\((?<loc>\w+)/)

        course_days, course_periods, course_locations = [], [], []
        course_time_location.each do |day, period, loc|
          course_days << DAYS[day]
          if DAYS[day] != 6
            course_periods << PERIODS[period]
          else
            period = PERIODS[period]+14
            course_periods << period
          end
          course_locations << loc
        end
        puts "data crawled : " + data[7]
        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[7],    # 課程名稱
          lecturer: data[1],    # 授課教師
          credits: data[12].to_i,    # 學分數
          code: "#{@year}-#{@term}-#{data[6]}_#{data[0]}",
          general_code: data[0],    # 選課代碼
          url: syllabus_url,    # 課程大綱之類的連結
          required: data[16].include?('必'),    # 必修或選修
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
    puts "Project finished !!!"
    @courses
  end
end
end
