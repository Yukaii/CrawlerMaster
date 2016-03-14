##
# 亞東技術學院 
# http://info.oit.edu.tw/cosinfo/schedule/Schedule.asp?btn=4
#
module CourseCrawler::Crawlers
	class OitCourseCrawler < CourseCrawler::Base

		def initialize year: nil, term: nil, update_progress: nil, after_each: nil

			@year = year || current_year
			@term = term || current_term
			@query_url = "http://info.oit.edu.tw/cosinfo/schedule/Schedule.asp?btn=4"
			@ic = Iconv.new('utf-8//IGNORE//translit', 'big5')
			@update_progress_proc = update_progress
   			@after_each_proc      = after_each
		end

		def courses
			@courses = []
			year = @year - 1911
			term = @term
			year_term = year.to_s + term.to_s
			select = [true, false]



			r = RestClient.get "http://info.oit.edu.tw/cosinfo/schedule/Schedule.asp?btn=4"
			cookies = r.cookies

			RestClient.get "http://info.oit.edu.tw/cosinfo/schedule/CosScheduleBtn.asp", cookies: cookies
			RestClient.get "http://info.oit.edu.tw/cosinfo/schedule/empty.html", cookies: cookies

			r = RestClient.get("http://info.oit.edu.tw/cosinfo/schedule/QuerySmtrCos.asp?smtr=" + year_term + "&CosNameKeyword=%&CosCredit=&CosSelType=false&CosTime=&CosRoom=&CosTch=", cookies: cookies)
			doc = Nokogiri::HTML(@ic.iconv(r))


			doc.css('table tr:not(:first-child)').each do |tr|
				data = tr.css('td').map{|td| td.text.gsub(/[\r\n]/,'')}

				course_days, course_periods, course_locations = [], [], []


				day_period = data[11].strip.split(',').map {|s|
					s.match(/(?<day>\d)[0]?(?<period>\d)/)
				}


				# department parse


				day_period.reject(&:nil?).each do |arr|	
			    	course_days << arr[:day].to_i
			    	course_periods << arr[:period].to_i
			    	course_locations << data[12]
			    end



			    course = {
		        year:         @year,    # 西元年
		        term:         @term,    # 學期 (第一學期=1，第二學期=2)
		        name:         data[1],    # 課程名稱
		        lecturer:     data[8],    # 授課教師
		        credits:      data[6],    # 學分數
		        code:         "#{@year}-#{@term}-#{data[0]}",
		        general_code: "#{data[0]}",
		        # general_code: data[2],    # 選課代碼
		        # url: syllabus_url,    # 課程大綱之類的連結(內容為HTML，這是一個要POST的)
		        required:     data[7].include?('必'),    # 必修或選修
		        #department:   123,    # 開課系所
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

				@courses << course

			end
			@courses
		end

	end
end