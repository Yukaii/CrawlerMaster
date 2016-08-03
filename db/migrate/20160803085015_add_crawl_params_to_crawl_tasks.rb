class AddCrawlParamsToCrawlTasks < ActiveRecord::Migration
  def change
    add_column :crawl_tasks, :course_year,       :integer
    add_column :crawl_tasks, :course_term,       :integer
    add_column :crawl_tasks, :organization_code, :string

    add_index  :crawl_tasks, :course_year
    add_index  :crawl_tasks, :course_term
    add_index  :crawl_tasks, :organization_code
  end
end
