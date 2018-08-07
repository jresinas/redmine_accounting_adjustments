require 'accounting_adjustments/project_patch'
require 'accounting_adjustments/settings_controller_patch'

Redmine::Plugin.register :redmine_accounting_adjustments do
  name 'Automatic Accounting Adjustment Plugin'
  author 'jresinas'
  description ''
  version '0.0.1'
  author_url 'http://www.emergya.es'

  settings :default => { }, :partial => 'settings/accounting_adjustment_settings'

  project_module :accounting_adjustments_plugin do
    permission :generate_accounting_adjustments, { :accounting_adjustments => [:index, :show, :generate] }
  end

  menu :project_menu, :accounting_adjustments, { :controller => 'accounting_adjustments', :action => 'index' },
       :caption => :"accounting_adjustments.label_accounting_adjustments",
       :param => :project_id
end