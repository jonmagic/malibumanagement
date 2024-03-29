// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function numbersonly(e){
	var unicode=e.charCode? e.charCode : e.keyCode
	if (unicode!=8 && unicode!=9 && unicode!=16 && unicode!=17 && unicode!=35 && unicode!=36 && unicode!=37 && unicode!=39 && unicode!=46 && unicode!=114 && unicode!=116 && unicode!=190 && unicode!=63232 && unicode!=63233 && unicode!=63234 && unicode!=63235 && unicode!=46 && unicode!=63272) { //allow all these keys: 8=backspace; 9=tab; 16=shift; 17=ctrl; 35=end; 36=home; 37=left; 39=right; 190=period; 63232+=safari-arrowkeys;
		if (unicode<48||unicode>57) //if not a number
			return false //disable key press
	}
}

function flash(txt, close_button, close_on_overlay_click, stay_open){
	if(close_button == undefined) close_button = false;
	if(close_on_overlay_click == undefined) close_on_overlay_click = false;
  if(stay_open == undefined) stay_open = false;

	if(close_button != false){
		buttons = '<div id="dialog_buttons" class="dialog_buttons">\
			<input id="dialog-button" type="button" value="'+close_button+'" onclick="Control.Modal.close();" class="dialog-button"/>\
		</div>';
		after_open = function(){setTimeout(function(){$('dialog-button').focus()},500)};
	} else {
		buttons = '';
		after_open = function(){true};
	}
	Control.Modal.open('<div>\
		<div class="dialog_content">\
			<div class="dialog_body">'+txt+'</div>'+buttons+
		'</div>\
	</div>', {fade:true, overlayCloseOnClick:close_on_overlay_click, afterOpen:after_open});
	if(stay_open != true){
	  if(stay_open == true){
		  setTimeout(function(){Control.Modal.close()}, 4500); // auto-close after 4.5 seconds
	  } else {
		  setTimeout(function(){Control.Modal.close()}, stay_open); // wait specified amount of time
	  }
	}
}

function deleteModal(id_to_delete, friendly_name){
	Control.Modal.open('<div>\
		<h2>Delete Client?</h2>\
		<div class="dialog_content">\
			<div class="dialog_body">Are you sure you want to delete client #' + id_to_delete + ' (' + friendly_name + ')?<br />Note: This CANNOT be undone.</div>\
			<div id="dialog_buttons" class="dialog_buttons">\
				<input type="button" value="Delete" onclick="deleteClient(' + id_to_delete + ');" class="dialog-button"/>\
				<input type="button" value="Cancel" onclick="Control.Modal.close();" class="dialog-button"/>\
			</div>\
		</div>\
	</div>', {fade:true, overlayCloseOnClick:false});
}

function mismatchModal(){
	Control.Modal.open('<div>\
		<h2>Kill Mismatch13?</h2>\
		<div class="dialog_content">\
			<div class="dialog_body">Run Mismatch13-Fix on all stores?<br />A report will be emailed to the administrator with the results of the process.</div>\
			<div id="dialog_buttons" class="dialog_buttons">\
				<input type="button" value="Kill Mismatch13" onclick="runMismatch();" class="dialog-button"/>\
				<input type="button" value="Cancel" onclick="Control.Modal.close();" class="dialog-button"/>\
			</div>\
		</div>\
	</div>', {fade: true, overlayCloseOnClick: false});
}

function runMismatch(){
	new Ajax.Request('/malibu/helios/fixmismatch', {asynchronous:true});
	$('mismatch13_link').replace('<span><em>Mismatch13 is currently being fixed. Please wait at least 10 minutes and reload this page if you want to run the Mismatch13 fix again.</em></span>');
}

function deleteClient(id_to_delete){
	new Ajax.Request('/malibu/helios/helios_clients/'+id_to_delete+'.js', {
		asynchronous: true,
		method: 'delete'
	});
	Control.Modal.open("<div class='loading-dialog'><img src='/images/ajax-loader.gif' valign='middle' />&nbsp;Deleting from all locations...</div>", {fade: true, overlayCloseOnClick: false});
}
