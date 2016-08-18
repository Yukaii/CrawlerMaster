##
# 宜大課程查詢
# http://www.niu.edu.tw/acade/curriculum/course/course-sec.htm
# 每個學期連結都不一樣，先寫死，有機會再來改寫成智慧選
#

module CourseCrawler::Crawlers
class NiuCourseCrawler < CourseCrawler::Base

  QUERY_URLS = {
    "1041" => "https://acade.niu.edu.tw/NIU/outside.aspx?mainPage=LwBBAHAAcABsAGkAYwBhAHQAaQBvAG4ALwBUAEsARQAvAFQASwBFADUAMAAvAFQASwBFADUAMAAxADAAXwAwADEALgBhAHMAcAB4AD8AQQBZAEUAQQBSAFMATQBTAD0AMQAwADQAMQA=",
    "1042" => "https://acade.niu.edu.tw/NIU/outside.aspx?mainPage=LwBBAHAAcABsAGkAYwBhAHQAaQBvAG4ALwBUAEsARQAvAFAAUgBHAC8AUABSAEcAMQAxADAAMABfADAAMQAuAGEAcwBwAHgAPwBhAHkAZQBhAHIAcwBtAHMAPQAxADAANAAyAA=="
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
		"0A" => 11,
		"0B" => 12,
		"0C" => 13,
		"0D" => 14
	}

	def initialize year: nil, term: nil, update_progress: nil, after_each: nil
    @year                 = year || current_year
    @term                 = term || current_term
    @after_each_proc      = after_each
    @update_progress_proc = update_progress
    @ic                   = Iconv.new('utf-8//translit//IGNORE', 'utf-8')

		@query = QUERY_URLS["#{@year-1911}#{@term}"]
		@post_url= "https://acade.niu.edu.tw/NIU//Application/TKE/TKE50/TKE5010_01.aspx?AYEARSMS=#{@year-1911}#{@term}"

	end

	def courses
    return if @query.nil?
    puts "get url ..."
		r = RestClient.get @query
		@cookies = r.cookies

		r = RestClient.get @post_url, cookies: @cookies
		doc = Nokogiri::HTML(r)

		view_state = Hash[ doc.css('input[type="hidden"]').map{|input| [input[:name], input[:value]]} ]

		response = RestClient.post @post_url, view_state.merge({
			"__EVENTTARGET" => 'DoExport',
			"OP" => 'OP1',
			"Q_WEEK" => '1',
			"CLASS" => '00',
			"radioButtonClass" => '0',
			"radioButtonQuery" => '0',
			"PC$PageSize" => '20',
			"PC$PageNo" => '1',
			"PC2$PageSize" => '20',
			"PC2$PageNo" => '1'
		}), cookies: @cookies

    # Dir.mkdir('tmp') unless Dir.exist?('tmp')
    File.write(Rails.root.join('tmp/tmp.xls'), response.to_s.force_encoding('utf-8'))

		@courses = []

		Spreadsheet.client_encoding = 'UTF-8'
		book = Spreadsheet.open Rails.root.join('tmp/tmp.xls').to_s

		sheet1 = book.worksheet 0
		# sheet2 = book.worksheet 'Sheet1'

		sheet1.each_with_index 2 do |row,index|
			# print "#{index+1}\n"

			# puts row[2]+index.to_s

			course_days, course_periods, course_locations = [], [], []
			row[10].to_s.split(',').each_with_index do |period, i|
        location = row[11].split(',')[0]
        if row[11].split(',').length > 1
          location = row[11].split(',')[i]
        end
				course_days << period[0].to_i
				course_periods << PERIODS[period[1..2]]
				course_locations << location
			end

      next if row[1].nil?
      puts "data crawled : " + row[2]
			course ={
        department:   row[0].split(","),
        name:         row[2],
        year:         @year,
        term:         @term,
        code:         "#{@year}-#{@term}-#{row[1]}",
        general_code: row[1],
        credits:      row[7].to_i,
        lecturer:     row[9],
        required:     row[8].include?('必'),
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
		end # sheet1 do
    puts "Project finished !!!"
		@courses
	end # end courses
end # class
end
