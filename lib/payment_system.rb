class PaymentSystem
  include ActionView::Helpers
  include ActionDispatch::Routing
  include Rails.application.routes.url_helpers

  def default_url_options
    ActionMailer::Base.default_url_options
  end

  # PaymentSystem class is used for handling all communication between store
  # and payment provider. The class should be enough flexible to implement
  # any payment system.

  attr_accessor :payment_method, :gateway, :cim_gateway

  def initialize(payment_method_id)
    @payment_method = PaymentSystem.get_payment_method(payment_method_id)
  end

  # Setup the gateway and the cim gateway for the store
  # More information about it you can find here:
  # https://github.com/mitfik/ror_ecommerce/wiki/Payments
  # Depends on the rails environment Settings will load proper credentials.

  def gateway
    PaymentSystem::Base.mode = payment_method.gateway_mode.to_sym
    if Rails.env.test?
      return PaymentSystem::TestGateway.new
    else
      klass = eval(payment_method.gateway_class_name)
      return klass.new(payment_method.gateway.to_hash)
    end
  end

  # TODO documetation
  def integrations
    eval payment_method.integration_class_name
  end

  def cim_gateway
    # TODO not implemented
    raise NotImplementedError
  end

  # TODO those methods are used in external terminal process flow
  # Move to integration ?
  # Prepare all necessary options for your payment gateway.
  # See:
  # TODO Documentation
  def prepare_options_for_gateway(options = {})
    order = options[:order]
    {:redirectUrl => replay_shopping_orders_url, :currencyCode => payment_method.currency_code, :orderNumber => order.id }
  end

  def prepare_options_for_authorization(options = {})
    order = options[:order]
    {:transactionId => order.confirmation_id }
  end

  class << self

    # Fetch payment method from settings by id
    def get_payment_method(payment_method_id)
      get_payment_methods.each do |payment_method|
        return payment_method if payment_method.id == payment_method_id.to_i
      end
      raise PaymentSystem::Error::InvalidPaymentMethodId
    end

    # Find out which payment method is set as default one.
    # if none then default one is the first one.
    def get_default_payment_method
      get_payment_methods.each do |payment_method|
        return payment_method if payment_method.default
      end
      return get_payment_methods.first
    end

    # Get all payment methods defined in settings
    # See settings.yml.example for details.
    def get_payment_methods
      Settings.payment_methods
    end
  end
end
