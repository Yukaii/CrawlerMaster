##
# 朝陽科大課程爬蟲
# 查詢網址：https://admin.cyut.edu.tw/crsinfo/cur_01.asp
#
module CourseCrawler::Crawlers
class CyutCourseCrawler < CourseCrawler::Base

  DEP = [ 'AEB', 'TA0', 'TF8', 'TC0', 'TC6', 'TC7', 'TC8', 'TC9', 'TCA', 'TCJ', 'TCK', 'TCL', 'TCM', 'TCN', 'TC0', 'TP4', 'TD0', 'TD4', 'TD5', 'TD6', 'TD7', 'TDD', 'TDE', 'TDF', 'TDG', 'TDH', 'TDI', 'TDJ', 'TP2', 'TP6', 'TE0', 'TE1', 'TE2', 'TE3', 'TE4', 'TE5', 'TE6', 'TE7', 'TE8', 'TE9', 'TEA', 'TEC', 'TP1', 'TF0', 'TF1', 'TF2', 'TF3', 'TF4', 'TF6', 'TH0', 'TJ0', 'TJ2', 'TJ4', 'TJ6', 'TJ9', 'TJB', 'TP5', 'XX1', 'XX2' ]
  H_SECID = [ '1', '2', '3' ]
  H_SUBID = [ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'Y', 'Z' ]

  PERIODS = CoursePeriod.find('CYUT').code_map

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil
    @year = year || current_year
    @term = term || current_term
    #@post_url = "https://admin.cyut.edu.tw/crsinfo/"
    @update_progress_proc = update_progress
    @after_each_proc = after_each
    @count = 1
    @ic = Iconv.new('utf-8//IGNORE', 'big5') #
  end

  def courses
    @courses = []
    puts "get url ..."
    DEP.each do |dep|
      H_SECID.each do |secid|
        H_SUBID.each do |subid|
          r = `curl -s "https://admin.cyut.edu.tw/crsinfo/cur_01.asp" -H "Cookie: ASPSESSIONIDAGTSCDSB=IHFPJDLCBHFABAGFLIMINNEI" -H "Origin: https://admin.cyut.edu.tw" -H "Accept-Encoding: gzip, deflate" -H "Accept-Language: zh-TW,zh;q=0.8,en-US;q=0.6,en;q=0.4" -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36" -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Cache-Control: max-age=0" -H "Referer: https://admin.cyut.edu.tw/crsinfo/cur_01.asp" -H "Connection: keep-alive" --data "h_status=run&h_acy=#{@year-1911}&h_sem=#{@term}&h_depno=#{dep}&h_secid=#{secid}&h_subid=#{subid}&h_year=all&h_class=all" --compressed`
          doc = Nokogiri::HTML(@ic.iconv(r))

          #set_progress "Department: " + DEP.size.to_s + " / " + (DEP.index(dep)+1).to_s + " H_SECID: " + H_SECID.size.to_s + " / " + (H_SECID.index(secid)+1).to_s + " H_SUBID : " + H_SUBID.size.to_s + " / " + (H_SUBID.index(subid)+1).to_s
          puts "Department: " + DEP.size.to_s + " / " + (DEP.index(dep)+1).to_s + " H_SECID: " + H_SECID.size.to_s + " / " + (H_SECID.index(secid)+1).to_s + " H_SUBID : " + H_SUBID.size.to_s + " / " + (H_SUBID.index(subid)+1).to_s

          if(doc.css('div[class="warning_font"]').text != "查無資料")
            rows = doc.css('table[class="tablefont1"] tr:nth-child(n+3)')
            rows && rows[0..-2].each do |row|
              # next if !index[1] || (index[1] && !index[1].text.length > 0)
              datas = row.css('td')

              course_days, course_periods, course_locations = [], [], []

              (10..16).each do |day_index|
                next if power_strip(datas[day_index].text).empty?

                datas[day_index].search('br').each {|br| br.replace("\n")}
                periods, location = datas[day_index].text.split("\n")

                p_start, p_end = periods.split(/[-,]/)
                p_end = p_start if p_end.nil?

                (PERIODS[p_start]..PERIODS[p_end]).each do |p|
                  course_days      << day_index - 9 # day start from 1 to 7
                  course_periods   << p
                  course_locations << location
                end
              end

              next if datas[0].nil? || datas[1].nil?

              course = {
                name:         datas[1].text.strip,
                year:         @year,
                term:         @term,
                code:         "#{@year}-#{@term}-#{datas[0].text.strip}-#{@count}",
                general_code: datas[0].text.strip+"#{@count}",
                class_no:     datas[9] && datas[9].text.strip,
                credits:      datas[4] && datas[4].text.strip && datas[4].text.strip.to_i,
                lecturer:     datas[8] && datas[8].text.strip,
                day_1:        course_days[0],
                day_2:        course_days[1],
                day_3:        course_days[2],
                day_4:        course_days[3],
                day_5:        course_days[4],
                day_6:        course_days[5],
                day_7:        course_days[6],
                day_8:        course_days[7],
                day_9:        course_days[8],
                period_1:     course_periods[0],
                period_2:     course_periods[1],
                period_3:     course_periods[2],
                period_4:     course_periods[3],
                period_5:     course_periods[4],
                period_6:     course_periods[5],
                period_7:     course_periods[6],
                period_8:     course_periods[7],
                period_9:     course_periods[8],
                location_1:   course_locations[0],
                location_2:   course_locations[1],
                location_3:   course_locations[2],
                location_4:   course_locations[3],
                location_5:   course_locations[4],
                location_6:   course_locations[5],
                location_7:   course_locations[6],
                location_8:   course_locations[7],
                location_9:   course_locations[8],
              }

              @after_each_proc.call(course: course) if @after_each_proc

              @courses << course
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
