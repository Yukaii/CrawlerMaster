# CourseCacheGenerateJob.perform_later('YM', 2016, 1)
class CourseCacheGenerateJob < ActiveJob::Base
  queue_as :default

  def perform(organization_code, course_year, course_term)
    organization = Colorgy::Organization.find_by(code: organization_code)
    calendar     = Colorgy::Calendar.find_by!(owner_type: 'Organization', owner_id: organization.id)

    courses = Colorgy::Course.where(calendar_id: calendar.id).root
                             .where("data -> 'course_year' = '#{course_year}' AND data -> 'course_term' = '#{course_term}'")
                             .reduce([]) do |prev, cur|
                               prev + cur.flatten_with_sub_courses
                             end

    courses_json_string = courses.map { |course| CourseSerializer.new(course) }.to_json

    # generate json file name
    file_name = "#{course_year}_#{course_term}_#{organization.code}_#{Time.zone.now.getutc.iso8601.gsub(/[-:]/, '')}.json"
    tempfile = Tempfile.new(file_name)

    begin
      tempfile.write(courses_json_string)
    ensure
      s3 = Aws::S3::Resource.new

      obj = s3.bucket(ENV['S3_BUCKET']).object("course-cache/#{file_name}")
      obj.upload_file(tempfile.path, acl: 'public-read')

      Colorgy::CourseCache.create(
        year: course_year,
        term: course_term,
        s3_url: obj.public_url,
        calendar_id: calendar.id
      )

      tempfile.close
      tempfile.unlink
    end
  end

end
