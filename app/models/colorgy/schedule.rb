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
  class Schedule < ColorgyRecord
    self.table_name = 'schedules'

    scope :root, -> { where(root_schedule_id: nil) }
  end
end
