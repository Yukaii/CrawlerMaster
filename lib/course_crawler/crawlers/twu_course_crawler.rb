# 環球科技大學
# 課程查詢網址：http://ecampus.twu.edu.tw/IISystem/school/Class/Class_Manage/Insert1/web.jsp

module CourseCrawler::Crawlers
class TwuCourseCrawler < CourseCrawler::Base

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
    "N" => 6,
    "5" => 7,
    "6" => 8,
    "7" => 9,
    "8" => 10,
    "9" => 11,
    "A" => 12,
    "B" => 13,
    "C" => 14,
    "D" => 15,
    "E" => 16,
    "F" => 17
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://ecampus.twu.edu.tw/IISystem/school/Class/Class_Manage/Insert1/web.jsp'
    @ic = Iconv.new('utf-8//IGNORE//translit', 'big5')
  end

  def courses
    @courses = []
    course_id = 0
    dept = nil

    r = RestClient.get(@query_url)
    doc = Nokogiri::HTML(r)
# binding.pry

# 先只找日間部
    doc.css('select[name="Edu_Session_ID_Filter"] option').map{|opt| opt[:value]}.each do |col|
      # col==4 是四技日間部 
      doc.css('select[name="Edu_Academy_ID_Filter"] option').map{|opt| opt[:value]}.each do |aca|
        # r = RestClient.get("http://140.130.168.152/ftp/Class/Print_063405_#{@year-1911}_#{@term}_#{aca}_1_#{col}_0_0_0_0.htm")
        r = %x(curl -s 'http://140.130.168.152/ftp/Class/Print_063405_#{@year-1911}_#{@term}_#{aca}_1_#{col}_0_0_0_0.htm' --compressed)
        doc2 = Nokogiri::HTML(@ic.iconv(r))
        doc2.css('table tr:nth-child(n+2)').map{|tr| tr}.each do |tr|
          data = tr.css('td').map{|td| td.text.gsub(/[\n\s]/,"")}
          dept = data[0].scan(/系所:(?<dept>\S+)\s/)[0] if data[0].scan(/系所:(?<dept>\S+)\s/)[0] != nil
          next if data.count < 11 or data[0] == "選課代碼" or data[0] == "合計" or data[0] == " "
          course_id += 1

# puts "http://140.130.168.152/ftp/Class/Print_063405_#{@year-1911}_#{@term}_#{aca}_1_#{col}_0_0_0_0.htm",data[0]
          course_days, course_periods, course_locations = [], [], []
          data[9].scan(/(?<day>[一二三四五六日])\](?<period>[\d\,]+)/).each do |day, periods|
            periods.scan(/[\w]/).each do |p|
              course_days << DAYS[day]
              course_periods << PERIODS[p]
              course_locations << data[8]
            end
          end

          course = {
            year: @year,    # 西元年
            term: @term,    # 學期 (第一學期=1，第二學期=2)
            name: data[5],    # 課程名稱
            lecturer: data[7],    # 授課教師
            credits: data[1].to_i,    # 學分數
            code: "#{@year}-#{@term}-#{course_id}_#{data[0]}",
            general_code: data[0],    # 選課代碼
            url: nil,    # 沒有
            required: data[4].include?('必'),    # 必修或選修
            department: dept,    # 開課系所
            # department_code: department_code,
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
# binding.pry
    @courses
  end
end
end