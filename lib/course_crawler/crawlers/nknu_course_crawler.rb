##
# 高師課程爬蟲
# http://www.nknu.edu.tw/~course/choose/
#

module CourseCrawler::Crawlers
class NknuCourseCrawler < CourseCrawler::Base

  PERIODS = {
    "1" => 1,
    "2" => 2,
    "3" => 3,
    "4" => 4,
    "5" => 5,
    "6" => 6,
    "7" => 7,
    "8" => 8,
    "9" => 9,
    "T" => 10,
  }

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil
    @year = year || current_year
    @term = term || current_term
  end

  def courses
    courses = []
    query_page = "http://140.127.40.75/schedule/scheduleDepartment.aspx"

    # doc = Nokogiri::HTML("<html></html>")
    # doc.css('html')

    doc = Nokogiri::HTML(http_client.get_content(query_page))
    departments = doc.css('select#ctl00_phMain_uDepartment option:not(:first-child)').map{|opt| [opt.text, opt[:value]] }

    departments.each do |dept_arr|
      view_state = Hash[doc.css('input[type="hidden"]').map{|input| [input[:name], input[:value]] }]

      form_data = {
        'ctl00$phMain$uYear': @year-1911,
        'ctl00$phMain$rdoDN': 'uDN_D',
        'ctl00$phMain$uDepartment': dept_arr[1],
        'ctl00$phMain$uSemester': @term,
        'ctl00$phMain$uDeForm': 'uDeForm1',
        'ctl00$phMain$uSearch': '查詢'
      }

      r = http_client.post(query_page, form_data.merge(view_state))
      doc = Nokogiri::HTML(r.body)

      doc.css('table#ctl00_phMain_uScheduleList_uList > tr:not(:first-child)')[0..-2].each_with_index do |row, index|
        cols = row.css('td')

        course_days, course_periods, course_locations = [], [], []
        lecturer_col, period_col, location_col = 6, 7, 8

        if cols.count > 12
          lecturer_col = 7
          period_col = 9
          location_col = 10
        end

        cols[period_col].text.split(',').each do |day_period|
          course_days << day_period[0].to_i
          course_periods << PERIODS[day_period[1]]
          course_locations << cols[location_col].text
        end

        code = cols[1].text

        course = {
          :year         => @year,
          :term         => @term,
          :code         => code,
          :general_code => "#{@year}-#{@term}-#{code}",
          :name         => cols[2].text,
          :url          => "http://140.127.40.75#{cols[2].css('a')[0][:href]}",
          :credits      => cols[3].text.to_i,
          :required     => cols[4].text.include?('必'),
          :department   => cols[5].text,
          :lecturer     => cols[lecturer_col].text,
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
          :location_9   => course_locations[8],
        }
        courses << course
      end
    end
    courses
  end

end
end
