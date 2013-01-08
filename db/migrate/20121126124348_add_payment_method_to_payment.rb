class AddPaymentMethodToPayment < ActiveRecord::Migration
  def change
    add_column :payments, :payment_method_id, :integer
  end
end
