module PaymentSystem::Base
  # TODO
  # Abstract module which is used for payments it should include
  # Billing::CreditCard
  # Billing::Gateway
  # TODO
  # Module should implement
  # test? method to check if mode is set up for test
  # class Base with mode instance method

  mattr_accessor :gateway_mode
  mattr_accessor :integration_mode
  # set both mode in the same time
  mattr_reader :mode


  def self.mode=(mode)
    @@mode = mode
    self.gateway_mode = mode
    self.integration_mode = mode
  end

  self.mode = :test # by default we set both on test mode

  # A check to see if we're in test mode
  def self.test?
    self.gateway_mode == :test
  end

  def self.production?
    self.gateway_mode == :production
  end
end
