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
    crawl_courses = @crawler_klass_instance.courses

    if crawl_courses.empty?
      # TODO: Log if results are empty
      puts 'no courses crawled' if $PROGRAM_NAME =~ /rake$/
      Rails.logger.info('no courses crawled')

      return
    end

    if options[:save_json]
      file_path = Rails.root.join('tmp', "#{organization_code.downcase}_courses_#{Time.zone.now.to_i}.json")
      File.write(file_path, Oj.dump(crawl_courses, indent: 2, mode: :compat))

      puts "courses crawled results generate at: #{file_path}" if $PROGRAM_NAME =~ /rake$/
    end

    return unless crawler_record.save_to_db || options[:save_to_db]

    task = CrawlTask.create(organization_code: organization_code, course_year: year, course_term: term, type: :crawler)

    # insert each crawled course by its attributes
    ActiveRecord::Base.transaction do
      course_ids = crawl_courses.map do |crawl_course|
        course = Course.where(
          year: crawl_course[:year],
          term: crawl_course[:term],
          organization_code: organization_code,
          code: crawl_course[:code],
          lecturer: crawl_course[:lecturer],
          name: crawl_course[:name]
        ).first_or_initialize.tap do |new_course|
          crawl_course[:ucode] = "#{organization_code}-#{crawl_course[:code]}"
          crawl_course[:organization_code] = organization_code
          Course::COLUMN_NAMES.each { |column| new_course.send(:"#{column}=", crawl_course[column]) }
        end

        task.course_versions << course.versions.last if course.new_record?
        course.save!
        task.course_versions << course.versions.last if course.changed?

        course.id
      end

      Course.where(organization_code: organization_code, year: year, term: term).where.not(id: course_ids).each do |course|
        course.destroy!
        task.course_versions << course.versions.last
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
end
