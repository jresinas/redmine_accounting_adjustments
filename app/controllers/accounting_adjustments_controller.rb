class AccountingAdjustmentsController < ApplicationController
	before_filter :find_project_by_project_id, :authorize
	before_filter :bsc_data

	menu_item :accounting_adjustments

	def index
		show
	end

	def show
		@overwrite_adjustments = begin params['overwrite_adjustments'].present? and params['overwrite_adjustments'] == "true" rescue false end
		@ignore_current_year = begin params['ignore_current_year'].present? and params['ignore_current_year'] == "true" rescue false end
		@end_date = @project.bsc_end_date
		@start_date = (@ignore_current_year.present? and @end_date.year > Date.today.year) ? Date.today + 1.year : Date.today

		@data = @project.get_accounting_adjustments_data(@start_date, @end_date, @overwrite_adjustments, @ignore_current_year)

		if request.xhr?
			render "_show", :layout => false
		end
	end

	def generate
		result = @project.generate_accounting_adjustments(params[:start_adjustments], params[:end_adjustments], params[:overwrite_adjustments], params[:ignore_current_year])

		if result.present?
			flash[:notice] = l(:"accounting_adjustments.text_success_creation")
		else
			flash[:error] = l(:"accounting_adjustments.text_error_creation")
		end

		redirect_to :action => 'index', :overwrite_adjustments => params[:overwrite_adjustments], :ignore_current_year => params[:ignore_current_year]
	end

	private
	def bsc_data
		unless @project.present? and @project.bsc_info.present?
			redirect_to project_path(@project), :flash => {:error => l(:"accounting_adjustments.text_no_bsc")}
		end
	end
end