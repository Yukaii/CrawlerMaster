# 國立交通大學
# 選課網址: http://timetable.nctu.edu.tw/

require_relative './nctu_course_crawler/nctu_course'

module CourseCrawler::Crawlers
class NctuCourseCrawler < CourseCrawler::Base

  # PERIODS = {
  #   "M" => 1,
  #   "N" => 2,
  #   "A" => 3,
  #   "B" => 4,
  #   "C" => 5,
  #   "D" => 6,
  #   "X" => 7,
  #   "E" => 8,
  #   "F" => 9,
  #   "G" => 10,
  #   "H" => 11,
  #   "Y" => 12,
  #   "I" => 13,
  #   "J" => 14,
  #   "K" => 15,
  #   "L" => 16,
  # }
  PERIODS = CoursePeriod.find('NCTU').code_map
  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil

    @year = year || current_year
    @term = term || current_term

    @update_progress_proc = update_progress
    @after_each_proc = after_each

  end

  def courses
    @courses = []
    puts "get url ..."
    cc = NctuCourse.new(year: @year, term: @term)

    @threads = []
    cc.departments.keys.each do |unit_id|
      sleep(1) until (
        @threads.delete_if { |t| !t.status };  # remove dead (ended) threads
        @threads.count < (ENV['MAX_THREADS'] || 25)
      )
      @threads << Thread.new do
        @courses.concat cc.get_course_list(unit_id: unit_id)
      end
    end

    ThreadsWait.all_waits(*@threads)

    @threads = []
    @new_courses = []
    # normalize course
    @courses.uniq.each do |old_course|
      sleep(1) until (
        @threads.delete_if { |t| !t.status };  # remove dead (ended) threads
        @threads.count < (ENV['MAX_THREADS'] || 25)
      )
      @threads << Thread.new do
        old_course = Hashie::Mash.new old_course
        puts "data crawled : " + old_course.cos_cname
        year = old_course.acy.to_i + 1911
        term = old_course.sem.to_i

        # normalize time location
        course_days = []
        course_periods = []
        course_locations = []
        old_course.cos_time.split(',').each do |tim_loc|
          tim_loc.match(/(?<d>\d)(?<ps>[#{PERIODS.keys.join}]+)\-?(?<loc>.+)/) do |m|
            m[:ps].split('').each do |p|
              course_days << m[:d].to_i
              course_periods << PERIODS[p]
              course_locations << m[:loc]
            end
          end
        end

        department_code = "#{old_course.degree}#{old_course.dep_id}"

        course = {
          year: year,
          term: term,
          code: "#{year}-#{term}-#{old_course.cos_code}-#{old_course.cos_id}-#{department_code}",
          general_code: old_course.cos_code,
          lecturer: old_course.teacher,
          url: old_course.URL,
          name: old_course.cos_cname,
          credits: old_course.cos_credit,
          department: old_course.dep_cname,
          department_code: department_code,
          required: old_course.cos_type.include?('必'),
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
        @new_courses << course
      end # end Thread
    end
    ThreadsWait.all_waits(*@threads)
    puts "Project finished !!!"
    @new_courses
  end

end
end
