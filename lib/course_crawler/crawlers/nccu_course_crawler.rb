# 國立政治大學
# 選課網址: http://wa.nccu.edu.tw/QryTor/

module CourseCrawler::Crawlers
class NccuCourseCrawler < CourseCrawler::Base
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

  # PERIODS = {
  #   "A" => 1,
  #   "B" => 2,
  #   "1" => 3,
  #   "2" => 4,
  #   "3" => 5,
  #   "4" => 6,
  #   "C" => 7,
  #   "D" => 8,
  #   "5" => 9,
  #   "6" => 10,
  #   "7" => 11,
  #   "8" => 12,
  #   "E" => 13,
  #   "F" => 14,
  #   "G" => 15,
  #   "H" => 16
  # }
  PERIODS = CoursePeriod.find('NCCU').code_map
  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil
    @query_url = "http://wa.nccu.edu.tw/QryTor/"

    @year = year || current_year
    @term = term || current_term
    @update_progress_proc = update_progress
    @after_each_proc = after_each
  end

  def courses
    @courses = []

    @threads = []

    visit @query_url
    puts "get url ..."
    inst_h = Hash[@doc.css('select[name="t_colLB"] option:not(:first-child)').map{|opt| [opt[:value], opt.text.split('　')[0]]}]

    post_hash = {
      "yyssDDL" => "#{@year-1911}#{@term}",
      "coursenameTB" => nil,
      "instructorTB" => nil,
    }

    inst_h.keys.each do |inst|
      visit @query_url
      puts "data crawled : " + inst

      r = RestClient.post(@query_url, post_hash.merge(get_view_state).merge({
        "__EVENTTARGET" => 't_colLB',
        "t_colLB" => inst
      }), cookies: @cookies) { |response, request, result, &block|
        if [301, 302, 307].include? response.code
          response.follow_redirection(request, result, &block)
        else
          response.return!(request, result, &block)
        end
      }
      @doc = Nokogiri::HTML(r.force_encoding(r.encoding))

      r = RestClient.post @query_url, post_hash.merge(get_view_state).merge({
        "__EVENTTARGET" => 'searchA',
        "t_colLB" => inst
      }), cookies: @cookies

      loop do
        doc = Nokogiri::HTML(r.force_encoding(r.encoding))
        rows = doc.css('.maintain_profile_content_table tr').select{|tr| !tr[:id].nil?}
        (0..rows.count-1).step(2).each do |i|
          datas = rows[i].css('td')

          general_code = datas[2] && datas[2].text.strip
          code = datas[2] && "#{@year}-#{@term}-#{general_code}"
          lecturer = datas[3] && datas[3].text.split('/')[0].strip
          credits = datas[4] && datas[4].text.to_i

          course_days = []
          course_periods = []
          course_locations = []
          locations = datas[6] && datas[6].text.strip.scan(/([^\d]+?([\d]+))/)
          periods_raws = datas[5] && datas[5].text.split('/')[0].strip
          periods_raws.scan(/([#{DAYS.keys.join}])([#{PERIODS.keys.join}]+)/).each_with_index do |m, i|
            m[1].split('').each do |p|
              course_days << DAYS[m[0]]
              course_periods << PERIODS[p]
              course_locations << (locations && !locations.empty? && locations[i] && !locations[i].empty? && locations[i][0]|| datas[6].text.strip)
            end
          end

          department = datas[14] && datas[14].text.strip
          required = datas[16] && datas[16].text.strip.include?('必')

          datas_2 = rows[i+1].css('td')
          name = datas_2[0] && datas_2[0].text.strip
          url = !datas_2.css('a').empty? && "#{@query_url}#{datas_2.css('a')[0][:href]}"

          course = {
            year: @year,
            term: @term,
            name: name,
            code: code,
            general_code: general_code,
            lecturer: lecturer,
            credits: credits,
            department: department,
            required: required,
            url: url,
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

          sleep(1) until (
            @threads.delete_if { |t| !t.status };  # remove dead (ended) threads
            @threads.count < (ENV['MAX_THREADS'] || 20)
          )
          @threads << Thread.new do
            @after_each_proc.call(course: course) if @after_each_proc
          end

          @courses << course
        end # each rows do

        # go through pages...
        if doc.css('#nextLB')[0][:href].nil?
          break
        else
          r = RestClient.post "#{@query_url}qryScheduleResult.aspx", post_hash.merge(get_view_state(doc: doc)).merge({
            "__EVENTTARGET" => 'nextLB',
            "t_colLB" => inst,
            "numberpageRBL" => 20,
            "numberpageRBL2" => 20,
            "language" => 'zh-TW',
          }), cookies: @cookies
        end
      end # loop do end
    end

    ThreadsWait.all_waits(*@threads)
    puts "Project finished !!!"
    @courses
  end

  def current_year
    (Time.zone.now.month.between?(1, 7) ? Time.zone.now.year - 1 : Time.zone.now.year)
  end

  def current_term
    (Time.zone.now.month.between?(2, 7) ? 2 : 1)
  end

  def get_view_state(doc: nil)
    if doc
      Hash[doc.css('input[type="hidden"]').map {|d| [d[:name], d[:value]]}]
    else
      Hash[@doc.css('input[type="hidden"]').map {|d| [d[:name], d[:value]]}]
    end
  end
end
end
