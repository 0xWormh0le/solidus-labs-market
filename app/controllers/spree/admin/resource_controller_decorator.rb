Spree::Admin::ResourceController.class_eval do
  def update_positions
    model_class.transaction do
      params[:positions].each do |id, index|
        next unless ( id.is_a?(Integer) || id.to_s =~ /\A\d+\Z/ )
        model_class.find(id).set_list_position(index)
      end
    end

    respond_to do |format|
      format.js { head :no_content }
    end
  end

  protected

  ##
  # Wanted from but missing in backend/lib/spree/backend/callbacks.rb.
  def add_callback(which_action, before_or_after, callback_method)
    self.class.callbacks ||= {}
    self.class.callbacks[which_action] ||= Spree::ActionCallbacks.new
    case before_or_after
      when :before
        self.class.callbacks[which_action].before_methods << callback_method
      when :after
        self.class.callbacks[which_action].after_methods << callback_method
      when :fails
        self.class.callbacks[which_action].fails_methods << callback_method
    end
  end
end