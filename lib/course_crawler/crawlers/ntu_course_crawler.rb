# 國立臺灣大學
# 課程查詢網址：https://nol.ntu.edu.tw/nol/coursesearch/search_result.php

module CourseCrawler::Crawlers
  class NtuCourseCrawler < CourseCrawler::Base

    include DSL

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
      "0"  => 1,
      "1"  => 2,
      "2"  => 3,
      "3"  => 4,
      "4"  => 5,
      "5"  => 6,
      "6"  => 7,
      "7"  => 8,
      "8"  => 9,
      "9"  => 10,
      "10" => 11,
      "A"  => 12,
      "B"  => 13,
      "C"  => 14,
      "D"  => 15
    }

    def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil

      @search_url = "https://nol.ntu.edu.tw/nol/coursesearch/search_result.php"
      @base_url = "https://nol.ntu.edu.tw/nol/coursesearch/"

      @year = year || current_year
      @term = term || current_term
      @update_progress_proc = update_progress
      @after_each_proc = after_each

      @encoding = 'big5'
    end

    def courses details: false, max_detail_count: 20_000
      @courses = []
      @threads = []
      @failures = []

      # 重設進度
      @update_progress_proc.call(progress: 0.0) if @update_progress_proc

      visit @search_url

      puts "post search_url: #{@year-1911} - #{@term}"
      visit "#{@search_url}?cstype=1&current_sem=#{@year-1911}-#{@term}"

      # pool = Thread.pool(ENV['MAX_THREADS'] && ENV['MAX_THREADS'].to_i || 25)

      pages_param = @doc.xpath('//select[@name="jump"]//@value').map(&:value).uniq
      @courses_processed_count = 0
      @courses_count = @doc.css('table[cellpadding="4"] tbody tr td font[color="#CC0033"]').text.to_i
      # @total_page_count = pages_param.count

      puts "total pages: #{pages_param.count}"
      done_page_count = 0
      pages_param.each do |query|
        # pool.process(query) do
        sleep(1) until (
          @threads.delete_if { |t| !t.status };  # remove dead (ended) threads
          @threads.count < (ENV['MAX_THREADS'] || 25)
        )

        @threads << Thread.new do
          # puts "get page url"
          retry_count = 0; success = false
          begin
            r = RestClient.get "#{@search_url}#{query}"
          rescue Exception => e
            @failures << "#{@search_url}#{query}"
            next
          end


          # puts "parse page"
          doc = Nokogiri::HTML(r.force_encoding(@encoding))
          # row_count = doc.xpath('/html/body/table[4]//tr[position()>1]').count
          # puts "row_count: #{row_count}"
          # @total_row_count += row_count

          doc.xpath('/html/body/table[4]//tr[position()>1]').each do |row|
            datas = row.css('td')

            course_days = []
            course_periods = []
            course_locations = []

            # results =  [["一", "12", "請洽系所辦"], ["四", "12", "請洽系所辦"]]
            results = datas[11] && datas[11].text.scan(/(?<d>[#{DAYS.keys.join}])(?<p>([#{PERIODS.keys.join}],?)+)(\((?<loc>[^\)]+)\))/)
            results.each do |re|
              re[1].split(",").each do |p|
                course_days << DAYS[re[0]]
                course_periods << PERIODS[p]
                course_locations << re[2]
              end
            end

            name = datas[4] && power_strip(datas[4].text)
            lecturer = datas[9] && power_strip(datas[9].text)
            department = datas[1] && power_strip(datas[1].text)
            url = nil || datas[4] && !datas[4].css('a').empty? && URI.encode("#{@base_url}#{datas[4].css('a')[0][:href]}")
            id = datas[6] && power_strip(datas[6].text).gsub(/\s/, '')
            class_code= datas[3] && power_strip(datas[3].text)
            department_code = url ? Hash[URI.decode_www_form(URI.encode url)]["dpt_code"] : nil
            number = datas[2] && power_strip(datas[2].text)

            code = [@year, @term, id, number, department_code, class_code].join('-')

            course = {
              year: @year,
              term: @term,
              serial: datas[0] && power_strip(datas[0].text),
              department: department,
              department_code: department_code,
              number: number,
              code: code,
              class_code: class_code,
              name: name,
              credits: datas[5] && datas[5].text.to_i,
              general_code: id,
              required: datas[8] && datas[8].text.include?('必'),
              lecturer: lecturer,
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
              url: url
            }

            @courses << course

            # callbacks
            @after_each_proc.call(course: course) if @after_each_proc
            # update the progress
            @update_progress_proc.call( progress: @courses_processed_count.to_f / @courses_count.to_f) if @update_progress_proc

            @courses_processed_count += 1
            # puts "done:  #{@courses_processed_count}"
            # puts "total_row_count: #{@total_row_count}"
          end # each tr row

          # @processed_page_count += 1
          done_page_count += 1
          # print "#{done_page_count}\n"
          set_progress "#{done_page_count} / #{pages_param.count}"
          print "#{done_page_count} / #{pages_param.count}\n"
          # puts "processed_page_count: #{@processed_page_count} / #{@total_page_count}"

        end # Thread.new do
      end # pages_param.each

      # pool.shutdown
      ThreadsWait.all_waits(*@threads)

      puts "done #{@courses.count} courses!"
      @courses
    end # def course

    def power_strip str
      str.strip.gsub(/^[ |\s]*|[ |\s]*$/,'')
    end

  end
end
