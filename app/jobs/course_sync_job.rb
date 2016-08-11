require 'thread'
require 'thwait'
require 'set'

class CourseSyncJob
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(*args)
    Course.import_to_course(*args)

    CourseCacheGenerateJob.perform_later(*args)
  end
end
