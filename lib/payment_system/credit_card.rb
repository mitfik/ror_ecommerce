module PaymentSystem
  class CreditCard < ActiveMerchant::Billing::CreditCard
    # You can implement own logic for CreditCard instead of inherited from ActiveMerchant::Billing::CreditCard
    #
    #
    # must be implemented:
    # def new to create object with parameters
    # def valid? method return true or false
    # TODO
  end
end
