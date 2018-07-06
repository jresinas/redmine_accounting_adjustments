class AccountingAdjustmentsController < ApplicationController
	before_filter :find_project_by_project_id, :authorize

	menu_item :accounting_adjustments

	def index
		show
	end

	def show
		@overwrite_adjustments = begin params['overwrite_adjustments'] == "true" rescue false end
		@ignore_current_year = begin params['ignore_current_year'] == "true" rescue false end

		@data = {}
		total_adjustments = 0.00
		@end_date = @project.bsc_end_date
		@start_date = (@ignore_current_year.present? and @end_date.year > Date.today.year) ? Date.today + 1.year : Date.today

		if @start_date.year <= @end_date.year
			mt = BSC::MetricsInterval.new(@project.id, @start_date.beginning_of_year, @end_date.end_of_year)
			accounting_adjustments = @project.get_accounting_adjustments(@start_date).sum(:"amount.value") if @overwrite_adjustments.present?

			scheduled_incomes = @overwrite_adjustments.present? ? (mt.total_income_scheduled - accounting_adjustments) : mt.total_income_scheduled
			scheduled_expenses = mt.total_expense_scheduled
			scheduled_mc = @overwrite_adjustments.present? ? 100 * ((scheduled_incomes - scheduled_expenses) / scheduled_incomes) : mt.scheduled_margin
			total_mc = scheduled_mc

			@data['totals'] = {
				:scheduled_incomes => scheduled_incomes.round(2),
				:scheduled_expenses => scheduled_expenses.round(2),
				:scheduled_mc => scheduled_mc.round(2),
				:theoric_incomes => scheduled_incomes.round(2),
				:theoric_start_adjustment => 0.00,
				:theoric_end_adjustment => 0.00,
				:theoric_mc => scheduled_mc.round(2)
			}

			last_year_adjustment = 0
			(@start_date.year..@end_date.year).each do |year|
				myear = BSC::MetricsInterval.new(@project.id, "01-01-#{year}".to_date, "31-12-#{year}".to_date)
				accounting_adjustments = @project.get_accounting_adjustments("01-01-#{year}".to_date, "31-12-#{year}".to_date).sum(:"amount.value") if @overwrite_adjustments.present?

				scheduled_incomes = @overwrite_adjustments.present? ? (myear.total_income_scheduled - accounting_adjustments) : myear.total_income_scheduled
				scheduled_expenses = myear.total_expense_scheduled
				scheduled_mc =  @overwrite_adjustments.present? ? 100 * ((scheduled_incomes - scheduled_expenses) / scheduled_incomes) : myear.scheduled_margin
				# theoric_incomes = -((100 * scheduled_expenses) / (mt.scheduled_margin - 100))
				theoric_incomes = -((100 * scheduled_expenses) / (total_mc - 100))
				# theoric_end_adjustment = (year != @end_date.year) ? -((100 * myear.total_expense_scheduled) / (mt.scheduled_margin - 100)) - scheduled_incomes : 0.00
				theoric_end_adjustment = (year != @end_date.year) ? -((100 * myear.total_expense_scheduled) / (total_mc - 100)) - scheduled_incomes : 0.00
				theoric_mc = total_mc

				@data[year] = {
					:scheduled_incomes => scheduled_incomes.round(2),
					:scheduled_expenses => scheduled_expenses.round(2),
					:scheduled_mc => scheduled_mc.round(2),
					:theoric_incomes => theoric_incomes.round(2),
					:theoric_start_adjustment => (-last_year_adjustment.round(2)),
					:theoric_end_adjustment => theoric_end_adjustment.round(2),
					:theoric_mc => theoric_mc.round(2)
				}
				# last_year_adjustment = (-((100 * myear.total_expense_scheduled) / (mt.scheduled_margin - 100)) - scheduled_incomes).round(2)
				# binding.pry
				last_year_adjustment = theoric_end_adjustment
				total_adjustments += last_year_adjustment
			end

			@data['totals'][:theoric_start_adjustment] = (-total_adjustments.round(2))
			@data['totals'][:theoric_end_adjustment] = total_adjustments.round(2)
		end

		if request.xhr?
			render "_show", :layout => false
		end
	end

	def generate
		if params[:overwrite_adjustments].present?
			end_date = @project.bsc_end_date
			start_date = params[:ignore_current_year].present? ? Date.today+1.year : Date.today
			@project.delete_accounting_adjustments(start_date.year, end_date.year)
		end

		if params[:start_adjustments].present?
			params[:start_adjustments].each do |year, amount|
				@project.create_start_accounting_adjustment(year, amount)
			end
		end

		if params[:end_adjustments].present?
			params[:end_adjustments].each do |year, amount|
				@project.create_end_accounting_adjustment(year, amount)
			end
		end

		redirect_to :action => 'index'
	end
end