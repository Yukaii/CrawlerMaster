class AddLastSyncAtToCrawlers < ActiveRecord::Migration
  def change
    add_column :crawlers, :last_sync_at, :datetime
  end
end
