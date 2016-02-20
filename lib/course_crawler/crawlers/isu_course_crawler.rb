##
# 義守課程爬蟲
# http://netreg.isu.edu.tw/wapp/wapp_sha/wap_s140000_bilingual.asp
#

module CourseCrawler::Crawlers
class IsuCourseCrawler < CourseCrawler::Base

  PERIODS = {
    "1" => 1,
    "2" => 2,
    "3" => 3,
    "4" => 4,
    "z" => 5,
    "5" => 6,
    "6" => 7,
    "7" => 8,
    "8" => 9,
    "9" => 10,
    "A" => 11,
    "B" => 12,
    "C" => 13,
    "D" => 14,
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = %x(curl -s 'http://netreg.isu.edu.tw/wapp/wapp_sha/wap_s140000_bilingual.asp' --compressed)
    @ic = Iconv.new('utf-8//IGNORE//translit', 'big5')
  end

  def courses
    @courses = []

    doc = Nokogiri::HTML(@ic.iconv(@query_url))
    majr_option = doc.css('table')[1].css('tr')[2].css('option')

    # 年級 (1~15)
    grade_beg = 1
    grade_end = 9
    # 部別
    divi_A="A"
    divi_M="M"
    divi_I="I"
    divi_D="D"
    divi_B="B"
    divi_G="G"
    divi_T="T"
    divi_F="T"

    for i in 0..majr_option.count - 2
      data = []
      # 系所
      majr_no = majr_option[i].text[0..1]
# binding.pry if majr_no == '10'
      r = %x(curl -s 'http://netreg.isu.edu.tw/wapp/wapp_sha/wap_s140001.asp' --data 'lange_sel=zh_TW&qry_setyear=#{@year-1911}&qry_setterm=#{@term}&grade_beg=#{grade_beg}&grade_end=#{grade_end}&majr_no=#{majr_no}&divi_A=#{divi_A}&divi_M=#{divi_M}&divi_I=#{divi_I}&divi_D=#{divi_D}&divi_B=#{divi_B}&divi_G=#{divi_G}&divi_T=#{divi_T}&divi_F=#{divi_F}&cr_code=&cr_name=&yepg_sel=+&crdnum_beg=0&crdnum_end=6&apt_code=+&submit1=%B0e%A5X' --compressed)
      doc = Nokogiri::HTML(@ic.iconv(r))

      (0..doc.css('table:nth-child(7) tr:nth-child(n+3)').count-1).each do |tr|
        data = mix_data(doc,tr)
# puts "#{tr+1}/#{majr_no}"
        next if data[0] == ""

# binding.pry #if tr == 8
        if doc.css('table:nth-child(7) tr:nth-child(n+3)')[tr].css('td a')[0] != nil
          syllabus_url = "http://netreg.isu.edu.tw/wapp/wapp_sha/#{doc.css('table:nth-child(7) tr:nth-child(n+3)')[tr].css('td a')[0][:href]}"
        else
          syllabus_url = nil
        end

        course_days, course_periods, course_locations = data[18],data[19],data[20]

        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[2],    # 課程名稱
          lecturer: data[4],    # 授課教師
          credits: data[5].to_i,   # 學分數
          code: "#{@year}-#{@term}-#{data[0]}_#{data[1]}",
          general_code: data[1],    # 選課代碼
          url: syllabus_url,    # 課程大綱之類的連結
          required: data[6].include?("必"),    # 修別(必選修)
          department: data[3],    # 開課系級
          # department_code: majr_no,    # 系所代碼
          # notes: data[17],    # 備註說明
          # people_limit: data[6],    # 限制選修人數
          # people: data[7],    # 修課人數
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
    @courses
  end

  def mix_data doc,tr
    # 往後察看下一欄的資訊，如果是本欄延續的資料就合起來~
    data = doc.css('table:nth-child(7) tr:nth-child(n+3)')[tr].css('td').map{|td| td.text.gsub(/[\s\r\t\n ]/,"")}
    data[18],data[19],data[20] = [],[],[]
    (1..data[10..16].length).each do |day|
      data[10..16][day-1].scan(/\w/).each do |p|
        data[18] << day
        data[19] << PERIODS[p]
        data[20] << data[9]
      end
    end

    if doc.css('table:nth-child(7) tr:nth-child(n+3)')[tr+1] != nil
      data_next = doc.css('table:nth-child(7) tr:nth-child(n+3)')[tr+1].css('td').map{|td| td.text.gsub(/[\s\r\t\n ]/,"")}
    else
      return data
    end

    if data_next[0] == ""
      data_next = mix_data(doc,tr+1)

      data[4] += ",#{data_next[4]}"

      data[18] += data_next[18]
      data[19] += data_next[19]
      data[20] += data_next[20]
    end
    data
  end
end
end