# 育達科技大學
# 課程查詢網址：http://course.ydu.edu.tw/LP/

module CourseCrawler::Crawlers
class YduCourseCrawler < CourseCrawler::Base

  PERIODS = {
    "0" => 1,
    "1" => 2,
    "2" => 3,
    "3" => 4,
    "4" => 5,
    "5" => 6,
    "6" => 7,
    "7" => 8,
    "8" => 9,
    "9" => 10,
    "10" => 11,
    "11" => 12,
    "12" => 13,
    "13" => 14,
    "14" => 15,
    "A" => 11,
    "B" => 12,
    "C" => 13,
    "D" => 14,
    "E" => 15
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://course.ydu.edu.tw/LP/'
  end

  def courses
    @courses = []
    course_id = 0

    r = RestClient.get(@query_url+"CosTable.aspx")
    doc = Nokogiri::HTML(r)

    hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    doc.css('select[id="DropDownList2"] option').map{|opt| [opt[:value],opt.text]}.each do |dept_v, dept_n|
      # 在4025的三年級E班是一個錯誤的網頁...
      begin
        r = RestClient.post(@query_url+"CosTable.aspx", hidden.merge({
          "DropDownList1" => "#{@year-1911}#{@term}",
          "DropDownList2" => dept_v,
          "DropDownList3" => "%%",
          "DropDownList4" => "%%",
          "Button1" => "查詢",
          # "DropDownList5" => "于長禧           ",
          # "TextBox1" => "",
          # "DropDownList6" => "0",
          }) )
      rescue
        # puts "cannot post #{dept_n}"
      end

      doc = Nokogiri::HTML(r)

      doc.css('table[id="GridView1"] tr:nth-child(n+2)').map{|tr| tr}.each do |tr|
# puts "#{dept_v},#{course_id}"
        data = tr.css('td').map{|td| td.text}
        course_id += 1
        syllabus_url = tr.css('td a').map{|a| a[:href]}[0]

        time_period = [[1,data[13]],[2,data[14]],[3,data[15]],[4,data[16]],[5,data[17]],[6,data[18]],[7,data[19]]]

        course_days, course_periods, course_locations = [], [], []
        time_period.each do |day, period|
          period.scan(/\w/) do |p|
            course_days << day
            course_periods << PERIODS[p]
            course_locations << data[21]
          end
        end

        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[2],    # 課程名稱
          lecturer: data[9],    # 授課教師
          credits: data[8].to_i,    # 學分數
          code: "#{@year}-#{@term}-#{course_id}_#{data[1]}",
          general_code: data[1],    # 選課代碼
          url: syllabus_url,    # 課程大綱之類的連結
          required: data[6].include?('必'),    # 必修或選修
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
# binding.pry if dept_v == "1004"
      end
    end
    @courses
  end

end
end