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

FactoryGirl.define do
  factory :rufus_job do
    jid "MyString"
crawler_id 1
  end

end
