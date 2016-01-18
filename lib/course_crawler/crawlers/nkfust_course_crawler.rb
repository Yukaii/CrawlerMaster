##
# 高第一課程爬蟲
# http://teaching.nkfust.edu.tw/Course/query/opencrs.aspx
#

module CourseCrawler::Crawlers
class NkfustCourseCrawler < CourseCrawler::Base

  PERIODS = {
    "Ｘ" =>  1,
    "１" =>  2,
    "２" =>  3,
    "３" =>  4,
    "４" =>  5,
    "５" =>  6,
    "６" =>  7,
    "７" =>  8,
    "８" =>  9,
    "９" => 10,
    "Ａ" => 11,
    "Ｂ" => 12,
    "Ｃ" => 13,
    "Ｄ" => 14,
    "Ｅ" => 15
  }

  TERM = {
    1 => "上",
    2 => "下"
  }

  DAYS = {
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6,
    "日" => 7
  }

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil

    @year = year || current_year
    @term = term || current_term

    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = "http://teaching.nkfust.edu.tw/Course/query/opencrs.aspx"
    @ic = Iconv.new('utf-8//IGNORE//translit', 'big5')
  end

  def courses
    @courses = []

    doc = Nokogiri::HTML(http_client.get_content(@query_url))

    # select year
    view_state = parse_hidden_fields(doc)
    doc = Nokogiri::HTML(
      http_client.post(@query_url, {
        "__EVENTTARGET" => 'ctl00$ContentPlaceHolder_MainContent$DropDownList_Acy',
        "ctl00$ContentPlaceHolder_MainContent$DropDownList_Acy"      => @year-1911,
        "ctl00$ContentPlaceHolder_MainContent$DropDownList_Semester" => '請選擇 Select',
        "ctl00$ContentPlaceHolder_MainContent$DropDownList_Dep"      => '請選擇',
      }.merge(view_state)).body
    )

    # select semester
    view_state = parse_hidden_fields(doc)
    doc = Nokogiri::HTML(
      http_client.post(@query_url, {
        "__EVENTTARGET" => 'ctl00$ContentPlaceHolder_MainContent$DropDownList_Semester',
        "ctl00$ContentPlaceHolder_MainContent$DropDownList_Acy"      => @year-1911,
        "ctl00$ContentPlaceHolder_MainContent$DropDownList_Semester" => TERM[@term],
        "ctl00$ContentPlaceHolder_MainContent$DropDownList_Dep"      => '請選擇'
      }.merge(view_state)).body
    )

    # select department
    view_state = parse_hidden_fields(doc)
    doc = Nokogiri::HTML(
      http_client.post(@query_url, {
        "__EVENTTARGET" => 'ctl00$ContentPlaceHolder_MainContent$DropDownList_Dep',
        "ctl00$ContentPlaceHolder_MainContent$DropDownList_Acy"      => @year-1911,
        "ctl00$ContentPlaceHolder_MainContent$DropDownList_Semester" => TERM[@term],
        "ctl00$ContentPlaceHolder_MainContent$DropDownList_Dep"      => '%%'
      }.merge(view_state)).body
    )

    view_state = parse_hidden_fields(doc)
    doc = Nokogiri::HTML(
      http_client.post(@query_url, {
        "ctl00$ContentPlaceHolder_MainContent$DropDownList_Acy"      => @year-1911,
        "ctl00$ContentPlaceHolder_MainContent$DropDownList_Semester" => TERM[@term],
        "ctl00$ContentPlaceHolder_MainContent$DropDownList_Dep"      => '%%',
        "ctl00$ContentPlaceHolder_MainContent$Button_Query"          => '開始查詢 Search'
      }.merge(view_state)).body
    )

    # parse course
    doc.css('table#ContentPlaceHolder_MainContent_GridView_Course_Query tr:not(:first-child)').each do |row|
      datas = row.xpath('td')

      general_code = power_strip(datas[2].text)

      course_days, course_periods, course_locations = [], [], []
      datas[8].text.scan(/([#{DAYS.keys.join}])\(.+?\)([#{PERIODS.keys.join}])\[(.+?)\]/).each do |m|
        course_days      << DAYS[m[0]]
        course_periods   << PERIODS[m[1]]
        course_locations << m[2]
      end

      @courses << {
        :year         => @year,
        :term         => @term,
        :serial       => power_strip(datas[1].text),
        :general_code => general_code,
        :code         => "#{@year}-#{@term}-#{general_code}",
        :name         => power_strip(datas[3].text),
        :credits      => power_strip(datas[5].text).to_i,
        :required     => datas[6].text.include?('必修'),
        :lecturer     => power_strip(datas[7].text),
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

    @courses
  end

  def parse_hidden_fields doc
    Hash[ doc.css('input[type="hidden"]').map{|input| [ input[:name], input[:value] ] } ]
  end
end
end
