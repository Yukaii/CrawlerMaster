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

require 'rails_helper'

RSpec.describe CourseError, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
