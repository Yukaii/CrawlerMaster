# 臺北城市科技大學
# 課程查詢網址：http://eportfolio.tpcu.edu.tw/bin/index.php?Plugin=coursemap&Action=schoolcourse

# 校務行政資訊系統(內部)：http://siw71.tpcu.edu.tw/tsint/
# 帳號:guest
# 密碼:123
module CourseCrawler::Crawlers
class TpcuCourseCrawler < CourseCrawler::Base

  DAYS = {
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6,
    "日" => 7
    }
	PERIODS = CoursePeriod.find('TPCU').code_map

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://siw71.tpcu.edu.tw/tsint/'
  end

  def courses
    @courses = []
    course_id = 0

    cookie = RestClient.get(@query_url+"index_main.jsp").cookies

    r = %x(curl -s '#{@query_url}perchk.jsp' -H 'Cookie: JSESSIONID=#{cookie["JSESSIONID"]}' --data 'hid_type=X&uid=guest&pwd=123&err=N&fncid=&ls_chochk=N' --compressed)

    r = %x(curl -s '#{@query_url}ag_pro/ag203.jsp?' -H 'Cookie: JSESSIONID=#{cookie["JSESSIONID"]}' --data 'arg01=#{@year-1911}&arg02=#{@term}&arg03=guest&arg04=&arg05=&arg06=&fncid=AG203' --compressed)
    doc = Nokogiri::HTML(r)

    doc.css('select[id="unt_id"] option:not(:last-child)').map{|opt| opt[:value]}.each do |unt|
      r = %x(curl -s '#{@query_url}ag_pro/ag203_1.jsp' -H 'Cookie: JSESSIONID=#{cookie["JSESSIONID"]}' --data 'yms_yms=#{@year-1911}%23#{@term}&ls_year=#{@year-1911}&ls_sms=#{@term}&dgr_id=%25&unt_id=#{unt}&clyear=&hid_crk=%25&sub_name=&teacher=' --compressed)
      doc = Nokogiri::HTML(r)

      doc.css('table:nth-child(5) tr:nth-child(n+2)').each do |tr|
        data = tr.css('td').map{|td| td.text.gsub(/[\s ]/,"")}
        course_id += 1

        course_time = data[10].scan(/([一二三四五六日])\)([\w\-\,]+)/)

        course_days, course_periods, course_locations = [], [], []
        course_time.each do |day, period|
          period.scan(/[\w\-]+/).each do |perd|
            (PERIODS[perd.scan(/\w+/)[0]]..PERIODS[perd.scan(/\w+/)[-1]]).each do |p|
              course_days << DAYS[day]
              course_periods << p
              course_locations << data[11]
            end
          end
        end

        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[3],    # 課程名稱
          lecturer: data[4],    # 授課教師
          credits: data[5].to_i,    # 學分數
          code: "#{@year}-#{@term}-#{course_id}_#{data[1]}",
          general_code: data[1],    # 選課代碼
          url: nil,    # 課程大綱之類的連結 # 內部網頁無法直接連結
          required: data[7].include?('必'),    # 必修或選修
          department: data[0],    # 開課系所
          # department_code: unt,
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
    @courses
  end

end
end
