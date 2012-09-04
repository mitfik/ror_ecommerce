module PaymentSystem
  class CimGateway < ActiveMerchant::Billing::AuthorizeNetCimGateway
    # Gateway for payments in store
  end
end
