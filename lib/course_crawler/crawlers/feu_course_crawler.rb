# 遠東科技大學
# 課程查詢網址：http://web.isic.feu.edu.tw/query/classcour.asp

module CourseCrawler::Crawlers
class FeuCourseCrawler < CourseCrawler::Base

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://web.isic.feu.edu.tw/query/'
    @ic = Iconv.new('utf-8//IGNORE//translit', 'big5')
  end

  def courses
    @courses = []
    course_id = 0

    r = RestClient.get(@query_url+"classcour.asp?ysem=#{@year-1911}#{@term}")
    doc = Nokogiri::HTML(r)

    sem = nil
    doc.css('select[name="SEM"] option').map{|opt| opt[:value]}.each do |sem_temp|
      sem = sem_temp if sem_temp.include?(@term.to_s)
    end

    doc.css('table:nth-child(1) tr:nth-child(2) td input').map{|i| i[:value]}.each do |d_n|
      r = RestClient.get(@query_url+"classcour.asp?ysem=#{@year-1911}#{@term}&daynight=#{d_n}")
      doc = Nokogiri::HTML(r)

      doc.css('select[name="DEPT"] option').map{|opt| URI.escape(opt[:value])}.each do |dept|
        r = RestClient.get(@query_url+"classcour.asp?ysem=#{@year-1911}#{@term}&daynight=#{d_n}&dept=#{dept.scan(/[\w]+/)[0]}")
        doc = Nokogiri::HTML(r)

        doc.css('select[name="SUB"] option').map{|opt| URI.escape(opt[:value])}.each do |sub|
          r = RestClient.get(@query_url+"classcour.asp?ysem=#{@year-1911}#{@term}&daynight=#{d_n}&dept=#{dept.scan(/[\w]+/)[0]}&sub=#{sub.scan(/[\w]+/)[0]}")
          doc = Nokogiri::HTML(r)

          doc.css('select[name="CLASS"] option').map{|opt| URI.escape(opt[:value])}.each do |cla|
            r = RestClient.post(@query_url+"classcour3.asp",{
              "YEAR" => @year-1911,
              "SEM" => "2.%A4U%BE%C7%B4%C1",
              "term" => "1",
              "DAYNIGHT" => d_n,
              "DEPT" => dept,
              "SUB" => sub,
              "CLASS" => cla,
              })
            doc = Nokogiri::HTML(r)

            (0..doc.css('table:nth-child(1) tr:nth-child(n+2)').count-1).each do |tr|
              data = mix_data(doc,tr)
              next if data[0] == " "
              data[1] = 0 if data[1] == ""
              if doc.css('table:nth-child(1) tr:nth-child(n+2)')[tr].css('td a')[0] != nil
                syllabus_url = @query_url+doc.css('table:nth-child(1) tr:nth-child(n+2)')[tr].css('td a')[0][:href]
              else
                syllabus_url = nil
              end
              dep_name = URI.decode(doc.css('b font font:nth-child(4) font[color="BLUE"]')[0].text)

              course_id += 1

              course_days, course_periods, course_locations = data[18], data[19], data[20]

              course = {
                year: @year,    # 西元年
                term: @term,    # 學期 (第一學期=1，第二學期=2)
                name: data[2],    # 課程名稱
                lecturer: data[6],    # 授課教師
                credits: data[4].to_i,    # 學分數
                code: "#{@year}-#{@term}-#{course_id}_#{data[1]}",
                general_code: data[1],    # 選課代碼
                url: syllabus_url,    # 課程大綱之類的連結
                required: data[3].include?('必'),    # 必修或選修
                department: dep_name,    # 開課系所
                # department_code: sub.scan(/[\w]+/)[0],
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
# binding.pry if course_id == 7
            end
          end
        end
      end
    end
    @courses
  end

  def mix_data doc,tr
    # 往後察看下一欄的資訊，如果是本欄延續的資料就合起來~
    data = doc.css('table:nth-child(1) tr:nth-child(n+2)')[tr].css('td').map{|td| td.text}
    data[18],data[19],data[20] = [],[],[]
    (1..data[8..14].length).each do |day|
      data[8..14][day-1].scan(/\d/).each do |p|
        data[18] << day
        data[19] << p.to_i
        data[20] << data[7]
      end
    end

    if doc.css('table:nth-child(1) tr:nth-child(n+2)')[tr+1] != nil
      data_next = doc.css('table:nth-child(1) tr:nth-child(n+2)')[tr+1].css('td').map{|td| td.text}
    else
      return data
    end

    if data_next[0] == " "
      data_next = mix_data(doc,tr+1)

      data[4] += ",#{data_next[4]}" if data_next[4] != " "

      data[18] += data_next[18]
      data[19] += data_next[19]
      data[20] += data_next[20]
    end
    data
  end
end
end