# 國立東華大學
# 課程查詢網址：http://sys.ndhu.edu.tw/aa/class/course/Default.aspx

# 沒有顯示必選修
module CourseCrawler::Crawlers
class NdhuCourseCrawler < CourseCrawler::Base

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

    @query_url = 'http://sys.ndhu.edu.tw/aa/class/course/Default.aspx'
    @ic = Iconv.new('utf-8//IGNORE//translit', 'big5')  # 如果遇到utf-8轉HTML有錯誤，可以先utf-8轉utf-8(可以除錯)
  end

  def courses
    @courses = []
    course_id = 0
    puts "get url ..."
    r = RestClient.get(@query_url)
    doc = Nokogiri::HTML(r)

    hidden = Hash[Nokogiri::HTML(r).css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    # 選擇學院
    doc.css('select[name="ddlCOLLEGE"] option:nth-child(n+2)').map{|opt| opt[:value]}.each do |col|
      r = RestClient.post(@query_url, hidden.merge({
        "ddlYEAR" => "#{@year-1911}/#{@term}",
        "ddlCOLLEGE" => col,
        "ddlDEP" => "NA",
        "ddlCLASS" => "NA",
        "tbSNAME" => "",
        "tbTCHER" => "",
        "ddlDAY" => "0",
        "ddlTIME" => "0",
        "ddlAREA" => "0",
        "ddlROOM" => "NA",
        "ddlSENG" => "0",
        "ddlCORE" => "0",
        "ddlSSTATUS" => "0",
        }) )
      doc = Nokogiri::HTML(r)
      hidden = Hash[Nokogiri::HTML(r).css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]
      # 選擇系所

      doc.css('select[name="ddlDEP"] option').map{|opt| [opt[:value],opt.text]}.each do |dept_v,dept_n|
        r = RestClient.post(@query_url, hidden.merge({
          "ddlYEAR" => "#{@year-1911}/#{@term}",
          "ddlCOLLEGE" => col,
          "ddlDEP" => dept_v,
          "ddlCLASS" => "NA",
          "tbSNAME" => "",
          "tbTCHER" => "",
          "ddlDAY" => "0",
          "ddlTIME" => "0",
          "ddlAREA" => "0",
          "ddlROOM" => "NA",
          "ddlSENG" => "0",
          "ddlCORE" => "0",
          "ddlSSTATUS" => "0",
          "btnCourse" => "查詢(中文)"
          }) )
        doc = Nokogiri::HTML(r)
        puts "data crawled : " + dept_n
        doc.css('table[id="GridView1"] tr:nth-child(n+2)').each do |tr|
          data = tr.css('td').map{|td| td.text.gsub(/[\r\n\s　]/,"")}
          next if data.length < 6
# puts "#{dept_n},#{course_id}"
          syllabus_url = tr.css('td a')[1][:href]

          course_id += 1

          course_time = data[3].scan(/([一二三四五六日])([\d]+)/)
          course_location_temp = data[13].split("/")

          course_days, course_periods, course_locations = [], [], []
          (0..course_time.length-1).each do |i|

            course_days << DAYS[course_time[i][0]]
            course_periods << course_time[i][1].to_i
            course_locations << course_location_temp[i+1]
          end

          course = {
            year: @year,    # 西元年
            term: @term,    # 學期 (第一學期=1，第二學期=2)
            name: data[5],    # 課程名稱
            lecturer: data[12][1..-1],    # 授課教師
            credits: data[11][0].to_i,    # 學分數
            code: "#{@year}-#{@term}-#{course_id}_#{data[4]}",
            general_code: data[4],    # 選課代碼
            url: syllabus_url,    # 課程大綱之類的連結
            required: nil,#data.include?('必'),    # 必修或選修
            department: data[14],    # 開課系所
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
