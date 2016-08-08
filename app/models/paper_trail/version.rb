class PaperTrail::Version < ActiveRecord::Base
  has_many :course_task_relations, foreign_key: :version_id
  has_many :course_tasks, through: :course_task_relations, source: :crawl_task

  # a PaperTrail::Version would only have one corresponding course_task
  # we build many-to-many relationship in order not to ruin the PaperTrail database schema
  def course_task
    course_tasks.first
  end

  # delgate course_errors to relation object
  def course_errors
    course_task_relations.first.course_errors
  end

end
