##
# 萬能科大
# http://weboffice.vnu.edu.tw/web_cos/
#

require 'capybara'
require 'capybara/poltergeist'

module CourseCrawler::Crawlers
class VnuCourseCrawler < CourseCrawler::Base
  include Capybara::DSL

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year || current_year
    @term = term || current_term

    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = "http://weboffice.vnu.edu.tw/web_cos/"

    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app,  {
        js_errors: false,
        timeout: 300,
        ignore_ssl_errors: true,
        # debug: true
      })
    end

    Capybara.javascript_driver = :poltergeist
    Capybara.current_driver = :poltergeist
  end

  def courses
    @courses = {}

    visit @query_url

    all('select[name="TabContainer1$ClassCurriculum$ClassYearSem"] option')
      .find{|opt| opt.value == "#{@year-1911},#{@term}" }
      .select_option
    sleep 0.8

    sec_options = all('select[name="TabContainer1$ClassCurriculum$ClassDivCode"] option:not(:first-child)')
    sec_options.length.times do |sec_index|
      all('select[name="TabContainer1$ClassCurriculum$ClassDivCode"] option:not(:first-child)')[sec_index].select_option
      sleep 0.8
      prog_options = all('select[name="TabContainer1$ClassCurriculum$ClassProgram"] option:not(:first-child)')
      prog_options.length.times do |prog_index|
        all('select[name="TabContainer1$ClassCurriculum$ClassProgram"] option:not(:first-child)')[prog_index].select_option
        sleep 0.8

        dept_options = all('select[name="TabContainer1$ClassCurriculum$ClassDept"] option:not(:first-child)')
        dept_options.length.times do |dept_index|
          all('select[name="TabContainer1$ClassCurriculum$ClassDept"] option:not(:first-child)')[dept_index].select_option
          sleep 0.8

          clas_options = all('select[name="TabContainer1$ClassCurriculum$ClassClass"] option:not(:first-child)')
          clas_options.length.times do |clas_index|
            all('select[name="TabContainer1$ClassCurriculum$ClassClass"] option:not(:first-child)')[clas_index].select_option
            sleep 0.8
            parse_course(Nokogiri::HTML(html))
          end # end clas_options times
        end # end dept_options times
      end # end prog_options times
    end # end sec_options times

    @courses.values
  end

  def parse_course doc
    urls = doc.css('a[class=" CosLinkStyle"]')
               .map{|a| a[:onclick].match(/NewWindow\('(?<link>.+?)\'/)[:link]}
               .map{|link| "http://weboffice.vnu.edu.tw/web_cos/#{link}" }
               .uniq

    urls.each do |url|
      if @courses[url].nil?
        doc          = Nokogiri::HTML(http_client.get_content(url))
        datas        = doc.css('td.td_usual')

        year         = datas[0].text.strip.to_i + 1911
        term         = datas[1].text.strip.to_i
        general_code = datas[3].text.strip

        period_time_table = doc.css('table[style="width: 30%"]')

        course_days, course_periods, course_locations = [], [], []
        period_time_table.css('tr:nth-child(n+3)').each do |row|
          tds = row.css('td')

          course_days      << tds[2].text.strip[0].to_i
          course_periods   << tds[2].text.strip[1..-1].to_i
          course_locations << tds[0].text.strip
        end

        @courses[url] = {
          :year         => year,
          :term         => term,
          :general_code => general_code,
          :code         => "#{year}-#{term}-#{general_code}",
          :name         => datas[4].text.strip.match(/(?<=\)).+/)[0],
          :lecturer     => datas[6].text.strip,
          :credits      => datas[7].text.strip.to_i,
          :required     => datas[9].text.include?('必'),
          :url          => url,
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
    end # end each urls
  end # end parse_course

end
end
