# 國立澎湖科技大學
# 課程查詢網址：http://as1.npu.edu.tw/npu/
# 帳號:guest
# 密碼:123

module CourseCrawler::Crawlers
class NpuCourseCrawler < CourseCrawler::Base

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

    @query_url = 'http://as1.npu.edu.tw/npu/'
  end

  def courses
    @courses = []
    course_id = 0

    cookie = RestClient.post(@query_url+"perchk.jsp",{
      "uid" => "guest",
      "pwd" => "123",
      "myway" => "yes",
      }).cookies

    r = %x(curl -s 'http://as1.npu.edu.tw/npu/ag_pro/ag304_01.jsp' -H 'Cookie: JSESSIONID=#{cookie["JSESSIONID"]}' --compressed)
    doc = Nokogiri::HTML(r)

    doc.css('select[name="rtxt_untid"] option:nth-child(n+2)').map{|opt| [opt[:value],opt.text]}.each do |dept_v,dept_n|
      r = RestClient.post(@query_url+"ag_pro/ag304_02.jsp",{
        "rtxt_year" => @year-1911,
        "rtxt_sms" => @term,
        "rtxt_untid" => dept_v,
        "unit_serch" => "查 詢",
        },{"Cookie" => "JSESSIONID=#{cookie["JSESSIONID"]}"})
      doc = Nokogiri::HTML(r)

      doc.css('table tr:nth-child(n+2) td').map{|td| td[:onclick].split("'")[1]}.each do |cla|
        r = RestClient.post(@query_url+"ag_pro/ag304_03.jsp",{
          "cls_id" => cla,
          "year" => @year-1911,
          "sms" => @term,
          },{"Cookie" => "JSESSIONID=#{cookie["JSESSIONID"]}"})
        doc = Nokogiri::HTML(r)

        url_data_temp = Hash[doc.css('table:nth-child(7) tr:nth-child(n+2) td:nth-child(n+2) a').map{|a| [a.text[5..8],a[:onclick].split("'")[7]]}.sort]

        doc.css('table:nth-child(2) tr:nth-child(n+2)').each do |tr|
          data = tr.css('td').map{|td| td.text.gsub(/ /,'')}
          syllabus_url = "#{@query_url}ag_pro/ag064_print.jsp?arg01=#{@year-1911}&arg02=#{@term}&arg04=#{url_data_temp[data[0]]}"

          course_id += 1

          course_time = data[8].scan(/([一二三四五六日])\)([\d\-,]+)/)

          course_days, course_periods, course_locations = [], [], []
          course_time.each do |day, period|
            period.split(',').each do |perd|
              (perd.scan(/\d+/)[0].to_i..perd.scan(/\d+/)[-1].to_i).each do |p|
                course_days << DAYS[day]
                course_periods << p
                course_locations << data[10]
              end
            end
          end

          course = {
            year: @year,    # 西元年
            term: @term,    # 學期 (第一學期=1，第二學期=2)
            name: data[1],    # 課程名稱
            lecturer: data[9],    # 授課教師
            credits: data[3].to_i,    # 學分數
            code: "#{@year}-#{@term}-#{course_id}_#{data[0]}",
            general_code: data[0],    # 選課代碼
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
    @courses
  end

end
end
