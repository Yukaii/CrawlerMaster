module ColorgyConnection
  extend ActiveSupport::Concern

  included do
    establish_connection ActiveRecord::Base.configurations[Rails.env]['colorgy_main']
  end
end
