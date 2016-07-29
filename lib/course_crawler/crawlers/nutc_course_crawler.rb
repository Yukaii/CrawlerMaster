# 臺中科技大學
# 課程查詢網址：http://academic.nutc.edu.tw/curriculum/show_subject/select_menu.asp

module CourseCrawler::Crawlers
class NutcCourseCrawler < CourseCrawler::Base

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
    "１" => 1,
    "２" => 2,
    "３" => 3,
    "４" => 4,
    "５" => 5,
    "６" => 6,
    "７" => 7,
    "８" => 8,
    "９" => 9,
    "１０" => 10,
    "１１" => 11,
    "１２" => 12,
    "１３" => 13,
    "１４" => 14
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://aisap.nutc.edu.tw/public/'
  end

  def courses
    @courses = []
    course_id_temp = {}

    # 先抓取全部的course_id
    doc = URI.decode(RestClient.get(@query_url+"subject_list.js"))

    course_code_data = []
    (doc.gsub(/[\"\s\n]/,"").split(";").count-1).downto(1) do |y_t|
      if doc.gsub(/[\"\s\n]/,"").split(";")[y_t][9..19].include?("#{@year-1911}#{@term}")
        course_code_data += doc.gsub(/[\"\s\n]/,"").split(";")[y_t].split("=[[")[1][0..-3].split("],[")
      else
        break
      end
    end

    # 分日間部&夜間部跑
    ["day","nig"].each do |d_n|

      course_code_data.each do |course_id|
        r = RestClient.get(@query_url+"#{d_n}/course_list.aspx?sem=#{@year-1911}#{@term}&subject=#{course_id.scan(/\w+/)[0]}")
        doc = Nokogiri::HTML(r)

        doc.css('table[class="grid_view empty_html"] tr:nth-child(n+2)').each do |tr|
          data = tr.css('td').map{|td| td.text}
          next if course_id_temp[data[1]]

          course_time_location = data[5].scan(/(?<day>[一二三四五六日])第(?<period>[１２３４５６７８９０、]+)節\s\((?<loc>\w+)/)

          course_days, course_periods, course_locations = [], [], []
          course_time_location.each do |day, period, loc|
            period.split("、").each do |p|
              course_days << DAYS[day]
              course_periods << PERIODS[p]
              course_locations << loc
            end
          end

          course = {
            year: @year,    # 西元年
            term: @term,    # 學期 (第一學期=1，第二學期=2)
            name: data[3],    # 課程名稱
            lecturer: data[9],    # 授課教師
            credits: data[7][0].to_i,    # 學分數
            code: "#{@year}-#{@term}-#{course_id.scan(/\w+/)[0]}_#{data[1]}",
            general_code: data[1],    # 選課代碼
            url: nil,    # 課程大綱之類的連結
            required: data[6].include?('必'),    # 必修或選修
            department: data[2],    # 開課系所
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

          course_id_temp[data[1]] = true

        end
      end
    end
    @courses
  end

end
end
