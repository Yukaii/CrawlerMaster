# 華夏科技大學
# 課程查詢網址：http://campus.hwh.edu.tw/Public/SchoolTable.aspx

# 無法選擇學年度與學期
module CourseCrawler::Crawlers
class HwhCourseCrawler < CourseCrawler::Base

  PERIODS = Hash[CoursePeriod.find('HWH').periods.select { |p| 1 <= p.order && p.order <= 15 }.map { |p| [p.code, p.order] }]
  PERIODS_WEEKEND = Hash[CoursePeriod.find('HWH').periods.select { |p| 16 <= p.order && p.order <= 33 }.map { |p| [p.code, p.order] }]

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://campus.hwh.edu.tw/Public/SchoolTable.aspx'
  end

  def courses
    @courses = []
    course_id = 0

    r = RestClient.get(@query_url)
    doc = Nokogiri::HTML(r)
    puts "get url ..."

    hidden = Hash[doc.css('input[type="hidden"]').map { |input| [input[:name], input[:value]] }]

    doc.css('select[id="classList"] option:nth-child(n+2)')
       .map { |opt| [opt[:value], opt.text] }
       .each do |dept_v, dept_n|

      r = RestClient.post(@query_url, hidden.merge({
        "ScriptManager" => "ScriptManager|queryButton",
        "__EVENTTARGET" => "queryButton",
        "classList" => dept_v,
        "cur_noTxt" => "",
        "cur_nameTxt" => "",
        "teacherTxt" => "",
        }) )
      doc = Nokogiri::HTML(r)

      count = 1
      doc.css('table[id="GridView"] tr[align="center"]:nth-child(n+2)').each do |tr|
        data = tr.css('td').map{ |td| td.text.gsub(/[\r\n\s]/, "") }
        next if data[2] == " "
        syllabus_url = "http://campus.hwh.edu.tw/Public/_courseComment.aspx?yrterm=#{@year-1911}#{@term}&cur_no=#{data[2]}"
        puts "Department :" + dept_n +" , data crawled : " + count.to_s
        count += 1
        course_id += 1

        course_time = data[10..16]

        course_days = []
        course_periods = []
        course_locations = []
        (1..course_time.length).each do |day|
          course_time[day-1].scan(/\w/).each do |p|
            course_days << day
            course_periods << if dept_n.include?('進') || dept_n.include?('夜') || dept_n.include?('職專') ||
                                 dept_n.include?('企管80學分專班')
                                PERIODS_WEEKEND[p]
                              else
                                PERIODS[p]
                              end
            course_locations << data[9]
          end
        end

        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[3],    # 課程名稱
          lecturer: data[4],    # 授課教師
          credits: data[6].to_i,    # 學分數
          code: "#{@year}-#{@term}-#{course_id}_#{data[2]}",
          general_code: data[2],    # 選課代碼
          url: syllabus_url,    # 課程大綱之類的連結
          required: data[5].include?('必'),    # 必修或選修
          department: data[1],    # 開課系所
          # department_code: dept_v,
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

        @after_each_proc.call(course: course) if @after_each_proc

        @courses << course
      end
    end
    puts "project finished !!!"
    @courses
  end

end
end
