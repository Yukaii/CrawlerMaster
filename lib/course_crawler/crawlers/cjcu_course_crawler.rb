##
# 長榮大學課程爬蟲
# 選課網址：https://eportal.cjcu.edu.tw/syllabus/home
#

module CourseCrawler::Crawlers
class CjcuCourseCrawler < CourseCrawler::Base
  include Capybara::DSL

	Grade = [ '1', '2', '3', '4' ]
	Classes = [ '1', '2', '3', '4' ]

  PERIODS = {
    '0'  => 1,
    '1'  => 2,
    '2'  => 3,
    '3'  => 4,
    '4'  => 5,
    '5'  => 6,
    '6'  => 7,
    '7'  => 8,
    '8'  => 9,
    '9'  => 10,
    '10' => 11,
    '11' => 12,
    '12' => 13,
    '13' => 14,
    '14' => 15,
    '15' => 16,
  }

	DAYS = {
		'一' => 1,
		'二' => 2,
		'三' => 3,
		'四' => 4,
		'五' => 5,
		'六' => 6,
		'日' => 7
	}


	def initialize year: nil, term: nil, update_progress: nil, after_each: nil

		@year = year || current_year
		@term = term || current_term # 1 => 1 , 2 => 2 , summer1 => 5 , summer2 => 6

		@ic = Iconv.new('utf-8//translit//IGNORE', 'utf-8')
		@update_progress_proc = update_progress
		@after_each_proc = after_each

    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app,  js_errors: false)
    end

    Capybara.javascript_driver = :poltergeist
    Capybara.current_driver = :poltergeist

	end

	def courses
		@courses = []

		year = @year
  	term = @term #initialize -> year and term

    edu_dep_h = {}

    visit "https://eportal.cjcu.edu.tw/syllabus/home"
    all('select[name="edus"] option').count.times do |edu_i|
      edu_opt = all('select[name="edus"] option')[edu_i]
      edu_opt.select_option

      edu_dep_h[edu_opt.value] = all('select[name="deps"] option').map{|opt| opt.value}
    end;


    edu_dep_h.each do |_, depts|
      depts.each do |department|
        Grade.each do |grade|
  			# puts "grade: " + Grade.size.to_s + "/" +(Grade.index(grade)+1).to_s + " , dep:"+DEP.size.to_s + "/" + (DEP.index(department)+1).to_s
    			Classes.each do |class_no| # class_name

  					@url_Get = "https://eportal.cjcu.edu.tw/api/Course/Get/?syear=#{year-1911}&semester=#{term}&dep=#{department}&grade=#{grade}&classno=#{class_no}"

  					r = RestClient.get @url_Get , accept: 'application/json'
  					#doc = Nokogiri::HTML(r)
  	  			data = JSON.parse(r)

  	  			data.each do |array|
  						# regex = /\[(.)\][A-Z]{3}\s\((.+)\)(.+)/
  						course_regex = /星期(?<d>.)\((?<s>\d+)節~(?<e>\d+)節\)(?<loc>([^星期]+)?)/
  						course_arrange_time_info = Nokogiri::HTML(array["course_arrange_time_info"]).text

  						course_days = []
  						course_periods = []
  						course_locations = []

  						course_arrange_time_info.scan(course_regex).each do |match_arr|
  							(match_arr[1].to_i..match_arr[2].to_i).each do |period|
  								course_days << DAYS[match_arr[0]]
  								course_periods << PERIODS[period.to_s]
  								course_locations << match_arr[3]
  							end
  						end


  		  			course = {
                year:         @year,
                term:         @term,
                name:         array["course_name"],
                code:         "#{@year}-#{@term}-#{array["open_no"]}",
                general_code: array["open_no"],
                credits:      array["credit"],
                grade:        array["grade"],
                class_name:   array["class_name"],
                lecturer:     array["master_teacher_name"],
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

		puts "ForeignLanguages : Running..."
		@url_GetInForeign = "https://eportal.cjcu.edu.tw/api/Course/GetByTaughtInForeignLanguages/?syear=#{year-1911}&semester=#{term}"
		r_Foregin = RestClient.get @url_GetInForeign , accept: 'application/json'

		data_Foregin = JSON.parse(r_Foregin)
		data_Foregin.each do |array|

			course_regex = /星期(?<d>.)\((?<s>\d+)節~(?<e>\d+)節\)(?<loc>([^星期]+)?)/
			course_arrange_time_info = Nokogiri::HTML(array["course_arrange_time_info"]).text

			course_days = []
			course_periods = []
			course_locations = []

			course_arrange_time_info.scan(course_regex).each do |match_arr|
				(match_arr[1].to_i..match_arr[2].to_i).each do |period|
					course_days << DAYS[match_arr[0]]
					course_periods << PERIODS[period.to_s]
					course_locations << match_arr[3]
				end
			end

	    course = {
        year:         @year,
        term:         @term,
        name:         array["course_name"],
        code:         "#{@year}-#{@term}-#{array["open_no"]}",
        general_code: array["open_no"],
        credits:      array["credit"],
        grade:        array["grade"],
        class_name:   array["class_name"],
        lecturer:     array["master_teacher_name"],
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
		end

    puts "End"
		@courses.uniq
	end

end
end
