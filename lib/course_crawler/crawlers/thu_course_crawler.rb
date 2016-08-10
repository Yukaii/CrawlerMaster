# 東海大學
# 課程查詢網址：http://course.thu.edu.tw/

module CourseCrawler::Crawlers
  class ThuCourseCrawler < CourseCrawler::Base
	PERIODS = Colorgy::CoursePeriod.find('THU').code_map
    def initialize(year: nil, term: nil, update_progress: nil, after_each: nil)
      @year                 = year || current_year
      @term                 = term || current_term
      @update_progress_proc = update_progress
      @after_each_proc      = after_each

      @ic = Iconv.new('utf-8//translit//IGNORE', 'utf-8') #
    end

    def courses
      @courses = []

      dps = ThuCourse.department_id(@year - 1911, @term)
      dps.each do |dp|
        courses = ThuCourse.department(@year - 1911, @term, dp[:id])
        courses.each do |course|
          course_days = []
          course_periods = []
          course_locations = []
          course[:date].each do |d|
            d[:time].each do |t|
              course_days << d[:day]
              course_periods << PERIODS[t]
              course_locations << d[:local]
            end
          end
          teacher = []
          course[:teacher].each do |t|
            teacher << t[:teacher_name]
          end
          course = {
            name:         course[:name],
            year:         @year,
            term:         @term,
            code:         "#{@year}-#{@term}-#{course[:id]}",
            general_code: course[:id],
            credits:      (course[:credit].split('-')[@term - 1]).to_s,
            lecturer:     teacher.join(',').to_s,
			required:     course[:name].include?('必'),
            day_1:        course_days[0],
            day_2:        course_days[1],
            day_3:        course_days[2],
            day_4:        course_days[3],
            day_5:        course_days[4],
            day_6:        course_days[5],
            day_7:        course_days[6],
            day_8:        course_days[7],
            day_9:        course_days[8],
            day_10:        course_days[9],
            day_11:        course_days[10],
            day_12:        course_days[11],
            day_13:        course_days[12],
            day_14:        course_days[13],
            day_15:        course_days[14],
            day_16:        course_days[15],
            day_17:        course_days[16],
            day_18:        course_days[17],
            day_19:        course_days[18],
            day_20:        course_days[19],
            period_1:     course_periods[0],
            period_2:     course_periods[1],
            period_3:     course_periods[2],
            period_4:     course_periods[3],
            period_5:     course_periods[4],
            period_6:     course_periods[5],
            period_7:     course_periods[6],
            period_8:     course_periods[7],
            period_9:     course_periods[8],
            period_10:     course_periods[9],
            period_11:     course_periods[10],
            period_12:     course_periods[11],
            period_13:     course_periods[12],
            period_14:     course_periods[13],
            period_15:     course_periods[14],
            period_16:     course_periods[15],
            period_17:     course_periods[16],
            period_18:     course_periods[17],
            period_19:     course_periods[18],
            period_20:     course_periods[19],
            location_1:   course_locations[0],
            location_2:   course_locations[1],
            location_3:   course_locations[2],
            location_4:   course_locations[3],
            location_5:   course_locations[4],
            location_6:   course_locations[5],
            location_7:   course_locations[6],
            location_8:   course_locations[7],
            location_9:   course_locations[8],
            location_10:   course_locations[9],
            location_11:   course_locations[10],
            location_12:   course_locations[11],
            location_13:   course_locations[12],
            location_14:   course_locations[13],
            location_15:   course_locations[14],
            location_16:   course_locations[15],
            location_17:   course_locations[16],
            location_18:   course_locations[17],
            location_19:   course_locations[18],
            location_20:   course_locations[19],
          }
          @after_each_proc.call(course: course) if @after_each_proc
          @courses << course
        end
      end
        @courses
  end
  end
end
