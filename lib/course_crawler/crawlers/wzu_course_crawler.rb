# 文藻外語大學
# 課程查詢網址：http://140.127.168.37/wtuc/index3.html
# 帳號:guest
# 密碼:12345678

module CourseCrawler::Crawlers
class WzuCourseCrawler < CourseCrawler::Base

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

    @query_url = 'http://140.127.168.37/wtuc/'
    @ic = Iconv.new('utf-8//IGNORE//translit', 'big5')  # 如果遇到utf-8轉HTML有錯誤，可以先utf-8轉utf-8(可以除錯)
  end

  def courses
    @courses = []
    course_id = 0

    cookie = RestClient.post(@query_url+"perchk.jsp",{
      "uid" => "guest",
      "pwd" => "12345678",
      "sys_name" => "web",
      "sys_kind" => "01",
      }).cookies

    r = %x(curl -s 'http://140.127.168.37/wtuc/ag_pro/ag156_00.jsp?' -H 'Cookie: JSESSIONID=#{cookie["JSESSIONID"]}' --data 'arg01=#{@year-1911}&arg02=#{@term}&arg03=guest&arg04=&arg05=&arg06=&fncid=AG156&wen_usrid=&wen_stsid=66' --compressed)
    doc = Nokogiri::HTML(r)

    doc.css('select[id="etxt_dvs"] option').map{|opt| opt[:value]}.each do |dvs|

      r = %x(curl -s 'http://140.127.168.37/wtuc/ag_pro/ag156_00.jsp' -H 'Cookie: JSESSIONID=#{cookie["JSESSIONID"]}' --data 'yms_yms=#{@year-1911}%23#{@term}&etxt_dvs=#{dvs}&etxt_dgr=&etxt_clsyear=%25&etxt_unit=&etxt_cls=&etxt_teaname=' --compressed)
      doc = Nokogiri::HTML(r)

      doc.css('select[id="etxt_dgr"] option:nth-child(n+2)').map{|opt| [opt[:value],opt.text]}.each do |dgr_v,dgr_n|
        r = %x(curl -s 'http://140.127.168.37/wtuc/ag_pro/ag156_01.jsp' -H 'Cookie: JSESSIONID=#{cookie["JSESSIONID"]}' --data 'yms_yms=#{@year-1911}%23#{@term}&etxt_dvs=#{dvs}&etxt_dgr=#{dgr_v}&etxt_clsyear=%25&etxt_unit=&etxt_cls=&etxt_teaname=' --compressed)
        doc = Nokogiri::HTML(r)

        doc.css('table:nth-child(2) tr:nth-child(n+2)').each do |tr|
          data = tr.css('td').map{|td| td.text}
          course_id += 1
          data[11] = data[11].split(" / ")

          course_time = data[11][0].scan(/([一二三四五六日])\)(\d\d?-\d\d?)/)

          course_days, course_periods, course_locations = [], [], []
          course_time.each do |day, periods|
            (periods.scan(/\d+/)[0].to_i..periods.scan(/\d+/)[-1].to_i).each do |p|
              course_days << DAYS[day]
              course_periods << p
              course_locations << data[11][1]
            end
          end

          course = {
            year: @year,    # 西元年
            term: @term,    # 學期 (第一學期=1，第二學期=2)
            name: data[5],    # 課程名稱
            lecturer: data[11][2],    # 授課教師
            credits: data[9].to_i,    # 學分數(需要轉換成數字，可以用.to_i)
            code: "#{@year}-#{@term}-#{course_id}_#{data[0]}",
            general_code: data[0],    # 選課代碼
            url: nil,    # 沒有課程大綱之類的連結
            required: data[8].include?('必'),    # 必修或選修
            department: dgr_v,    # 開課系所
            # department_code: dgr_v,
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
