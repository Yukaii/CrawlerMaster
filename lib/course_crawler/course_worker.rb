##
# A general crawler containing worker class. Works for all classes of crawler.
# It would automatically lookup classes under "Crawler" module and call default
# execution method.
#
# Example:
#   CourseCrawler::CourseWorker.perform_async "NtustCourseCrawler", { year: 2015, term: 2 }
#
# The class CourseCrawler::Crawler::NtustCourseCrawler will be loaded and create an instance
# then call default method "courses".

module CourseCrawler
  class CourseWorker
    include Sidekiq::Worker
    include Mixin

    sidekiq_options retry: false

    def perform(crawler_name, options = {})
      crawler_klass = Crawlers.const_get(crawler_name)

      organization_code = crawler_name.match(/(.+?)CourseCrawler/)[1].upcase
      crawler_record    = Crawler.find_by(organization_code: organization_code)

      year = options[:year] || crawler_record.year || current_year
      term = options[:term] || crawler_record.term || current_term

      @crawler_klass_instance =
        crawler_klass.new(
          year:            year,
          term:            term,
          update_progress: options[:update_progress],
          after_each:      options[:after_each]
        )

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

      # Save course datas into database
      inserted_column_names = [:ucode] + Course.inserted_column_names + [:created_at, :updated_at]

      courses_inserts = courses.map do |course|
        course[:name] && course[:name].gsub!("'", "''")

        course[:lecturer] = course[:lecturer_name] || course[:lecturer] || ''
        course[:lecturer].gsub!("'", "''")

        course[:required] = course[:required].nil? ? 'FALSE' : course[:required]

        inserts = inserted_column_names[2..-3].map do |k|
          course[k].nil? ? 'NULL' : "'#{course[k]}'"
        end.join(', ')

        # 去頭去尾
        "( '#{organization_code}-#{course[:code]}', '#{organization_code}', #{inserts}, '#{Time.zone.now}', '#{Time.zone.now}' )"
      end

      sqls = courses_inserts.in_groups_of(500, false).map do |inserts|
        <<-eof
          INSERT INTO courses (#{inserted_column_names.join(', ')})
          VALUES #{inserts.join(', ')}
        eof
      end

      ActiveRecord::Base.transaction do
        Course.where(organization_code: organization_code, year: year, term: term).destroy_all
        sqls.map { |sql| ActiveRecord::Base.connection.execute(sql) }

        Rails.logger.info("#{crawler_name}: Succesfully save to database.")
      end

      crawler_record.update!(last_run_at: Time.zone.now)
    end
  end
end
