##
# 明志科大
# http://stda.mcut.edu.tw/web1/std_datasearch/stda_course_search.aspx

module CourseCrawler::Crawlers
class McutCourseCrawler < CourseCrawler::Base
  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year || current_year
    @term = term || current_term

    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = "http://stda.mcut.edu.tw/web1/std_datasearch/stda_course_search.aspx"
  end

  def courses
    @courses = {}
    puts "get url ..."
    doc = Nokogiri::HTML(http_client.get_content @query_url)
    view_state = Hash[doc.css('input[type="hidden"]').map{|input| [input[:name], input[:value]] }]

    doc = Nokogiri::HTML(http_client.post(@query_url, {
      "DropDownList_yr" => @year-1911,
      "DropDownList_tr" => @term,
      "DropDownList_dep" => 'day',
      "Button3" => '查詢課程'
    }.merge(view_state)).body)

    doc.css('#GridView1 tr:not(:first-child)').each do |row|
      datas = row.xpath('td')
      puts "data crawled : " + datas[3].text.to_s
      general_code = datas[2].text

      @courses[general_code] ||= {}
      @courses[general_code][:name]     = datas[3].text
      @courses[general_code][:url]      = !datas[3].css('a').empty? && datas[3].css('a')[0][:href]
      @courses[general_code][:lecturer] = datas[8].text
      @courses[general_code][:credits]  = datas[9].text.to_i

      @courses[general_code][:course_days]      ||= []
      @courses[general_code][:course_periods]   ||= []
      @courses[general_code][:course_locations] ||= []

      # ex: 第1.0節~第1.0節
      beg, endd = datas[1].text.split('~').map{|s| s.match(/第(.+)節/)[1].to_i }
      (beg..endd).each do |p|
        @courses[general_code][:course_days]      << datas[0].text.to_i
        @courses[general_code][:course_periods]   << p
        @courses[general_code][:course_locations] << datas[11].text
      end

    end

    @courses.map do |general_code, course|
      course_days, course_periods, course_locations = course[:course_days], course[:course_periods], course[:course_locations]
      {
        :year         => @year,
        :term         => @term,
        :name         => course[:name],
        :url          => course[:url],
        :lecturer     => course[:lecturer],
        :credits      => course[:credits],
        :code         => "#{@year}-#{@term}-#{general_code}",
        :general_code => general_code,
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
    end # end @courses map
  end # end course
end
end
