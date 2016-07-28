class AddTestColumnsToCrawlers < ActiveRecord::Migration
  def change
    add_column :crawlers, :save_to_db, :boolean, default: false
    add_column :crawlers, :sync,       :boolean, default: false

    say_with_time 'udpating crawlers default setting...' do
      Crawler.all.find_each do |crawler|
        crawler.update!(save_to_db: false, sync: false)
      end
    end
  end
end
