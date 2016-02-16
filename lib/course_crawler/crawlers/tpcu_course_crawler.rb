# 臺北城市科技大學
# 課程查詢網址：http://eportfolio.tpcu.edu.tw/bin/index.php?Plugin=coursemap&Action=schoolcourse

# 沒有課程時間
module CourseCrawler::Crawlers
class TpcuCourseCrawler < CourseCrawler::Base

  # DAYS = {
  #   "一" => 1,
  #   "二" => 2,
  #   "三" => 3,
  #   "四" => 4,
  #   "五" => 5,
  #   "六" => 6,
  #   "日" => 7
  #   }

  # PERIODS = {
  #   "1" => 1,
  #   "2" => 2,
  #   "3" => 3,
  #   "4" => 4,
  #   "5" => 5,
  #   "6" => 6,
  #   "7" => 7,
  #   "8" => 8,
  #   "9" => 9,
  #   "A" => 10,
  #   "B" => 11,
  #   "C" => 12,
  #   "D" => 13,
  #   "E" => 14
  #   }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://eportfolio.tpcu.edu.tw/bin/index.php?Plugin=coursemap&Action='
  end

  def courses
    @courses = []
    course_id = 0

    # r = RestClient.get(@query_url+"schoolcourse")
    # doc = Nokogiri::HTML(r)

    r = RestClient.post(@query_url+"course&TagName=id_YSK_search_result", {
      "rs" => "sajaxSubmit",
      "rsargs[]" => "<Input><F><K>year</K><V>#{@year-1911}</V></F><F><K>semester</K><V>#{@term}</V></F><F><K>degree</K><V></V></F><F><K>dept</K><V></V></F><F><K>grade</K><V></V></F><F><K>byteacher</K><V>0</V></F><F><K>undefined</K><V>undefined</V></F><F><K>keyword</K><V>%E8%AB%8B%E8%BC%B8%E5%85%A5%E9%97%9C%E9%8D%B5%E5%AD%97</V></F><F><K></K><V>%E6%9F%A5%E8%A9%A2</V></F><F><K>dgrName</K><V></V></F><F><K>deptName</K><V></V></F><F><K>Op</K><V>sBySch</V></F></Input>",
      })
    doc = Nokogiri::HTML(r)

    doc.css('div[id="WtucCsMap"] tr').each do |tr|
      data = tr.css('td').map{|td| td.text}
      syllabus_url_data = tr.css('td a')[0][:onclick].split("'")
      syllabus_url = @query_url+"course&Op=getCourseDetail&Year=#{@year-1911}&DgrId=#{syllabus_url_data[3]}&DeptId=#{syllabus_url_data[1]}&SubId=#{syllabus_url_data[5]}&Com=0&ClsId=#{syllabus_url_data[9]}&SrcDup=#{syllabus_url_data[11]}&Type=#{syllabus_url_data[7]}&Semester=#{@term}&TagName=urlPop11&DivId=urlPop11&rs=sajaxSubmit&rsargs[]=%3CInput%3E%3CF%3E%3CK%3E%3C/K%3E%3CV%3Eundefined%3C/V%3E%3C/F%3E%3C/Input%3E"
      course_id += 1

      # course_time_location = time.scan(time_period_regex)

      course_days, course_periods, course_locations = [], [], []
      # course_time_location.each do |k, v|
      #   course_days << DAYS[k[0]]
      #   course_periods << PERIODS[k[1..-1]]
      #   course_locations << v
      # end

      course = {
        year: @year,    # 西元年
        term: @term,    # 學期 (第一學期=1，第二學期=2)
        name: data[3].gsub(/[\t\s]/,""),    # 課程名稱
        lecturer: data[9],    # 授課教師
        credits: data[7].to_i,    # 學分數
        code: "#{@year}-#{@term}-#{course_id}_#{syllabus_url_data[5]}",
        general_code: syllabus_url_data[5],    # 選課代碼
        url: syllabus_url,    # 課程大綱之類的連結
        required: data[6].include?('必'),    # 必修或選修
        department: data[5],    # 開課系所
        # department_code: syllabus_url_data[9],
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
# binding.pry
    end
    @courses
  end
end
end