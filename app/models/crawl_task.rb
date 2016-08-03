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

class CrawlTask < ActiveRecord::Base
  has_many :course_task_relations, foreign_key: :task_id
  has_many :course_versions, through: :course_task_relations, source: :version

  belongs_to :crawler, foreign_key: :organization_code, primary_key: :organization_code

  enum type: [:crawler, :import]

  validates :organization_code, presence: true

  self.inheritance_column = :_type_disabled
end
