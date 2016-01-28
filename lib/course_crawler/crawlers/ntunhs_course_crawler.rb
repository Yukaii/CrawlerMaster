# 國立臺北護理健康大學
# 課程查詢網址：http://system10.ntunhs.edu.tw/AcadInfoSystem/Modules/QueryCourse/QueryCourse.aspx

module CourseCrawler::Crawlers
class NtunhsCourseCrawler < CourseCrawler::Base

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year || current_year
    @term = term || current_term

    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://system10.ntunhs.edu.tw/AcadInfoSystem/Modules/QueryCourse/QueryCourse.aspx'
  end

  def courses
    @courses = []

    r = HTTPClient.get(@query_url).body
    doc = Nokogiri::HTML(r)

    hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    r = HTTPClient.post(@query_url, hidden.merge({
      "ctl00$ScriptManager1" => "ctl00$ScriptManager1|ctl00$ContentPlaceHolder1$btnQuery",
      # "__EVENTTARGET" => "",
      # "__EVENTARGUMENT" => "",
      "ctl00$ContentPlaceHolder1$ddlSem" => "#{@year - 1911}#{@term}",
      "ctl00$ContentPlaceHolder1$cblSemNo$0" => "#{@year - 1911}#{@term}",
      # "ctl00$ContentPlaceHolder1$ddlDept" => "",
      # "ctl00$ContentPlaceHolder1$ddlProgram" => "",
      # "ctl00$ContentPlaceHolder1$ddlDeptProgram" => "",
      # "ctl00$ContentPlaceHolder1$hidDeptProgram" => "",
      # "ctl00$ContentPlaceHolder1$txtTeachNo" => "",
      # "ctl00$ContentPlaceHolder1$txtTeachName" => "",
      # "ctl00$ContentPlaceHolder1$txtCourseNo" => "",
      # "ctl00$ContentPlaceHolder1$txtCourseName" => "",
      # "ctl00$ContentPlaceHolder1$txtClassNo" => "",
      # "ctl00$ContentPlaceHolder1$txtClassName" => "",
      # "ctl00$ContentPlaceHolder1$txtRoomNo" => "",
      # "ctl00$ContentPlaceHolder1$ddlCompare" => "",
      # "ctl00$ContentPlaceHolder1$txtCNT" => "",
      # "ctl00$ContentPlaceHolder1$hidSelectItem" => "",
      # "ctl00$ContentPlaceHolder1$hidEmptyFlag" => "false",
      # "ctl00$ContentPlaceHolder1$hidEmptyDataText" => "查無符合條件資料",
      "__ASYNCPOST" => "true",
      "ctl00$ContentPlaceHolder1$btnQuery" => "查詢",
    }), {"User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/47.0.2526.73 Chrome/47.0.2526.73 Safari/537.36"}).body
    doc = Nokogiri::HTML(r)


    row_groups = doc.css('table.GridView tr:not(:first-child)').map{|tr| tr[:group]}.uniq
    row_groups.each do |group|
      rows = doc.css(%Q{table.GridView tr[group="#{group}"]})
      datas = rows[0].xpath('td')

      locations = datas[10].text.strip

      # first rows period data
      course_days, course_periods, course_locations = parse_course_periods(datas[11], datas[12], locations)

      # other rows period data
      rows.length > 1 && rows[1..-1].each do |_row|
        tds = _row.xpath('td')
        _d, _p, _l = parse_course_periods(tds[0], tds[1], locations)
        course_days.concat(_d)
        course_periods.concat(_p)
        course_locations.concat(_l)
      end

      general_code = datas[4].css('span')[0][:title]

      course = {
        :year         => @year,
        :term         => @term,
        :name         => power_strip(datas[4].text),
        :lecturer     => power_strip(datas[5].xpath('span')[0].text),
        :credits      => datas[8].text.to_i,
        :required     => datas[9].text.include?('必'),
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
        :location_9   => course_locations[8],
      }

      @courses << course

    end # end each group of rows
    @courses
  end

  def parse_course_periods day, periods, locations
    day = day.text.strip.to_i
    return [], [], [] if day.zero?

    p_start, p_end = periods.text.strip.match(/(\d+?(~?\d+?)?)節?/)[1].split('~')
    p_end = p_start if p_end.nil?

    course_days, course_periods, course_locations = [], [], []
    (p_start.to_i..p_end.to_i).each do |p|
      course_days      << day
      course_periods   << p
      course_locations << locations
    end

    return course_days, course_periods, course_locations
  end

end
end
