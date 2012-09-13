class Myaccount::CreditCardsController < Myaccount::BaseController
  before_filter :check_settings

  def index
    @credit_cards = current_user.payment_profiles
  end

  def show
    @credit_card = current_user.payment_profiles.find(params[:id])
  end

  def new
    @credit_card = current_user.payment_profiles.new
  end

  def create
    @credit_card = current_user.payment_profiles.new(allowed_params)
    if @credit_card.save
      flash[:notice] = "Successfully created credit card."
      redirect_to myaccount_credit_card_url(@credit_card)
    else
      render :action => 'new'
    end
  end

  def edit
    @credit_card = current_user.payment_profiles.find(params[:id])
  end

  def update
    @credit_card = current_user.payment_profiles.find(params[:id])
    if @credit_card.update_attributes(allowed_params)
      flash[:notice] = "Successfully updated credit card."
      redirect_to myaccount_credit_card_url(@credit_card)
    else
      render :action => 'edit'
    end
  end

  def destroy
    @credit_card = current_user.payment_profiles.find(params[:id])
    @credit_card.inactivate!
    flash[:notice] = "Successfully destroyed credit card."
    redirect_to myaccount_credit_cards_url
  end

  private

  def allowed_params
    params.require(:credit_card).permit(:address_id, :month, :year, :cc_type, :first_name, :last_name, :card_name)
  end

  def selected_myaccount_tab(tab)
    tab == 'credit_cards'
  end

  # if we do not host terminal we turn off credit cards profiles 
  # we do not want to store anything related with credit cards
  def check_settings
    redirect_to myaccount_overview_url unless Settings.payments_system.merchant_hosted_terminal
  end
end
