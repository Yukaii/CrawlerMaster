# == Schema Information
#
# Table name: crawl_tasks
#
#  id                :integer          not null, primary key
#  type              :integer          default(0), not null
#  finished_at       :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  course_year       :integer
#  course_term       :integer
#  organization_code :string
#
# Indexes
#
#  index_crawl_tasks_on_course_term        (course_term)
#  index_crawl_tasks_on_course_year        (course_year)
#  index_crawl_tasks_on_organization_code  (organization_code)
#  index_crawl_tasks_on_type               (type)
#

FactoryGirl.define do
  factory :crawl_task do
    type 1
    started_at "2016-08-03 16:07:28"
    finished_at "2016-08-03 16:07:28"
  end
end
