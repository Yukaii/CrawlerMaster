class AddLastRunAtToCrawlers < ActiveRecord::Migration
  def up
    add_column :crawlers, :last_run_at, :datetime

    say_with_time 'updating crawler last_run_at...' do
      Crawler.reset_column_information

      Crawler.all.find_each do |crawler|
        crawler.courses.last && crawler.update(last_run_at: crawler.courses.last.updated_at)
      end
    end
  end

  def down
    remove_column :crawlers, :last_run_at
  end
end
