require 'sidekiq/api'

module CourseCrawler
  module SidekiqHelper
    # A helper method that can get crawler progress by jid and crawler class name(in String)
    #   Example
    # => CourseCrawler.get_progress "NtustCourseCrawler", "56e8ce29fed9667aa81490e1"
    #
    # You can also pass jid as array too:
    # => CourseCrawler.get_progress "NtustCourseCrawler", ["56e8ce29fed9667aa81490e1", "JID-55eec3cc4c4e143e9d3a7aca"]
    def get_progress(class_name, jid = [])
      klass = const_get(class_name)

      if jid.is_a?(Array)
        Sidekiq.redis { |conn| jid.map { |id| conn.get("progress:#{klass}_#{id}") } }
      else
        Sidekiq.redis { |conn| conn.get("progress:#{klass}_#{jid}") }
      end
    end

    def find_workers(name)
      Sidekiq::Workers.new.select { |_process_id, _thread_id, work| work['payload']['args'][0] == name }
    end

    def find_queued_jobs(name)
      Sidekiq::Queue.new('name').select { |queue| queue.item['args'][0] == name }
    end

  end
end
