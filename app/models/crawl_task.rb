# == Schema Information
#
# Table name: crawl_tasks
#
#  id          :integer          not null, primary key
#  type        :integer          default(0), not null
#  finished_at :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_crawl_tasks_on_type  (type)
#

class CrawlTask < ActiveRecord::Base
  has_many :course_task_relations, foreign_key: :task_id
  has_many :course_versions, through: :course_task_relations, source: :version

  enum type: [:crawler, :import]

  self.inheritance_column = :_type_disabled
end
