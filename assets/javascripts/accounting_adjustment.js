$(document).ready(function(){
	$(document).on('change', '#overwrite_adjustments', function(e){
		console.log($('#overwrite_adjustments')[0].checked);
		$('#accounting_adjustments_content').load('accounting_adjustments/show', get_params());
	});

	$(document).on('change', '#ignore_current_year', function(e){
		console.log($('#ignore_current_year')[0].checked);
		$('#accounting_adjustments_content').load('accounting_adjustments/show', get_params());
	});
});

function get_params(){
	return {'overwrite_adjustments': $('#overwrite_adjustments')[0].checked, 'ignore_current_year': $('#ignore_current_year')[0].checked}
}