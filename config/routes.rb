scope '/projects/:project_id' do
  match '/accounting_adjustments' => 'accounting_adjustments#index', via: [:get, :post, :put, :patch]
  match '/accounting_adjustments/show' => 'accounting_adjustments#show', via: [:get, :post, :put, :patch]
  match '/accounting_adjustments/generate' => 'accounting_adjustments#generate', via: [:get, :post, :put, :patch]
end