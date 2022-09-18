::Spree::CheckoutController.class_eval do

  helper Spree::CheckoutHelperExtension

  def update_all
    if update_order
      assign_temp_address

      [:bill_address_attributes, :shipments_attributes, :payment_attributes, :confirm].each do|sub_param_key|
        unless sub_param_key == :confirm || params[:order][sub_param_key]
          flash[:error] = t("activerecord.errors.models.spree/order.missing_#{sub_param_key.to_s.gsub('_attributes', '')}")
          redirect_on_failure
          return
        end
        unless transition_forward
          redirect_on_failure
          return
        end
      end

      if @order.completed?
        finalize_order
      else
        send_to_next_state
      end
    else
      render :edit
    end
  end

  ##
  # This replaces app's own routes method, and auto adds order_id: @order.id,
  # so @order or params[:order_id] is expected.
  def checkout_state_path(order_state)
    spree.checkout_state_path(order_state, order_id: @order.try(:id) || params[:order_id] )
  end

  private


end