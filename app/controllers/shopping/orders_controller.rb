class Shopping::OrdersController < Shopping::BaseController
  before_filter :require_login
  # GET /shopping/orders
  # GET /shopping/orders.xml
  ### The intent of this action is two fold
  #
  # A)  if there is a current order redirect to the process that
  # => needs to be completed to finish the order process.
  # B)  if the order is ready to be checked out...  give the order summary page.
  #
  ##### THIS METHOD IS BASICALLY A CHECKOUT ENGINE
  def index
    #current or in-progress otherwise cart (unless cart is empty)
    @order = find_or_create_order
    if f = next_form(@order)
      redirect_to f
    else
      form_info
      respond_to do |format|
        format.html # index.html.erb
      end
    end
  end

  #  add checkout button
  def checkout
    #current or in-progress otherwise cart (unless cart is empty)
    order = find_or_create_order
    @order = session_cart.add_items_to_checkout(order) # need here because items can also be removed
    redirect_to shopping_orders_url
  end

  # POST /shopping/orders
  # POST /shopping/orders.xml
  def update
    @order = find_or_create_order
    @order.ip_address = request.remote_ip

    address = @order.bill_address.cc_params
    unless @order.complete?
      if params[:payment_method_id]
        proceed_to_pay(@order, params[:payment_method_id])
      else
        flash[:alert] = t("error_please_choose_payment_method")
      end
    else
      session_cart.mark_items_purchased(@order)
      flash[:error] = I18n.t('the_order_purchased')
      redirect_to myaccount_order_url(@order)
    end
  end

  # replay from payment system in case if merchant_hosted_terminal is false
  # and user will be redirect to external terminal
  def replay
    transactionId, success  = PaymentSystem::Integrations.parse_replay(params)
    payment = Payment.find_by_confirmation_id(transactionId) if transactionId
    if success && payment
      if payment.authorize
        order = payment.invoice.order
        order.order_complete!
        order.save
        clean_after_payment(order)
        flash[:notice] = I18n.t('notice_transaction_accepted')
        redirect_to myaccount_order_path(order)
      else
        flash[:alert] = I18n.t('alert_payment_not_authorized')
        redirect_to root_url
      end
    else
      # cancel order and inform user that he didn't pay and we didn't block any money so he can try one more time.
      flash[:alert] = I18n.t('alert_payment_canceled')
      redirect_to root_url
      #TODO Transaction should be canceled - check if everything is remove and clear
    end
  end

  private

    # we have two scenarios how ror-e can handle payments.
    # With merchant hosted terminal or without
    def proceed_to_pay(order, payment_method_id)
      payment_system = PaymentSystem.new(payment_method_id)
      if payment_system.payment_method.merchant_hosted_terminal
        proceed_payment_with_hosted_terminal
      else
        proceed_payment_without_hosted_terminal(payment_method_id)
      end
    end

    def proceed_payment_without_hosted_terminal(payment_method_id)
      # prepare invoice with payment and setup purchase
      response = @order.prepare_invoice(payment_method_id)
      if response.succeeded?
        redirect_to PaymentSystem::Integrations.terminal_url(response.payments.last)
      else
        flash[:alert] =  [I18n.t('could_not_process'), I18n.t('the_order')].join(' ')
        render :action => "index"
      end
    end

    def proceed_payment_with_hosted_terminal
      @credit_card ||= PaymentSystem::CreditCard.new(cc_params)
      address = @order.bill_address.cc_params
      if @credit_card.valid?
        if response = @order.create_invoice(@credit_card,
                                          @order.credited_total,
                                          {:email => @order.email, :billing_address=> address, :ip=> @order.ip_address },
                                          @order.amount_to_credit)
          if response.succeeded?
            clean_after_payment(@order)
            redirect_to myaccount_order_path(@order)
          else
            form_info
            flash[:alert] =  [I18n.t('could_not_process'), I18n.t('the_order')].join(' ')
            render :action => "index"
          end
        else
          form_info
          flash[:alert] = [I18n.t('could_not_process'), I18n.t('the_credit_card')].join(' ')
          render :action => 'index'
        end
      else
        form_info
        flash[:alert] = [I18n.t('credit_card'), I18n.t('is_not_valid')].join(' ')
        render :action => 'index'
      end
    end

    def clean_after_payment(order)
      order.remove_user_store_credits
      session_cart.mark_items_purchased(order)
      Notifier.order_confirmation(order, invoice).deliver rescue puts( 'do nothing...  dont blow up over an email')
    end

    def form_info
      @credit_card ||= PaymentSystem::CreditCard.new()
      @order.credited_total
    end

    def require_login
      if !current_user
        flash[:alert] = t("error_you_must_login")
        session[:return_to] = shopping_orders_url
        redirect_to( login_url() ) and return
      end
    end

    def cc_params
      {
            :type               => params[:type],
            :number             => params[:number],
            :verification_value => params[:verification_value],
            :month              => params[:month],
            :year               => params[:year],
            :first_name         => params[:first_name],
            :last_name          => params[:last_name]
      }
    end
end
