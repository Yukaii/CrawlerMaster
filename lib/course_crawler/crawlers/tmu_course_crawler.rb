##
# 臺北醫學大學
# http://acadsys.tmu.edu.tw/pubinfo/cousreSearch.aspx
require 'capybara'
require 'capybara/dsl'
require 'capybara/poltergeist'

module CourseCrawler::Crawlers
class TmuCourseCrawler < CourseCrawler::Base

  PERIODS = {
    "1"  =>  1,
    "2"  =>  2,
    "3"  =>  3,
    "4"  =>  4,
    "5"  =>  5,
    "6"  =>  6,
    "7"  =>  7,
    "8"  =>  8,
    "9"  =>  9,
    "A"  => 10,
    "B"  => 11,
    "C"  => 12,
    "D"  => 13
  }

  include Capybara::DSL
  def initialize year: nil, term: nil, update_progress: nil, after_each: nil
    @year = year || current_year
    @term = term || current_term

    @post_url = "http://acadsys.tmu.edu.tw/pubinfo/cousreSearch.aspx"

    @update_progress_proc = update_progress
    @after_each_proc = after_each

    Capybara.javascript_driver = :webkit
    Capybara.current_driver = :webkit
  end

  def courses
    @courses = []
    page.driver.allow_url("acadsys.tmu.edu.tw")

    visit "http://acadsys.tmu.edu.tw/pubinfo/cousreSearch.aspx"
    first("select[name=\"ctl00$ContentPlaceHolder1$DropDownListSmtr\"] option[value=\"#{@year-1911}#{@term}\"]")

    first('input[name="ctl00$ContentPlaceHolder1$SearchButton"]').click

    page_count = 1
    loop do
      parse_course(Nokogiri::HTML(html))
      set_progress "page #{page_count}"

      page_count += 1;
      next_page = first(%Q{a[href="javascript:__doPostBack('ctl00$ContentPlaceHolder1$GridView1','Page$#{page_count}')"]})

      break if next_page.nil?
      next_page.click
      sleep 1.5
    end

    @courses
  end

  def parse_course doc
    index = doc.css('table[id="ctl00_ContentPlaceHolder1_GridView1"] tr')

    index[1..-3].each do |row|
      datas = row.css('td')

      course_days, course_periods, course_locations = [], [], []
      (14..20).each do |day_index|
        p_str = power_strip(datas[day_index].text)
        next if p_str.empty?
        p_str.split('').map{|p| PERIODS[p]}.each do |p|
          course_days      << day_index - 13
          course_periods   << p
          course_locations << datas[21].text.strip
        end
      end

      course = {
        name:         "#{datas[5].text.strip}",
        year:         @year,
        term:         @term,
        code:         "#{@year}-#{@term}-#{datas[3].text.strip}",
        general_code: datas[3].text.strip,
        department:   "#{datas[1].text.strip}",
        credits:      datas[8].text.strip.to_i,
        lecturer:     "#{datas[13].text}",
        day_1:        course_days[0],
        day_2:        course_days[1],
        day_3:        course_days[2],
        day_4:        course_days[3],
        day_5:        course_days[4],
        day_6:        course_days[5],
        day_7:        course_days[6],
        day_8:        course_days[7],
        day_9:        course_days[8],
        period_1:     course_periods[0],
        period_2:     course_periods[1],
        period_3:     course_periods[2],
        period_4:     course_periods[3],
        period_5:     course_periods[4],
        period_6:     course_periods[5],
        period_7:     course_periods[6],
        period_8:     course_periods[7],
        period_9:     course_periods[8],
        location_1:   course_locations[0],
        location_2:   course_locations[1],
        location_3:   course_locations[2],
        location_4:   course_locations[3],
        location_5:   course_locations[4],
        location_6:   course_locations[5],
        location_7:   course_locations[6],
        location_8:   course_locations[7],
        location_9:   course_locations[8],
      }

      @after_each_proc.call(course: course) if @after_each_proc
      @courses << course
    end
  end
end
end
