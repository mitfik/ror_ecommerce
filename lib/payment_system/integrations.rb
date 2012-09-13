module PaymentSystem
  module Integrations

    # Integration for payments in store
    # Object which should implement 

    # Should return valid url where user should be redirect
    def self.setup_purchase(params)
      result = PaymentSystem.gateway.setup_purchase(params)
      if result["TransactionId"]
        return ActiveMerchant::Billing::Integrations::Netaxept.generate_terminal_url(result["TransactionId"], Settings.payments_system.gateway.login)
      else
        return nil
      end
    end


    # Provide terminal url for given invoice
    # last payment?
    def self.terminal_url(invoice)
      transactionId = invoice.payments.last.params["TransactionId"]
      return ActiveMerchant::Billing::Integrations::Netaxept.generate_terminal_url(transactionId, Settings.payments_system.gateway.login)
    end

    # Inform payment system to capture money
    def self.process_payment

    end

    # authorize payment 
    # figure out different between integration and gateway
    def self.authorize_payment(transaction)
    end

    # Try capture money for give transaction
    # return true or false
    def self.capture_payment(transaction)
      return false
    end

    def self.cancel_payment(transaction)
      return false
    end

    # In case if we need give back money to customer
    # return false or true
    def self.credit_payment(transaction)
      return false
    end

    # After user will pay or not we will get notification about that
    # this method handle response from payment system and return array with transaction id and boolean 
    # to inform if payment was successul
    def self.parse_replay(params)
      return [params[:transactionId], (params[:responseCode] == 'OK' ? true : false )]
    end
     
  end
end
