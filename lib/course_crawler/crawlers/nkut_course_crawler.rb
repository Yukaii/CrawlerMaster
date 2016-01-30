# 南開科技大學
# 課程查詢網址：http://coursemap.nkut.edu.tw/bin/index.php?Plugin=coursemap&Action=schoolcourse

# 沒有節次資料，也沒有課程代碼...
module CourseCrawler::Crawlers
class NkutCourseCrawler < CourseCrawler::Base

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

    @query_url = 'http://coursemap.nkut.edu.tw/bin/index.php?Plugin=coursemap&Action=course&TagName=id_YSK_search_result'
    @query_url2 = "http://coursemap.nkut.edu.tw/bin/index.php?Plugin=coursemap&Action=course&Op=getCourseDetail&Year=#{@year-1911}&Type=1&Semester=#{@term}"
  end

  def courses
    @courses = []
    course_id = 0

    r = RestClient.post(@query_url, {
      "rs" => "sajaxSubmit",
      "rsargs[]" => "<Input><F><K>year</K><V>#{@year-1911}</V></F><F><K>semester</K><V>#{@term}</V></F><F><K>degree</K><V></V></F><F><K>dept</K><V></V></F><F><K>grade</K><V></V></F><F><K>byteacher</K><V>0</V></F><F><K>undefined</K><V>undefined</V></F><F><K>keyword</K><V>%E8%AB%8B%E8%BC%B8%E5%85%A5%E9%97%9C%E9%8D%B5%E5%AD%97</V></F><F><K></K><V>%E6%9F%A5%E8%A9%A2</V></F><F><K>dgrName</K><V>%E4%B8%8D%E5%88%86%E5%AD%B8%E5%88%B6</V></F><F><K>deptName</K><V></V></F><F><K>Op</K><V>sBySch</V></F></Input>",
      })
    doc = Nokogiri::HTML(r)

    doc.css('table:last-child tr').map{|tr| tr}.each do |tr|
      data = tr.css('td').map{|td| td.text}
# puts data[3].gsub(/[\n\t\s]/,'')
      url_data = tr.css('td a').map{|a| a[:onclick]}[0].scan(/\'(?<codes>[\d\w]+?)?\'/)
      r = RestClient.post(@query_url2+"&DgrId=#{url_data[1][0]}&DeptId=#{url_data[0][0]}&SubId=#{url_data[2][0]}&Com=#{url_data[3][0]}&ClsId=#{url_data[4][0]}&SrcDup=#{url_data[5][0]}", {
        "rs" => "sajaxSubmit",
        "rsargs[]" => "<Input><F><K></K><V>undefined</V></F></Input>",
        })
      doc = Nokogiri::HTML(r)

      course_code = doc.css('tr:nth-child(7) td')[1].text
      course_code = 0 if course_code == ""

      course_id += 1

      # time_period_regex = /(?<period>[MFTSWUR][\dA-Z]+)(\((?<loc>.*?)\))?/
      # course_time_location = Hash[ time.scan(time_period_regex) ]

      course_days, course_periods, course_locations = [], [], []
      # course_time_location.each do |k, v|
      #   course_days << DAYS[k[0]]
      #   course_periods << PERIODS[k[1..-1]]
      #   course_locations << v
      # end

      course = {
        year: @year,    # 西元年
        term: @term,    # 學期 (第一學期=1，第二學期=2)
        name: data[3].gsub(/[\n\t\s]/,''),    # 課程名稱
        lecturer: data[9],    # 授課教師
        credits: data[7].to_i,    # 學分數
        code: "#{@year}-#{@term}-#{course_id}_#{course_code}",
        general_code: course_code,    # 選課代碼
        url: nil,    # 課程大綱之類的連結
        required: data[6].include?('必'),    # 必修或選修
        department: data[2],    # 開課系所
        # department_code: url_data[0][0],
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