class Course < ActiveRecord::Base
  belongs_to :crawler, foreign_key: :organization_code, primary_key: :organization_code

  BASIC_COLUMNS = [ :organization_code, :department_code, :lecturer, :year, :term, :name, :code, :general_code, :required ]

  SCHEDULE_COLUMNS = [ :day_1, :day_2, :day_3, :day_4, :day_5, :day_6, :day_7, :day_8, :day_9, :period_1, :period_2, :period_3, :period_4, :period_5, :period_6, :period_7, :period_8, :period_9, :location_1, :location_2, :location_3, :location_4, :location_5, :location_6, :location_7, :location_8, :location_9 ]

  ADDITIONAL_COLUMNS = [ :credits, :url, :name_en, :full_semester ]

  def self.inserted_column_names
    BASIC_COLUMNS + SCHEDULE_COLUMNS + ADDITIONAL_COLUMNS
  end
end
