module PaymentSystem
  module Billing
    # TODO remove it 
    # Abstract module which is used for payments it should include
    # Billing::CreditCard
    # Billing::Gateway
    # TODO
    # Module should implement 
    # test? method to check if mode is set up for test
    # class Base with mode instance method
    include ActiveMerchant::Billing
  end
end
