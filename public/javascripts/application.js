// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function numbersonly(e){
	var unicode=e.charCode? e.charCode : e.keyCode
	if (unicode!=8 && unicode!=9 && unicode!=16 && unicode!=17 && unicode!=35 && unicode!=36 && unicode!=37 && unicode!=39 && unicode!=190) { //allow all these keys: 8=backspace; 9=tab; 16=shift; 17=ctrl; 35=end; 36=home; 37=left; 39=right; 190=period
		if (unicode<48||unicode>57) //if not a number
			return false //disable key press
	}
}
