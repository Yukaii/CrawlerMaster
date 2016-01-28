# 南臺科技大學
# 課程查詢網址：http://120.117.2.118/CourSel/Pages/NextCourse.aspx

module CourseCrawler::Crawlers
class StustCourseCrawler < CourseCrawler::Base

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

    @query_url = 'http://120.117.2.118/CourSel/Pages/'
  end

  def courses
    @courses = []

    r = RestClient.get(@query_url+"NextCourse.aspx")
    doc = Nokogiri::HTML(r)
    @cookie = r.cookies

    @hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    course_id = 0
    doc.css('select[id="ctl00_ContentPlaceHolder1_ddl_dept"] option:nth-child(n+2)').map{|option| option[:value]}.each do |dept|

      doc = web_post(dept: dept, btn_query: nil)

      doc.css('select[id="ctl00_ContentPlaceHolder1_ddl_class"] option:nth-child(n+2)').map{|option| option[:value]}.each do |cla|

        doc = web_post(dept: dept, cla: cla)

        # puts "#{dept}_#{cla}"

        pages = doc.css('table[id="ctl00_ContentPlaceHolder1_gv_result"] tr:last-child a').map{|a| a.text}[-1]
        pages = 1 if pages == nil || pages.length > 1

        (1..pages.to_i).each do |page|
          doc = web_post(dept: dept, cla: cla, btn_query: nil, hdf_query: "True", eVENTTARGET: "ctl00$ContentPlaceHolder1$gv_result", eVENTARGUMENT: "Page$#{page}") if page > 1

          doc.css('table[id="ctl00_ContentPlaceHolder1_gv_result"] tr:nth-child(n+2)').map{|tr| tr}.each do |tr|
            data = tr.css('td span').map{|td| td.text}
            next if not data[2].to_s.include?('修')
            course_name = tr.css('td a').map{|td| td.text}[0]
            general_code = tr.css('td a').map{|td| td[:title]}[0]
            syllabus_url = @query_url+tr.css('td a').map{|td| td[:href]}[0]
            course_id += 1

            time_period_regex = /(?<day>[一二三四五六日])\s(?<period>((\d+)\s?)+)/
            course_time = Hash[ data[4].scan(time_period_regex) ]

            course_days, course_periods, course_locations = [], [], []
            course_time.each do |day, period|
              period.split(' ').each do |p|
                course_days << DAYS[day[0]]
                course_periods << p.to_i
                course_locations << nil
              end
            end

            course = {
              year: @year,    # 西元年
              term: @term,    # 學期 (第一學期=1，第二學期=2)
              name: course_name,    # 課程名稱
              lecturer: data[1],    # 授課教師
              credits: data[0].to_i,    # 學分數
              code: "#{@year}-#{@term}-#{course_id}-#{general_code}",
              general_code: general_code,    # 選課代碼
              url: syllabus_url,    # 課程大綱之類的連結
              required: data[2].include?('必'),    # 必修或選修
              department: data[3],    # 開課系所
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

        # puts "#{course_id} / #{dept}_#{cla}_#{page}"
          end
        end
      end
    end

    # binding.pry
    @courses
  end

  def web_post dept: nil, cla: nil, btn_query: "查詢課程", eVENTTARGET: nil, eVENTARGUMENT: nil, hdf_query: nil
    form_data = {
      "__EVENTTARGET" => eVENTTARGET,
      "__EVENTARGUMENT" => eVENTARGUMENT,
      "__LASTFOCUS" => nil,
      "ctl00$ContentPlaceHolder1$ddl_dept" => dept,
      # "ctl00$ContentPlaceHolder1$txt_subname" => "",
      # "ctl00$ContentPlaceHolder1$txt_credit" => "",
      "ctl00$ContentPlaceHolder1$ddl_rs" => "*",
      # "ctl00$ContentPlaceHolder1$txt_teaname" => "",
      # "ctl00$ContentPlaceHolder1$txt_keywords" => "",
      "ctl00$ContentPlaceHolder1$CollapsiblePanelExtender2_ClientState" => "true",
      "ctl00$ContentPlaceHolder1$cpe_ClientState" => "true",
      }
    form_data = form_data.merge({"ctl00$ContentPlaceHolder1$ddl_class" => cla,}) if cla != nil
    form_data = form_data.merge({"ctl00$ContentPlaceHolder1$btn_query" => btn_query,}) if btn_query != nil
    form_data = form_data.merge({"ctl00$ContentPlaceHolder1$hdf_query" => hdf_query,}) if hdf_query != nil
    r = RestClient.post(@query_url+"NextCourse.aspx", @hidden.merge(form_data), head = {"Cookie" => "ASP.NET_SessionId=#{@cookie['ASP.NET_SessionId']}"})
    doc = Nokogiri::HTML(r)
    @hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]
    doc
  end

end
end
