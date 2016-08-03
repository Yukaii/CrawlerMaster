# == Schema Information
#
# Table name: courses
#
#  id                :integer          not null, primary key
#  organization_code :string           not null
#  department_code   :string
#  lecturer          :string
#  year              :integer          not null
#  term              :integer          not null
#  name              :string
#  code              :string
#  general_code      :string
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
#  day_10            :integer
#  day_11            :integer
#  day_12            :integer
#  day_13            :integer
#  day_14            :integer
#  day_15            :integer
#  day_16            :integer
#  day_17            :integer
#  day_18            :integer
#  day_19            :integer
#  day_20            :integer
#  period_10         :integer
#  period_11         :integer
#  period_12         :integer
#  period_13         :integer
#  period_14         :integer
#  period_15         :integer
#  period_16         :integer
#  period_17         :integer
#  period_18         :integer
#  period_19         :integer
#  period_20         :integer
#  location_10       :string
#  location_11       :string
#  location_12       :string
#  location_13       :string
#  location_14       :string
#  location_15       :string
#  location_16       :string
#  location_17       :string
#  location_18       :string
#  location_19       :string
#  location_20       :string
#
# Indexes
#
#  index_courses_on_code               (code)
#  index_courses_on_general_code       (general_code)
#  index_courses_on_organization_code  (organization_code)
#  index_courses_on_required           (required)
#  index_courses_on_term               (term)
#  index_courses_on_ucode              (ucode)
#  index_courses_on_year               (year)
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
