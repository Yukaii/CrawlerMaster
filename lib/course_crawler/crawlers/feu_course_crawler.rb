##
# 遠東科技大學
# http://web.isic.feu.edu.tw/query/classcour.asp?ysem=1041
#
require 'capybara'
require 'capybara/poltergeist'

module CourseCrawler::Crawlers
class FeuCourseCrawler < CourseCrawler::Base
  include Capybara::DSL

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil
    @year = year || current_year
    @term = term || current_term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = "http://web.isic.feu.edu.tw/query/classcour.asp?ysem=#{@year-1911}#{@term}"

    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app,  {
        js_errors: false,
        timeout: 300,
        ignore_ssl_errors: true,
      })
    end

    Capybara.javascript_driver = :poltergeist
    Capybara.current_driver = :poltergeist
  end

  def courses
    @courses = []
    visit @query_url

    daynight = all('input[name="DAYNIGHT"]')
    daynight.length.times do |daynight_index|
      all('input[name="DAYNIGHT"]')[daynight_index].click

      depts = all('select[name="DEPT"] option')
      depts.length.times do |dept_index|
        all('select[name="DEPT"] option')[dept_index].select_option

        subs = all('select[name="SUB"] option')
        subs.length.times do |sub_index|
          all('select[name="SUB"] option')[sub_index].select_option

          clas = all('select[name="CLASS"] option')
          clas.length.times do |clas_index|
            all('select[name="CLASS"] option')[clas_index].select_option

            click_on '　　查　　詢　　'
            parse_courses(Nokogiri::HTML(html))
            click_on '回前頁'
          end # end clas times
        end # end sub times
      end # end dept times
    end # end daynight times

    @courses
  end

  def parse_courses doc
    year, term, _ = doc.css('font[color="BLUE"]').map(&:text)

    year = year.to_i + 1911
    case term
    when "上學期"
      term = 1
    when "下學期"
      term = 2
    else
      term = 0
    end

    doc.css('table[width="1000"] tr:not(:first-child)').each do |row|
      datas = row.xpath('td')

      general_code = datas[1].text.strip
      next if general_code.empty?

      url = datas[2].css('a').any? ? datas[2].css('a')[0][:href] : nil
      url = "http://web.isic.feu.edu.tw/query/#{url}"

      course_days, course_periods, course_locations = [], [], []
      7.times do |i|
        day_index = i + 8

        datas[day_index].text.strip.split(',').map(&:to_i).each do |p|
          course_days      << i+1
          course_periods   << p
          course_locations << datas[7].text.strip
        end
      end

      @courses << {
        :year         => year,
        :term         => term,
        :code         => "#{year}-#{term}-#{general_code}",
        :general_code => general_code,
        :name         => datas[2].text.strip,
        :url          => url,
        :required     => datas[3].text.include?('必'),
        :credits      => datas[4].text.strip.to_i,
        :lecturer     => datas[6].text.strip,
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
end
end
