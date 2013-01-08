class PaymentSystem

    attr_accessor :payment_method, :gateway, :cim_gateway

    def initialize(payment_method_id)
      @payment_method = PaymentSystem.get_payment_method(payment_method_id)
    end
    # Setup gateway and cim gateway for store
    # If you want to change one of those please read: https://github.com/mitfik/ror_ecommerce/wiki/Payments
    # Depends on the environment which will be used Settings will load proper credentials
    # except test env because we load different Gateway class (GatewayTest) see config/environments/test.rb

    def gateway
      PaymentSystem::Base.mode = payment_method.gateway_mode.to_sym
      if Rails.env.test?
        # TODO replace by something not from ActiveMerchant
        return ActiveMerchant::Billing::BogusGateway.new
      else
        return eval(payment_method.gateway_class_name).new(payment_method.gateway.to_hash)
      end
    end

    def integrations
      # TODO think if we need integration at all ? because most those things will be in gateway any way
      eval payment_method.integration_class_name
    end

    def cim_gateway
      # TODO not implemented
      raise NotImplementedError
    end

    # Base on that what payment method do you use and it should be in payment method class
    def prepare_options_for_gateway(options = {})
      order = options[:order]
      redirect_url = options[:redirect_url]
      {:redirectUrl => redirect_url, :currencyCode => payment_method.currency_code, :orderNumber => order.id }
    end

    def self.get_payment_method(payment_method_id)
      get_payment_methods.each do |payment_method|
        return payment_method if payment_method.id == payment_method_id.to_i
      end
      return nil
    end

    def self.get_default_payment_method
      get_payment_methods.each do |payment_method|
        return payment_method if payment_method.default
      end
    end

    def self.get_payment_methods
      Settings.payment_methods
    end

end
