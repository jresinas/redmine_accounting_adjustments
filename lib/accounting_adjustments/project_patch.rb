module AccountingAdjustments
	module ProjectPatch
		def self.included(base) # :nodoc:
          base.extend(ClassMethods)
          base.send(:include, InstanceMethods)

          base.class_eval do
          end
        end

        module ClassMethods
        end

        module InstanceMethods
        	def create_start_accounting_adjustment(year, amount)
        		create_accounting_adjustment("01-01-#{year}".to_date, amount) if amount.to_f <= -0.01 or amount.to_f >= 0.01
        	end

        	def create_end_accounting_adjustment(year, amount)
        		create_accounting_adjustment("31-12-#{year}".to_date, amount) if amount.to_f <= -0.01 or amount.to_f >= 0.01
        	end

            def delete_accounting_adjustments(start_year, end_year)
                adjustments = get_accounting_adjustments("#{start_year}-01-01".to_date, "#{end_year}-12-31".to_date)
                adjustments.destroy_all
            end

            def get_accounting_adjustments(start_date = nil, end_date = nil)
                if accounting_adjustment_enabled
                    if start_date.present? and end_date.present?
                        issues.joins("LEFT JOIN custom_values AS amount ON amount.custom_field_id = #{Setting.plugin_redmine_accounting_adjustments['amount_field']} AND amount.customized_id = issues.id LEFT JOIN custom_values AS type ON type.custom_field_id = #{Setting.plugin_redmine_accounting_adjustments['type_field']} AND type.customized_id = issues.id LEFT JOIN custom_values AS date ON date.custom_field_id = #{Setting.plugin_redmine_accounting_adjustments['date_field']} AND date.customized_id = issues.id").where("tracker_id = ? AND type.value = ? AND ((MONTH(date.value) = 12 AND DAY(date.value) = 31) OR (MONTH(date.value) = 1 AND DAY(date.value) = 1)) AND YEAR(date.value) BETWEEN ? AND ?", Setting.plugin_redmine_accounting_adjustments['tracker'], Setting.plugin_redmine_accounting_adjustments['type_value'], start_date.year, end_date.year) #.select("amount.value AS amount")
                    elsif start_date.present?
                        issues.joins("LEFT JOIN custom_values AS amount ON amount.custom_field_id = #{Setting.plugin_redmine_accounting_adjustments['amount_field']} AND amount.customized_id = issues.id LEFT JOIN custom_values AS type ON type.custom_field_id = #{Setting.plugin_redmine_accounting_adjustments['type_field']} AND type.customized_id = issues.id LEFT JOIN custom_values AS date ON date.custom_field_id = #{Setting.plugin_redmine_accounting_adjustments['date_field']} AND date.customized_id = issues.id").where("tracker_id = ? AND type.value = ? AND ((MONTH(date.value) = 12 AND DAY(date.value) = 31) OR (MONTH(date.value) = 1 AND DAY(date.value) = 1)) AND YEAR(date.value) >= ?", Setting.plugin_redmine_accounting_adjustments['tracker'], Setting.plugin_redmine_accounting_adjustments['type_value'], start_date.year) #.select("amount.value AS amount")
                    elsif end_date.present?
                        issues.joins("LEFT JOIN custom_values AS amount ON amount.custom_field_id = #{Setting.plugin_redmine_accounting_adjustments['amount_field']} AND amount.customized_id = issues.id LEFT JOIN custom_values AS type ON type.custom_field_id = #{Setting.plugin_redmine_accounting_adjustments['type_field']} AND type.customized_id = issues.id LEFT JOIN custom_values AS date ON date.custom_field_id = #{Setting.plugin_redmine_accounting_adjustments['date_field']} AND date.customized_id = issues.id").where("tracker_id = ? AND type.value = ? AND ((MONTH(date.value) = 12 AND DAY(date.value) = 31) OR (MONTH(date.value) = 1 AND DAY(date.value) = 1)) AND YEAR(date.value) <= ?", Setting.plugin_redmine_accounting_adjustments['tracker'], Setting.plugin_redmine_accounting_adjustments['type_value'], end_date.year) #.select("amount.value AS amount")
                    else
                        issues.joins("LEFT JOIN custom_values AS amount ON amount.custom_field_id = #{Setting.plugin_redmine_accounting_adjustments['amount_field']} AND amount.customized_id = issues.id LEFT JOIN custom_values AS type ON type.custom_field_id = #{Setting.plugin_redmine_accounting_adjustments['type_field']} AND type.customized_id = issues.id LEFT JOIN custom_values AS date ON date.custom_field_id = #{Setting.plugin_redmine_accounting_adjustments['date_field']} AND date.customized_id = issues.id").where("tracker_id = ? AND type.value = ? AND ((MONTH(date.value) = 12 AND DAY(date.value) = 31) OR (MONTH(date.value) = 1 AND DAY(date.value) = 1))", Setting.plugin_redmine_accounting_adjustments['tracker'], Setting.plugin_redmine_accounting_adjustments['type_value']) #.select("amount.value AS amount")
                    end
                else
                    Issue.none
                end
            end

        	private
        	def create_accounting_adjustment(date, amount)
                if accounting_adjustment_enabled
            		aa = Issue.create({
            		project_id: self.id,
            		author_id: User.current.id,
            		tracker_id: Setting.plugin_redmine_accounting_adjustments['tracker'],
            		subject: "Ajuste Contable #{date}"
            		}) do |i|
                        type = CustomValue.new({
                            custom_field_id: Setting.plugin_redmine_accounting_adjustments['type_field'],
                            value: Setting.plugin_redmine_accounting_adjustments['type_value']
                        })

                        date = CustomValue.new({
                            custom_field_id: Setting.plugin_redmine_accounting_adjustments['date_field'],
                            value: date
                        })

                        amount = CustomValue.new({
                            custom_field_id: Setting.plugin_redmine_accounting_adjustments['amount_field'],
                            value: amount
                        })

                        amount_local = CustomValue.new({
                            custom_field_id: Setting.plugin_redmine_accounting_adjustments['amount_local_field'],
                            value: amount
                        })

                        enterprise = CustomValue.new({
                            custom_field_id: Setting.plugin_redmine_accounting_adjustments['biller_field'],
                            value: Setting.plugin_redmine_accounting_adjustments['biller_value']
                        })

                        # currency = CustomValue.new({
                        #     custom_field_id: 263,
                        #     value: 1
                        # })

                        i.custom_values << type
                        i.custom_values << date
                        i.custom_values << amount
                        i.custom_values << amount_local
                        i.custom_values << enterprise
                        # i.custom_values << currency
                    end
                end
         	end

            def accounting_adjustment_enabled
                return Setting.plugin_redmine_accounting_adjustments['tracker'].present? && Setting.plugin_redmine_accounting_adjustments['type_field'].present? && Setting.plugin_redmine_accounting_adjustments['amount_field'].present? && Setting.plugin_redmine_accounting_adjustments['date_field'].present? && Setting.plugin_redmine_accounting_adjustments['type_value'].present?
            end
        end
	end
end

ActionDispatch::Callbacks.to_prepare do
  Project.send(:include, AccountingAdjustments::ProjectPatch)
end