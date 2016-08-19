# 正修科技大學
# 課程查詢網址：http://120.118.220.21/csit1042/main.asp

module CourseCrawler::Crawlers
class CsuCourseCrawler < CourseCrawler::Base

  DAYS = {
    "M" => 1,
    "T" => 2,
    "W" => 3,
    "H" => 4,
    "F" => 5,
    "A" => 6,
    "N" => 7,
    "S" => 6,
    "U" => 7
    }

  PERIODS = CoursePeriod.find('CSU').code_map

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = "http://120.118.220.21/csit#{@year-1911}#{@term}/course/"
    @ic = Iconv.new('big5//IGNORE//translit', 'big5')
  end

  def courses
    @courses = []
    # repeat_list = []
    course_id = 0
    puts "get url ..."
    r = RestClient.get(@query_url+"course11.asp")
    doc_main = Nokogiri::HTML(r)

    doc_main.css('select[id="sysno"] option').map{|opt| opt[:value]}.each do |sysno|
      doc_main.css('select[id="dept"] option').map{|opt| opt[:value]}.each do |dept|
        doc_main.css('select[id="grade"]> option').map{|opt| opt[:value]}.each do |grade|
          doc_main.css('select[id="req_sel"]> option').map{|opt| opt[:value]}.each do |req_sel|
            next if req_sel == "2" && course_id != 0
# puts sysno+','+dept+','+grade+','+req_sel+':'+course_id.to_s
# sysno, dept, grade, req_sel = '4','34','1','1'
            r = RestClient.get(@query_url+"course12.asp?page=1&sysno=#{sysno}&dept=#{dept}&grade=#{grade}&req_sel=#{req_sel}&tname=&courname=")
            doc = Nokogiri::HTML(r)

            if doc.css('font>div').text != nil && doc.css('font>div').text != ""
              pages = doc.css('font>div').text.scan(/共\s(?<pages>\d+)/)[0][0].to_i
            else
              pages = 1
            end

            (1..pages).each do |page|
              r = RestClient.get(@query_url+"course12.asp?page=#{page}&sysno=#{sysno}&dept=#{dept}&grade=#{grade}&req_sel=#{req_sel}&tname=&courname=")
              doc = Nokogiri::HTML(@ic.iconv(r))

              doc.css('table:nth-child(3) tr:nth-child(n+2)').map{|tr| tr}.each do |tr|
                data = tr.css('>td').map{|td| td.text}
                data = data.values_at(0,4..-1) if data.count > 11

                # next if repeat_list.include?(data[1].scan(/\w+/)[0])
                # repeat_list << data[1].scan(/\w+/)[0]
                course_id += 1
                data[2] = data[2].gsub(/[\t\r\n\s]/,"")
                data[6] = data[6].gsub(/[\t\r\n\s]/,"")

                if data[10] != nil
                  course_time = data[10].scan(/[MTWHFANSU]\w/)
                else
                  course_time = []
                end

                course_days, course_periods, course_locations = [], [], []
                course_time.each do |time|
                  course_days << DAYS[time[0]]
                  course_periods << PERIODS[time[1]]
                  course_locations << data[7].gsub(/[\t\r\n\s]/,"")
                end
                  puts "data crawled : " + data[2]
                course = {
                  year: @year,    # 西元年
                  term: @term,    # 學期 (第一學期=1，第二學期=2)
                  name: data[2],    # 課程名稱
                  lecturer: data[6],    # 授課教師
                  credits: data[4].to_i,    # 學分數
                  code: "#{@year}-#{@term}-#{course_id}_#{data[1].scan(/\w+/)[0]}",
                  general_code: data[1].scan(/\w+/)[0],    # 選課代碼
                  url: nil,    # 課程大綱之類的連結
                  required: data[5].include?('必'),    # 必修或選修
                  department: data[0],    # 開課系所
                  # department_code: dept,
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
          end
        end
      end
    end
    puts "Project finished !!!"
    @courses
  end

end
end
