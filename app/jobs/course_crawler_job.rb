##
# crawler container worker class
#
# Example:
#   CourseCrawlerJob.perform_async "NTUST", { year: 2015, term: 2 }
#
# The instance CourseCrawler::Crawler::NtustCourseCrawler will be created
# and call its default crawler method "courses"

class CourseCrawlerJob
  include Sidekiq::Worker
  include CourseCrawler::DateMixin

  sidekiq_options retry: false

  def perform(organization_code, options = {})
    crawler_klass  = CourseCrawler.find!(organization_code)
    crawler_record = Crawler.find_by(organization_code: organization_code)

    year = options[:year] || crawler_record.year || current_year
    term = options[:term] || crawler_record.term || current_term

    @crawler_klass_instance =
      crawler_klass.new(
        year:            year,
        term:            term,
        update_progress: options[:update_progress],
        after_each:      options[:after_each]
      )

    # get back coresion year/term from crawler
    year = @crawler_klass_instance.year
    term = @crawler_klass_instance.term

    @crawler_klass_instance.worker = self
    courses = @crawler_klass_instance.courses

    if courses.empty?
      # TODO: Log if results are empty
      puts 'no courses crawled' if $PROGRAM_NAME =~ /rake$/
      Rails.logger.info('no courses crawled')

      return
    end

    if options[:save_json]
      file_path = Rails.root.join('tmp', "#{organization_code.downcase}_courses_#{Time.zone.now.to_i}.json")
      File.write(file_path, Oj.dump(courses, indent: 2, mode: :compat))

      puts "courses crawled results generate at: #{file_path}" if $PROGRAM_NAME =~ /rake$/
    end

    return unless crawler_record.save_to_db || options[:save_to_db]

    task       = CrawlTask.create(organization_code: organization_code, course_year: year, course_term: term, type: :crawler)
    db_courses = Course.where(organization_code: organization_code, year: year, term: term)

    # diff courses set
    crawl_course_codes     = courses.map { |course| course[:code] }
    existing_course_codes  = db_courses.pluck(:code)

    # calculate intersect and union
    course_codes_to_update = crawl_course_codes & existing_course_codes
    course_codes_to_delete = existing_course_codes - course_codes_to_update
    course_codes_to_insert = crawl_course_codes - course_codes_to_update

    insert_courses = courses.select { |course| course_codes_to_insert.include?(course[:code]) }
    delete_courses = db_courses.where(code: course_codes_to_delete)
    update_courses = db_courses.where(code: course_codes_to_update)

    course_updates_hash = prepare_course_updates_hash(courses, course_codes_to_update)

    ActiveRecord::Base.transaction do
      # insert courses
      insert_courses.each do |course|
        course = Course.create!(course_params(course, organization_code))
        task.course_versions << course.versions.last
      end

      # delete courses
      delete_courses.find_each do |course|
        course.destroy!
        task.course_versions << course.versions.last
      end

      # update courses
      update_courses.find_each do |course|
        course.update!(course_updates_hash[course[:code]])
        task.course_versions << course.versions.last if course.changed?
      end
    end

    if Course.where(organization_code: organization_code).group(:ucode).having('COUNT(courses.ucode) > 1').any?
      puts "Duplicate code!" if $PROGRAM_NAME =~ /rake$/
    end

    crawler_record.update!(last_run_at: Time.zone.now)
    task.update!(finished_at: Time.zone.now)

    # fix counter_cache because we insert courses through sql directly
    Crawler.reset_counters(crawler_record.id, :courses)
  end

  private

  def course_params(course, organization_code)
    course.slice(*Course::COLUMN_NAMES).merge(
      ucode: "#{organization_code}-#{course[:code]}",
      organization_code: organization_code
    )
  end

  def prepare_course_updates_hash(courses, course_codes_to_update)
    Hash[
      course_codes_to_update.map do |code|
        [
          code,
          courses.find { |course| course[:code] == code }.slice(*Course::COLUMN_NAMES)
        ]
      end
    ]
  end
end
