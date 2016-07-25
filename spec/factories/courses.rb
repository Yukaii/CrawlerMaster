# == Schema Information
#
# Table name: courses
#
#  id                :integer          not null, primary key
#  organization_code :string           not null
#  department_code   :string
#  lecturer          :string           not null
#  year              :integer          not null
#  term              :integer          not null
#  name              :string           not null
#  code              :string           not null
#  general_code      :string           not null
#  ucode             :string
#  required          :boolean
#  credits           :integer
#  url               :string
#  name_en           :string
#  full_semester     :boolean
#  day_1             :integer
#  day_2             :integer
#  day_3             :integer
#  day_4             :integer
#  day_5             :integer
#  day_6             :integer
#  day_7             :integer
#  day_8             :integer
#  day_9             :integer
#  period_1          :integer
#  period_2          :integer
#  period_3          :integer
#  period_4          :integer
#  period_5          :integer
#  period_6          :integer
#  period_7          :integer
#  period_8          :integer
#  period_9          :integer
#  location_1        :string
#  location_2        :string
#  location_3        :string
#  location_4        :string
#  location_5        :string
#  location_6        :string
#  location_7        :string
#  location_8        :string
#  location_9        :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

FactoryGirl.define do
  factory :course do
    organization_code "MyString"
department_code "MyString"
lecturer_name "MyString"
year 1
term 1
name "MyString"
code "MyString"
general_code "MyString"
ucode "MyString"
required false
  end

end
