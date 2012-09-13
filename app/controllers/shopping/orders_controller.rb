class Shopping::OrdersController < Shopping::BaseController
  before_filter :require_login
  # GET /shopping/orders
  ### The intent of this action is two fold
  #
  # A)  if there is a current order redirect to the process that
  # => needs to be completed to finish the order process.
  # B)  if the order is ready to be checked out...  give the order summary page.
  #
  ##### THIS METHOD IS BASICALLY A CHECKOUT ENGINE
  def index
    @order = find_or_create_order
    if f = next_form(@order)
      redirect_to f
    else
      expire_all_browser_cache
      form_info
    end
  end


  #  add checkout button
  def checkout
    #current or in-progress otherwise cart (unless cart is empty)
    order = find_or_create_order
    @order = session_cart.add_items_to_checkout(order) # need here because items can also be removed
    redirect_to next_form_url(order)
  end

  # POST /shopping/orders
  def update
    @order = find_or_create_order
    @order.ip_address = request.remote_ip

    @credit_card ||= PaymentSystem::CreditCard.new(cc_params)

    address = @order.bill_address.cc_params

    if !@order.in_progress?
      proceed_to_pay
    end
  end

  # replay from payment system in case if merchant_hosted_terminal is false
  # and user will be redirect to external terminal
  def replay
    transactionId, success  = PaymentSystem::Integrations.parse_replay(params)
    payment = Payment.find_by_confirmation_id(transactionId) if transactionId
    @order = payment.invoice.order if payment
    if success && @order
      if @order.authorize_payment(payment)
        @order.order_complete!
        @order.save
        clean_after_payment
        flash[:notice] = I18n.t('notice_transaction_accepted')
        redirect_to myaccount_order_path(@order)
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

    # we have two scenarion how ror-e can be configured with merchant hosted terminal or without
    # here we decide how to handle those payments
    def proceed_to_pay
      if Settings.payments_system.merchant_hosted_terminal
        proceed_payment_with_hosted_terminal
      else
        proceed_payment_without_hosted_terminal
      end
    end

    def proceed_payment_without_hosted_terminal

      address = @order.bill_address.cc_params
      # prepare invoice with payment and setup purchase
      response = @order.prepare_invoice(@order.credited_total,
                                        {:email => @order.email, :billing_address => address, :ip => @order.ip_address,
                                         :redirectUrl => replay_shopping_order_url, :orderNumber => @order.number,
                                         :currencyCode => Settings.payments_system.currency_code}, @order.amount_to_credit)
      if response.succeeded?
        redirect_to PaymentSystem::Integrations.terminal_url(response)
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
            expire_all_browser_cache
            ##  MARK items as purchased
            session_cart.mark_items_purchased(@order)
            session[:last_order] = @order.number
            redirect_to( confirmation_shopping_order_url(@order) ) and return
          else
            flash[:alert] =  [I18n.t('could_not_process'), I18n.t('the_order')].join(' ')
          end
        else
          flash[:alert] = [I18n.t('could_not_process'), I18n.t('the_credit_card')].join(' ')
        end
        form_info
        render :action => 'index'
      else
        form_info
        flash[:alert] = [I18n.t('credit_card'), I18n.t('is_not_valid')].join(' ')
        render :action => 'index'
      end
    end

  def confirmation
    @tab = 'confirmation'
    if session[:last_order].present? && session[:last_order] == params[:id]
      session[:last_order] = nil
      @order = Order.where(:number => params[:id]).includes({:order_items => :variant}).first
      render :layout => 'application'
    else
      session[:last_order] = nil
      if current_user.finished_orders.present?
        redirect_to myaccount_order_url( current_user.finished_orders.last )
      elsif current_user
        redirect_to myaccount_orders_url
      end
    end
  end
  private

  def customer_confirmation_page_view
    @tab && (@tab == 'confirmation')
  end

  def form_info
    @credit_card ||= PaymentSystem::CreditCard.new()
    @order.credited_total
  end
  def require_login
    if !current_user
      session[:return_to] = shopping_orders_url
      redirect_to( login_url() ) and return
    end
  end

end
