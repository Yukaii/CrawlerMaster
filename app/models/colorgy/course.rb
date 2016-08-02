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
module Colorgy
  class Course < Schedule
    store_accessor :data, :course_year, :course_term, :course_lecturer,
                   :course_credits, :course_url, :course_required, :course_code, :period_string,
                   :course_notes, :course_type

    has_many       :sub_courses, foreign_key: :root_schedule_id, class_name: 'Colorgy::Course', dependent: :destroy
    belongs_to     :calendar, class_name: 'Colorgy::Calendar'

    accepts_nested_attributes_for :sub_courses, allow_destroy: true

    def check_course_type
      if calendar.owner_type == 'Organization'
        'official'
      elsif calendar.owner_type == 'User'
        if reference_id.nil?
          'custom'
        else
          'modified'
        end
      end
    end

    def flatten_with_sub_courses
      [self] + sub_courses
    end

    # Overwrite default sti behavior
    # http://stackoverflow.com/questions/23293177/rails-sti-how-to-change-mapping-between-class-name-value-of-the-type-column
    class << self
      def find_sti_class(type_name)
        type_name = name
        super
      end

      def sti_name
        name.demodulize
      end
    end
  end
end
