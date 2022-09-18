##
#
module FormActionHelper
  ##
  # @form_attributes <Hash>
  #   If it is a nested form, such as model 'product' and fields like 'product[name]',
  #   set argument as ['product', {name: 'product title'} ]
  def fill_into_form(form_attributes)
    field_name_pattern = form_attributes.is_a?(Array) ? "#{form_attributes.first}[%s]" : '%s'
    attr = form_attributes.is_a?(Array) ? form_attributes.last : form_attributes
    attr.each_pair do|k, v|
      next if v.nil?
      field_name = field_name_pattern % [k]
      begin
        if v.is_a?(Array)
          v.each do|sub_v|
            if sub_v.is_a?(Hash)
              sub_v.each_pair do|sub_v_k, sub_v_v|
                xpath_field = find(:xpath, "//*[@name='#{field_name}[]#{sub_v_k}']")
                if sub_v_k.to_s == 'currency'
                  xpath_field.select(sub_v_v)
                else
                  xpath_field.set(sub_v_v)
                end
              end
            end
          end
        else
          find(:xpath, "//*[@name='#{field_name}']").set(v )
        end
      rescue Capybara::ElementNotFound
        puts "** Cannot find product field #{k}"
      end
    end
  end
end