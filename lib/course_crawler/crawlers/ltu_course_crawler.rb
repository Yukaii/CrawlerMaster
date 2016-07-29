# 嶺東科技大學
# 課程查詢網址：https://course.ltu.edu.tw/StudySelect.aspx

module CourseCrawler::Crawlers
class LtuCourseCrawler < CourseCrawler::Base

# 日夜六日的節次不同
  PERIODS = {
    "1" => 1,
    "2" => 2,
    "3" => 3,
    "4" => 4,
    "A" => 5,
    "5" => 6,
    "6" => 7,
    "7" => 8,
    "8" => 9,
    "9" => 10,
    "B" => 11,
    "一" => 12,
    "二" => 13,
    "三" => 14,
    "四" => 15,
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'https://course.ltu.edu.tw/'
  end

  def courses
    @courses = []
    course_id = 0

    r = RestClient.get(@query_url+"StudySelect.aspx")
    doc = Nokogiri::HTML(r)

    hidden = Hash[Nokogiri::HTML(r).css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    r = RestClient.post(@query_url+"StudySelect.aspx", hidden.merge({
      "TBid" => "",
      "TBpass" => "",
      "DDLyea" => "#{@year-1911}#{@term}",
      "RB_4" => "RB_4",
      "DDLlike" => "0",
      "CBLike" => "on",
      "TBlike" => "%",
      "Bselect" => "查詢",
      }) )
    doc = Nokogiri::HTML(r)

    doc.css('table[class="GridViewStyle"] tr:nth-child(n+2)').each do |tr|
      data = tr.css('td').map{|td| td.text.gsub(/[\r\n\s]/,"")}
      data[2] = 0 if data[2] == " "
      syllabus_url = @query_url+tr.css('td a')[0][:href] if not tr.css('td a')[0][:href].include?("javascript")

      course_id += 1

      course_time = data[13].scan(/(?<day>\d)\-(?<period>[\w一二三四]+)/)

      course_days, course_periods, course_locations = [], [], []
      course_time.each do |day, period|
        course_days << day.to_i
        if day.to_i < 6
          course_periods << PERIODS[period]
        else
          if day.to_i == 6 && data[0].include?("進院")
            course_periods << period.to_i + 4
          else
            course_periods << period.to_i
          end
        end
        course_locations << data[10]
      end

      course = {
        year: @year,    # 西元年
        term: @term,    # 學期 (第一學期=1，第二學期=2)
        name: data[3],    # 課程名稱
        lecturer: data[9],    # 授課教師
        credits: data[6].to_i,    # 學分數
        code: "#{@year}-#{@term}-#{course_id}_#{data[2]}",
        general_code: data[2],    # 選課代碼
        url: syllabus_url,    # 課程大綱之類的連結
        required: data[4].include?('必'),    # 必修或選修
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
    @courses
  end
end
end
