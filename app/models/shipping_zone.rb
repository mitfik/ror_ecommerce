class ShippingZone < ActiveRecord::Base
  has_many :shipping_methods
  has_many :states
  has_many :countries

  validates :name,            :presence => true,       :length => { :maximum => 255 }
  accepts_nested_attributes_for :states
  accepts_nested_attributes_for :countries

end
