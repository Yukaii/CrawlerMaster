##
# A general crawler containing worker class. Works for all classes of crawler.
# It would automatically lookup classes under "Crawler" module and call default
# execution method.
#
# Example:
#   CourseCrawler::Worker.perform_async "NtustCourseCrawler", { year: 2015, term: 2 }
#
# The class CourseCrawler::Crawler::NtustCourseCrawler will be loaded and create an instance
# then call default method "courses".

module CourseCrawler
  class Worker
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

      sql = <<-eof
        INSERT INTO courses (#{inserted_column_names.join(', ')})
        VALUES #{courses_inserts.join(', ')}
      eof

      if crawler_model.save_to_db
        ActiveRecord::Base.transaction {
          Course.where(organization_code: org, year: year, term: term).destroy_all
          ActiveRecord::Base.connection.execute(sql)

          Rails.logger.info("#{args[0]}: Succesfully save to database.")
        }
      end

      ## Sync to Core
      # get crawler settings
      api_put_columns = (Course.inserted_column_names + [ :created_at, :updated_at ])

      http_client = HTTPClient.new

      courses = Course.where(organization_code: org, year: year, term: term)
      courses_count = courses.count

      # execute sync
      if crawler_model.sync
        courses.find_in_batches(batch_size: 200) do |courses|
          courses.map{|c| Hash[c.attributes.map{|k, v| [k.to_sym, v]}].slice(*api_put_columns) }.each_with_index do |course, index|

            http_client.put("#{crawler_model.data_management_api_endpoint}/#{course[:code]}?key=#{crawler_model.data_management_api_key}",
              { crawler_model.data_name => course }
            )

            @klass_instance.set_progress("syncing: #{index+1} / #{courses_count}")
          end # end courses.each_with_index
        end # end courses.find_in_batches
      end # end if crwaler_model.sync

    end
  end
end
