# 僑光科技大學
# 課程查詢網址：http://192.192.125.219/QueryOpen/OrgList.aspx

module CourseCrawler::Crawlers
class OcuCourseCrawler < CourseCrawler::Base

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
    "15" => 5,
    "5" => 6,
    "6" => 7,
    "7" => 8,
    "8" => 9,
    "9" => 10,
    "10" => 11,
    "11" => 12,
    "12" => 13,
    "13" => 14
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://192.192.125.219'
  end

  def courses
    @courses = []
    course_id = 0

    r = RestClient.get(@query_url+"/QueryOpen/OrgList.aspx")
    doc = Nokogiri::HTML(r)

    doc.css('select[id="DDLOrg1"] option:not(:last-child)').map{|opt| [opt[:value], opt.text]}.each do |orgID,orgTitle|
# puts orgID+",#{course_id}"
      r = %x(curl -s "#{@query_url}/QueryOpen/OrgList1.aspx?OrgID=#{orgID}&Year=#{@year-1911}&Semi=#{@term}&SelType=3&Credit=-1&Week=0&SSect=0&ESect=0&Subject=&TeaName=&Sort=0&OrgDown=Down&OrgTitle=#{orgTitle}" --compressed)
      doc = Nokogiri::HTML(r)

      doc.css('table tr:nth-child(n+2)').map{|tr| tr}.each do |tr|
        data = tr.css('td').map{|td| td.text}
        data[7] = nil if data[7] == "&nbsp"
        data[8] = nil if data[8] == "&nbsp"
        syllabus_url = @query_url + tr.css('td a').map{|td| td[:onclick]}[0].split("'")[1]
        course_id += 1

        course_time = data[9].scan(/(?<day>[一二三四五六日])-(?<period>\d\d?~?\d?\d?)/)

        course_days, course_periods, course_locations = [], [], []
        course_time.each do |day, period|
          (period.split("~")[0].to_i..period.split("~")[-1].to_i).each do |p|
            course_days << DAYS[day]
            course_periods << PERIODS["#{p}"]
            course_locations << data[8]
          end
        end

        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[1],    # 課程名稱
          lecturer: data[7],    # 授課教師
          credits: data[5].to_i,    # 學分數
          code: "#{@year}-#{@term}-#{course_id}_#{data[2]}",
          general_code: data[2],    # 選課代碼
          url: syllabus_url,    # 課程大綱之類的連結
          required: data[4].include?('必'),    # 必修或選修
          department: data[12],    # 開課系所
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
    @courses
  end

end
end
