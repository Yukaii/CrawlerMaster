# 臺灣科技大學
# http://140.118.31.215/querycourse/ChCourseQuery/QueryCondition.aspx

module CourseCrawler::Crawlers
  class NtustCourseCrawler < CourseCrawler::Base
    attr_reader :semester_list, :courses_list, :query_url, :result_url

    DAYS = {
      "M" => 1,
      "F" => 5,
      "T" => 2,
      "S" => 6,
      "W" => 3,
      "U" => 7,
      "R" => 4,
      "一" => 1,
      "二" => 2,
      "三" => 3,
      "四" => 4,
      "五" => 5,
      "六" => 6,
      "日" => 7
    }

    PERIODS = CoursePeriod.find('NTUST').code_map

    DEPS = {
      "AD" => "建築系",
      "CD" => "創意設計學士班",
      "DE" => "設計研究所",
      "DT" => "工商業設計系",
      "DX" => "創意設計學士學位學程",
      "AT" => "應用科技學士學位學程",
      "BB" => "醫學工程學士學位學程",
      "BE" => "醫學工程研究所",
      "CI" => "色彩與照明科技研究所",
      "CX" => "色彩影像與照明科技學士學位學程",
      "EN" => "應用科技研究所",
      "HC" => "不分系學士班",
      "MS" => "應用科技研究所材料科技學程",
      "CS" => "資訊工程系",
      "EC" => "電資學士班",
      "EE" => "電機工程系",
      "EO" => "光電工程研究所",
      "ET" => "電子工程系",
      "CC" => "人文社會學科",
      "EP" => "師資培育中心",
      "FL" => "應用外語系",
      "GE" => "通識學科",
      "PE" => "體育室",
      "VE" => "數位學習與教育研究所",
      "IB" => "智慧財產權學士學位學程",
      "PA" => "專利研究所",
      "TB" => "科技管理學士學位學程",
      "TM" => "科技管理研究所",
      "BA" => "企業管理系",
      "FB" => "財務金融學士學位學程",
      "FN" => "財務金融研究所",
      "IM" => "工業管理系",
      "MA" => "MBA",
      "MB" => "管理學士班",
      "MG" => "管理研究所",
      "MI" => "資訊管理系",
      "AC" => "自動化及控制研究所",
      "CE" => "工程學士班",
      "CH" => "化學工程系",
      "CT" => "營建工程系",
      "GX" => "綠能產業機電工程學士學位學程",
      "ME" => "機械工程系",
      # "MS" => "材料科技研究所",
      "RD" => "高階科技研發碩士學位學程",
      "RS" => "跨系所學程",
      "TV" => "工程技術研究所技職專業發展學程",
      "TX" => "材料科學與工程系",
    }

    # Initializes a new crawler instance.
    #
    # A crawler instance is a represent of a data set that is desired to be
    # crawled, so a few parameters can be provided during creation to scope
    # the crawled data:
    #
    # +year+::
    #   +Integer+ (學年度) school year of the Gregorian calendar (YYYY), defaults to
    #   the current school year.
    #
    # +term+::
    #   +Integer+ (學期) school term, 1 or 2, defaults to the current school term
    #
    # +progress_proc+::
    #   +Proc+ a proc that can be called with an +float+ representing the current
    #   progress while progressing
    def initialize(year: current_year, term: current_term, update_progress: nil, after_each: nil)
      @host_url = "http://140.118.31.215"
      @query_url = "http://140.118.31.215/querycourse/ChCourseQuery/QueryCondition.aspx"
      @result_url = "http://140.118.31.215/querycourse/ChCourseQuery/QueryResult.aspx"

      @year = year || current_year
      @term = term || current_term

      @update_progress_proc = update_progress
      @after_each_proc = after_each
    end

    # Getter of the courses data that the crawler is in charge to crawl, returns
    # an +Array+ of +Hash+
    #
    # Params:
    #
    # +details+::
    #   +Boolean+ whether to dig in each courses' web page and get complete
    #   detials or not
    #
    # +max_detail_count+::
    #   +Integer+ the maxium course detials to retrieve
    def courses(details: false, max_detail_count: 20_000)
      # 初始 courses 陣列
      @courses = []
      @failures = []
      # 我超神，我用多執行緒 http://i.imgur.com/aZqsVBQ.png
      @threads = []

      # 重設進度
      @update_progress_proc.call(progress: 0.0) if @update_progress_proc

      retry_count = 3
      http_client.receive_timeout = 600

      set_progress("Crawler Initialized")

      while retry_count > 0
        begin

          r = http_client.get_content @query_url
          query_page = Nokogiri::HTML(r)

          view_states = Hash[query_page.css('input[type="hidden"]').map{|input| [ input[:name], input[:value] ]}]
          @semester_list = query_page.css('#semester_list option').map { |option| option['value'] }
          # 把表單驗證，還有要送出的資料弄成一包 hash
          # 看是第幾學年度
          semester = "#{@year - 1911}#{@term}"
          post_data = view_states.merge({
            :Acb0101 => 'on',
            :BCH0101 => 'on',
            :semester_list => @semester_list.find { |s| s.match /^#{semester}/ },
            :QuerySend => '送出查詢'
          })

          r = http_client.post(@query_url, post_data)
          @result_url = URI.join(@host_url, r.header["Location"][0])
          # 然後再到結果頁看結果，記得送 cookie，因為有 session id
          set_progress "Loading courses list..."

          r = http_client.get_content @result_url
        rescue Exception => e
          puts e
          if retry_count > 0
            retry_count -= 1
            retry
          else
            raise e
          end
        end
        break
      end

      set_progress "Got courses list, parsing..."

      @courses_list = Nokogiri::HTML(r)
      @courses_list_trs = @courses_list.css('table#my_dg tr:not(:first-child)')
      @courses_list_trs_count = @courses_list_trs.count

      @courses_details_processed_count = 0

      set_progress "Starting to progress course..."

      # 跳過第一列，因為是 table header，何不用 th = =?
      @courses_list_trs.each_with_index do |row, index|
        # puts "Preparing course #{index + 1}/#{@courses_list_trs_count}..."

        # 每一欄
        table_data = row.css('td')

        # 分配欄位，多麼機械化！
        course_general_code = table_data[0].text.strip
        course_code = "#{semester}-#{course_general_code}"
        course_name = table_data[2].text.strip

        # 跳過 '空白列'，覺得 buggy
        next if table_data[3].css('a').empty?

        course_url = table_data[3].css('a').first['href']
        course_credits = table_data[4].text.to_i
        course_required = table_data[5].text == '必'
        course_full_semester = table_data[6].text == '全'
        course_lecturer = table_data[7].text.strip

        # course_time_periods = table_data[8].text.split('、').map(&:strip)
        # course_locations = table_data[9].text.split('、').map(&:strip)
        course_students_enrolled = table_data[13].text.to_i
        course_notes = table_data[14].text


        # if details && index < max_detail_count
        #   # 準備開啟新的 thread 來取得細節資料
        #   # 在這之前先確保 thread 數量在限制之內，若超過的話就等待
        sleep(1) until (
          @threads.delete_if { |t| !t.status };  # remove dead (ended) threads
          @threads.count < (ENV['MAX_THREADS'] || 20)
        )

        @threads << Thread.new do
          retries ||= 0

          # puts "Starting to get deatils (#{@courses_details_processed_count}/#{@courses_list_trs_count}): #{course_name}(#{course_code})"
          set_progress "details: #{@courses_details_processed_count}/#{@courses_list_trs_count}"
          # 好，讓我們爬更深一層
          r = RestClient.get(URI.encode(course_url))

          # 做一個編碼轉換的動作，防止 Nokogiri 解析失敗的動作
          ic = Iconv.new("utf-8//translit//IGNORE", "utf-8")
          detail_page = Nokogiri::HTML(ic.iconv(r.to_s))

          # 總共上下兩張大 table
          table_head = detail_page.css('.tblMain').first
          # table_detail = detail_page.css('.tblMain').last

          # 解析時間教室字串！一般來說長這樣：M6(IB-509) M7(IB-509)
          time_period_regex = /(?<period>[MFTSWUR][\dA-Z]+)(\((?<loc>.*?)\))?/
          course_time_location = Hash[ table_head.css('#lbl_timenode').text.scan(time_period_regex) ]

          # 把 course_time_location 轉成資料庫可以儲存的格式
          course_days = []
          course_periods = []
          course_locations = []
          course_time_location.each do |k, v|
            course_locations << v
            course_days << DAYS[k[0]]
            period = PERIODS[k[1..-1]]
            # period += 1 if @year > 2014  # 台科自 104 學年度起增加第 0 節，為讓節次從 1 開始排列故全部 +1
            course_periods << period
          end

          # # 學年 / 課程宗旨 / 課程大綱 / 教科書 / 參考書目 / 修課學生須知 / 評量方式 / 備註說明
          # course_semester = detail_page.css('#lbl_semester').text
          # course_objective = detail_page.css('#tbx_object').text
          # course_outline = detail_page.css('#tbx_content').text
          # course_textbook = detail_page.css('#tbx_textbook').text
          # course_references = detail_page.css('#tbx_refbook').text
          # course_notice = detail_page.css('#tbx_note').text
          # course_grading = detail_page.css('#tbx_grading').text
          # course_note = detail_page.css('#tbx_remark').text

          # # 英語課程名稱 / 先修課程 / 課程相關網址
          # course_name_en = detail_page.css('#lbl_engname').text
          # course_prerequisites = detail_page.css('#lbl_precourse').text
          # course_website = detail_page.css('#hlk_coursehttp').text
          # if retries > 10
          #   @failures << course_code
          #   self.terminate!
          # else
          #   retries += 1
          #   puts "Error occurred while processing details of #{course_name}(#{course_code})! retry later (#{retries}/10)..."
          #   puts "Error message: #{e}"
          #   sleep((5..20).to_a.sample)
          #   redo
          # end

          next if course_general_code.include? '校隊'

          # hash 化 course
          course = {
            :name => course_name,
            :code => course_code,
            :general_code => course_general_code,
            :department => DEPS[course_general_code[0..1]],
            :department_code => course_general_code[0..1],
            :organization_code => 'NTUST',
            :year => @year,
            :term => @term,
            :lecturer => course_lecturer,
            :credits => course_credits,
            :required => course_required,
            :full_semester => course_full_semester,
            :students_enrolled => course_students_enrolled,
            :url => URI.encode(course_url),
            :day_1 => course_days[0],
            :day_2 => course_days[1],
            :day_3 => course_days[2],
            :day_4 => course_days[3],
            :day_5 => course_days[4],
            :day_6 => course_days[5],
            :day_7 => course_days[6],
            :day_8 => course_days[7],
            :day_9 => course_days[8],
            :period_1 => course_periods[0],
            :period_2 => course_periods[1],
            :period_3 => course_periods[2],
            :period_4 => course_periods[3],
            :period_5 => course_periods[4],
            :period_6 => course_periods[5],
            :period_7 => course_periods[6],
            :period_8 => course_periods[7],
            :period_9 => course_periods[8],
            :location_1 => course_locations[0],
            :location_2 => course_locations[1],
            :location_3 => course_locations[2],
            :location_4 => course_locations[3],
            :location_5 => course_locations[4],
            :location_6 => course_locations[5],
            :location_7 => course_locations[6],
            :location_8 => course_locations[7],
            :location_9 => course_locations[8],
          }

          @courses << course
        end # end Thread

        # # callbacks
        # @after_each_proc.call(course: course) if @after_each_proc
        # # update the progress
        # @update_progress_proc.call(progress: @courses_details_processed_count.to_f / @courses_list_trs_count.to_f) if @update_progress_proc
      end

      # merge 所有的 threads
      ThreadsWait.all_waits(*@threads)
      puts "Done"

      raise "Failure in #{@failures.join(', ')}" if @failures.count > 0

      # 回傳課程陣列
      @courses
    end

    def http_client
      @clnt ||= HTTPClient.new
    end
  end

end
