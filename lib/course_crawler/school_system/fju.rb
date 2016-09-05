require 'capybara/dsl'
require 'capybara/poltergeist'

# run:
# CourseCrawler::SchoolSystem::Fju.new.crawl(UserID: '', Password: '')
# in rails console

class CourseCrawler::SchoolSystem::Fju
  include Capybara::DSL

  def initialize
    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app, js_errors: false)
    end

    Capybara.javascript_driver = :poltergeist
    Capybara.current_driver = :poltergeist
  end

  def crawl(params)
    visit "http://140.136.251.210/student/Account/Login"

    fill_in 'UserID', with: params[:UserID]
    fill_in 'Password', with: params[:Password]

    first('input[type="submit"]').click

    click_link('校內系統選單')

    new_window = window_opened_by { click_link '選課清單' }
    within_window new_window do
      doc = Nokogiri::HTML(html)

      course_datas = doc.css('table#GV_NewSellist tr:not(:first-child)').map do |row|
        datas = row.css('td')

        {
          course_code: datas[4].text.strip,
          course_name: datas[7].text.strip,
          course_lecturer: datas[12].text.strip
        }
      end

      return course_datas
    end
  end
end
