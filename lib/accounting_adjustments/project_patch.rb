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
            def get_accounting_adjustments_data(start_date, end_date, overwrite_adjustments, ignore_current_year)
                data = {}
                total_adjustments = 0.00
                if start_date.year <= end_date.year
                    mt = BSC::MetricsInterval.new(self.id, start_date.beginning_of_year, end_date.end_of_year)
                    accounting_adjustments = get_accounting_adjustments(start_date).sum(:"amount.value") if overwrite_adjustments.present?

                    scheduled_incomes = overwrite_adjustments.present? ? (mt.total_income_scheduled - accounting_adjustments) : mt.total_income_scheduled
                    scheduled_expenses = mt.total_expense_scheduled
                    scheduled_mc = overwrite_adjustments.present? ? 100 * ((scheduled_incomes - scheduled_expenses) / scheduled_incomes) : mt.scheduled_margin
                    total_mc = scheduled_mc

                    data['totals'] = {
                        :scheduled_incomes => scheduled_incomes.round(2),
                        :scheduled_expenses => scheduled_expenses.round(2),
                        :scheduled_mc => scheduled_mc.round(2),
                        :theoric_incomes => scheduled_incomes.round(2),
                        :theoric_start_adjustment => 0.00,
                        :theoric_end_adjustment => 0.00,
                        :theoric_mc => scheduled_mc.round(2)
                    }

                    last_year_adjustment = 0
                    (start_date.year..end_date.year).each do |year|
                        myear = BSC::MetricsInterval.new(self.id, "01-01-#{year}".to_date, "31-12-#{year}".to_date)
                        accounting_adjustments = get_accounting_adjustments("01-01-#{year}".to_date, "31-12-#{year}".to_date).sum(:"amount.value") if overwrite_adjustments.present?

                        scheduled_incomes = overwrite_adjustments.present? ? (myear.total_income_scheduled - accounting_adjustments) : myear.total_income_scheduled
                        scheduled_expenses = myear.total_expense_scheduled
                        scheduled_mc = 100 * ((scheduled_incomes - scheduled_expenses) / scheduled_incomes)
                        theoric_end_adjustment = ((total_mc * scheduled_incomes) + (100 * scheduled_expenses) - (100 * scheduled_incomes)) / (100 - total_mc) + last_year_adjustment
                        theoric_incomes = scheduled_incomes + theoric_end_adjustment - last_year_adjustment
                        theoric_mc = 100 * (theoric_incomes - scheduled_expenses) / theoric_incomes

                        data[year] = {
                            :scheduled_incomes => scheduled_incomes.round(2),
                            :scheduled_expenses => scheduled_expenses.round(2),
                            :scheduled_mc => scheduled_mc.round(2),
                            :theoric_incomes => theoric_incomes.round(2),
                            :theoric_start_adjustment => -last_year_adjustment.round(2),
                            :theoric_end_adjustment => theoric_end_adjustment.round(2),
                            :theoric_mc => theoric_mc.round(2)
                        }

                        last_year_adjustment = theoric_end_adjustment
                        total_adjustments += last_year_adjustment
                    end

                    data['totals'][:theoric_start_adjustment] = -total_adjustments.round(2)
                    data['totals'][:theoric_end_adjustment] = total_adjustments.round(2)
                end

                data
            end

            def generate_accounting_adjustments(start_adjustments, end_adjustments, overwrite_adjustments = false, ignore_current_year = false)
                ActiveRecord::Base.transaction do
                    if overwrite_adjustments.present?
                        end_date = self.bsc_end_date
                        start_date = ignore_current_year.present? ? Date.today+1.year : Date.today
                        delete_accounting_adjustments(start_date.year, end_date.year)
                    end

                    if start_adjustments.present?
                        start_adjustments.each do |year, amount|
                            create_start_accounting_adjustment(year, amount)
                        end
                    end

                    if end_adjustments.present?
                        end_adjustments.each do |year, amount|
                            create_end_accounting_adjustment(year, amount)
                        end
                    end
                end
            end

            private
        	def create_start_accounting_adjustment(year, amount)
        		create_accounting_adjustment("01-01-#{year}".to_date, amount) if amount.to_f <= -0.01 or amount.to_f >= 0.01
        	end

        	def create_end_accounting_adjustment(year, amount)
        		create_accounting_adjustment("31-12-#{year}".to_date, amount) if amount.to_f <= -0.01 or amount.to_f >= 0.01
        	end

            def delete_accounting_adjustments(start_year, end_year)
                adjustments = get_accounting_adjustments("#{start_year}-01-02".to_date, "#{end_year}-12-31".to_date)
                adjustments.destroy_all
            end

            def get_accounting_adjustments(start_date = nil, end_date = nil)
                if accounting_adjustment_enabled?
                    if start_date.present? and end_date.present?
                        issues.joins("LEFT JOIN custom_values AS amount ON amount.custom_field_id = #{Setting.plugin_redmine_accounting_adjustments['amount_field']} AND amount.customized_id = issues.id LEFT JOIN custom_values AS type ON type.custom_field_id = #{Setting.plugin_redmine_accounting_adjustments['type_field']} AND type.customized_id = issues.id LEFT JOIN custom_values AS date ON date.custom_field_id = #{Setting.plugin_redmine_accounting_adjustments['date_field']} AND date.customized_id = issues.id").where("tracker_id = ? AND type.value = ? AND ((MONTH(date.value) = 12 AND DAY(date.value) = 31) OR (MONTH(date.value) = 1 AND DAY(date.value) = 1)) AND DATE(date.value) BETWEEN ? AND ? AND issues.subject LIKE ?", Setting.plugin_redmine_accounting_adjustments['tracker'], Setting.plugin_redmine_accounting_adjustments['type_value'], start_date, end_date, "#{Setting.plugin_redmine_accounting_adjustments['subject']}%") #.select("amount.value AS amount")
                    elsif start_date.present?
                        issues.joins("LEFT JOIN custom_values AS amount ON amount.custom_field_id = #{Setting.plugin_redmine_accounting_adjustments['amount_field']} AND amount.customized_id = issues.id LEFT JOIN custom_values AS type ON type.custom_field_id = #{Setting.plugin_redmine_accounting_adjustments['type_field']} AND type.customized_id = issues.id LEFT JOIN custom_values AS date ON date.custom_field_id = #{Setting.plugin_redmine_accounting_adjustments['date_field']} AND date.customized_id = issues.id").where("tracker_id = ? AND type.value = ? AND ((MONTH(date.value) = 12 AND DAY(date.value) = 31) OR (MONTH(date.value) = 1 AND DAY(date.value) = 1)) AND DATE(date.value) >= ? AND issues.subject LIKE ?", Setting.plugin_redmine_accounting_adjustments['tracker'], Setting.plugin_redmine_accounting_adjustments['type_value'], start_date, "#{Setting.plugin_redmine_accounting_adjustments['subject']}%") #.select("amount.value AS amount")
                    elsif end_date.present?
                        issues.joins("LEFT JOIN custom_values AS amount ON amount.custom_field_id = #{Setting.plugin_redmine_accounting_adjustments['amount_field']} AND amount.customized_id = issues.id LEFT JOIN custom_values AS type ON type.custom_field_id = #{Setting.plugin_redmine_accounting_adjustments['type_field']} AND type.customized_id = issues.id LEFT JOIN custom_values AS date ON date.custom_field_id = #{Setting.plugin_redmine_accounting_adjustments['date_field']} AND date.customized_id = issues.id").where("tracker_id = ? AND type.value = ? AND ((MONTH(date.value) = 12 AND DAY(date.value) = 31) OR (MONTH(date.value) = 1 AND DAY(date.value) = 1)) AND DATE(date.value) <= ? AND issues.subject LIKE ?", Setting.plugin_redmine_accounting_adjustments['tracker'], Setting.plugin_redmine_accounting_adjustments['type_value'], end_date, "#{Setting.plugin_redmine_accounting_adjustments['subject']}%") #.select("amount.value AS amount")
                    else
                        issues.joins("LEFT JOIN custom_values AS amount ON amount.custom_field_id = #{Setting.plugin_redmine_accounting_adjustments['amount_field']} AND amount.customized_id = issues.id LEFT JOIN custom_values AS type ON type.custom_field_id = #{Setting.plugin_redmine_accounting_adjustments['type_field']} AND type.customized_id = issues.id LEFT JOIN custom_values AS date ON date.custom_field_id = #{Setting.plugin_redmine_accounting_adjustments['date_field']} AND date.customized_id = issues.id").where("tracker_id = ? AND type.value = ? AND ((MONTH(date.value) = 12 AND DAY(date.value) = 31) OR (MONTH(date.value) = 1 AND DAY(date.value) = 1)) AND issues.subject LIKE ?", Setting.plugin_redmine_accounting_adjustments['tracker'], Setting.plugin_redmine_accounting_adjustments['type_value'], "#{Setting.plugin_redmine_accounting_adjustments['subject']}%") #.select("amount.value AS amount")
                    end
                else
                    Issue.none
                end
            end

        	def create_accounting_adjustment(date, amount)
                if accounting_adjustment_enabled?
            		aa = Issue.create({
            		project_id: self.id,
            		author_id: User.current.id,
            		tracker_id: Setting.plugin_redmine_accounting_adjustments['tracker'],
            		subject: Setting.plugin_redmine_accounting_adjustments['subject']+" #{date}"
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

                    raise ActiveRecord::Rollback if aa.new_record?

                    return aa
                else
                    raise ActiveRecord::Rollback
                end
         	end

            def accounting_adjustment_enabled?
                return Setting.plugin_redmine_accounting_adjustments['tracker'].present? && Setting.plugin_redmine_accounting_adjustments['type_field'].present? && Setting.plugin_redmine_accounting_adjustments['amount_field'].present? && Setting.plugin_redmine_accounting_adjustments['date_field'].present? && Setting.plugin_redmine_accounting_adjustments['type_value'].present?
            end

            
        end
	end
end

ActionDispatch::Callbacks.to_prepare do
  Project.send(:include, AccountingAdjustments::ProjectPatch)
end