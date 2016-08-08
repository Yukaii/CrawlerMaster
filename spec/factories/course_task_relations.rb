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

FactoryGirl.define do
  factory :course_task_relation do
    version_id 1
    task_id 1
  end
end
