# == Schema Information
#
# Table name: calendars
#
#  id         :integer          not null, primary key
#  owner_id   :integer
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  owner_type :string
#  default    :boolean          default(FALSE)
#  data       :hstore
#
# Indexes
#
#  index_calendars_on_owner_id  (owner_id)
#
module Colorgy
  class Calendar < ColorgyRecord
    self.table_name = 'calendars'
  end
end
