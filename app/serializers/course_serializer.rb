# == Schema Information
#
# Table name: schedules
#
#  id               :integer          not null, primary key
#  type             :string
#  name             :string
#  color_hex        :string
#  description      :text
#  owner_id         :integer
#  location         :text
#  root_schedule_id :integer
#  start_time       :datetime
#  end_time         :datetime
#  rrule            :text
#  data             :hstore
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  calendar_id      :integer
#  reference_id     :integer
#
# Indexes
#
#  index_schedules_on_calendar_id       (calendar_id)
#  index_schedules_on_data              (data)
#  index_schedules_on_owner_id          (owner_id)
#  index_schedules_on_reference_id      (reference_id)
#  index_schedules_on_root_schedule_id  (root_schedule_id)
#  index_schedules_on_type              (type)
#

class CourseSerializer < ActiveModel::Serializer
  attribute :id
  attribute :name
  attribute :description
  attribute :color_hex
  attribute :location
  attribute :start_time
  attribute :end_time
  attribute :rrule

  attribute :course_year
  attribute :course_term
  attribute :course_lecturer
  attribute :course_credits
  attribute :course_url
  attribute :course_required
  attribute :course_code
  attribute :period_string
  attribute :course_notes
  attribute :course_type

  attribute :calendar_id
  attribute :reference_id
  attribute :root_schedule_id

  attribute :created_at
  attribute :updated_at

  def course_type
    object.course_type || object.check_course_type
  end

end
