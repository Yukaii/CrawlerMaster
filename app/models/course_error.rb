# == Schema Information
#
# Table name: course_errors
#
#  id          :integer          not null, primary key
#  type        :integer
#  message     :string
#  relation_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class CourseError < ActiveRecord::Base
  self.inheritance_column = :_type_disabled

  belongs_to :course_task_relation, foreign_key: :relation_id

  enum type: [
    # some required field for course
    :invalid_lecturer,
    :invalid_name,
    :invalid_required,
    :invalid_credits,

    # no period no course(?)
    :empty_day,
    :empty_period,
    :empty_location,

    # most of the course a least have two periods
    :only_one_period
  ]

  validates :type, presence: true
end
