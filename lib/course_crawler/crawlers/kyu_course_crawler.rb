# 高苑科技大學
# 課程查詢網址：http://webinfo2.kyu.edu.tw/CosPlan/CosSearch.aspx

module CourseCrawler::Crawlers
class KyuCourseCrawler < CourseCrawler::Base

  DAYS = {
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6,
    "日" => 7
    }
# 周一至周五
  PERIODS = {
    "1" => 1,
    "2" => 2,
    "3" => 3,
    "4" => 4,
    "中午" => 5,
    "5" => 6,
    "6" => 7,
    "7" => 8,
    "8" => 9,
    "A" => 10,
    "B" => 11,
    "C" => 12,
    "D" => 13
    }
# 六日
# PERIODS2的值在後方會再加13, 所以 1 => 1+13=14, ... , E => 18+13=31
  PERIODS2 = {
    "1" => 1,
    "2" => 2,
    "3" => 3,
    "4" => 4,
    "5" => 5,
    "午休" => 6,
    "6" => 7,
    "7" => 8,
    "8" => 9,
    "9" => 10,
    "10" => 11,
    "11" => 12,
    "12" => 13,
    "A" => 14,
    "B" => 15,
    "C" => 16,
    "D" => 17,
    "E" => 18
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://webinfo2.kyu.edu.tw/WebSL.TimeTable/Kyu_CosNameOPDB.aspx'
  end

  def courses
    @courses = []
    course_id = 0
    kyu_term = {1=>"U", 2=>"D"}
    puts "get url ..."
    r = RestClient.get(@query_url)
    hidden = Hash[Nokogiri::HTML(r).css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    r = %x(curl -s '#{@query_url}' --data '__EVENTTARGET=&__EVENTARGUMENT=&__LASTFOCUS=&__VIEWSTATE=#{URI.escape(hidden["__VIEWSTATE"],"/=+")}&__VIEWSTATEGENERATOR=BD2CDF3C&__EVENTVALIDATION=#{URI.escape(hidden["__EVENTVALIDATION"],"/=+")}&ctl00%24ContentPlaceHolder1%24drp_slSemester=#{@year-1911}#{kyu_term[@term]}&ctl00%24ContentPlaceHolder1%24text_CosName=%25&ctl00%24ContentPlaceHolder1%24text_seqNO=&ctl00%24ContentPlaceHolder1%24btn_Cossl=%E6%9F%A5%E8%A9%A2' --compressed)
    doc = Nokogiri::HTML(r)
    count = 1
    doc.css('table[id="ctl00_ContentPlaceHolder1_ListView1_itemPlaceholderContainer"] tr:nth-child(n+2)').each do |tr|
      data = tr.css('td').map{|td| td.text}
      puts "data crawled : " + count.to_s
      count += 1
      course_id += 1

      course_time = data[14].scan(/(?<day>[一二三四五六日])\((?<period>[中午\w\~,]+)/)

      course_days, course_periods, course_locations = [], [], []
      course_time.each do |day, period|
        period.split(",").each do |perd|
          if DAYS[day] < 6
            (PERIODS[perd.split('~')[0]]..PERIODS[perd.split('~')[-1]]).each do |p|
              course_days << DAYS[day]
              course_periods << p
              course_locations << data[11]
            end
          else
            (PERIODS2[perd.split('~')[0]]..PERIODS2[perd.split('~')[-1]]).each do |p|
              course_days << DAYS[day]
              course_periods << p+13
              course_locations << data[11]
            end
          end
        end
      end

      course = {
        year: @year,    # 西元年
        term: @term,    # 學期 (第一學期=1，第二學期=2)
        name: data[2],    # 課程名稱
        lecturer: data[3],    # 授課教師
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
    puts "Project fininshed !!!"
    @courses
  end

end
end
