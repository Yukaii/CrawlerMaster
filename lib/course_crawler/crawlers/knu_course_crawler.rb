# 開南大學
# 課程查詢網址：http://portal.knu.edu.tw/info/Application/COU/COU130Q_01v1.aspx

# 有課程資料可以下載真好
# http://portal.knu.edu.tw/info/Application/COU/COU200M_01v1.aspx

module CourseCrawler::Crawlers
class KnuCourseCrawler < CourseCrawler::Base

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

    @query_url = 'http://portal.knu.edu.tw/info/'
  end

  def courses
    @courses = []

    r = RestClient.get(@query_url+"Application/COU/COU200M_01v1.aspx")
    doc = Nokogiri::HTML(r)
    puts "get url ..."

    url = doc.css('table[class="sortable"] tr:nth-child(n+2)')
    url.count.times do |u|
      if url[u].text.include?("#{@year - 1911}#{@term}")
        url = "#{@query_url}#{url[u].css('a')[0][:href][6..-1]}"
        break
      end
    end

    r = `curl -s '#{url}' --compressed`

    xls_file = Tempfile.new('knu_course_data_temp.xls')
    xls_file.write(r)

    doc = Spreadsheet.open(xls_file.path)

    doc.worksheets[0].map { |row| row }[1..-1].each do |data|
      course_time_location = data[11].scan(/週(?<day>[#{DAYS.keys.join}])(?<period>\d+)(?<loc>\w+)/)

      course_days = []
      course_periods = []
      course_locations = []
      course_time_location.each do |day, period, loc|
        course_days << DAYS[day]
        course_periods << period.to_i
        course_locations << loc
      end

      course = {
        year: @year,    # 西元年
        term: @term,    # 學期 (第一學期=1，第二學期=2)
        name: "#{data[4]} #{data[3]}",    # 課程名稱
        lecturer: data[7],    # 授課教師
        credits: data[6].to_i,    # 學分數
        code: "#{@year}-#{@term}-#{data[2]}",
        general_code: data[2],    # 選課代碼
        url: nil,    # 課程大綱之類的連結
        required: data[10].include?('必'),    # 必修或選修
        department: data[14],    # 開課系所
        # department_code: nil,
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
        location_9: course_locations[8]
      }

      @after_each_proc.call(course: course) if @after_each_proc

      @courses << course
    end
    puts "Project finished !!!"
    @courses
  end
end
end
