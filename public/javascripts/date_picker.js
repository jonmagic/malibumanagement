/* ANSI Datepicker Calendar - David Lee 2005

  david [at] davelee [dot] com [dot] au

  project homepage: http://projects.exactlyoneturtle.com/date_picker/

  License:
  use, modify and distribute freely as long as this header remains intact;
  please mail any improvements to the author

  Modified by Daniel Parker to not require id's of elements

  To include in your code:
   1) Create a form element and a link
   2) In the link, onclick, call DatePicker.toggle() with two arguments: the form element (the dom element, not an id) and the link element (just use 'this').
*/

var months = 'January,February,March,April,May,June,July,August,September,October,November,December'.split(',');
function getMonthName(monthNum) { //anomalous
	return months[monthNum];
};

var date_pickerzes = [];

var DatePicker = {
	hide: function(form_el, link_el){
		re = / picker_([0-9]+)$/;
		matches = re.exec(link_el.className);
		if(matches){
			if(date_pickerzes['_'+matches[1]]){
				date_pickerzes['_'+matches[1]].hideDatePicker();
			}
		}
	},

	toggle: function(form_el, link_el, display_as){
		re = / picker_([0-9]+)$/;
		matches = re.exec(link_el.className);
		if(matches){
			if(date_pickerzes['_'+matches[1]]){
				date_pickerzes['_'+matches[1]].toggleDatePicker();
			}
		} else {
			var picker = new DatePickerEngine(form_el, link_el, display_as);
			picker.toggleDatePicker();
		}
	},

	picker: function(picker_id){
		return date_pickerzes['_'+picker_id];
	}
};

