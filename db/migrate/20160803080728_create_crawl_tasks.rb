class CreateCrawlTasks < ActiveRecord::Migration
  def change
    create_table :crawl_tasks do |t|
      t.integer :type, null: false, default: 0
      t.datetime :finished_at

      t.timestamps null: false
    end

    add_index :crawl_tasks, :type
  end
end
