# 輔英科技大學
# 課程查詢網址：http://cos.fy.edu.tw/fywww/new/new_info/cos_info/yco_1000.asp

# 13614.832 sec 跑很久...
module CourseCrawler::Crawlers
class FyCourseCrawler < CourseCrawler::Base

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://cos.fy.edu.tw/fywww/new/new_info/cos_info/'
    @ic = Iconv.new('big5','utf-8')
  end

  def courses
    @courses = []
    @repeat_list = []
    @course_id = 0
    puts "get url ..."
    r = RestClient.get(@query_url+"yco_3100.asp")
    doc_top = Nokogiri::HTML(r)

    # 各系科必選修課程 & 跨領域課程
    doc_top.css('table table:last-child a').map{|a| a[:href]}.values_at(0,-1).each do |course_type|
      r = RestClient.get(@query_url+course_type)
      doc = Nokogiri::HTML(r)

      yt = doc.css('table table:last-child a').map{|a| a[:href]}[0]
      if yt.include?("#{@year-1911}#{@term}") == true
        r = RestClient.get(@query_url+yt)
        doc = Nokogiri::HTML(r)
      end

      doc.css('table table:last-child a').map{|a| a[:href]}.each do |dept|
        analyze_coures_table(dept)
      end
    end

    # 大學部博雅涵養課程
    r = RestClient.get(@query_url+doc_top.css('table table:last-child a').map{|a| a[:href]}[1])
    doc = Nokogiri::HTML(r)

    yt = doc.css('table table:last-child a').map{|a| a[:href]}[0]
    if yt.include?("#{@year-1911}#{@term}") == true
      analyze_coures_table(yt)
    end
    puts "Project finished !!!"
    @courses
  end

  def analyze_coures_table part_url
    r = RestClient.get(@query_url+part_url)
    doc = Nokogiri::HTML(r)
    #puts "analyze the courses ..."
    # 開始一堂一堂的爬
    doc.css('table table:last-child a').map{|a| a}.each do |cor|

      if @repeat_list.include?(cor.text)
        next
      else
        @repeat_list << cor.text
      end

      r = RestClient.get(@query_url+cor[:href])
      doc = Nokogiri::HTML(r)

      courses_temp = []

      course_table_repeat = {}

      # 先分析完整個課表
      course_table_tr = doc.css('table table:last-child table > tr:nth-child(n+2)').map{|tr| tr}
      (0..course_table_tr.count-1).each do |period|
        course_table_td = course_table_tr[period].css('>td:nth-child(n+2)').map{|td| td}
        (0..course_table_td.count-1).each do |day|
          course_table_td[day].css('tr > td > font').map{|font| font}.each do |c|
            course_table_obj = c
            next if course_table_obj == nil || course_table_obj.include?("補課週")

            department_code = course_table_obj.css('>font a').text

            if not course_table_repeat.include?(department_code)
              @course_id += 1
              course_table_repeat[department_code] = @course_id
              puts "course ID : "+ @course_id.to_s
            end

            syllabus_url = course_table_obj.css('>font a')[0][:href]
            teacher = course_table_obj.css('>font font').text.scan(/\W+/)[0]
            location = course_table_obj.css('>font font').map{|f| f.text}[0].scan(/\w+/)[0] if course_table_obj.css('>font font').map{|f| f.text}[0] != nil
            location = "" if location == nil

            r = RestClient.get(URI.escape(@ic.iconv(syllabus_url)))
            doc = Nokogiri::HTML(r)

            name_code_credits = doc.css('table[class="ViewTB"] > tr:not(:nth-child(n+6)) td span').map{|s| s.text}
            if name_code_credits.length > 6
              name = name_code_credits[0]
              general_code = name_code_credits[1]
              credits = name_code_credits[6].to_i
              department = name_code_credits[4]
            else
              next
            end
            puts "data crawled : " + name
            courses_temp << [course_table_repeat[department_code],[day+1,period+1,location],[name,teacher,credits,general_code,syllabus_url.gsub(/'/,"%27"),department_code,department]]
          end
        end
      end

      course_days, course_periods, course_locations = [], [], []
      temp_data = []
      # 把分析完的課表整合
      (courses_temp.sort<<[[],[],[]]).each do |temp_cor|

        if temp_cor[0] != temp_data[0] && temp_data != []
          data = temp_data

          course = {
            year: @year,    # 西元年
            term: @term,    # 學期 (第一學期=1，第二學期=2)
            name: data[2][0],    # 課程名稱
            lecturer: data[2][1],    # 授課教師
            credits: data[2][2],    # 學分數
            code: "#{@year}-#{@term}-#{data[0]}_#{data[2][3]}",
            general_code: data[2][3],    # 選課代碼
            url: data[2][4],    # 課程大綱之類的連結
            required: data[1].include?('必'),    # 必修或選修 (這學校沒有寫這個選項)
            department: data[2][6],    # 開課系所
            # department_code: data[2][5],
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

        course_days, course_periods, course_locations = [], [], [] if temp_cor[0] != temp_data[0]

        course_days      << temp_cor[1][0]
        course_periods   << temp_cor[1][1]
        course_locations << temp_cor[1][2]

        temp_data = temp_cor
      end
    end
  end

end
end