function DatePickerEngine(form_el, link_el, display_as){
	var that = this;
	this.picker_id = Math.floor(Math.random()*1000); // Allows for the links to reference the right DatePicker object via the two accessor methods above.
	this.form_element = form_el;
	this.link_element = link_el;
	date_pickerzes['_'+this.picker_id] = this;
	this.link_element.className = [this.link_element.className.split(' '), 'picker_'+this.picker_id].join(' ');
	date_pickerzes[this.link_element] = this;
	this.calendar_element = null;
	this.version = 0.4;
  /* Configuration options */
	this.constantHeight = true;
	this.useDropDownForYear = false;
	this.useDropDownForMonth = false;
	this.yearsPriorInDrop = 10;
	this.yearsNextInDrop = 10;
	this.year = new Date().getFullYear();
	this.firstDayOfWeek = 0;
	this.abbreviateMonthInLink = true;
	this.abbreviateYearInLink = false;
	this.showDaySuffixInLink = false;
	this.showDaySuffixInCalendar = false;
	this.largeCellSize = 22;
	this.showCancelLink = true;
	this._priorLinkText = link_el.innerHTML;
	this._priorDate = form_el.value;
	this.days = 'Sun,Mon,Tue,Wed,Thu,Fri,Sat'.split(',');
	this.displayAs = display_as || function(date){
		var ansi_date=date.getFullYear() + '-' + (date.getMonth()+1) + '-' + date.getDate();
		var d_day=(that.showDaySuffixInLink ? that.formatDay(ansi_date.split('-')[2]) : ansi_date.split('-')[2]);
		var d_year=(that.abbreviateYearInLink ? ansi_date.split('-')[0].substring(2,4) : ansi_date.split('-')[0]);
		var d_mon=getMonthName(Number(ansi_date.split('-')[1])-1);
		if(that.abbreviateMonthInLink) d_mon=d_mon.substring(0,3);
		return(d_mon + ' ' + d_day + ', ' + d_year);
	};

  /* Method declarations */
	this.showDatePicker = function(){
		if(that.calendar_element == null) that.writeCalendar();
		that.calendar_element.style.display = 'block';
		that._priorLinkText = that.link_element.innerHTML;
		that._priorDate = that.form_element.value;
	};
	this.hideDatePicker = function(){
		if(that.calendar_element == null) that.writeCalendar();
		that.calendar_element.style.display = 'none';
	};
	this.toggleDatePicker = function(){
		if(that.calendar_element == null) that.writeCalendar();
		if(that.calendar_element.style.display == 'block'){
			that.hideDatePicker();
		} else {
			that.showDatePicker();
		}
	};

	this.writeCalendar = function(){
		var date = that.selectedDate();
		var firstWeekday = new Date(date.getFullYear(), date.getMonth(), 1).getDay();
		var lastDateOfMonth = new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();
		var day = 1; // current day of month

		// not quite entirely pointless: fix Safari display bug with absolute positioned div
		that.link_element.innerHTML = that.link_element.innerHTML;

		var o = '<table cellspacing="1">'; // start output buffer
		o += '<thead><tr>';

		// month buttons
		o +=
			'<th style="text-align:left">' + that.makeChangeCalendarLink('&lt;',-1) + '</th>' +
			'<th colspan="5">' + (that.showDaySuffixInCalendar ? that.formatDay(date.getDate()) : date.getDate()) +
			' ' + that.writeMonth(date.getMonth()) + '</th>' +
			'<th style="text-align:right">' + that.makeChangeCalendarLink('&gt;',1) + '</td>';
		o += '</tr><tr>';

		// year buttons
		o +=
			'<th colspan="2" style="text-align:left">' + that.makeChangeCalendarLink('&lt;&lt;',-12) + '</th>' +
			'<th colspan="3">' + that.writeYear(date.getFullYear()) + '</th>' +
			'<th colspan="2" style="text-align:right">' + that.makeChangeCalendarLink('&gt;&gt;',12) + '</th>';
		o += '</tr><tr class="day_labels">';

		// day labels
		for(var i=0; i<that.days.length; i++){
			o += '<th>' + that.days[(i+that.firstDayOfWeek) % 7] + '</th>';
		}
		o += '</tr></thead>';

		if(that.showCancelLink){
			o += '<tfoot><tr><td colspan="7"><div class="cancel_butt"><a href="javascript:void(0)" onclick="DatePicker.picker('+that.picker_id+').cancel()">[x] cancel</a></div></td></tr></tfoot>';
		}

		// day grid
		o += '<tbody>';
		for(var r=1; r<7 && (that.constantHeight || day < lastDateOfMonth); r++){
			o += '<tr>';
			for(var dn=0; dn<that.days.length; dn++){
				var tr_day = (that.firstDayOfWeek + dn) % 7
				if((tr_day >= firstWeekday || day > 1) && (day <= lastDateOfMonth)){
					pdate = date.getFullYear() + '-' + (date.getMonth() + 1) + '-' + day;
					style = (that.selectMonth ? 'style="width: ' + that.largeCellSize + 'px"' : '')
					o +=
						'<td ' + style + '>' + // link : each day
						"<a href=\"javascript:void(0)\" onclick=\"DatePicker.picker(" + that.picker_id + ").pickDate('" + pdate + "'); return false;\">" + day + '</a>' +
						'</td>';
					day++;
				} else {
					o += '<td>&nbsp;</td>';
				}
			}
			o += '</tr>';
		}
		o += '</tbody></table>';

		//write the calendar...
		if(that.calendar_element == null) that.calendar_element = document.createElement('span');
		that.calendar_element.className = 'date_picker';
		that.calendar_element.innerHTML = o;
		that.form_element.parentNode.appendChild(document.createTextNode(' '));
		that.link_element.parentNode.insertBefore(that.calendar_element,that.link_element.nextSibling);
		true;
	};

	this.rewriteCalendar = function(){
		that.writeCalendar();
	};

	this.makeChangeCalendarLink = function(label, month_offset){
		return('<a href="javascript:void(0)" onclick="DatePicker.picker('+that.picker_id+').changeCalendar('+month_offset+')">' + label + '</a>');
	};

	this.formatDay = function(date){
		var x;
		switch (String(date)){
			case '1' :
			case '21': case '31': x = 'st'; break;
			case '2' : case '22': x = 'nd'; break;
			case '3' : case '23': x = 'rd'; break;
			default:
				x = 'th';
		}

		return date + x;
	};

	this.writeMonth = function(month){
		if(that.useDropDownForMonth){
			var ops='';
			for(i in that.months){
				sel=(i==that.selectedDate().getMonth() ? 'selected="selected" ' : '');
				ops += '<option ' + sel + 'value="'+ i +'">' + getMonthName(i) + '</option>';
			}
			return '<select onchange="DatePicker.picker(\'' + that.picker_id + '\').selectMonth(this.value)">' + ops + '</select>';
		} else {
			return getMonthName(month);
		}
	};

	this.writeYear = function(year){
		if(that.useDropDownForYear){
			var min = that.year - that.yearsPriorInDrop;
			var max = that.year + that.yearsNextInDrop;
			var ops = '';
			for(var i=min; i<max; i++){
				sel=(i==that.selectedDate().getFullYear() ? 'selected="selected" ' : '');
				ops += '<option ' + sel + 'value="' + i + '">' + i + '</options>';
			}
			return '<select onchange="DatePicker.picker(\'' + that.picker_id + '\').selectYear(this.value)">' + opts + '</select>';
		} else {
			return year;
		}
	};

	this.selectedDate = function(){
		if(that.form_element.value=='') return new Date(); // default to today if no value exists
		return that.dateFromAnsiDate(that.form_element.value);
	};

	this.dateFromAnsiDate = function(ansi_date){
		return new Date(ansi_date.split('-')[0], Number(ansi_date.split('-')[1]) - 1, ansi_date.split('-')[2]);
	};

	this.cancel = function(){
		delete date_pickerzes[that.link_element];
		delete date_pickerzes[that.picker_id];
		that.link_element.innerHTML = that._priorLinkText;
		that.form_element.value = that.priorDate;
		// 'unwrite' the calendar
		pren = that.calendar_element.parentNode;
		pren.removeChild(that.calendar_element);
		that.calendar_element = null;
	};

	this.pickDate = function(ansi_date){
		that.setDate(ansi_date);
		that.toggleDatePicker();
	};

	this.setDate = function(ansi_date){
		that.form_element.value = ansi_date;
		that.link_element.innerHTML = that.displayAs(that.dateFromAnsiDate(ansi_date));
	};

	this.changeCalendar = function(month_offset){
		var d1=that.selectedDate();
		var d2;
		if(month_offset % 12 == 0){ // 1 year forward / back (fix Safari bug)
			d2 = new Date(d1.getFullYear() + month_offset / 12, d1.getMonth(), d1.getDate());
		} else if(d1.getMonth() == 0 && month_offset == -1){ // tiptoe around another Safari bug
			d2 = new Date(d1.getFullYear() - 1, 11, d1.getDate());
		} else {
			d2 = new Date(d1.getFullYear(), d1.getMonth() + month_offset, d1.getDate());
		}
		d2 = that.unclipDates(d1,d2);
		var ansi_date=d2.getFullYear() + '-' + (d2.getMonth()+1) + '-' + d2.getDate();
		that.setDate(ansi_date);
		that.rewriteCalendar();
	};

	this.unclipDates = function(d1,d2){
		if(d2.getDate() != d1.getDate()){
			d2 = new Date(d2.getFullYear(), d2.getMonth(), 0);
		}
		return d2;
	};

	this.selectMonth = function(month){
		d=that.selectedDate();
		d2=new Date(d.getFullYear(), month, d.getDate());
		d2=that.unclipDates(d,d2);
		that.setDate(d2.getFullYear() + '-' + (Number(month)+1) + '-' + d2.getDate());
		that.rewriteCalendar();
	};

	this.selectYear = function(year){
		d=that.selectedDate();
		d2=new Date(year, d.getMonth(), d.getDate());
		d2=that.unclipDates(d,d2);
		that.setDate(year + '-' + (d2.getMonth()+1) + '-' + d2.getDate());
		that.rewriteCalendar();
	};
}
