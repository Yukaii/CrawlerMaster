# == Schema Information
#
# Table name: organizations
#
#  id                            :integer          not null, primary key
#  code                          :string
#  name                          :string
#  short_name                    :string
#  enabled                       :boolean          default(TRUE), not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  user_school_system_data_count :integer          default(0)
#
# Indexes
#
#  index_organizations_on_code  (code) UNIQUE
#

module Colorgy
  class Organization < ColorgyRecord
    self.table_name = 'organizations'
    has_many :users, class_name: '::Colorgy::User', primary_key: :code, foreign_key: :organization_code
    has_many :user_school_system_data, class_name: '::Colorgy::UserSchoolSystemDatum'
  end
end
