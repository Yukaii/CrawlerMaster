module CourseCrawler::Crawlers
class FcuCourseCrawler < CourseCrawler::Base

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
  "00" => 1,
  "01" => 2,
  "02" => 3,
  "03" => 4,
  "04" => 5,
  "05" => 6,
  "06" => 7,
  "07" => 8,
  "08" => 9,
  "09" => 10,
  "10" => 11,
  "11" => 12,
  "12" => 13,
  "13" => 14,
  "14" => 15,
  }

	def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year                 = year || current_year
    @term                 = term || current_term
    @update_progress_proc = update_progress
    @after_each_proc      = after_each

		@query_url = 'http://sdsweb.oit.fcu.edu.tw/coursequest/condition.jsp'
		@ic = Iconv.new('utf-8//IGNORE//translit', 'utf-8')
	end

	def courses
		@courses = []

		r = RestClient.post(@query_url, {
			"userID" => "guest",
			"userPW" => "guest",
			"Button2" => "%B5n%A4J",
			})

		@query_url = "http://sdsweb.oit.fcu.edu.tw/coursequest/advancelist.jsp"
		r = RestClient.post(@query_url, {
			"yms_year" => "#{@year-1911}",
			"yms_smester" => "#{@term}",
			"week" => "0",
			"start" => "0",
			"end" => "0",
			"submit1" => "%ACd++%B8%DF",
			}, {"Cookie" => "JSESSIONID=#{r.cookies["JSESSIONID"]}"})
		doc = Nokogiri::HTML(@ic.iconv(r))

    doc.css('table tr:not(:first-child)').each do |tr|
      data = []
      for i in 0..tr.css('td').count - 1
        data[i] = tr.css('td')[i].text
        syllabus_url = "http://sdsweb.oit.fcu.edu.tw#{tr.css('td a').map{|a| a[:href]}[0][2..-1]}"
        course_code = data[1].split('  ')[0] if data[1] != nil
      end

      time_period_regex = /\((?<day>[一二三四五六日])\)(?<period>.+)/
      course_time_location = Hash[data[7].split(' ').inject([]){|arr, s| arr.concat(s.scan(time_period_regex))}]

      # 把 course_time_location 轉成資料庫可以儲存的格式
      course_days, course_periods, course_locations = [], [], []
      course_time_location.each do |k, v|
        periods = v.split('-').map(&:to_i)
        if periods.count == 1
          course_days << DAYS[k]
          course_periods << periods[0]
        else
          (periods[0]..periods[1]).each do |period|
            course_days << DAYS[k]
            course_periods << period
          end
        end
      end

      course = {
        year:         @year,    # 西元年
        term:         @term,    # 學期 (第一學期=1，第二學期=2)
        name:         data[1].split(/\s+/).last,    # 課程名稱
        lecturer:     "",    # 授課教師
        credits:      data[3].to_i,    # 學分數(需要轉換成數字，可以用.to_i)
        code:         "#{@year}-#{@term}-#{course_code}-#{data[0]}", # course_code 科目代碼，data[0] 選課代碼，要問逢甲的同學
        general_code: "#{course_code}-#{data[0]}",
        # general_code: data[0],    # 選課代碼
        url:          syllabus_url,    # 課程大綱之類的連結(如果有的話)
        required:     nil,    # 必修或選修
        department:   data[6],    # 開課系所
        # note: data[11],
        # department_term: data[2],
        # mid_exam: data[4],
        # final_exam: data[5],
        # exam_early: data[6],
        # limit_people: data[9],    # 開放名額
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
        location_9:   course_locations[8]
      }

      @after_each_proc.call(course: course) if @after_each_proc
      @courses << course
# binding.pry if @courses.count == 30
    end

    @courses
  end

end
end
