# 美和科技大學
# 課程查詢網址：http://203.71.232.17/meiho_all/eachOnline.asp?Type=aa

# 上課地點在班級課表裡面...先不去抓他
module CourseCrawler::Crawlers
class MeihoCourseCrawler < CourseCrawler::Base

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://203.71.232.17/meiho_all/Aa/'
    @ic = Iconv.new('utf-8//IGNORE//translit', 'big5')
  end

  def courses
    @courses = []
    puts "get url ..."
    r = RestClient.get(@query_url+"sel/sel_0405.asp")
    doc = Nokogiri::HTML(@ic.iconv(r))

    #計算資料量
    count = 1
    doc.css('select[name="cbo_edu04"] option').map{|opt| [opt[:value],opt.text]}.each do |dept_v,dept_n|
      r = RestClient.post(@query_url+"sel/sel_0405.asp", {
        "SelYear" => @year-1911,
        "SelTerm" => @term,
        "Rad" => "5",
        "cbo_edu04" => dept_v,
        # "cbo_edu06" => "101101",
        # "Cpermanent" => "",
        # "TeacherCode" => "",
        # "Cteacher" => "",
        "Status" => "%ACd+%B8%DF",
        })
      doc = Nokogiri::HTML(@ic.iconv(r))

      puts "data crawled : " + count.to_s + " , " + dept_n
      count += 1
      doc.css('table:last-child tr:nth-child(n+2)').map{|tr| tr}.each do |tr|
        data = tr.css('td').map{|td| td.text}
        # 新增 , 因為有些科系沒有資訊會導致錯誤
        if tr.css('td a').map{|a| a[:href]}[1] != nil
          syllabus_url = @query_url+tr.css('td a').map{|a| a[:href]}[1].split("'")[1][3..-1]

          data[2] = syllabus_url.scan(/Permanents=(\w+)/)[0][0]
          course_id = syllabus_url.scan(/Per_No=(\w+)/)[0][0]

          course_days, course_periods, course_locations = [], [], []
          data[8].scan(/\d\d/).each do |period|
            course_days << data[7][1].to_i
            course_periods << period.to_i+1
            # course_locations << nil # 上課地點在班級課表裡面...
          end

          course = {
            year: @year,    # 西元年
            term: @term,    # 學期 (第一學期=1，第二學期=2)
            name: data[3],    # 課程名稱
            lecturer: data[4],    # 授課教師
            credits: data[6].to_i,    # 學分數
            code: "#{@year}-#{@term}-#{course_id}_#{data[2]}",
            general_code: data[2],    # 選課代碼
            url: syllabus_url,    # 課程大綱之類的連結
            required: data[5].include?('必'),    # 必修或選修
            department: dept_n,    # 開課系所
            # department_code: dept_v,
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
    end
    puts "Project finished !!!"
    @courses
  end

end
end
