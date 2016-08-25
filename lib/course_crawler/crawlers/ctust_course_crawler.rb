# 中臺科技大學
# 課程查詢網址：http://ccservice.ctust.edu.tw/ctust3g/function/cr/crq.aspx

# 校務資訊系統：http://120.107.40.140/CTUST/
# 帳號：guest1
# 密碼：guest1
module CourseCrawler::Crawlers
class CtustCourseCrawler < CourseCrawler::Base

  DAYS = {
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6,
    "日" => 7
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://ccservice.ctust.edu.tw/ctust3g/function/cr/'
  end

  def courses
    @courses = []
    puts "get url ..."
    r = RestClient.get(@query_url+"crq.aspx")

    hidden = Hash[Nokogiri::HTML(r).css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]
    doc = Nokogiri::HTML(r)
    cookie = nil

    doc.css('select[name="ddlFaculty"] option:nth-child(n+2)').map{|opt| [opt[:value],opt.text]}.each do |dept_v, dept_n|
# puts "#{dept_n}"
      r = RestClient.post(@query_url+"crq.aspx", hidden.merge({
        "ddlAcademicYear" => @year-1911,
        "ddlSemester" => @term,
        "tbxCourseBeginId" => "",
        "ddlDivision" => "0",
        "tbxCourseBeginName" => "",
        "ddlEducationSystem" => "0",
        "tbxTeacherId" => "",
        "ddlFaculty" => dept_v,
        "tbxTeacherName" => "",
        "tbxOpenCourseSquadId" => "",
        "tbxCourseId" => "",
        "ddlMaxCnt" => "10000",
        "btnQuery" => "查詢",
        }) )

      doc = Nokogiri::HTML(r)
      hidden = Hash[Nokogiri::HTML(r).css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]
# puts doc.css('table table tr:nth-child(5) td span').text
      next if doc.css('table table tr:nth-child(5) td span').text == "查無資料！"

      r = RestClient.post(@query_url+"crq.aspx", hidden.merge({
        "ddlAcademicYear" => @year-1911,
        "ddlSemester" => @term,
        "tbxCourseBeginId" => "",
        "ddlDivision" => "0",
        "tbxCourseBeginName" => "",
        "ddlEducationSystem" => "0",
        "tbxTeacherId" => "",
        "ddlFaculty" => dept_v,
        "tbxTeacherName" => "",
        "tbxOpenCourseSquadId" => "",
        "tbxCourseId" => "",
        "ddlMaxCnt" => "10000",
        "BtnPrintSelectedItem" => "批次列印",
        "DatagridCourseIntroList$ctl01$CheckBoxInGridHead" => "on",
        }) )

      doc = Nokogiri::HTML(r)
      hidden = Hash[Nokogiri::HTML(r).css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]
      cookie = r.cookies if cookie == nil

      r = RestClient.get(@query_url+"crpcm2.aspx", {:cookies => cookie})
      doc = Nokogiri::HTML(r)

      course_table_index = []
      table = doc.css('table[border="2"]')
      (0..table.map{|table| table.css('tr:first-child').text}.length-1).each do |t|
        if table.map{|table| table.css('tr:first-child').text}[t].include?("開課學年期")
          course_table_index << t
        end
      end

      course_table_index.each do |t|
        data = table[t].css('td:nth-child(2n+2)').map{|td| td.text}

        course_time_location = data[7].scan(/(?<day>[一二三四五六日])第(?<period>\d)節-(?<loc>[\w\-]+)/)

        course_days, course_periods, course_locations = [], [], []
        course_time_location.each do |day, period, loc|
          course_days << DAYS[day]
          course_periods << period.to_i
          course_locations << loc
        end
        puts "data crawled : " + data[1]
        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[1],    # 課程名稱
          lecturer: data[3],    # 授課教師
          credits: data[10].to_i,    # 學分數
          code: "#{@year}-#{@term}-#{data[13]}_#{data[14]}",
          general_code: data[14],    # 選課代碼
          url: nil,    # 沒有課程大綱之類的連結
          required: data[8].include?('必'),    # 必修或選修
          department: data[5],    # 開課系所
          # department_code: data[12],
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
      cookie = nil
    end
    puts "Project finished !!!"
    @courses
  end

end
end
