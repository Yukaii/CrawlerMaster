module Colorgy
  class UserSchoolSystemDatum < ColorgyRecord
    self.table_name = 'user_school_system_data'
    belongs_to :user,         class_name: '::Colorgy::User'
    belongs_to :organization, class_name: '::Colorgy::Organization', counter_cache: true
    validates_inclusion_of :state, :in => %w(pending error success)
  end
end

# == Schema Information
#
# Table name: user_school_system_data
#
#  id                     :integer          not null, primary key
#  login_data             :string
#  hope_organization_code :string
#  user_id                :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  organization_id        :integer
#  state                  :string           default("pending")
#
# Indexes
#
#  index_user_school_system_data_on_organization_id  (organization_id)
#  index_user_school_system_data_on_user_id          (user_id)
#
