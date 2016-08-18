##
# 逢甲課程爬蟲
# 選課網址：http://sdsweb.oit.fcu.edu.tw/coursequest/condition.jsp
# 使用 guest/guest 登入
# 登入後到進階查詢(http://sdsweb.oit.fcu.edu.tw/coursequest/advance.jsp)

# 沒有上課地點,必選修,教師名稱
module CourseCrawler::Crawlers
class FcuCourseCrawler < CourseCrawler::Base

 DAYS = {
  "一" => 1,
  "二" => 2,
  "三" => 3,
  "四" => 4,
  "五" => 5,
  "六" => 6,
  "日" => 7,
  }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each
    @count = 1
    @query_url = 'http://sdsweb.oit.fcu.edu.tw/coursequest/'
  end

  def courses
    @courses = []
    puts "get url ..."
    cookie = RestClient.post(@query_url+"condition.jsp", {
      "userID" => "guest",
      "userPW" => "guest",
      "Button2" => "%B5n%A4J",
      }).cookies

    week_start_end_data = []
    (1..7).each do |w|
      week_start_end_data += [[w,1,7],[w,8,14]]
    end

    week_start_end_data.each do |wsed|
      r = RestClient.post(@query_url+"advancelist.jsp", {
        "yms_year" => "#{@year-1911}",
        "yms_smester" => "#{@term}",
        "week" => wsed[0],
        "start" => wsed[1],
        "end" => wsed[2],
        "submit1" => "%ACd++%B8%DF",
        }, {"Cookie" => "JSESSIONID=#{cookie["JSESSIONID"]}"})
      doc = Nokogiri::HTML(r)

# puts "#{wsed},#{doc.css('table tr:not(:first-child)').count}"
      doc.css('table tr:not(:first-child)').each do |tr|
        data = tr.css('td').map{|td| td.text.gsub(/[\r\t\n\s]/,"")}
        syllabus_url = "http://sdsweb.oit.fcu.edu.tw#{tr.css('td a').map{|a| a[:href]}[0][2..-1]}"
        course_code = data[1].scan(/\w+/)[0] if data[1] != nil

        course_time = data[7].scan(/\((?<day>[一二三四五六日])\)(?<period>[\d\-]+)/)

        # 把 course_time_location 轉成資料庫可以儲存的格式
        course_days, course_periods, course_locations = [], [], []
        course_time.each do |day, period|
          (period.split("-")[0].to_i..period.split("-")[-1].to_i).each do |p|
            course_days << DAYS[day]
            course_periods << p+1
            course_locations << nil # 沒有上課地點
          end
        end
        puts "data crawled : " + data[1]
        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[1],    # 課程名稱
          lecturer: nil,    # 授課教師
          credits: data[3].to_i,    # 學分數(需要轉換成數字，可以用.to_i)
          code: "#{@year}-#{@term}-#{course_code}-#{data[0]}-#{@count}",
          general_code: data[0]+"-#{@count}",    # 選課代碼
          url: syllabus_url,    # 課程大綱之類的連結(如果有的話)
          required: nil,    # 必修或選修
          department: data[6],    # 開課系所
          # note: data[11],
          # department_term: data[2],
          # mid_exam: data[4],
          # final_exam: data[5],
          # exam_early: data[6],
          # limit_people: data[9],    # 開放名額
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
        @count += 1
        @after_each_proc.call(course: course) if @after_each_proc

        @courses << course
      end
    end
    puts "Project finished !!!"
    @courses
  end

end
end
