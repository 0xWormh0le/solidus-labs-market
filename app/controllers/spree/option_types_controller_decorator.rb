Spree::Api::OptionTypesController.class_eval do
  def related
    record_type = params[:record_type]
    record_type = 'Spree::' + record_type.classify unless record_type.index('::')
    @option_types = ::Spree::RelatedOptionType.closest_option_types(record_type, params[:record_id] )

    respond_to do|format|
      format.json {
        render json: @option_types.collect{|ot| ot.as_json_with_option_values(current_spree_user) } }
    end
  end
end