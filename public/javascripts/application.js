// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function numbersonly(e){
	var unicode=e.charCode? e.charCode : e.keyCode
	if (unicode!=8 && unicode!=9 && unicode!=16 && unicode!=17 && unicode!=37 && unicode!=39 && unicode!=110 && unicode!=190 && unicode!=35 && unicode!=36) { //if the key isn't the backspace key (which we should allow)
		if (unicode<48||unicode>57) //if not a number
			return false //disable key press
	}
}
