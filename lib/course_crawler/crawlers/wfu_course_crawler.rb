# 吳鳳科技大學
# 課程查詢網址：http://www2.wfu.edu.tw/wp/cur/

# only excel
# 沒有上課地點
module CourseCrawler::Crawlers
class WfuCourseCrawler < CourseCrawler::Base

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
    "F" => 14
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://www2.wfu.edu.tw/wp/cur/'
  end

  def courses
    @courses = []
    course_id = 0

    r = RestClient.get(@query_url)
    doc = Nokogiri::HTML(r)

    excel_url = nil
    (0..doc.css('div[id="contentarea"] a').count-1).each do |url_temp|
      if doc.css('div[id="contentarea"] a')[url_temp].text.include?("附件：#{@year-1911}-0#{@term}開課資料查詢")
        excel_url = doc.css('div[id="contentarea"] a')[url_temp][:href]
        break
      end
    end

    r = %x(curl -s '#{excel_url}' --compressed)
    doc = File.new("wfu_course_data_temp","w")
    doc.write(r)
    doc = Spreadsheet.open "wfu_course_data_temp"
    File.delete("wfu_course_data_temp")

    doc.worksheets.each do |worksheet|
      worksheet.map{|row| row}[1..-1].each do |data|
        if worksheet.name.include?("領域") || worksheet.name.include?("概論")
          data[1] = data[2]
          data[16] = data[11]
          data[13..14] = data[9..10]
          data[8..10] = data[5..7]
        elsif worksheet.name.include?("開課查詢")
        elsif worksheet.name.include?("發展")
          data[1] = data[2]
          data[16] = data[10]
          data[13..14] = data[8..9]
          data[8..10] = data[4..6]
        else
          data[1] = data[2]
          data[13..14] = data[9..10]
          data[8..10] = data[5..7]
          data[16] = data[12]
        end

        course_id += 1

        if data[14] != nil
          course_time = data[14].scan(/(?<day>[一二三四五六日])\)(?<period>[\w\-]+)/)
        else
          course_time = []
        end

        course_days, course_periods, course_locations = [], [], []
        course_time.each do |day, period|
          (PERIODS[period.scan(/\w/)[0]]..PERIODS[period.scan(/\w/)[-1]]).each do |p|
            course_days << DAYS[day]
            course_periods << p
            course_locations << nil
          end
        end

        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[9],    # 課程名稱
          lecturer: data[13],    # 授課教師
          credits: data[10].to_i,    # 學分數
          code: "#{@year}-#{@term}-#{course_id}_#{data[8]}",
          general_code: data[8],    # 選課代碼
          url: nil,    # 課程大綱之類的連結
          required: data[16].include?('必'),    # 必修或選修
          department: data[1],    # 開課系所
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
    end
    @courses
  end

end
end
