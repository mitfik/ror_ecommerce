module PaymentSystem
  class Gateway < ActiveMerchant::Billing::NetaxeptGateway
    # Gateway for payments in store
    # Object which should implement 
    #
    # setup_purchase
    # setup_authorization
    #
    # def register
    #   # prepare terminal url and all neccessary things before user will be send to termianl
    # end
    #
    # auth
    # capture
    # cancel
  end
end
