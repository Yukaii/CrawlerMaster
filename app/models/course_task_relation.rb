# == Schema Information
#
# Table name: course_task_relations
#
#  id         :integer          not null, primary key
#  version_id :integer
#  task_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_course_task_relations_on_task_id                 (task_id)
#  index_course_task_relations_on_task_id_and_version_id  (task_id,version_id) UNIQUE
#  index_course_task_relations_on_version_id              (version_id)
#


class CourseTaskRelation < ActiveRecord::Base
  belongs_to :version, class_name: 'PaperTrail::Version', foreign_key: :version_id
  belongs_to :crawl_task, foreign_key: :task_id
end
