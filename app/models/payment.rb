# == Schema Information
#
# Table name: payments
#
#  id              :integer(4)      not null, primary key
#  invoice_id      :integer(4)
#  confirmation_id :string(255)
#  amount          :integer(4)
#  error           :string(255)
#  error_code      :string(255)
#  message         :string(255)
#  action          :string(255)
#  params          :text
#  success         :boolean(1)
#  test            :boolean(1)
#  created_at      :datetime
#  updated_at      :datetime
#  payment_method_id :integer(4)
#

class Payment < ActiveRecord::Base
  belongs_to :invoice

  serialize :params

  validates :amount,      :presence => true
  validates :invoice_id,  :presence => true

  def capture_cim
    @gateway = PaymentSystem.gateway

    response = @gateway.create_customer_profile_transaction({:transaction => {
                           :type                        => :auth_capture,
                           :amount                      => self.invoice.amount.to_s,
                           :customer_profile_id         => self.invoice.order.user.customer_cim_id,
                           :customer_payment_profile_id => self.invoice.order.user.payment_profile.payment_cim_id}})

    if response.success? and response.authorization
      update_attributes({:confirmation_id => response.authorization})
      return true
    else
      update_attributes({:error => !response.success?,
                         :error_code => response.params['messages']['message']['code'],
                         :error_message => response.params['messages']['message']['text']})
      return false
    end
  end

  def payment_method
    PaymentSystem.get_payment_method(self.payment_method_id)
  end

  def payment_method=(payment_method)
    self.payment_method_id = payment_method.id
  end

  # Authorize payment after registration and verification from payment system
  # Scenario with external terminal where we have already invoice and payment
  # objects
  def authorize
    payment_system = PaymentSystem.new(payment_method_id)
    result = payment_system.gateway.authorize(nil, nil, {:transactionId => confirmation_id})
    invoice.payment_authorized! if result.success?
    result.success?
  end


  class << self

      def store( credit_card, options = {})
        options[:order_id] ||= unique_order_number
        process( 'store' ) do |gw|
          gw.store( credit_card, options )
        end
      end

      def unstore( profile_key, options = {})
        options[:order_id] ||= unique_order_number
        process( 'unstore' ) do |gw|
          gw.unstore( profile_key, options )
        end
      end

      def authorize(amount, credit_card, options = {})
        process('authorization', amount) do |gw|
          gw.authorize(amount, credit_card, options)
        end
      end

      # Register transaction, prepare everything before we will proceed payment
      def register(amount, order, payment_method_id)
        process('registration', order, amount, payment_method_id) do |gw, options|
          gw.register(amount, options)
        end
      end

      def capture(amount, authorization, order)
        process('capture', order, amount, payment_method_id) do |gw|
          gw.capture(amount, authorization, order)
        end
      end

      def charge( amount, profile_key, options ={})
        options[:order_id] ||= unique_order_number
        # TODO refactor this code
        if PaymentSystem.gateway.respond_to?(:purchase)
          process( 'charge', amount ) do |gw|
            gw.purchase( amount, profile_key, options )
          end
        else
          # do it in 2 transactions
          process( 'charge', amount ) do |gw|
            result = gw.authorize( amount, profile_key, options )
            if result.success?
              gw.capture( amount, result.reference, options )
            else
              result
            end
          end
        end
      end

      # validate card via transaction
      def validate_card( credit_card, options ={})
        options[:order_id] ||= unique_order_number
        # authorize $1
        amount = 100
        result = process( 'validate', amount ) do |gw|
          gw.authorize( amount, credit_card, options )
        end
        if result.success?
          # void it
          result = process( 'validate' ) do |gw|
            gw.void( result.reference, options )
          end
        end
        result
      end

    private

      def unique_order_number
        "#{Time.now.to_i}-#{rand(1_000_000)}"
      end

      def process(action, order, amount = nil, payment_method_id)
        payment_system = PaymentSystem.new(payment_method_id)
        options = {:order => order, :redirect_url => PaymentSystem::Integrations.replay_url }
        parameters = payment_system.prepare_options_for_gateway(options)
        result = Payment.new(:payment_method_id => payment_method_id)

        result.amount = (amount && !amount.integer?) ? (amount * 100).to_i : amount
        result.action = action
          begin
            response          = yield payment_system.gateway, parameters
            result.success    = response.success?
            result.confirmation_id  = response.authorization
            result.message    = response.message
            result.params     = response.params
            result.test       = response.test?
          # TODO remove this typical for AM error type
          rescue ActiveMerchant::ActiveMerchantError => e
            #puts e
            result.success = false
            result.confirmation_id = nil
            result.message = e.message
            result.params = {}
            result.test = PaymentSystem.gateway.test?
          end
        result
      end
  end
end
