# == Schema Information
#
# Table name: organizations
#
#  id         :integer          not null, primary key
#  code       :string
#  name       :string
#  short_name :string
#  enabled    :boolean          default(TRUE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_organizations_on_code  (code) UNIQUE
#
module Colorgy
  class Organization < ColorgyRecord
    self.table_name = 'organizations'
  end
end
