##
# 建國科大
# http://db.ctu.edu.tw/db_subject/index.aspx
#

module CourseCrawler::Crawlers
class CtuCourseCrawler < CourseCrawler::Base
  GRADE = [ '00', '01', '02', '03', '04' ]

  CLASS = [ '1', '2', '3', '4', '5', '6' ]

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil
    @year = year
    @term = term
    @count = 1
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = "http://db.ctu.edu.tw/db_subject/index.aspx"
  end

  def courses
    @courses = []
    puts "get url ..."
    doc = Nokogiri::HTML(http_client.get_content(@query_url))
    view_state = Hash[ doc.css(%Q{input[type="hidden"]}).map{|input| [ input[:name], input[:value] ] } ]

    _terms = doc.css('select[name="ddl_Term"] option').map{ |opt| opt[:value] }.reject{|v| power_strip(v).empty?}
    _years = doc.css('select[name="ddl_Year"] option').map{ |opt| opt[:value] }.reject{|v| power_strip(v).empty?}
    _class = doc.css('select[name="ddl_class"] option').map{ |opt| opt[:value] }.reject{|v| power_strip(v).empty?}
    _coms  = doc.css('select[name="ddl_com"] option').map{ |opt| opt[:value] }.reject{|v| power_strip(v).empty?}
    _deps  = doc.css('select[name="Ddl"] option').map{|opt| opt[:value] }.reject{|v| power_strip(v).empty?}

    # 太狂啦
    _terms.each{ |term| _years.each{ |year| _class.each{|clas| _coms.each{ |com| _deps.each{ |dept|
      r = http_client.post(@query_url, {
        :ddlYear => (@year-1911).to_s[-2..-1],
        :ddlTerm => @term,
        :ddl_Term => term, # 部別
        :ddl_Year =>  year, # 年級
        :ddl_class => clas, # 班級
        :ddl_com => com, # 制別
        :Ddl => dept,
        :A => 'rb1',
        :Button1 => '開始查詢'
      }.merge(view_state), :follow_redirect => true)

      url = "http://db.ctu.edu.tw" + URI.decode(Nokogiri::HTML(r.body).css('a')[0][:href]).to_s
      parse_course(Nokogiri::HTML(http_client.get_content(url)))

    }}}}}
    puts "Project finished !!!"
    @courses
  end

  def parse_course doc
    index = doc.css('table').css('tr')
    index[3..-2].each do |row|
      datas = row.css('td')

      course_days = []
      course_periods = []
      course_locations = []

      day_course = datas[7].text.split(/(..)/)
      day_course.each do |course|
      #  binding.pry
        next if course.size == 0

        course_days      << course[0]
        course_periods   << course[1]
        course_locations << datas[8].text.strip
      end
      puts "data crawled : " + datas[2].css('a')[0].text.strip
      course = {
        :name         => datas[2].css('a')[0].text.strip,
        :year         => @year,
        :term         => @term,
        :code         => "#{@year}-#{@term}-#{datas[0].text.strip}-#{@count}",
        :general_code => datas[0].text.strip+"-#{@count}",
        :degree       => datas[1].text.strip,
        :credits      => datas[3].text.strip,
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
        :location_9   => course_locations[8],
      }
      @count += 1
      @after_each_proc.call(course: course) if @after_each_proc
      @courses << course

    end
  end

end
end
