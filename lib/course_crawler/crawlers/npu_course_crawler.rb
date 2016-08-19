# 國立澎湖科技大學
# 課程查詢網址：http://as1.npu.edu.tw/npu/
# 帳號:guest
# 密碼:123
require 'capybara'
require 'capybara/dsl'
require 'capybara/poltergeist'
module CourseCrawler::Crawlers
  class NpuCourseCrawler < CourseCrawler::Base
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

    def initialize(year: nil, term: nil, update_progress: nil, after_each: nil)
      @year = year
      @term = term
      @update_progress_proc = update_progress
      @after_each_proc = after_each

      @query_url = 'https://as1.npu.edu.tw/npu/index.html'
      Capybara.javascript_driver = :poltergeist
      Capybara.current_driver = :poltergeist
      Capybara::Webkit.configure do |config|
        config.allow_url('*.npu.edu.tw')
      end
    end

    def courses
      @courses = []
      visit @query_url
      sleep 3
      within_frame('Main') do
        find('#uid').set('guest')
        find('#pwd').set('123')
        click_on '確定送出'
      end
	  puts 'login...'
      sleep 1
      within_frame('Lmenu') do
        find('#fspan1').click
        all('.ob_td').each do |td|
          if td.text.include?('課程資料查詢')
            td.click
            break
          end
        end
      end
	  puts 'search course'
      sleep 1
      within_frame('Main') do
        find("#yms_yms option[value='#{@year - 1911}##{@term}']").select_option
        click_on '查詢'
		puts 'get course data'
        course_parse(html)
      end
      @courses
    end
	
    def course_parse(html)
      doc = Nokogiri::HTML(html)
      table = doc.css('table')
      trs = table[1].css('tr')
      trs.each do |tr|
        td = tr.css('td')
        tdd = td
        next unless td[0]['align'] == 'center' && td.count > 5
        td = tdd.map { |t| t.text.gsub(/ /, '') }
        course_time = td[12].scan(/([一二三四五六日])\)([\d\-,]+)/)
        course_days = []
        course_periods = []
        course_locations = []
        course_time.each do |day, period|
          period.split(',').each do |perd|
            (perd.scan(/\d+/)[0].to_i..perd.scan(/\d+/)[-1].to_i).each do |p|
              course_days << DAYS[day]
              course_periods << p
              course_locations << td[9]
            end
          end
        end

        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: td[4], # 課程名稱
          lecturer: td[8], # 授課教師
          credits: td[5].to_i, # 學分數
          code: "#{@year}-#{@term}-#{td[3]}",
          general_code: td[3], # 選課代碼
          url: nil, # 課程大綱之類的連結
          required: td[7].include?('必'), # 必修或選修
          department: td[1], # 開課系所
          # department_code: dept_v,
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
