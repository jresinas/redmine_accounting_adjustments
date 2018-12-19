$(document).ready(function(){
	$(document).on('change', '#overwrite_adjustments', function(e){
		$('#accounting_adjustments_submit input').prop('disabled', true);
		$('#accounting_adjustments_content').load('accounting_adjustments/show', get_params(), function(){
			$('#accounting_adjustments_submit input').prop('disabled', false);
		});
	});

	$(document).on('change', '#ignore_current_year', function(e){
		$('#accounting_adjustments_submit input').prop('disabled', true);
		$('#accounting_adjustments_content').load('accounting_adjustments/show', get_params(), function(){
			$('#accounting_adjustments_submit input').prop('disabled', false);

		});
	});

	$(document).on('change', '#ignore_compensations', function(e){
		$('#accounting_adjustments_submit input').prop('disabled', true);
		$('#accounting_adjustments_content').load('accounting_adjustments/show', get_params(), function(){
			$('#accounting_adjustments_submit input').prop('disabled', false);
		});
	});
});

function get_params(){
	return {'overwrite_adjustments': $('#overwrite_adjustments')[0].checked, 'ignore_current_year': $('#ignore_current_year')[0].checked, 'ignore_compensations': $('#ignore_compensations')[0].checked}
}