# 龍華科技大學
# 課程查詢網址：https://www.lhu.edu.tw/oapx/lhuplan/Query/course_qry.aspx

module CourseCrawler::Crawlers
class LhuCourseCrawler < CourseCrawler::Base

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
    "A" => 10,
    "B" => 11,
    "C" => 12,
    "D" => 13,
    "E" => 14,
    "F" => 15,
    "G" => 16
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://www.lhu.edu.tw/oapx/lhuplan/Query/course_qry.aspx'
  end

  def courses
    @courses = []

    r = RestClient.get(@query_url)
    doc = Nokogiri::HTML(r)

    hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    course_id = 0
    doc.css('select[id="DDL_Dept"] option:nth-child(n+2)').map{|opt| opt[:value]}.each do |dept|

      r = RestClient.post(@query_url, hidden.merge({
        "TB_TYear" => @year-1911,
        "TB_TTerm" => @term,
        "DDL_Dept" => dept,
        # "TB_SubName" => "",
        # "TB_TeaName" => "",
        "Btn_Qry" => "開始查詢"
        }) )
      doc = Nokogiri::HTML(r)

      doc.css('table[id="GridView1"] tr:nth-child(n+2)').map{|tr| tr}.each do |tr|
        data = tr.css('td').map{|td| td.text}
        data[1] = tr.css('td a').map{|a| a[:href]}[1].scan(/tSubNo=(?<gen_code>\w+)&/)[0][0]
        # data[2] = tr.css('td a').map{|a| a[:href]}[1].scan(/tClassNo=(?<dept_code>\w+)/)[0][0]
        data[5] = data[5].split('-')[2].to_i
        data[7] = tr.css('td span').map{|td| td.text}[2]

        syllabus_url = tr.css('td a').map{|a| a[:href]}[0]
        course_id += 1

        course_time = Hash[ data[8].scan(/(?<day>\w)(?<period>\w)/) ]

        course_days, course_periods, course_locations = [], [], []
        course_time.each do |day, period|
          course_days << day.to_i
          course_periods << PERIODS[period]
          course_locations << data[9]
        end

        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[3],    # 課程名稱
          lecturer: data[7],    # 授課教師
          credits: data[5],    # 學分數
          code: "#{@year}-#{@term}-#{course_id}-?(#{data[1]})?",
          general_code: data[1],    # 選課代碼
          url: syllabus_url,    # 課程大綱之類的連結
          required: data[4].include?('必'),    # 必修或選修
          department: data[6],    # 開課系所
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
  # binding.pry
      end
    end

    @courses
  end

end
end