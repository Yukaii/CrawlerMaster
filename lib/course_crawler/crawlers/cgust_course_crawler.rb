# 長庚科技大學
# 課程查詢網址：http://webmis.cgust.edu.tw/%E8%AA%B2%E5%8B%99%E7%B5%84/%E8%AA%B2%E7%A8%8B%E6%9F%A5%E8%A9%A2/coursequery.htm

module CourseCrawler::Crawlers
class CgustCourseCrawler < CourseCrawler::Base

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
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://webmis.cgust.edu.tw/%E8%AA%B2%E5%8B%99%E7%B5%84/%E8%AA%B2%E7%A8%8B%E6%9F%A5%E8%A9%A2/'
    @ic = Iconv.new('utf-8//IGNORE//translit', 'big5')
  end

  def courses
    @courses = []
    course_id = 0

    r = RestClient.get(@query_url+"CourseQuery.asp")
    doc = Nokogiri::HTML(r)
    cookie = r.cookies

    doc.css('select[name="deptid"] option').map{|opt| [opt[:value],opt.text]}.each do |dept_v,dept_n|
      r = %x(curl -s '#{@query_url}CourseReport.asp' --data 'acadmyear=#{@year-1911}&term=#{@term}&deptid=#{dept_v}&grade=-&class=&TrSearch=%C3%F6%C1%E4%A6r%B7j%B4M%B1%D0%AEv%A1B%BD%D2%B5%7B%A9%CE%B1%D0%AB%C7&search=%ACd%B8%DF' --compressed)
      doc = Nokogiri::HTML(@ic.iconv(r))
# puts "#{dept_v},#{dept_n}"
      doc.css('tr:nth-child(n+2)').map{|tr| tr}.each do |tr|
        data = tr.css('td').map{|td| td.text}
        next if data.count < 10
        course_id += 1
        if tr.css('td input').map{|a| a[:onclick].split("'")[1]}[0] != nil
          syllabus_url = @query_url+tr.css('td input').map{|a| a[:onclick].split("'")[1]}[0]
        else
          syllabus_url = nil
        end

        course_time = data[9].scan(/W(?<day>\d)\,(?<periods>\d\d?\-\d\d?)/)

        course_days, course_periods, course_locations = [], [], []
        course_time.each do |day, periods|
          next if day == "0"
          (periods.split("-")[0].to_i..periods.split("-")[-1].to_i).each do |p|
            course_days << day.to_i
            course_periods << p
            course_locations << data[10]
          end
        end

        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[5],    # 課程名稱
          lecturer: data[3],    # 授課教師
          credits: data[7].to_i,    # 學分數
          code: "#{@year}-#{@term}-#{course_id}_#{data[4]}",
          general_code: data[4],    # 選課代碼
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
      end
    end
    @courses
  end

end
end
