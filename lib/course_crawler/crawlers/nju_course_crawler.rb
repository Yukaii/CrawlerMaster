# 南榮科技大學
# 課程查詢網址：http://120.116.128.232/public/

module CourseCrawler::Crawlers
class NjuCourseCrawler < CourseCrawler::Base

  DAYS = {
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6,
    "日" => 7
    }

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
    "10" => 10,
    "11" => 11,
    "12" => 12,
    "13" => 13,
    "14" => 14,
    "15" => 15
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://120.116.128.232/public/public.aspx'
  end

  def courses
    @courses = []
    course_id = 0

    puts "get url ..."
    r = RestClient.get(@query_url)
    doc = Nokogiri::HTML(r)
    cookie = r.cookies

    hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    r = RestClient.post(@query_url, hidden.merge({
      "ScriptManager1" => "PublicAcx1$UpdatePanel1|PublicAcx1$Menu1",
      "__EVENTTARGET" => "PublicAcx1$Menu1",
      "__EVENTARGUMENT" => "C",
      "__ASYNCPOST" => "true"
      }), {"User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/48.0.2564.116 Chrome/48.0.2564.116 Safari/537.36"})
    doc = Nokogiri::HTML(r)

    hidden = {"__VIEWSTATE" => r.scan(/__VIEWSTATE\|([\w\+\=\/]+)\|/)[0][0], "__VIEWSTATEGENERATOR" => r.scan(/__VIEWSTATEGENERATOR\|([\w\+\=\/]+)\|/)[0][0]}

    doc.css('select[name="PublicAcx1$CourseQueryAcx1$DDLOrg1"] option').map{|opt| opt[:value]}.each do |org|
      r = RestClient.post(@query_url, hidden.merge({
        "ScriptManager1" => "PublicAcx1$CourseQueryAcx1$UpdatePanel1|PublicAcx1$CourseQueryAcx1$DDLOrg1",
        "PublicAcx1$CourseQueryAcx1$txt_Year" => @year-1911,
        "PublicAcx1$CourseQueryAcx1$ddl_Semi" => @term,
        "PublicAcx1$CourseQueryAcx1$cbDownOrg" => "on",
        "PublicAcx1$CourseQueryAcx1$DDLOrg1" => org,
        "PublicAcx1$CourseQueryAcx1$DDLOrg2" => "",
        "PublicAcx1$CourseQueryAcx1$ddCredit" => "-1",
        "PublicAcx1$CourseQueryAcx1$ddWeek" => "0",
        "PublicAcx1$CourseQueryAcx1$ddSSect" => "1",
        "PublicAcx1$CourseQueryAcx1$ddESect" => "15",
        "PublicAcx1$CourseQueryAcx1$edtTitle" => "",
        "PublicAcx1$CourseQueryAcx1$edtName" => "",
        "PublicAcx1$CourseQueryAcx1$ddSort" => "0",
        "__EVENTTARGET" => "PublicAcx1$CourseQueryAcx1$DDLOrg1",
        "__EVENTARGUMENT" => "",
        "__LASTFOCUS" => "",
        "__VIEWSTATEENCRYPTED" => "",
        "__AjaxControlToolkitCalendarCssLoaded" => "",
        "__ASYNCPOST" => "true",
        }), {"User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/48.0.2564.116 Chrome/48.0.2564.116 Safari/537.36"})
      doc = Nokogiri::HTML(r)

      hidden2 = {"__VIEWSTATE" => r.scan(/__VIEWSTATE\|([\w\+\=\/]+)\|/)[0][0], "__VIEWSTATEGENERATOR" => r.scan(/__VIEWSTATEGENERATOR\|([\w\+\=\/]+)\|/)[0][0]}

      doc.css('select[id="PublicAcx1_CourseQueryAcx1_DDLOrg2"] option:nth-child(n+2)').map{|opt| [opt[:value],opt.text]}.each do |dept_v, dept_n|
# puts dept_n
        r = RestClient.post(@query_url, hidden2.merge({
          "ScriptManager1" => "PublicAcx1$CourseQueryAcx1$UpdatePanel4|PublicAcx1$CourseQueryAcx1$LB_Query",
          "PublicAcx1$CourseQueryAcx1$txt_Year" => @year-1911,
          "PublicAcx1$CourseQueryAcx1$ddl_Semi" => @term,
          "PublicAcx1$CourseQueryAcx1$cbDownOrg" => "on",
          "PublicAcx1$CourseQueryAcx1$DDLOrg1" => org,
          "PublicAcx1$CourseQueryAcx1$DDLOrg2" => dept_v,
          "PublicAcx1$CourseQueryAcx1$ddCredit" => "-1",
          "PublicAcx1$CourseQueryAcx1$ddWeek" => "0",
          "PublicAcx1$CourseQueryAcx1$ddSSect" => "1",
          "PublicAcx1$CourseQueryAcx1$ddESect" => "15",
          "PublicAcx1$CourseQueryAcx1$edtTitle" => "",
          "PublicAcx1$CourseQueryAcx1$edtName" => "",
          "PublicAcx1$CourseQueryAcx1$ddSort" => "0",
          "__EVENTTARGET" => "PublicAcx1$CourseQueryAcx1$LB_Query",
          "__EVENTARGUMENT" => "",
          "__LASTFOCUS" => "",
          "__ASYNCPOST" => "true",
          "__VIEWSTATEENCRYPTED" => "",
          "__AjaxControlToolkitCalendarCssLoaded" => "",
          }), {"User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/48.0.2564.116 Chrome/48.0.2564.116 Safari/537.36"})
        doc = Nokogiri::HTML(r)

        doc.css('table[id="PublicAcx1_CourseQueryAcx1_GridView1"] tr:nth-child(n+2)').each do |tr|
          data = tr.css('td').map{|td| td.text}
          next if data.length < 10

          course_id += 1

          course_time = data[8].scan(/(?<day>[一二三四五六日])\-(?<period>[\d\~,]+)/)

          course_days, course_periods, course_locations = [], [], []
          course_time.each do |day, period|
            period.split(",").each do |perd|
              (PERIODS[perd.scan(/\d+/)[0]]..PERIODS[perd.scan(/\d+/)[-1]]).each do |p|
                course_days << DAYS[day]
                course_periods << p
                course_locations << data[7]
              end
            end
          end
          puts "data crawled : " + data[1]
          course = {
            year: @year,    # 西元年
            term: @term,    # 學期 (第一學期=1，第二學期=2)
            name: data[1],    # 課程名稱
            lecturer: data[6],    # 授課教師
            credits: data[4].to_i,    # 學分數
            code: "#{@year}-#{@term}-#{data[2]}_#{data[0]}",
            general_code: data[0],    # 選課代碼
            url: nil,    # 課程大綱之類的連結
            required: data[3].include?('必'),    # 必修或選修
            department: data[11],    # 開課系所
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
