# 樹德科技大學
# 課程查詢網址：https://info.stu.edu.tw/ACA/student/QueryAGECourse/index.asp

module CourseCrawler::Crawlers
class StuCourseCrawler < CourseCrawler::Base

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
    '1' => 1,
    '2' => 2,
    '3' => 3,
    '4' => 4,
    'N' => 5,
    '午' => 5,
    '5' => 6,
    '6' => 7,
    '7' => 8,
    '8' => 9,
    'E' => 10,
    '傍' => 10,
    'A' => 11,
    'B' => 12,
    'C' => 13,
    'D' => 14,
  }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'https://info.stu.edu.tw/ACA/student/QueryAGECourse/index.asp'
  end

  def courses
    @courses = []
    course_id = 0

    r = RestClient.get(@query_url)
    doc = Nokogiri::HTML(r)

    doc.css('select[name="dep"] option:nth-child(n+2)').map{|opt| [opt[:value],opt.text]}.each do |dept_v, dept_n|
      r = RestClient.post(@query_url, {
        "yr" => "#{@year-1911}#{@term}",
        "dep" => dept_v,
        "coursetype" => "",
        "ref1" => "",
        "admissionType" => "0",
        "credit" => "0",
        "re" => "0",
        "grd" => "0",
        "prog" => "0",
        "ecourse" => "0",
        "eng" => "0",
        "forcourse" => "0",
        "coursename" => "",
        "teachername" => "",
        })
      doc = Nokogiri::HTML(r)
      doc.css('table[class="sortable"] tbody tr').each do |tr|
        data = tr.css('td').map{|td| td.text}
        next if data.length < 10
# puts "#{dept_v},#{data[1]}"
        syllabus_url = "https://info.stu.edu.tw/#{tr.css('td a').map{|a| a[:href]}[0]}"

        course_id += 1

        if data[4] != nil
	        course_time = data[4].scan(/(?<day>[一二三四五六日])(?<period>\w)/)
	      else
	      	course_time = []
	      end

        course_days, course_periods, course_locations = [], [], []
        course_time.each do |day, period|
          course_days << DAYS[day]
          course_periods << PERIODS[period]
          course_locations << data[5]
        end

        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[1],    # 課程名稱
          lecturer: data[3],    # 授課教師
          credits: data[14].to_i,    # 學分數
          code: "#{@year}-#{@term}-#{course_id}_#{data[0]}",
          general_code: data[0],    # 選課代碼
          url: syllabus_url,    # 課程大綱之類的連結
          required: data[13].include?('必'),    # 必修或選修
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
