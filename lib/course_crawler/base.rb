##
# general crawler methods
#
require 'rest-client'
require 'thwait'
require 'thread'

module CourseCrawler
  class Base
    include DateMixin

    attr_reader   :year, :term
    attr_accessor :worker, :period_set

    def set_progress(progress)
      Sidekiq.redis do |conn|
        conn.set(progress_key, progress)
      end
    end

    def job_id
      worker && worker.jid.to_s
    end

    def progress_key
      "progress:#{self.class}_#{job_id}"
    end

    def http_client
      return @http_clnt if @http_clnt

      @http_clnt = HTTPClient.new
      @http_clnt.send_timeout = 1800
      @http_clnt.receive_timeout = 1800
      @http_clnt
    end

    def power_strip(str)
      str.strip.gsub(/^[ |\s]*|[ |\s]*$/, '')
    end
  end
end
