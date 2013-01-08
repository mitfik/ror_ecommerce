class PaymentSystem::Gateway < ActiveMerchant::Billing::NetaxeptGateway
    # template to reuse
    # Gateway for payments in store
    # Object which should implement
    #
    # setup_purchase
    # setup_authorization
    #
    # def register
    #   # register new transaction and prepare terminal url before user will be redirect to terminal
    # end
    #
    # auth
    # capture
    # cancel
    def initialize(options = {} )
      parameters = prepare_options_for_gateway(options)
      super parameters
      ActiveMerchant::Billing::Base.mode = PaymentSystem::Base.mode
    end


    private
      # Prepare all necessary options for your payment gateway.
      # See:
      def prepare_options_for_gateway(options = {})
        # TODO move that to NetaxeptIntegration
        order = options[:order]
        {:redirectUrl => PaymentSystem::Integrations.replay_url, :currencyCode => payment_method.currency_code, :orderNumber => order.id }
      end
end
