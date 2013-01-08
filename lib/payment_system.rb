class PaymentSystem

  # PaymentSystem class is used for handling all communication between store
  # and any payment system. The class should be enough flexible to implement
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
      return PaymentSystem::Gateway.new(payment_method.gateway.to_hash)
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


  def self.get_payment_method(payment_method_id)
    get_payment_methods.each do |payment_method|
      return payment_method if payment_method.id == payment_method_id.to_i
    end
    return nil
  end

  # Find out which payment method is set as default one.
  def self.get_default_payment_method
    get_payment_methods.each do |payment_method|
      return payment_method if payment_method.default
    end
  end

  # Get all payment methods defined in settings
  # See settings.yml.example for details.
  def self.get_payment_methods
    Settings.payment_methods
  end

end
