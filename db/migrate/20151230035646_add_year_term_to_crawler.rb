class AddYearTermToCrawler < ActiveRecord::Migration
  def change
    add_column :crawlers, :year, :integer
    add_column :crawlers, :term, :integer
  end
end
