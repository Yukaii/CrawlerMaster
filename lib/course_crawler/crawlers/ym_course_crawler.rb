# 國立陽明大學
# 課程查詢網址：https://portal.ym.edu.tw/course/CSCS/CSCS01S01

# 只能看最新的課程狀態！！！學年度與學期無法選擇！！！
module CourseCrawler::Crawlers
class YmCourseCrawler < CourseCrawler::Base

  PERIODS = {
    "1" => 1,
    "2" => 2,
    "3" => 3,
    "4" => 4,
    "N" => 5,
    "5" => 6,
    "6" => 7,
    "7" => 8,
    "8" => 9,
    "9" => 10,
    "A" => 11,
    "B" => 12,
    "C" => 13,
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil
    # 只能看最新的課程狀態！！！學年度與學期無法選擇！！！
    @year = current_year
    @term = current_term

    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = "https://portal.ym.edu.tw/course/CSCS/CSCS01S01"
  end

  def courses
    @courses = []

    doc = Nokogiri::HTML( RestClient::Request.execute(url: @query_url, method: :get, verify_ssl: false))

    (0..1).each do |option|   # 0 => 大學部, 1 => 研究所

      doc.css('table:first-child select')[option].css('option:nth-child(n+2)').map{|opt| [opt[:value], opt.text]}.each do |dept_c, dept_n|

        tr_dept_c = nil
        if option == 1
          tr_dept_c = dept_c
          dept_c = nil
        end

        result_url = RestClient::Request.execute(url: "https://portal.ym.edu.tw/course/CSCS/CSCS0101List_2?Page=1&PageSize=999&SortColumn=LessonNo&SortDirection=Ascending&Filters.ClassCode=#{dept_c}&Filters.Tr_ClassCode=#{tr_dept_c}", method: :get, verify_ssl: false)
        doc = Nokogiri::HTML(result_url)
        dept_c = tr_dept_c if dept_c == nil

        doc.css('table[id="ListTable"] tbody tr').map{|tr| tr}.each do |tr|
          data = tr.css('td').map{|td| td.text}
          syllabus_url = tr.css('td:nth-child(2) a').map{|a| a[:href]}[0]

          course_days, course_periods, course_locations = [], [], []
          {1 => data[6], 2 => data[7], 3 => data[8], 4 => data[9], 5 => data[10], 6 => data[11], 7 => data[12]}.each do |k, v|
            next if v.scan(/\w+/)[0] == nil
            v.scan(/\w+/)[0].scan(/\w/).each do |period|
              course_days << k
              course_periods << PERIODS[period]
              course_locations << v.scan(/\w+(\S+)/)[0][0] if v.scan(/\w+(\S+)/)[0] != nil
            end
          end

          course = {
            year: @year,    # 西元年
            term: @term,    # 學期 (第一學期=1，第二學期=2)
            name: data[1],    # 課程名稱
            lecturer: data[15],    # 授課教師
            credits: data[3].to_i,    # 學分數
            code: "#{@year-1911}-#{@term}-#{dept_c}-#{data[0]}",
            general_code: data[0],    # 選課代碼
            url: syllabus_url,    # 課程大綱之類的連結(如果有的話)
            required: data[2].include?('必'),    # 必修或選修
            department: dept_n,    # 開課系所
            department_code: dept_c,
            # notes: data[23],
            # hours: data[4],
            # experiment_hours: data[5],
            # faculty: data[14],
            # people_limit: data[16],
            # people: data[17],
            # people_now: data[18],
            # level: data[19],
            # full_english: data[20],
            # reading_with_class: data[21],
            # interscholastic_course: data[22],
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
    @courses
  end
end
end
