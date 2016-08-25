##
# 崑山科大
# http://120.114.50.49/TPS_Outline/Default.aspx
# 他只限魚爬取一開始default的學年度，其餘學念度無法查詢

module CourseCrawler::Crawlers
class KsuCourseCrawler < CourseCrawler::Base

  DAYS = {
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6,
    "日" => 7,
  }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year || current_year
    @term = term || current_term

    @update_progress_proc = update_progress
    @after_each_proc = after_each
    @count = 1 #新增看資訊用
    @query_url = "http://120.114.50.49/TPS_Outline/Default.aspx"
  end

  def courses
    @courses = []

    puts "get url ..."
    doc = Nokogiri::HTML(http_client.get_content(@query_url))
    initial_loop = true

    sections = get_opt_hash_from_doc(doc, "ctl00$MainContent$DropDownList4")
    sections.each_with_index do |(sec, sec_val), sec_index|

      if sec_index != 0
        doc = Nokogiri::HTML(submit(sec_val, nil, nil, parse_view_state(doc), "ctl00$MainContent$DropDownList4"))
      end
      depts = get_opt_hash_from_doc(doc, "ctl00$MainContent$DropDownList3")

      depts.each_with_index do |(dept, dept_val), dept_index|

        if dept_index != 0
          doc = Nokogiri::HTML(submit(sec_val, dept_val, nil, parse_view_state(doc), "ctl00$MainContent$DropDownList3"))
        end
        clas = get_opt_hash_from_doc(doc, "ctl00$MainContent$DropDownList5")

        clas.each_with_index do |(cla, cla_val), clas_index|
          if initial_loop
            doc = Nokogiri::HTML(submit(sec_val, dept_val, cla_val, parse_view_state(doc), "ctl00$MainContent$DropDownList2"))
            initial_loop = false
          end

          if clas_index != 0
            doc = Nokogiri::HTML(submit(sec_val, dept_val, cla_val, parse_view_state(doc), "ctl00$MainContent$DropDownList5"))
          end

          parse_course(doc)
        end # end each clas
      end # end each dept
    end # end each section
    puts "Project finished !!!"
    @courses
  end

  def parse_course doc
    puts "data crawled : " + @count.to_s
    @count += 1
    doc.css('#MainContent_GridView1 tr:not(:first-child)').each do |row|
      datas  = row.xpath('td')

      url    = !datas[5].css('a').empty? && datas[5].css('a')[0][:href]
      url    = "http://120.114.50.49/TPS_Outline/#{url}"

      params = CGI.parse(URI.parse(url).query)
      serial = params["id"].first

      year   = datas[0].text.to_i + 1911
      term   = datas[1].text.to_i

      @year  = datas[0].text.to_i + 1911
      @term  = datas[1].text.to_i

      next if serial.nil?

      detail_doc   = Nokogiri::HTML(http_client.get_content(url))

      general_code = detail_doc.css('#MainContent_Label2').text
      location     = detail_doc.css('#MainContent_TextBox5').text
      credits      = detail_doc.css('#MainContent_OH0').text.to_i
      required     = detail_doc.css('#MainContent_OH4').text.include?('必修')

      # ex: 週二(5),週四(3、4)
      course_days, course_periods, course_locations = [], [], []
      raw_day_period = detail_doc.css('#MainContent_CourseTime').text
      raw_day_period.split(',').each do |day_period|
        day_period.match(/週(?<d>[#{DAYS.keys.join}])\((?<p>.+)\)/) do |m|
          m[:p].split('、').each do |p|
            course_days << DAYS[m[:d]]
            course_periods << p.to_i
            course_locations << location
          end
        end
      end

      @courses << {
        :year         => year,
        :term         => term,
        :general_code => general_code,
        :code         => "#{year}-#{term}-#{general_code}",
        :name         => datas[2].text,
        :serial       => serial,
        :lecturer     => datas[4].text,
        :url          => url,
        :credits      => credits,
        :required     => required,
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

  def submit sec=nil, dep=nil, cla=nil, viewstate=nil, event_target=nil

    sec ||= @prev_sec
    dep ||= @prev_dep
    cla ||= @prev_cla

    body = http_client.post(@query_url, {
      "__EVENTTARGET" => event_target,
      "ctl00$MainContent$DropDownList1" => @year-1911,
      "ctl00$MainContent$DropDownList2" => @term,
      "ctl00$MainContent$DropDownList4" => sec,
      "ctl00$MainContent$DropDownList3" => dep,
      "ctl00$MainContent$DropDownList5" => cla
    }.merge(viewstate)).body

    # remember last choice
    @prev_sec, @prev_dep, @prev_cla = sec, dep, cla

    return body;
  end

  def get_opt_hash_from_doc doc, select_name
    Hash[doc.css("select[name=\"#{select_name}\"] option").map{|opt| [ opt.text, opt[:value] ] }]
  end

  def parse_view_state doc
    Hash[doc.css('input[type="hidden"]').map{|input| [input[:name], input[:value]] }]
  end

  # for debugging
  def save_temp doc
    File.write(Rails.root.join('tmp', 'ksu.html'), doc.to_s)
  end

end
end
