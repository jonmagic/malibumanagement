// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function numbersonly(e){
	var unicode=e.charCode? e.charCode : e.keyCode
	alert("KeyCode: "+unicode)
	if (unicode!=8 && unicode!=9 && unicode!=16 && unicode!=17 && unicode!=35 && unicode!=36 && unicode!=37 && unicode!=39 && unicode!=46 && unicode!=114 && unicode!=116 && unicode!=190 && unicode!=63232 && unicode!=63233 && unicode!=63234 && unicode!=63235 && unicode!=46 && unicode!=63272) { //allow all these keys: 8=backspace; 9=tab; 16=shift; 17=ctrl; 35=end; 36=home; 37=left; 39=right; 190=period; 63232+=safari-arrowkeys;
		if (unicode<48||unicode>57) //if not a number
			return false //disable key press
	}
}
