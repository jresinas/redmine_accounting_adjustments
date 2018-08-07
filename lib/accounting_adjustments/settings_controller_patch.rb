module AccountingAdjustments
  module SettingsControllerPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def show_tracker_custom_fields_type
        render :layout => false
      end 

      def show_custom_field_possible_values
        render :layout => false
      end
    end
  end
end

ActionDispatch::Callbacks.to_prepare do
  require_dependency 'settings_controller'
  SettingsController.send(:include, AccountingAdjustments::SettingsControllerPatch)
end
