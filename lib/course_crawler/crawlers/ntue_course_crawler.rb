# 國立臺北教育大學
# 課程查詢網址：http://apstu.ntue.edu.tw/Secure/default.aspx
require 'capybara'
require 'capybara/dsl'

module CourseCrawler::Crawlers
  class NtueCourseCrawler < CourseCrawler::Base
    include Capybara::DSL
    PERIODS = {
      "01" => 1,
      "02" => 2,
      "03" => 3,
      "04" => 4,
      "0N" => 5,
      "05" => 6,
      "06" => 7,
      "07" => 8,
      "08" => 9,
      "0E" => 10,
      "09" => 11,
      "10" => 12,
      "11" => 13,
      "12" => 14
    }.freeze

    def initialize(year: nil, term: nil, update_progress: nil, after_each: nil)
      @year = year || current_year
      @term = term || current_term
      @update_progress_proc = update_progress
      @after_each_proc = after_each

      @query_url = 'http://apstu.ntue.edu.tw/Secure/default.aspx'
      @ic = Iconv.new('utf-8//translit//IGNORE', 'utf-8')
      # selenium
      Capybara.javascript_driver = :webkit
      Capybara.current_driver = :webkit
      Capybara::Webkit.configure do |config|
        config.allow_url("*.ntue.edu.tw")
      end
    end

    def courses
      @courses = []
      visit @query_url
      sleep 1
      find('#LoginDefault_ibtLoginGuest').click
      sleep 1
      within_frame('MAIN') do
        find('#MenuDefault_dgData_ibtMENU_ID_0').click
        click_on '各種課表查詢'
        sleep 1
        find("#A0425SMenu_ddlSYSE option[value='#{@year - 1911}#{@term}']").select_option
        sleep 1
        page_num = 1
        course_parse(html)
        loop do
          page = first('.TRPagerStyle')
          page = page.all('a')
          first_num = page.first.text == '...'
          last_num = page.last.text == '...'
          break if page_num >= page.last.text.to_i && !last_num && page_num != 0

          page.each do |a|
            if first_num
              first_num = false
              next
            end
            next unless a.text.to_i > page_num || a.text == '...'
            page_num = a.text.to_i
            a.click
            sleep 2.5
            course_parse(html)
            break
          end
        end
      end

      @courses
    end

    def course_parse(doc)
      doc = Nokogiri::HTML(doc)

      doc.css('table[class="DgTable"] tr[onmouseover="OnOver(this);"]').map { |tr| tr }.each do |tr|
        data = tr.css('td span').map(&:text)
        name = tr.css('td a').map(&:text)[0]

        time_period_regex = /(?<day>[1234567])(?<period>\w\w\w\w)/
        course_time_period = data[7].scan(time_period_regex) # !!!data[8]裡有寫單雙周!!!
        course_days = []
        course_periods = []
        course_locations = []
        course_time_period.each do |k, v|
          (PERIODS[v[0..1]]..PERIODS[v[2..3]]).each do |period|
            course_days << k.to_i
            course_periods << period # !!!有些課程分單、雙周上課!!!
            course_locations << data[8]
          end
        end

        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: name, # 課程名稱
          lecturer: data[6], # 授課教師
          credits: data[9].to_i,    # 學分數
          code: "#{@year}-#{@term}-#{data[0]}",
          general_code: data[0],    # 選課代碼
          required: data[1].include?('必'), # 必修或選修
          department: (data[4]).to_s + " " + (data[3]).to_s, # 開課系所
          # note: data[14],    # 備註   !!!這裡有寫單雙周!!!
          # department_type: data[2],    # 修別 (XX課程)
          # study_type: data[5],    # 學制
          # people_minimum: data[10],    # 人數下限
          # people_maximum: data[11],    # 人數上限
          # people_1: data[12],    # 已選人數
          # people_2: data[13],    # 選中人數
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
        @courses << course
      end
  end
  end
end
