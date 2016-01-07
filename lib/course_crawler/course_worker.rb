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
    sidekiq_options :retry => 1

    def perform *args
      klass = Crawlers.const_get args[0]

      org = args[0].match(/(.+?)CourseCrawler/)[1].upcase
      crawler_model = Crawler.find_by(organization_code: org)

      year = args[1][:year] || crawler_model.year || (Time.now.month.between?(1, 7) ? Time.now.year - 1 : Time.now.year)
      term = args[1][:term] || crawler_model.term || (Time.now.month.between?(2, 7) ? 2 : 1)

      @klass_instance =
        klass.new(
          year: year,
          term: term,
          update_progress: args[1][:update_progress],
          after_each: args[1][:after_each]
        )

      @klass_instance.worker = self
      courses = @klass_instance.courses

      # maybe we should throw an exception?
      return if courses.empty?

      # Save course datas into database
      inserted_column_names = [:ucode] + Course.inserted_column_names + [ :created_at, :updated_at ]

      courses_inserts = courses.map do |c|
        c[:name] && c[:name].gsub!("'", "''")
        c[:lecturer_name] = c[:lecturer_name] || c[:lecturer] || ""
        c[:lecturer_name].gsub!("'", "''")

        c[:required] = c[:required].nil? ? "NULL" : c[:required]

        # 去頭去尾
        "( '#{org}-#{c[:code]}', '#{org}', #{
          inserted_column_names[2..-3].map do |k|
            c[k].nil? ? "NULL" : "'#{c[k]}'"
          end.join(', ')
        }, '#{Time.now}', '#{Time.now}' )"
      end

      sqls = courses_inserts.in_groups_of(500, false).map { |cis|
        <<-eof
          INSERT INTO courses (#{inserted_column_names.join(', ')})
          VALUES #{cis.join(', ')}
        eof
      }

      # sql = <<-eof
      #   INSERT INTO courses (#{inserted_column_names.join(', ')})
      #   VALUES #{courses_inserts.join(', ')}
      # eof

      if crawler_model.save_to_db
        ActiveRecord::Base.transaction {
          Course.where(organization_code: org, year: year, term: term).destroy_all
          sqls.map{|sql| ActiveRecord::Base.connection.execute(sql) }

          Rails.logger.info("#{args[0]}: Succesfully save to database.")
        }
      end

      ## Sync to Core
      if crawler_model.sync
        crawler_model.sync_to_core(year, term)
      end

    end
  end
end
