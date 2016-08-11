##
# 輔仁課程爬蟲
# http://estu.fju.edu.tw/fjucourse/firstpage.aspx
# http://estu.fju.edu.tw/fjucourse/Secondpage.aspx

module CourseCrawler::Crawlers
class FjuCourseCrawler < CourseCrawler::Base
  include CrawlerRocks::DSL

  DAYS = {
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6,
    "日" => 7,
  }

  PERIODS = {
    "D0" =>  1,
    "D1" =>  2,
    "D2" =>  3,
    "D3" =>  4,
    "D4" =>  5,
    "DN" =>  6,
    "D5" =>  7,
    "D6" =>  8,
    "D7" =>  9,
    "D8" => 10,
    "E0" => 11,
    "E1" => 12,
    "E2" => 13,
    "E3" => 14,
    "E4" => 15,
  }

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil

    @year = year || current_year
    @term = term || current_term

    @update_progress_proc = update_progress
    @after_each_proc = after_each

    if @term == 1
      @query_url = "http://estu.fju.edu.tw/fjucourse/firstpage.aspx"
    else
      @query_url = "http://estu.fju.edu.tw/fjucourse/Secondpage.aspx"
    end

    @ic = Iconv.new("utf-8//translit//IGNORE", "utf-8")
  end

  def courses
    @courses = []
    @threads = []

    # step 1
    r = RestClient.get @query_url
    @doc = Nokogiri::HTML(@ic.iconv r)
    puts "step 1 , get url"

    # step 2
    r = RestClient.post @query_url, get_view_state.merge({
      "But_BaseData" => "依基本開課資料查詢"
    })
    @doc = Nokogiri::HTML(@ic.iconv r)
    puts "step 2 , search"

    # step 3 選擇學制
    r = RestClient.post @query_url, get_view_state.merge({
      "__EVENTTARGET" => "DDL_AvaDiv",
      "DDL_AvaDiv" => 'D',
      "DDL_Section_S" => nil,
      "DDL_Section_E" => nil,
    })
    @doc = Nokogiri::HTML(@ic.iconv r)
    puts "step 3 , get DDL_AvaDiv"

    # step 查詢
    r = RestClient.post @query_url, get_view_state.merge({
      "DDL_AvaDiv" => 'D',
      "DDL_Avadpt" => 'All-全部',
      "DDL_Class" => nil,
      "DDL_Section_S" => nil,
      "DDL_Section_E" => nil,
      "But_Run" => '查詢（Search）',
    })
    doc = Nokogiri::HTML(@ic.iconv r)
    puts "step 4 , final fetch"

    parse_course_list(doc)

    @courses.each do |course|
      puts "data saved ...."

      sleep(1) until (
        @threads.delete_if { |t| !t.status };  # remove dead (ended) threads
        @threads.count < ( (ENV['MAX_THREADS'] && ENV['MAX_THREADS'].to_i) || 30)
      )
      @threads << Thread.new {
        @after_each_proc.call(course: course) if @after_each_proc
      }
    end

    ThreadsWait.all_waits(*@threads)
    @courses
    puts "Project finished !!!"
  end

  def parse_course_list doc
    @courses ||= []
    count = 1;
    rows = doc.xpath('//table[@id="GV_CourseList"]/tr[position()>1]')
    rows && rows.each_with_index do |row, index|
      datas = row.css('td')

      puts "data crawled : " + count.to_s
      STDOUT.flush
      count += 1
      # a sub course, has main course code
      next if not (datas[2] && datas[2].text.gsub(/[^a-zA-Z0-9]/,'').empty?)

      course_days = []
      course_periods = []
      course_locations = []
      (13..19).step(3) do |i|
        day = nil
        day_text = (datas[i] && datas[i].text)
        day_text.match(/([#{DAYS.keys.join}])/) do |m|
          day = m[0]
        end

        datas[i+1] && datas[i+1].text.match(/(?<s>.{2})\-(?<e>.{2})/) do |m|
          (PERIODS[m[:s]]..PERIODS[m[:e]]).each do |period|
            course_days << (day && DAYS[day])
            course_periods << period
            course_locations << (datas[i+2] && datas[i+2].text)
          end
        end
      end

      name = row.css("td #GV_CourseList_Lab_Coucna_#{index}")[0] && row.css("td #GV_CourseList_Lab_Coucna_#{index}")[0].text.strip
      # periods.concat parse_period(datas[12] && datas[12].text, datas[13] && datas[13].text, datas[14] && datas[14].text)
      # periods.concat parse_period(datas[15] && datas[15].text, datas[16] && datas[16].text, datas[17] && datas[17].text)
      # periods.concat parse_period(datas[18] && datas[18].text, datas[19] && datas[19].text, datas[20] && datas[20].text)
      # periods.each_with_index {|d,i| periods.delete_at(i) if d.nil? }
      general_code = datas[1] && datas[1].text.strip
      code = "#{@year}-#{@term}-#{general_code}"

      @courses << {
        # serial_no: datas[0].text.to_i,
        year: @year,
        term: @term,
        code: code,
        general_code: general_code,
        department: datas[3].text,
        department_code: datas[1].text.strip[0..2],
        name: name,
        # eng_name: row.css("td #GV_CourseList_Lab_Couena_#{index}")[0].text,
        credits: datas[6] && datas[6].text.to_i,
        required: datas[7] && datas[7].text == '必',
        # full_semester: datas[8].text == '學年',
        lecturer: datas[9] && datas[9].css("#GV_CourseList_Lab_Tchcna_#{index}").text,
        # language: datas[10].text,
        day_1: course_days[0],
        day_2: course_days[1],
        day_3: course_days[2],
        day_4: course_days[3],
        day_5: course_days[4],
        day_6: course_days[5],
        day_7: course_days[6],
        day_8: course_days[7],
        day_9: course_days[8],
        period_1: course_periods[0],
        period_2: course_periods[1],
        period_3: course_periods[2],
        period_4: course_periods[3],
        period_5: course_periods[4],
        period_6: course_periods[5],
        period_7: course_periods[6],
        period_8: course_periods[7],
        period_9: course_periods[8],
        location_1: course_locations[0],
        location_2: course_locations[1],
        location_3: course_locations[2],
        location_4: course_locations[3],
        location_5: course_locations[4],
        location_6: course_locations[5],
        location_7: course_locations[6],
        location_8: course_locations[7],
        location_9: course_locations[8],
      }
    end
  end
end
end
