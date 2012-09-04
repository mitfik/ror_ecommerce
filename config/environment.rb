# Load the rails application
require File.expand_path('../application', __FILE__)
require File.expand_path('../../lib/printing/invoice_printer', __FILE__)

Paperclip.options[:command_path] = "/usr/local/bin"

# Initialize the rails application
Hadean::Application.initialize!
Hadean::Application.configure do 
  config.after_initialize do
    unless Settings.encryption_key
      raise "
      ############################################################################################
      !  You need to setup the settings.yml
      !  copy settings.yml.example to settings.yml
      !
      !  Make sure you personalize the passwords in this file and for security never check this file in.
      ############################################################################################
      "
    end

    # Setup gateway and cim gateway for store
    # If you want to change one of those please read: https://github.com/drhenner/ror_ecommerce/wiki/Payments
    # Depends on the environment which will be used Settings will load proper credentials
    # except test env because we load different Gateway class (GatewayTest) see config/environments/test.rb
    PaymentSystem::GATEWAY = PaymentSystem::Gateway.new(Settings.payments_system.gateway.to_hash) unless Rails.env.test?
    PaymentSystem::CIMGATEWAY = PaymentSystem::CimGateway.new(Settings.payments_system.cim_gateway.to_hash)
  end
end
