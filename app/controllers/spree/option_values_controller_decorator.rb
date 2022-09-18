::Spree::Api::OptionValuesController.class_eval do

  ##
  # Rewrite of super w/ something inserted in middle.
  def create
    authorize! :create, Spree::OptionValue
    @option_value = scope.new(option_value_params)
    @option_value.user_id = current_spree_user.try(:admin?) ? nil : current_spree_user.try(:id)

    if @option_value.save
      render :show, status: 201
    else
      invalid_resource!(@option_value)
    end
  end

  def index
    including_custom_index
  end

  def including_custom_index
    if params[:ids]
      @option_values = scope.where(id: params[:ids])
    else
      @option_values = scope.ransack(params[:q]).result.distinct
    end
    ability = ::Spree::Ability.new( current_spree_user )
    @option_values = @option_values.accessible_by( ability )
    respond_with(@option_values)
  end

end