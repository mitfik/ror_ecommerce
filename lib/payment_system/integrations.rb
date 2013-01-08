module PaymentSystem::Integrations

  # Integration for payments in store
  # Object which should implement

  # Should return valid terminal url where user should be redirected
  # to continue payment.
  def self.setup_purchase(params)
    result = PaymentSystem.gateway.setup_purchase(params)
    if result["TransactionId"]
      return PaymentSystem.integrations.generate_terminal_url(result["TransactionId"], PaymentSystem.payment_method.gateway.login)
    else
      return nil
    end
  end


  # Provide terminal url for given invoice
  # last payment?
  def self.terminal_url(payment)
    # TODO move that because others payments method could nedds much more then just login and transactionId
    transactionId = payment.params["TransactionId"]
    payment_system = PaymentSystem.new(payment.payment_method_id)
    return payment_system.integrations.generate_terminal_url(transactionId, payment_system.payment_method.gateway.login)
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
  # TODO add error message in case of fail
  # this should be override by proper payment system like paypal class
  def self.parse_replay(params)
    return [params[:transactionId], (params[:responseCode] == 'OK' ? true : false )]
  end

  # Url which is sent to payment system and after transaction payment system
  # will send notification on it.
  def self.replay_url
    # TODO replace by replay_shopping_orders_url
    return "http://localhost:3000/shopping/orders/replay"
  end

end
