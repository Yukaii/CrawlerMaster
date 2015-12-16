class AddDescriptionToCrawlers < ActiveRecord::Migration
  def change
    add_column :crawlers, :description, :string
  end
end
