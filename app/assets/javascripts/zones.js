$(document).ready( function() {
	$(".reg_ru").on("click", function(){
		$.ajax({
			url : "/admin/ps_config_zones/reg_ru",
			type: "GET",
			data : '',
			success: function(data, textStatus, jqXHR)
			{
				$(".index_content").empty();
				$("#collection_selection").remove();
				$("#active_admin_content").html(data);
			},
			error: function (jqXHR, textStatus, errorThrown)
			{
		 
			}
		});
	
	});
})