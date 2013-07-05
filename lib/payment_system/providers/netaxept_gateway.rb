class PaymentSystem::Providers::NetaxeptGateway

    def initialize(options = {})
      super options
      # Set mode: test or production
      ActiveMerchant::Billing::Base.mode = PaymentSystem::Base.mode
    end

    def cancel(confirmation_id, options = {})
      void(confirmation_id, options)
    end

    class << self
      # After user will pay or not we will get notification about that
      # this method handle response from payment system and return array with transaction id and boolean
      # to inform if payment was successul
      def parse_replay(params)
        return [params[:transactionId], (params[:responseCode] == 'OK' ? true : false )]
      end

      # Provides terminal url for given invoice
      # last payment?
      def terminal_url(payment)
        transactionId = payment.params["TransactionId"]
        payment_system = PaymentSystem.new(payment.payment_method_id)
        return payment_system.integrations.generate_terminal_url(transactionId, payment_system.payment_method.gateway.login)
      end
    end
end
