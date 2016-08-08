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

require 'rails_helper'

RSpec.describe CourseTaskRelation, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
