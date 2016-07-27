# == Schema Information
#
# Table name: crawlers
#
#  id                           :integer          not null, primary key
#  name                         :string
#  short_name                   :string
#  class_name                   :string
#  organization_code            :string
#  setting                      :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  data_management_api_endpoint :string
#  data_management_api_key      :string
#  data_name                    :string
#  save_to_db                   :boolean          default(FALSE)
#  sync                         :boolean          default(FALSE)
#  category                     :string
#  description                  :string
#  year                         :integer
#  term                         :integer
#  last_sync_at                 :datetime
#  courses_count                :integer
#  last_run_at                  :datetime
#

require 'rails_helper'

RSpec.describe Crawler, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
