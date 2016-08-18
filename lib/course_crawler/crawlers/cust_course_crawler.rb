# 中華科技大學
# 課程查詢網址：http://ap.cust.edu.tw/CIS/Personnel/ListCourse.do

# 沒有學年度可以選擇
module CourseCrawler::Crawlers
class CustCourseCrawler < CourseCrawler::Base

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

    @query_url = 'http://ap.cust.edu.tw'
  end

  def courses
    @courses = []
    course_id = 0
    puts "get url ..."
    r, cookie = nil, nil
    error_times = 0

    while error_times < 10
      begin
        r = RestClient.get(@query_url+"/CIS/Personnel/ListCourse.do")
        cookie = r.cookies
        error_times = 0
        break
      rescue
        error_times += 1
      end
    end

    # campusNo = [1,2,5] # 校區的代碼(台北、新竹、高雄)
    [1,2,5].each do |campusNo|
      while error_times < 10
        begin
          r = RestClient.post(@query_url+"/CIS/Personnel/ListCourse.do", {
          "term" => @term,
          "CampusNo" => "#{campusNo}",
          # "SchoolNo" => "",
          # "DeptNo" => "",
          # "Grade" => "",
          # "ClassNo" => "",
          # "cname" => "",
          # "techid" => "",
          # "week" => "",
          # "begin" => "",
          # "end" => "",
          # "chi_name" => "",
          # "opt" => "",
          # "open" => "",
          # "elearning" => "",
          "method" => "查詢"
          }, cookie: cookie)
          error_times = 0
          break
        rescue
          error_times += 1
        end
      end

      doc = Nokogiri::HTML(r)

      doc.css('table[id="row"] tbody tr').map{|tr| tr}.each do |tr|
# puts "#{campusNo},#{course_id}"
        data = tr.css('td').map{|td| td.text}
        course_id += 1
        data[3] = data[3].scan(/(.+) 課表/)[0][0] if data[3].include?(" 課表")
        data[4] = data[4].scan(/(.+) 課表/)[0][0] if data[4].include?(" 課表")
        data[12] = data[12].scan(/(.+) 課表/)[0][0] if data[12].include?(" 課表")
        syllabus_url = @query_url + tr.css('td:nth-child(11) a').map{|a| a[:href]}[0]

        course_time_location = data[12].scan(/(?<day>[一二三四五六日])(?<period>\d\d?~\d\d?),\s?(?<loc>\w+)?/)

        course_days, course_periods, course_locations = [], [], []
        course_time_location.each do |day, period, loc|
          (period.split('~')[0].to_i..period.split('~')[-1].to_i).each do |p|
            course_days << DAYS[day]
            course_periods << p
            course_locations << loc
          end
        end
        puts "data crawled : "+data[2]
        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[2],    # 課程名稱
          lecturer: data[4],    # 授課教師
          credits: data[6].to_i,    # 學分數
          code: "#{@year}-#{@term}-#{course_id}_#{data[1]}",
          general_code: data[1],    # 選課代碼
          url: syllabus_url,    # 課程大綱之類的連結
          required: data[5].include?('必'),    # 必修或選修
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
      end
    end
    puts "Project finished !!!"
    @courses
  end

end
end
