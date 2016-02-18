require 'thread'
require 'thwait'
require 'set'

module CourseCrawler
  class CourseSyncWorker
    include Sidekiq::Worker
    sidekiq_options :retry => 1

    def perform opts={}
      org, year, term, class_name = opts["org"], opts["year"], opts["term"], opts["class_name"]
      return if !(org && year && term && class_name)

      api_put_columns = Course.inserted_column_names + [ :created_at, :updated_at ]
      crawler_model   = Crawler.find_by(organization_code: org)

      courses         = Course.where(organization_code: org, year: year, term: term)
      courses_count   = courses.count

      return if crawler_model.nil?

      threads      = []
      thread_limit = 10
      differences  = []
      error_keys   = Set.new

      courses.find_in_batches(batch_size: 200) do |courses|
        courses.map{|c| Hash[c.attributes.map{|k, v| [k.to_sym, v]}].slice(*api_put_columns) }.each_with_index do |course, index|

          sleep(1) until ( threads.delete_if { |t| !t.status }; threads.count < thread_limit )

          threads << Thread.new do
            r = RestClient.put("#{crawler_model.data_management_api_endpoint}/#{course[:code]}?key=#{crawler_model.data_management_api_key}",
                { "#{crawler_model.data_name}".to_sym => course }
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
        end # end courses.each_with_index
      end # end courses.find_in_batches

      ThreadsWait.all_waits(*threads)

      crawler_model.last_sync_at = Time.now
      crawler_model.save
    end
  end
end
