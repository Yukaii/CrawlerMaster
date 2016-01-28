# 國立暨南國際大學
# 課程查詢網址：http://www.doc.ncnu.edu.tw/ncnu/index.php?option=com_content&view=article&id=324&Itemid=382&lang=tw

module CourseCrawler::Crawlers
class NcnuCourseCrawler < CourseCrawler::Base

  PERIODS = {
    "x" => 1,
    "y" => 2,
    "a" => 3,
    "b" => 4,
    "c" => 5,
    "d" => 6,
    "z" => 7,
    "e" => 8,
    "f" => 9,
    "g" => 10,
    "h" => 11,
    "i" => 12,
    "j" => 13,
    "k" => 14,
    "l" => 15,
    "m" => 16
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://www.ncnu.edu.tw/ncnuweb/'
  end

  def courses
    @courses = []

    doc = %x(curl -s '#{@query_url}services/course.aspx' --compressed)

    depts = doc.scan(/\"(?<dep>\w\w?\d\d\d?)\"/)[1..-1]

    # 要看有沒有必修要跑到另一個網頁看阿！！！
    required = []
    # depts_id = ["00","01","04","03","06","05","08","Z6","38","39","46","C2","12","11","13","14","19","18","Zc","45","29","22","21","23","24","00","00","00","28","00","02","07","09","00","35","00"]
    depts_id = ["00","01","02","03","04","05","06","07","08","09","11","12","13","14","18","19","21","22","23","24","28","29","35","38","39","45","46","C2","Z6","Zc"]
    ["B","G","P"].each do |i|
      depts_id.each do |dept|
        doc = %x(curl -s '#{@query_url}webservice/csvDepartRequireCourses.aspx?year=#{@year-1911}&deptid=#{dept}&class=#{i}' --compressed)
        required += doc[1..-4].split("\"\r\n\"")[2..-1].map{|required_course| required_course.split("\",\"")[3]}

        doc = %x(curl -s '#{@query_url}webservice/csvDepartGroupCourses.aspx?year=#{@year-1911}&deptid=#{dept}&class=#{i}' --compressed)
        if doc[1..-4].split("\"\r\n\"")[2..-1] != nil
          required += doc[1..-4].split("\"\r\n\"")[2..-1].map{|required_course| required_course.split("\",\"")[3]}
        end
      end
    end

    course_id = 0

    depts.each do |dept|
      doc = %x(curl -s '#{@query_url}webservice/csvDepartOpenCourses.aspx?year=#{@year-1911}#{@term}&uid=#{dept[0]}' --compressed)

      doc[1..-4].split("\"\r\n\"")[1..-1].each do |line|
        course_id += 1
        # "學期別","開課系所","課程綱要(general_code)","課程名稱","開課教師","部別","年級","學分","時間","地點"
        data = line.split("\",\"")
        syllabus_url = "#{@query_url}webservice/csvDepartOpenCourseSyllabus.aspx?year=#{@year-1911}#{@term}&courseid=#{data[2]}"

        course_days, course_periods, course_locations = [], [], []
        if data[8] != nil
          course_time = Hash[ data[8].scan(/((?<day>\d)(?<period>\w+))+?/) ]

          course_time.each do |day, period|
            period.split('').each do |p|
              course_days << day[0].to_i
              course_periods << PERIODS[p[0]]
              course_locations << data[9]
            end
          end
        end

        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[3],    # 課程名稱
          lecturer: data[5],    # 授課教師
          credits: data[8].to_i,    # 學分數
          code: "#{@year}-#{@term}-#{course_id}_#{data[2]}",
          general_code: data[2],    # 選課代碼
          url: syllabus_url,    # 課程大綱之類的連結
          required: required.include?(data[3]),    # 必修或選修
          department: data[1],    # 開課系所
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

# binding.pry if dept[0] == "mf00"
      end
    end
    @courses
  end

end
end
