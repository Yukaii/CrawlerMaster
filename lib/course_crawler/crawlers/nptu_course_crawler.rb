# 國立屏東大學
# 課程查詢網址：http://webap.nptu.edu.tw/web/Secure/default.aspx
require 'capybara'
require 'capybara/dsl'
module CourseCrawler::Crawlers
  class NptuCourseCrawler < CourseCrawler::Base
    include Capybara::DSL

    DAYS = {
      "一" => 1,
      "二" => 2,
      "三" => 3,
      "四" => 4,
      "五" => 5,
      "六" => 6,
      "日" => 7
    }.freeze

    PERIODS = {
      "M" => 1,
      "1" => 2,
      "2" => 3,
      "3" => 4,
      "4" => 5,
      "N" => 6,
      "5" => 7,
      "6" => 8,
      "7" => 9,
      "8" => 10,
      "9" => 11,
      "A" => 12,
      "B" => 13,
      "C" => 14,
      "D" => 15
    }.freeze

    def initialize(year: nil, term: nil, update_progress: nil, after_each: nil)
      @year = year - 1911
      @term = term
      @update_progress_proc = update_progress
      @after_each_proc = after_each

      @query_url = 'http://webap.nptu.edu.tw/web/'
      Capybara.javascript_driver = :webkit
      Capybara.current_driver = :webkit
      Capybara::Webkit.configure do |config|
        config.allow_url("*.nptu.edu.tw")
      end
    end

    def courses
      @courses = []
      visit @query_url
      sleep 2
      click_on 'LoginDefault_ibtLoginGuest'

      within_frame('MENU') do
        data = Nokogiri::HTML(html)
        doc = data.css('a')
        doc.each do |a|
          click_on a.text if a.text.include?('主選單')
        end
      end
      sleep 1
      within_frame('MAIN') do
        data = Nokogiri::HTML(html)
        doc = data.css('a')
        doc.each do |a|
          if a.text.include?('課表')
            click_on a.text
            break
          end
        end
      end
      sleep 2
      within_frame('MAIN') do
        find("#A0425Q3_ddlSYSE option[value='#{@year}#{@term}']").select_option
        sleep 1
        data = Nokogiri::HTML(html)
        doc = data.css('#A0425Q3_ddlDEPT_ID')
        doc = doc.first.css('option')
        dps = []
        doc.each do |value|
          dps << value[:value] if value[:value] != ''
        end
        dps = dps.uniq
        dps.each do |dp|
          find("#A0425Q3_ddlSYSE option[value='#{@year}#{@term}']").select_option
          sleep 1
          find("#A0425Q3_ddlDEPT_ID option[value='#{dp}']").select_option
          click_on '查詢'
          begin
            parse_course(html)
            find('#A0425S3_ibtBackQueryUp').click
          rescue
            puts "departmentid: #{dp} no data"
          end
        end
      end
      @courses
    end

    def parse_course(html)
      doc = Nokogiri::HTML(html)

      doc.css('table[id="A0425S3_dgData"] tr:nth-child(n+2)').each do |tr|
        data = tr.css('td').map { |td| td.text.gsub(/[\r\n\s]/, '') }

        course_days = []
        course_periods = []
        course_locations = []
        (0..data[10].scan(/\d/).count - 1).each do |i|
          period = data[11].scan(/\w+/)[i]
          period.scan(/\w/).each do |p|
            next if p == "0"
            course_days << data[10].scan(/\d/)[i].to_i
            course_periods << PERIODS[p]
            course_locations << data[12]
          end
        end

        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[5], # 課程名稱
          lecturer: data[9], # 授課教師
          credits: data[7].to_i,    # 學分數
          code: "#{@year}-#{@term}-#{data[4]}_#{data[3]}",
          general_code: data[3],    # 選課代碼
          url: nil, # 課程大綱之類的連結
          required: data[6].include?('必'), # 必修或選修
          department: data[2], # 開課系所
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
          location_9: course_locations[8]
        }

        @after_each_proc.call(course: course) if @after_each_proc
        @courses << course
      end
    end
  end
end
