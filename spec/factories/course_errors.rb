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

FactoryGirl.define do
  factory :course_error do
    type 1
    message "MyString"
    relation_id ""
  end
end
