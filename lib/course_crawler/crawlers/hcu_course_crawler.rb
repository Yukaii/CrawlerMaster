##
# 玄奘課程爬蟲
# http://hrs.hcu.edu.tw/strategy/std/index.asp
#
module CourseCrawler::Crawlers
class HcuCourseCrawler < CourseCrawler::Base

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year || current_year
    @term = term || current_term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://hrs.hcu.edu.tw/strategy/std/index.asp'
    @ic = Iconv.new('utf-8//IGNORE//translit', 'big5')
  end

  def courses
    @courses = []

    year = @year - 1911

    r = RestClient.get(@query_url)
    doc = Nokogiri::HTML(@ic.iconv(r))

    r = RestClient.post("http://hrs.hcu.edu.tw/strategy/std/index2.asp", {
      "yy" => year,
      "mm" => @term,
      # "s1" => "",
      # "s22" => "",
      # "s2" => "",
      # "s6" => "",
      # "s7" => "",
      # "s8" => "",
      })
    doc = Nokogiri::HTML(@ic.iconv(r))

    doc.css('tbody tr[height="30"]').map{|tr| tr}.each do |tr|
      data = tr.css('td:nth-child(n+3)').map{|td| td.text}
      _datas = tr.css('td')
      # syllabus_url = tr.css('td a').map{|a| a}
      # note = tr[:title]

      time_period_regex = /(?<day>\d)[0]?(?<period>\d+)/
      course_time_location = data[5].scan(time_period_regex)

      # 把 course_time_location 轉成資料庫可以儲存的格式
      course_days, course_periods, course_locations = [], [], []
      course_time_location.each do |arr|
        day, period = arr

        course_days      << day.to_i
        course_periods   << period.to_i
        course_locations << power_strip(data[6])
      end

      general_code = data[2]
      cla_code = Digest::MD5.hexdigest(_datas[2].text)[0..5]

      course = {
        year:         @year,    # 西元年
        term:         @term,    # 學期 (第一學期=1，第二學期=2)
        name:         data[3],    # 課程名稱
        lecturer:     data[4],    # 授課教師
        credits:      data[7].to_i,    # 學分數
        code:         "#{@year}-#{@term}-#{data[1]}_#{data[2]}_#{cla_code}",
        general_code: "#{data[2]}",
        # general_code: data[2],    # 選課代碼
        # url: syllabus_url,    # 課程大綱之類的連結(內容為HTML，這是一個要POST的)
        required:     data[12].include?('必'),    # 必修或選修
        department:   data[0] + "#{data[5].scan(/[單雙]/)[0]}",    # 開課系所
        # note: note,
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
# binding.pry if data[2] == "A00889"
    end
    @courses
  end
end
end
