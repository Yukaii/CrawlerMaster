module CourseImport
  extend ActiveSupport::Concern

  class_methods do
    def import_to_course(organization_code, course_year, course_term)
      semester_date = Colorgy::SemesterDate.find_by!(year: course_year, term: course_term)
      organization  = Colorgy::Organization.find_by!(code: organization_code)
      calendar      = Colorgy::Calendar.find_by!(owner_type: 'Organization', owner_id: organization.id)

      periods       = CoursePeriod.find!(organization_code)

      transaction do
        existing_courses = Colorgy::Course.where("data -> 'course_year' = '#{course_year}' AND data -> 'course_term' = '#{course_term}'").where(calendar_id: calendar.id).root

        where(organization_code: organization_code, year: course_year, term: course_term).find_each do |legacy_course|
          course_days      = legacy_course.course_days.reject(&:nil?)
          course_periods   = legacy_course.course_periods
          course_locations = legacy_course.course_locations

          next if course_days.reject(&:nil?).reject(&:zero?).count == 0

          # map coures attributes
          period        = periods.find { |p| p.order == course_periods[0] }
          rrule         = (semester_date.to_rrule_array(course_days[0]) + ['FREQ=WEEKLY', "WKST=#{Course::DAYS[course_days[0]]}"]).join(';')
          period_string = "#{course_days[0]}#{period.code}"

          course_attributes =
            build_course_attributes(
              legacy_course: legacy_course,
              location:      course_locations[0],
              rrule:         rrule,
              period_string: period_string,
              calendar_id:   calendar.id,
              start_time:    period.start_time(semester_date.nearest_day(course_days[0])),
              end_time:      period.end_time(semester_date.nearest_day(course_days[0]))
            )

          sub_courses_attributes = course_days[1..-1].each_with_index.map do |day, index|
            period        = periods.find { |p| p.order == course_periods[index + 1] } # skip the root course
            rrule         = (semester_date.to_rrule_array(day) + ['FREQ=WEEKLY', "WKST=#{Course::DAYS[day]}"]).join(';')
            period_string = "#{day}#{period.code}"

            build_course_attributes(
              legacy_course: legacy_course,
              location:      course_locations[index + 1], # skip the root course
              rrule:         rrule,
              period_string: period_string,
              calendar_id:   calendar.id,
              start_time:    period.start_time(semester_date.nearest_day(day)),
              end_time:      period.end_time(semester_date.nearest_day(day))
            )
          end

          course = existing_courses.where("data -> 'course_code' = '#{legacy_course.code}'").first_or_initialize

          # destroy all sub_courses and re-create them
          course.sub_courses.destroy_all
          course.update!(course_attributes.merge(sub_courses_attributes: sub_courses_attributes))
        end # end legacy_courses.find_each
      end # end transaction do
    end # end import

    def build_course_attributes(legacy_course: nil, location: nil, rrule: nil, period_string: nil, calendar_id: nil, start_time: nil, end_time: nil)
      {
        name:            legacy_course.name,
        course_year:     legacy_course.year,
        course_term:     legacy_course.term,
        course_lecturer: legacy_course.lecturer,
        course_credits:  legacy_course.credits,
        course_url:      legacy_course.url,
        course_required: legacy_course.required,
        course_code:     legacy_course.code,

        location:        location,
        calendar_id:     calendar_id,
        rrule:           rrule,
        period_string:   period_string,

        start_time:      start_time,
        end_time:        end_time
      }
    end
  end # end class_methods do
end
