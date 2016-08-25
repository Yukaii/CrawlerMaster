# 明新科技大學
# 課程查詢網址：https://sss.must.edu.tw/cosinfo/qry_cosbyname.asp
#
# curl有改過，因為先前的連不上去，改程直接複製整個bash
#


module CourseCrawler::Crawlers
class MustCourseCrawler < CourseCrawler::Base

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
  #   "10" => 10,
  # # 進修部
  #   "0" => 10,
  #   "1" => 11,
  #   "2" => 12,
  #   "3" => 13,
  #   "4" => 14
  #   }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://sss.must.edu.tw/cosinfo/'
    @ic = Iconv.new('utf-8//IGNORE//translit', 'big5')
  end

  def courses
    @courses = []
    course_id = 0
    puts "get url ..."
    r = RestClient.get(@query_url+"qry_cosbyname.asp")
    doc = Nokogiri::HTML(r)

    doc.css('select[name="DiviList"] option').map{|opt| opt[:value]}.each do |divi|
      #r = %x(curl -s '#{@query_url}qry_cosbyname.asp' --data 'YearList=#{@year-1911}&SmtrList=#{@term}&DiviList=#{divi}&CosName=%AD%5E%A4%E5%28%A4%40%29' --compressed)
      r = %x(curl -s 'https://sss.must.edu.tw/cosinfo/qry_cosbyname.asp' -H 'Pragma: no-cache' -H 'Origin: https://sss.must.edu.tw' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: zh-TW,zh;q=0.8,en-US;q=0.6,en;q=0.4' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: no-cache' -H 'Referer: https://sss.must.edu.tw/cosinfo/qry_cosbyname.asp' -H 'Cookie: ASPSESSIONIDSSBRRSBT=JGNJMEEAAIKKOACHLANCDFOG; sto-id=FNAAAAAK; ASPSESSIONIDSQDSTQAT=LGFOOJKCPHIIAFLFBNILJHOJ; ASPSESSIONIDQSBSQTBT=HPMLGGCDOOFKPBDBIJGIJDNB' -H 'Connection: keep-alive' --data 'YearList=105&SmtrList=1&DiviList=1&CosName=+' --compressed)
      # r = RestClient.post(@query_url+"qry_cosbyname.asp" , {
      #   "YearList"  =>  "105" ,
      #   "SmtrList"  =>  "1"   ,
      #   "DiviList"  =>  "1"   ,
      #   "CosName"   =>  "+"   ,
      # })

      doc = Nokogiri::HTML(@ic.iconv(r))

      puts "data crawled : " + divi
      doc.css('body > center table tr:nth-child(n+2)').each do |tr|
        data = tr.css('td').map{|td| td.text}
        syllabus_url = "#{@query_url}#{tr.css('a').map{|a| a[:value]}[0]}" if tr.css('a').map{|a| a[:value]}[0] != nil

        course_id += 1

        course_days, course_periods, course_locations = [], [], []
        course_time = data[11].scan(/(?<day>\d)\-\-?(?<period>\d+)/)
        if divi != "2"
          course_time.each do |day, period|
            course_days << day.to_i
            course_periods << period.to_i
            course_locations << data[10]
          end
        else  # 進修部的時間分析比較複雜
          p_temp = 0
          course_time.each do |day, period|
            course_days << day.to_i
            if not data[3].include?('產')
              if day.to_i < 6
                course_periods << period.to_i + 9
              else
                if period.to_i-p_temp < -2
                  course_periods << period.to_i + 9
                else
                  course_periods << period.to_i
                end
                p_temp = period.to_i
              end
            else
              course_periods << period.to_i
            end
            course_locations << data[10]
          end
        end

        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[1],    # 課程名稱
          lecturer: data[9],    # 授課教師
          credits: data[4].to_i,    # 學分數
          code: "#{@year}-#{@term}-#{course_id}_#{data[0].gsub(/\r/,'')}",
          general_code: data[0].gsub(/\r/,''),    # 選課代碼
          url: syllabus_url,    # 課程大綱之類的連結
          required: data[6].include?('必'),    # 必修或選修
          department: data[3],    # 開課系所
          # department_code: data[2],
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
    puts "Project finished !!!"
    @courses
  end
end
end
