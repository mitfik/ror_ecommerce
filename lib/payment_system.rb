module PaymentSystem
  mattr_accessor :gateway_object
  mattr_accessor :cimgateway_object

    # Setup gateway and cim gateway for store
    # If you want to change one of those please read: https://github.com/drhenner/ror_ecommerce/wiki/Payments
    # Depends on the environment which will be used Settings will load proper credentials
    # except test env because we load different Gateway class (GatewayTest) see config/environments/test.rb
    def self.gateway 
      PaymentSystem::Billing::Base.mode = Settings.payments_system.gateway_mode.to_sym
      return gateway_object || gateway_object = PaymentSystem::Gateway.new(Settings.payments_system.gateway.to_hash) unless Rails.env.test?
      return gateway_object || gateway_object = ActiveMerchant::Billing::BogusGateway.new if Rails.env.test?
    end

    def self.cim_gateway
      return cimgateway_object || cimgateway_object = PaymentSystem::CimGateway.new(Settings.payments_system.cim_gateway.to_hash)
    end
end
