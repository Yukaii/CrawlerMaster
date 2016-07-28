require 'thread'
require 'thwait'
require 'set'

module CourseCrawler
  class CourseSyncWorker
    include Sidekiq::Worker
    sidekiq_options :retry => 1

    def perform(opts={})
      org        = opts['org'],
      year       = opts['year']
      term       = opts['term']
      class_name = opts['class_name']

      return unless org && year && term && class_name

      api_put_columns = Course.inserted_column_names + [ :created_at, :updated_at ]
      crawler_model   = Crawler.find_by(organization_code: org)

      courses         = Course.where(organization_code: org, year: year, term: term)
      courses_count   = courses.count

      return if crawler_model.nil?

      threads      = []
      thread_limit = 10
      differences  = []
      error_keys   = Set.new

      courses.find_each.with_index do |course_record, index|
        course = Hash[course_record.attributes.map { |k, v| [k.to_sym, v] }].slice(*api_put_columns)

        sleep(1) until ( threads.delete_if { |t| !t.status }; threads.count < thread_limit )

        threads << Thread.new do
          r = RestClient.put(
            "#{crawler_model.data_management_api_endpoint}/#{course[:code]}?key=#{crawler_model.data_management_api_key}",
            :"#{crawler_model.data_name}" => course
          )

          updated_course = JSON.parse(r)

          # diff = Hash[*(
          # (updated_course.size > course.size) \
          #   ? updated_course.to_a - course.to_a \
          #   : course.to_a         - updated_course.to_a
          # ).flatten]

          # diff.keys.each{|k| error_keys << k }
          # differences << Hash[diff.keys.map do |k|
          #   [ k.to_s, [course[k], updated_course[k]] ]
          # end].concat(["course_id", course.id])

          # Sidekiq.redis do |conn|
          #   conn.set("progress:#{class_name}_#{self.jid}", "syncing: #{index+1} / #{courses_count}")
          # end
        end # end Thread.new do
      end

      ThreadsWait.all_waits(*threads)

      crawler_model.last_sync_at = Time.zone.now
      crawler_model.save
    end
  end
end
