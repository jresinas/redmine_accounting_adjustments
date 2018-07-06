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
                binding.pry
        		create_accounting_adjustment("01-01-#{year}".to_date, amount) if amount.to_f <= -0.01 or amount.to_f >= 0.01
        	end

        	def create_end_accounting_adjustment(year, amount)
                binding.pry
        		create_accounting_adjustment("31-12-#{year}".to_date, amount) if amount.to_f <= -0.01 or amount.to_f >= 0.01
        	end

            def delete_accounting_adjustments(start_year, end_year)
                adjustments = get_accounting_adjustments("#{start_year}-01-01".to_date, "#{end_year}-12-31".to_date)
                adjustments.destroy_all
            end

            def get_accounting_adjustments(start_date = nil, end_date = nil)
                if start_date.present? and end_date.present?
                    issues.joins("LEFT JOIN custom_values AS amount ON amount.custom_field_id = 152 AND amount.customized_id = issues.id LEFT JOIN custom_values AS type ON type.custom_field_id = 273 AND type.customized_id = issues.id LEFT JOIN custom_values AS date ON date.custom_field_id = 153 AND date.customized_id = issues.id").where("tracker_id = ? AND type.value = ? AND ((MONTH(date.value) = 12 AND DAY(date.value) = 31) OR (MONTH(date.value) = 1 AND DAY(date.value) = 1)) AND YEAR(date.value) BETWEEN ? AND ?", 65, "Ajuste contable", start_date.year, end_date.year) #.select("amount.value AS amount")
                elsif start_date.present?
                    issues.joins("LEFT JOIN custom_values AS amount ON amount.custom_field_id = 152 AND amount.customized_id = issues.id LEFT JOIN custom_values AS type ON type.custom_field_id = 273 AND type.customized_id = issues.id LEFT JOIN custom_values AS date ON date.custom_field_id = 153 AND date.customized_id = issues.id").where("tracker_id = ? AND type.value = ? AND ((MONTH(date.value) = 12 AND DAY(date.value) = 31) OR (MONTH(date.value) = 1 AND DAY(date.value) = 1)) AND YEAR(date.value) >= ?", 65, "Ajuste contable", start_date.year) #.select("amount.value AS amount")
                elsif end_date.present?
                    issues.joins("LEFT JOIN custom_values AS amount ON amount.custom_field_id = 152 AND amount.customized_id = issues.id LEFT JOIN custom_values AS type ON type.custom_field_id = 273 AND type.customized_id = issues.id LEFT JOIN custom_values AS date ON date.custom_field_id = 153 AND date.customized_id = issues.id").where("tracker_id = ? AND type.value = ? AND ((MONTH(date.value) = 12 AND DAY(date.value) = 31) OR (MONTH(date.value) = 1 AND DAY(date.value) = 1)) AND YEAR(date.value) <= ?", 65, "Ajuste contable", end_date.year) #.select("amount.value AS amount")
                else
                    issues.joins("LEFT JOIN custom_values AS amount ON amount.custom_field_id = 152 AND amount.customized_id = issues.id LEFT JOIN custom_values AS type ON type.custom_field_id = 273 AND type.customized_id = issues.id LEFT JOIN custom_values AS date ON date.custom_field_id = 153 AND date.customized_id = issues.id").where("tracker_id = ? AND type.value = ? AND ((MONTH(date.value) = 12 AND DAY(date.value) = 31) OR (MONTH(date.value) = 1 AND DAY(date.value) = 1))", 65, "Ajuste contable") #.select("amount.value AS amount")
                end
            end

        	private
        	def create_accounting_adjustment(date, amount)
        		aa = Issue.create({
        		project_id: self.id,
        		author_id: User.current.id,
        		tracker_id: 65,
        		subject: "Ajuste Contable #{date}"
        		}) do |i|
                    type = CustomValue.new({
                        custom_field_id: 273,
                        value: "Ajuste contable"
                    })

                    date = CustomValue.new({
                        custom_field_id: 153,
                        value: date
                    })

                    amount = CustomValue.new({
                        custom_field_id: 152,
                        value: amount
                    })

                    amount_local = CustomValue.new({
                        custom_field_id: 261,
                        value: amount
                    })

                    enterprise = CustomValue.new({
                        custom_field_id: 156,
                        value: "Emergya Ingeniería S.L."
                    })

                    currency = CustomValue.new({
                        custom_field_id: 263,
                        value: 1
                    })

                    i.custom_values << type
                    i.custom_values << date
                    i.custom_values << amount
                    i.custom_values << amount_local
                    i.custom_values << enterprise
                    i.custom_values << currency
                end
         	end
        end
	end
end

ActionDispatch::Callbacks.to_prepare do
  Project.send(:include, AccountingAdjustments::ProjectPatch)
end