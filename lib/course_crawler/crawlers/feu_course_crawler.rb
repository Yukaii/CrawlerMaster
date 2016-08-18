# 遠東科技大學
# 課程查詢網址：http://web.isic.feu.edu.tw/query/classcour.asp

module CourseCrawler::Crawlers
class FeuCourseCrawler < CourseCrawler::Base

  PERIODS = {
    "1" => 1,
    "2" => 2,
    "3" => 3,
    "4" => 4,
    "午休" => 5,
    "5" => 6,
    "6" => 7,
    "7" => 8,
    "8" => 9,
    "9" => 10,
    "A" => 11,
    "B" => 12,
    "C" => 13,
    "D" => 14,
    "E" => 15,
  # 進修部
  #   "1" => 10,
  #   "2" => 11,
  #   "3" => 12,
  #   "4" => 13,
  #   "5" => 14
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://web.isic.feu.edu.tw/query/'
    @ic = Iconv.new('utf-8//IGNORE//translit', 'big5')
  end

  def courses
    @courses = []
    course_id = 0
    puts "get url ..."
    r = RestClient.post(@query_url+"classcour3b.asp", {
      "YEAR" => @year-1911,
      "SEM" => @term,
      "DAYNIGHT" => "D",
      "courname" => "",
      "COURSEM" => "0",
      })
    doc = Nokogiri::HTML(r)

    doc.css('table table tr:nth-child(n+2)').each do |tr|
      data = tr.css('td').map{|td| td.text}
      syllabus_url = "#{@query_url}#{tr.css('td a').map{|a| a[:href]}[0]}"

      course_id += 1

      course_time = [data[8],data[9],data[10],data[11],data[12],data[13],data[14]]
      course_days, course_periods, course_locations = [], [], []
      (1..course_time.length).each do |day|
        course_time[day-1].scan(/\w/).each do |p|
          course_days << day
          course_periods << PERIODS[p]
          course_locations << data[7]
        end
      end
      puts "data crawled : "+data[2]
      course = {
        year: @year,    # 西元年
        term: @term,    # 學期 (第一學期=1，第二學期=2)
        name: data[2],    # 課程名稱
        lecturer: data[6].gsub(/\s/,''),    # 授課教師
        credits: data[4].to_i,    # 學分數
        code: "#{@year}-#{@term}-#{course_id}_#{data[1]}",
        general_code: data[1],    # 選課代碼
        url: syllabus_url,    # 課程大綱之類的連結
        required: data[3].include?('必'),    # 必修或選修
        department: data[0],    # 開課系所
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
    puts "Project finished !!!"
    @courses
  end
end
end
