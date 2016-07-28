# == Schema Information
#
# Table name: rufus_jobs
#
#  id         :integer          not null, primary key
#  jid        :string
#  crawler_id :integer
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  original   :string
#

require 'rails_helper'

RSpec.describe RufusJob, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
