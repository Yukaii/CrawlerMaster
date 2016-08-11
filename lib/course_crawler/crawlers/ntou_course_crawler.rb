# 國立臺灣海洋大學
# 課程查詢網址：http://ais.ntou.edu.tw/outside.aspx?mainPage=LwBBAHAAcABsAGkAYwBhAHQAaQBvAG4ALwBUAEsARQAvAFQASwBFADIAMgAvAFQASwBFADIAMgAxADEAXwAuAGEAcwBwAHgAPwBwAHIAbwBnAGMAZAA9AFQASwBFADIAMgAxADEA

# 第一次跑爬蟲跑到宿網爆掉...(跑完一次好像有3G多？)
# 5451.355 sec
module CourseCrawler::Crawlers
class NtouCourseCrawler < CourseCrawler::Base

  PERIODS = {
    "00" => 1,
    "01" => 2,
    "02" => 3,
    "03" => 4,
    "04" => 5,
    "05" => 6,
    "06" => 7,
    "07" => 8,
    "08" => 9,
    "09" => 10,
    "10" => 11,
    "11" => 12,
    "12" => 13,
    "13" => 14,
    "14" => 15
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://ais.ntou.edu.tw/'
  end

  def courses
    @courses = []

    cookie = RestClient.get(@query_url+"outside.aspx?mainPage=LwBBAHAAcABsAGkAYwBhAHQAaQBvAG4ALwBUAEsARQAvAFQASwBFADIAMgAvAFQASwBFADIAMgAxADEAXwAuAGEAcwBwAHgAPwBwAHIAbwBnAGMAZAA9AFQASwBFADIAMgAxADEA").cookies

    r = RestClient.get(@query_url+"Application/TKE/TKE22/TKE2211_01.aspx",{"Cookie" => cookie})
    doc = Nokogiri::HTML(r)

    hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    r = %x(curl -s 'http://ais.ntou.edu.tw/Application/TKE/TKE22/TKE2211_01.aspx' -H 'Cookie: ASP.NET_SessionId=#{cookie["ASP.NET_SessionId"]}' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/48.0.2564.82 Chrome/48.0.2564.82 Safari/537.36' --data 'ScriptManager1=AjaxPanel%7CQUERY_BTN7&__EVENTTARGET=&__EVENTARGUMENT=&__LASTFOCUS=&__VIEWSTATE=#{URI.escape(hidden["__VIEWSTATE"],"/+=")}&__VIEWSTATEENCRYPTED=&__EVENTVALIDATION=#{URI.escape(hidden["__EVENTVALIDATION"],"/+=")}&ActivePageControl=&ColumnFilter=&SAYEAR=&QUERY_TYPE=2&Q_DEGREE_CODE=0&Q_FACULTY_CODE=0700&Q_GRADE=&Q_CLASSID=&radioButtonClass=1&Q_CH_LESSON=%25&radioButtonQuery=1&Q_TCH_FACULTY_CODE=0700&Q_WEEK=1&Q_CLASS=00&Q_CLSSRM_BUILD=%E4%BA%BA%E6%96%87%E5%A4%A7%E6%A8%93&Q_CLSSRM_ID=502&PC%24PageSize=5000&PC%24PageNo=1&PC2%24PageSize=5000&PC2%24PageNo=1&__ASYNCPOST=true&QUERY_BTN7=%E9%97%9C%E9%8D%B5%E5%AD%97%E6%9F%A5%E8%A9%A2' --compressed)
    doc = Nokogiri::HTML(r)

    hidden = {"__VIEWSTATE" => r[-1200000..-1].split("|hiddenField|")[4][12..-3], "__EVENTVALIDATION" => r[-1200000..-1].split("|hiddenField|")[6].split("|")[1]}

    doc.css('table[class="sortable"] tr:nth-child(n+2)').each do |tr|
      data = tr.css('td').map{|td| td.text}
      url_temp = tr.css('td a').map{|a| a[:href].split("'")[1]}[0]
# puts "#{data[0]}/#{doc.css('table[class="sortable"] tr:nth-child(n+2)').count}"

      post_temp = RestClient.post(@query_url+"Application/TKE/TKE22/TKE2211_01.aspx",{
        "ScriptManager1" => "AjaxPanel|#{url_temp}",
        # "ActivePageControl" => "",
        # "ColumnFilter" => "",
        # "SAYEAR" => "",
        # "QUERY_TYPE" => "2",
        # "Q_DEGREE_CODE" => "0",
        # "Q_FACULTY_CODE" => "0700",
        # "Q_GRADE" => "",
        # "Q_CLASSID" => "",
        # "radioButtonClass" => "1",
        # "Q_CH_LESSON" => "%",
        # "radioButtonQuery" => "1",
        # "Q_TCH_FACULTY_CODE" => "0700",
        # "Q_WEEK" => "1",
        # "Q_CLASS" => "03",
        # "Q_CLSSRM_BUILD" => "人文大樓",
        # "Q_CLSSRM_ID" => "502",
        # "PC$PageSize" => "10",
        # "PC$PageNo" => "1",
        # "PC2$PageSize" => "10",
        # "PC2$PageNo" => "1",
        "__EVENTTARGET" => url_temp,
        "__EVENTARGUMENT" => "",
        "__LASTFOCUS" => "",
        "__VIEWSTATE" => hidden["__VIEWSTATE"],
        "__EVENTVALIDATION" => hidden["__EVENTVALIDATION"],
        "__VIEWSTATEENCRYPTED" => "",
        "__ASYNCPOST" => "true",
        },{
          "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/48.0.2564.82 Chrome/48.0.2564.82 Safari/537.36",
          "Cookie" => cookie
          })

      course_time_loc_data = %x(curl -s '#{@query_url}Application/TKE/TKE22/TKE2211_02.aspx?PKNO=#{post_temp[-800..-1].scan(/PKNO=(\d+)/)[0][0]}' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/48.0.2564.82 Chrome/48.0.2564.82 Safari/537.36' -H 'Cookie: ASP.NET_SessionId=#{cookie["ASP.NET_SessionId"]}' --compressed)
      course_time_loc_data = Nokogiri::HTML(course_time_loc_data)
      ctld = course_time_loc_data.css('table[id="QTable2"] table')[1].css('tr:nth-child(12) td').map{|td| td.text}

      course_time = ctld[1].scan(/(?<day>\d)(?<period>\d+)/)

      course_days, course_periods, course_locations = [], [], []
      course_time.each do |day, period|
        course_days << day.to_i
        course_periods << PERIODS[period]
        course_locations << ctld[3]
      end

      course = {
        year: @year,    # 西元年
        term: @term,    # 學期 (第一學期=1，第二學期=2)
        name: data[3],    # 課程名稱
        lecturer: data[7],    # 授課教師
        credits: data[8].to_i,    # 學分數
        code: "#{@year}-#{@term}-#{data[0]}_#{data[2].gsub(/[\r\n\s]/,"")}",
        general_code: data[2].gsub(/[\r\n\s]/,""),    # 選課代碼
        url: nil,    # 課程大綱之類的連結
        required: data[9].include?('必'),    # 必修或選修
        department: data[4],    # 開課系所
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
    @courses
  end

end
end
