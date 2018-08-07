scope '/projects/:project_id' do
  match '/accounting_adjustments' => 'accounting_adjustments#index', via: [:get, :post, :put, :patch]
  match '/accounting_adjustments/show' => 'accounting_adjustments#show', via: [:get, :post, :put, :patch]
  match '/accounting_adjustments/generate' => 'accounting_adjustments#generate', via: [:get, :post, :put, :patch]
end

match '/settings/show_tracker_custom_fields_type' => 'settings#show_tracker_custom_fields_type', :via => [:get, :post]
match '/settings/show_custom_field_possible_values' => 'settings#show_custom_field_possible_values', :via => [:get, :post]
