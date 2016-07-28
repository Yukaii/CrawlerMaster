##
# 聖約翰科技大學
# http://sjuportal.sju.edu.tw/Sjucourse/SJU_CourseQry.aspx
#

require 'capybara'
require 'capybara/poltergeist'
require 'capybara/dsl'

module CourseCrawler::Crawlers
class SjuCourseCrawler < CourseCrawler::Base
  include Capybara::DSL

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil

    @year = year || current_year
    @term = term || current_term

    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = "http://sjuportal.sju.edu.tw/Sjucourse/SJU_CourseQry.aspx"

    Capybara.javascript_driver = :webkit
    Capybara.current_driver = :webkit
  end

  def courses
    @courses = []

    page.driver.allow_url("sjuportal.sju.edu.tw")

    visit @query_url

    frame = first 'iframe'
    within_frame frame do
      all('select[name="ddlYearSem"] option').find{|opt| opt.value == "#{@year-1911}-#{@term}"}.select_option
      sleep 0.8

      divs = all('select[name="ddlDivCode"] option:not(:first-child)')
      divs.length.times do |div_index|
        divs = all('select[name="ddlDivCode"] option:not(:first-child)')
        divs[div_index].select_option
        sleep 0.8

        depts = all('select[name="ddlDept"] option:not(:first-child)')
        depts.length.times do |dept_index|
          depts = all('select[name="ddlDept"] option:not(:first-child)')
          depts[dept_index].select_option
          sleep 0.8

          clas = all('select[name="ddlClass"] option:not(:first-child)')
          clas.length.times do |clas_index|
            clas = all('select[name="ddlClass"] option:not(:first-child)')
            clas[clas_index].select_option
            sleep 0.8

            first('input[type="submit"][name="btnClassQry"]').click
            parse_course(Nokogiri::HTML(html))
          end # end clas times
        end # end depts times
      end # end divs times
    end # end within_frame

    @courses
  end # end def courses

  def parse_course doc
    doc.css('table#gvSbjList tr:not(:first-child)').each do |row|
      datas = row.xpath('td')

      url = datas[1].css('span').empty? ? nil : datas[1].css('span')[0][:onclick].match(/WinOpen\(\'(.+?)\'/)[1]

      location = datas[13].text.strip
      course_days, course_periods, course_locations = [], [], []
      general_code = datas[0].text.strip

      7.times do |i|
        day_index = i + 6

        datas[day_index].text.strip
                        .scan(/\[(\d+)\]/)
                        .flatten
                        .map(&:to_i).each do |period|

          course_days      << i + 1
          course_periods   << period
          course_locations << location
        end
      end

      @courses << {
        :year         => @year,
        :term         => @term,
        :name         => datas[1].text.strip,
        :url          => url,
        :required     => datas[3].text.include?('必'),
        :credits      => datas[4].text.strip.to_i,
        :lecturer     => datas[14].text.strip,
        :general_code => general_code,
        :code         => "#{@year}-#{@term}-#{general_code}",
        :day_1        => course_days[0],
        :day_2        => course_days[1],
        :day_3        => course_days[2],
        :day_4        => course_days[3],
        :day_5        => course_days[4],
        :day_6        => course_days[5],
        :day_7        => course_days[6],
        :day_8        => course_days[7],
        :day_9        => course_days[8],
        :period_1     => course_periods[0],
        :period_2     => course_periods[1],
        :period_3     => course_periods[2],
        :period_4     => course_periods[3],
        :period_5     => course_periods[4],
        :period_6     => course_periods[5],
        :period_7     => course_periods[6],
        :period_8     => course_periods[7],
        :period_9     => course_periods[8],
        :location_1   => course_locations[0],
        :location_2   => course_locations[1],
        :location_3   => course_locations[2],
        :location_4   => course_locations[3],
        :location_5   => course_locations[4],
        :location_6   => course_locations[5],
        :location_7   => course_locations[6],
        :location_8   => course_locations[7],
        :location_9   => course_locations[8]
      }
    end
  end
end; end;
