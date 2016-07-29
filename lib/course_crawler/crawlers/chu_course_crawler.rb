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
    }.freeze

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
    }.freeze

    COLLEGE_TYPE = %w(B H S).freeze

    def initialize year: nil, term: nil, update_progress: nil, after_each: nil

      @year = year
      @term = term
      @update_progress_proc = update_progress
      @after_each_proc = after_each

      @query_url = 'http://course.chu.edu.tw/'
      @result_url = 'http://course.chu.edu.tw/schedular_check.asp'
      @Page_url = 'http://course.chu.edu.tw/schedular_result.asp?page='
      @ic = Iconv.new('utf-8//IGNORE//translit', 'big5')
    end

    def courses
      @courses = []
      course_id = 0
      #首先大學部
      r = RestClient.get(@query_url)
      doc = Nokogiri::HTML(r)
      dept_master = doc.css('select[name="master_select"]').css('option')[1..-1].each do |master_dept|
        master_sel = master_dept.attr('value')

        begin
          r = RestClient.post(@result_url , {
            master_select: master_sel.to_s ,
            master_course: '%ACd%B8%DF' ,
            })
        rescue Exception => e
          # http 302問題，所以必須重新導向
          r = e.response.follow_redirection

        end

        cookie = r.cookies
        doc = Nokogiri::HTML(r)
        page_total = doc.css('table')[1].css('tr')[-1].text.split('/')[-1].to_i
        (1..page_total).each do |page|
          # r = RestClient.get(@Page_url+page.to_s)
          # 問題以解決
          r = %x(curl -s '#{@query_url}schedular_result.asp?page=#{page}' -H 'Cookie: ASPSESSIONIDQARDDQRA=#{cookie["ASPSESSIONIDQARDDQRA"]}; ASPSESSIONIDQARDCRRB=#{cookie["ASPSESSIONIDQARDCRRB"]}; _ga=#{cookie["_ga"]}; ASPSESSIONIDQCSDBQRB=#{cookie["ASPSESSIONIDQCSDBQRB"]}' --compressed)
          doc = Nokogiri::HTML(@ic.iconv(r))

          course_id = input_course_to_hash(doc, course_id ,master_dept)

        end
      end # master_dept

      # 大學部
      # college = B , S , H
      COLLEGE_TYPE.each do |select_t|
        begin
          r = RestClient.post(
            @result_url,
            college_select: select_t
          )
        rescue Exception => e
          # http 302問題，所以必須重新導向
          r = e.response.follow_redirection
        end
        # 每個系dept
        doc = Nokogiri::HTML(r)

        dept_total = doc.css('select[name="dept_select"]').css('option')[0..-1].each do |dept|
          dept_sel = dept.attr('value')

          begin
            r = RestClient.post(@result_url , {
              dept_select: dept_sel.to_s ,
              grade_select: 10 ,
              class_select: 10 ,
              college_course: '%ACd%B8%DF' ,
              })
          rescue Exception => e
            # http 302問題，所以必須重新導向
            r = e.response.follow_redirection
          end

          cookie = r.cookies
          doc = Nokogiri::HTML(r)

          # 取頁數
          page_total = doc.css('table')[1].css('tr')[-1].text.split('/')[-1].to_i
          (1..page_total).each do |page|
            # r = RestClient.get(@Page_url+page.to_s)
            # 問題以解決
            r = %x(curl -s '#{@query_url}schedular_result.asp?page=#{page}' -H 'Cookie: ASPSESSIONIDQARDDQRA=#{cookie["ASPSESSIONIDQARDDQRA"]}; ASPSESSIONIDQARDCRRB=#{cookie["ASPSESSIONIDQARDCRRB"]}; _ga=#{cookie["_ga"]}; ASPSESSIONIDQCSDBQRB=#{cookie["ASPSESSIONIDQCSDBQRB"]}' --compressed)
            doc = Nokogiri::HTML(@ic.iconv(r))

            # page_datas = doc.css('table')[1].css('tr')[2..-2]
            # page_datas.each do |data|
            # course_id += 1
            course_id = input_course_to_hash(doc, course_id ,dept)
            # input_course_to_hash(data,course_id)
            # end
          end

        end
      end

      @courses
    end

    def input_course_to_hash(doc, course_id , dept)

      doc.css('table[bgcolor="#FFFFFF"] tr[bgcolor="#EEEEEE"]').each do |tr|
        data = tr.css('td').map(&:text)
        course_id += 1

        course_days, course_periods, course_locations = [], [], []

        data[6].split('(')[1..-1].each do |course_time_location|
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
          name: data[1].split(' ~課程大綱~')[0],    # 課程名稱
          lecturer: data[9],    # 授課教師
          credits: data[4].to_i,    # 學分數
          code: "#{@year}-#{@term}-#{course_id}_#{data[0]}",
          general_code: data[0],    # 選課代碼
          url: nil,    # 課程大綱之類的連結
          required: data[3].include?('必'),    # 必修或選修
          department: dept.text,    # 開課系所
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
