# inside app/models/colorgy directory is a set of model that connect to Colorgy main repo
# only borrow some essential functionality
class ColorgyRecord < ActiveRecord::Base
  include ColorgyConnection

  self.abstract_class = true
end
