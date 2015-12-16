##
# A few general crawler methods
#
require 'rest-client'
require 'thwait'
require 'thread'

module CourseCrawler
  class Base
    include Mixin
    attr_accessor :worker

    def set_progress progress
      Sidekiq.redis do |conn|
        conn.set(progress_key, progress)
      end
    end

    def job_id
      "#{worker.jid}"
    end

    def progress_key
      "progress:#{self.class}_#{job_id}"
    end

  end
end
