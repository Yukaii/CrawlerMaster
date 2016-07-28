# == Schema Information
#
# Table name: courses
#
#  id                :integer          not null, primary key
#  organization_code :string           not null
#  department_code   :string
#  lecturer          :string           not null
#  year              :integer          not null
#  term              :integer          not null
#  name              :string           not null
#  code              :string           not null
#  general_code      :string           not null
#  ucode             :string
#  required          :boolean
#  credits           :integer
#  url               :string
#  name_en           :string
#  full_semester     :boolean
#  day_1             :integer
#  day_2             :integer
#  day_3             :integer
#  day_4             :integer
#  day_5             :integer
#  day_6             :integer
#  day_7             :integer
#  day_8             :integer
#  day_9             :integer
#  period_1          :integer
#  period_2          :integer
#  period_3          :integer
#  period_4          :integer
#  period_5          :integer
#  period_6          :integer
#  period_7          :integer
#  period_8          :integer
#  period_9          :integer
#  location_1        :string
#  location_2        :string
#  location_3        :string
#  location_4        :string
#  location_5        :string
#  location_6        :string
#  location_7        :string
#  location_8        :string
#  location_9        :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class Course < ActiveRecord::Base
  belongs_to :crawler, foreign_key: :organization_code, primary_key: :organization_code, counter_cache: true

  BASIC_COLUMNS = [
    :organization_code,
    :department_code,
    :lecturer,
    :year,
    :term,
    :name,
    :code,
    :general_code,
    :required
  ].freeze

  SCHEDULE_COLUMNS = [
    :day_1,
    :day_2,
    :day_3,
    :day_4,
    :day_5,
    :day_6,
    :day_7,
    :day_8,
    :day_9,
    :period_1,
    :period_2,
    :period_3,
    :period_4,
    :period_5,
    :period_6,
    :period_7,
    :period_8,
    :period_9,
    :location_1,
    :location_2,
    :location_3,
    :location_4,
    :location_5,
    :location_6,
    :location_7,
    :location_8,
    :location_9
  ].freeze

  ADDITIONAL_COLUMNS = [
    :credits,
    :url,
    :name_en,
    :full_semester
  ].freeze

  def self.inserted_column_names
    BASIC_COLUMNS + SCHEDULE_COLUMNS + ADDITIONAL_COLUMNS
  end
end
