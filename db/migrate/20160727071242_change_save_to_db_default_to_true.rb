class ChangeSaveToDbDefaultToTrue < ActiveRecord::Migration
  def change
    change_column_default :crawlers, :save_to_db, true
  end
end
