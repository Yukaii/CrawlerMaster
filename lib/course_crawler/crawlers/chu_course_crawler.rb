# 中華大學
# 課程查詢網址：http://140.126.122.38/

module CourseCrawler::Crawlers
class ChuCourseCrawler < CourseCrawler::Base

  DAYS = {
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6,
    "日" => 7
    }

  PERIODS = {
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
    "E" => 14
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://140.126.122.38/'
    @ic = Iconv.new('utf-8//IGNORE//translit', 'big5')
  end

  def courses
    @courses = []
    course_id = 0

    r = RestClient.post(@query_url+"index_1.asp", {
      "open_year" => @year-1911,
      "open_semester" => @term,
      "Submit1" => "%ACd%B8%DF"
      })#, {"Cookie" => cookie})
    cookie = r.cookies

    r = %x(curl -s '#{@query_url}schedular.asp' -H 'Cookie: ASPSESSIONIDCSSATAQT=#{cookie["ASPSESSIONIDCSSATAQT"]}' --data 'Submit1=%ACO%A1A%B6%7D%A9l%ACd%B8%DF' --compressed)

    r = %x(curl -s '#{@query_url}schedular_check.asp' -H 'Cookie: ASPSESSIONIDCSSATAQT=#{cookie["ASPSESSIONIDCSSATAQT"]}' --data 'keyword=%25&text_course=%ACd%B8%DF' --compressed)

    r = %x(curl -s '#{@query_url}schedular_result.asp' -H 'Cookie: ASPSESSIONIDCSSATAQT=#{cookie["ASPSESSIONIDCSSATAQT"]}' --compressed)
    doc = Nokogiri::HTML(@ic.iconv(r))

    # 把課程資料整理出來，順便累加course_id
    course_id = input_course_to_hash(doc, course_id)

    pages = doc.css('table[bgcolor="#FFFFFF"] tr[bgcolor="#CCCCCC"] td p font font:nth-child(5)')[0].text.to_i
    (2..pages).each do |page|
puts "#{course_id}/page#{page}"
      r = %x(curl -s '#{@query_url}schedular_result.asp?page=#{page}' -H 'Cookie: ASPSESSIONIDCSSATAQT=#{cookie["ASPSESSIONIDCSSATAQT"]}' --compressed)
      doc = Nokogiri::HTML(@ic.iconv(r))

      course_id = input_course_to_hash(doc, course_id)
    end

    @courses
# binding.pry
  end

  def input_course_to_hash doc, course_id
    doc.css('table[bgcolor="#FFFFFF"] tr[bgcolor="#EEEEEE"]').each do |tr|
      data = tr.css('td').map{|td| td.text}

      course_id += 1

      course_days, course_periods, course_locations = [], [], []
      data[7].split("(")[1..-1].each do |course_time_location|
        course_time_location.scan(/(?<day>[一二三四五六日])\)(?<period>[\w]+)【(?<loc>[\w\W\.]+)】/).each do |day, period, loc|
          period.scan(/\w/).each do |p|
            course_days << DAYS[day]
            course_periods << PERIODS[p]
            course_locations << loc
          end
        end
      end

      course = {
        year: @year,    # 西元年
        term: @term,    # 學期 (第一學期=1，第二學期=2)
        name: data[2].split(' ~課程大綱~')[0],    # 課程名稱
        lecturer: data[10],    # 授課教師
        credits: data[5].to_i,    # 學分數
        code: "#{@year}-#{@term}-#{course_id}_#{data[0]}",
        general_code: data[0],    # 選課代碼
        url: nil,    # 課程大綱之類的連結
        required: data[4].include?('必'),    # 必修或選修
        department: data[1],    # 開課系所
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
        location_9: course_locations[8],
        }

      @after_each_proc.call(course: course) if @after_each_proc

      @courses << course
    end
    course_id
  end
end
end