module Colorgy
  class AttendanceShip < ColorgyRecord
    belongs_to :user,   class_name: '::Colorgy::User'
    belongs_to :course, class_name: '::Colorgy::Course', foreign_key: :schedule_id

    validates_uniqueness_of :user_id, :scope => [:schedule_id]
  end
end

# == Schema Information
#
# Table name: attendance_ships
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  schedule_id :integer
#  rsvp        :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_attendance_ships_on_user_id_and_schedule_id  (user_id,schedule_id) UNIQUE
#
