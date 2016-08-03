# == Schema Information
#
# Table name: course_caches
#
#  id          :integer          not null, primary key
#  s3_url      :string
#  calendar_id :integer
#  year        :integer
#  term        :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

module Colorgy
  class CourseCache < ColorgyRecord
  end
end
