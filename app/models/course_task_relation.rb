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
  include CourseValidationConcern

  belongs_to :version, class_name: 'PaperTrail::Version', foreign_key: :version_id
  belongs_to :crawl_task, foreign_key: :task_id

  has_many   :course_errors, foreign_key: :relation_id, dependent: :destroy

  after_create :validate_course

  # it's not ActiveRecord Validation as we do not prevent creating a new record
  # when validation failed. And CourseError is assosiate with CourseTaskRelation
  # model because we perform check on each PaperTrail::Version.
  def validate_course
    course_snapshot = version.reify.nil? ? version.item : version.reify

    course_errors.create(type: :invalid_name)     unless name_valid?(course_snapshot)
    course_errors.create(type: :invalid_lecturer) unless lecturer_valid?(course_snapshot)
    course_errors.create(type: :invalid_required) unless required_valid?(course_snapshot)
    course_errors.create(type: :invalid_credits)  unless credits_valid?(course_snapshot)

    course_errors.create(type: :empty_day) if course_snapshot.day_1.nil?
    course_errors.create(type: :empty_period) if course_snapshot.period_1.nil?
    course_errors.create(type: :empty_location) if course_snapshot.location_1.nil?

    course_errors.create(type: :only_one_period) if course_snapshot.day_2.nil? || course_snapshot.period_2.nil? || course_snapshot.location_2.nil?
  end
end
