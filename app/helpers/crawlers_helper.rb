module CrawlersHelper
  def course_versions_count(task)
    task.course_versions.size
  end

  def error_course_versions_count(task)
    task.select_course_versions(true).size
  end
end
