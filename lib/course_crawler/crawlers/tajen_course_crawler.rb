# 大仁科技大學
# 課程查詢網址：http://a04.tajen.edu.tw/files/14-1004-53797,r31-1.php

# 節次資料：http://www.tajen.edu.tw/files/14-1000-22281,r19-1.php?Lang=zh-tw
# 檔案是XLSX,用rubyXL解
require 'rubyXL'

module CourseCrawler::Crawlers
class TajenCourseCrawler < CourseCrawler::Base

  DAYS = {
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6,
    "日" => 7
  }

  PERIODS_WEEKDAY = Hash[CoursePeriod.find('TAJEN').periods.select { |p| 1 <= p.order && p.order <= 17 }.map { |p| [p.code, p.order] }]
  PERIODS_WEEKEND = Hash[CoursePeriod.find('TAJEN').periods.select { |p| 18 <= p.order && p.order <= 35 }.map { |p| [p.code, p.order] }]

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://a04.tajen.edu.tw/bin/downloadfile.php?file=WVhSMFlXTm9MelU1TDNCMFlWOHpNamcxT1Y4NE1qRTJOamd4WHpZNU5qWTRMbmhzYzNnPQ==&fname=KLRPDGOPGHB5ZTUX15RPQPPKB1VTCDFDUXRPJDPK35NLB5CHCDQPRLOLHDVTOPRPRLNLGHQPKLOPCDDDEDSTGDRPEDIHGDQP14EDCDRPJDFDTWEHGHA5HDSX35FDWXVTKLRPDGOP45QPNP55CD31QP5515JHFDCHUTJHYXQPUXWXKOKO'
  end

  def courses
    @courses = []

    r = %x(curl -s '#{@query_url}' --compressed)
    doc = File.new("tajen_course_data_temp","w")
    doc.write(r)
    doc = RubyXL::Parser.parse("tajen_course_data_temp")
    File.delete("tajen_course_data_temp")

    doc.worksheets[0].map(&:cells)[1..-1].each do |cells|
      data = cells.map(&:value)

      next if data[1].include?("夜") # 不處裡進修部

      course_time = data[14].scan(/(?<day>[一二三四五六日])\((?<period>[\d,]+)/)

      course_days = []
      course_periods = []
      course_locations = []
      course_time.each do |day, period|
        period.split(",").each do |p|
          course_days << DAYS[day]
          course_periods << if DAYS[day] > 5
                              PERIODS_WEEKEND[p]
                            else
                              PERIODS_WEEKDAY[p]
                            end
          course_locations << data[13]
        end
      end

      course = {
        year: @year,    # 西元年
        term: @term,    # 學期 (第一學期=1，第二學期=2)
        name: data[8],    # 課程名稱
        lecturer: data[9],    # 授課教師
        credits: data[10],    # 學分數
        code: "#{@year}-#{@term}-#{data[7]}",
        general_code: data[7],    # 選課代碼
        url: nil,    # 課程大綱之類的連結
        required: data[0].include?('必'),    # 必修或選修
        department: data[4],    # 開課系所
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
