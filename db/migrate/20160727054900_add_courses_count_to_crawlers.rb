class AddCoursesCountToCrawlers < ActiveRecord::Migration
  def up
    add_column :crawlers, :courses_count, :integer

    say_with_time 'Updating courses counter cache......' do
      Crawler.reset_column_information

      Crawler.all.find_each do |crawler|
        Crawler.reset_counters(crawler.id, :courses)
      end
    end
  end

  def down
    remove_column :crawlers, :courses_count
  end
end
