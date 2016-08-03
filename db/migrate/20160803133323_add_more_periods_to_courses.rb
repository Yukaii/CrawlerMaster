class AddMorePeriodsToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :day_10, :integer
    add_column :courses, :day_11, :integer
    add_column :courses, :day_12, :integer
    add_column :courses, :day_13, :integer
    add_column :courses, :day_14, :integer
    add_column :courses, :day_15, :integer
    add_column :courses, :day_16, :integer
    add_column :courses, :day_17, :integer
    add_column :courses, :day_18, :integer
    add_column :courses, :day_19, :integer
    add_column :courses, :day_20, :integer

    add_column :courses, :period_10, :integer
    add_column :courses, :period_11, :integer
    add_column :courses, :period_12, :integer
    add_column :courses, :period_13, :integer
    add_column :courses, :period_14, :integer
    add_column :courses, :period_15, :integer
    add_column :courses, :period_16, :integer
    add_column :courses, :period_17, :integer
    add_column :courses, :period_18, :integer
    add_column :courses, :period_19, :integer
    add_column :courses, :period_20, :integer

    add_column :courses, :location_10, :string
    add_column :courses, :location_11, :string
    add_column :courses, :location_12, :string
    add_column :courses, :location_13, :string
    add_column :courses, :location_14, :string
    add_column :courses, :location_15, :string
    add_column :courses, :location_16, :string
    add_column :courses, :location_17, :string
    add_column :courses, :location_18, :string
    add_column :courses, :location_19, :string
    add_column :courses, :location_20, :string
  end
end
