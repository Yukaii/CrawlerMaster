# Sample Usage:
# => CourseImportJob.perform_later('YM', 2016, 1)
class CourseImportJob < ActiveJob::Base
  queue_as :default

  def perform(*args)
    Course.import_to_course(*args)
  end
end
