// Functions: start_billing & repeat_billing
// Purpose: Repeatedly request that the eft files are uploaded, until they are all successfully uploaded.
// Method: Call the submit_payments action, receive the results (json), and then call it again if there are any left undone.
var start_billing = function(for_month, incoming_path){
  // 1) Setup
  //  Everything goes in the #time_to_bill div.
  var $billing = jQuery('#time_to_bill');
  $billing.find('span').remove();
  $billing.find('p').remove();
  if(jQuery('#time_to_bill ul').length===0) $billing.append("<ul></ul>");
  jQuery('div.loading-dialog span').text("Uploading files to DCAS...");
  repeat_billing(for_month, incoming_path);
};
var repeat_billing = function(for_month, incoming_path){
  var $billing = jQuery('#time_to_bill');
  var $billing_files = jQuery('#time_to_bill ul');
  // 2) Call the action
  jQuery.getJSON((incoming_path ? '/malibu/eft/submit_payments?for_month='+for_month+'&incoming_path='+incoming_path : '/malibu/eft/submit_payments?for_month='+for_month), function(data){
    console.log(data);
    var key, that_remain=0, store, type;
    // 3) Integrate results
    // jQuery('#time_to_bill ul li').remove();
    for(key in data){
      if(key == 'error'){
        alert(data[key]);
      }else{
        type = key.split('--')[1];
        store = key.split('--')[0];
        if(jQuery("#upload_status_"+key).length===0){
          $billing_files.append("<li class='file_upload_status'>"+store.charAt(0).toUpperCase()+store.substr(1)+" ("+type+") - <span id='upload_status_"+key+"'>"+data[key]+"</span></li>");
        }else{
          jQuery("#upload_status_"+key).text(data[key]);
        }
        if(data[key].split(' ')[0] == "Failed"){
          jQuery("#upload_status_"+key).addClass('failed');
          that_remain = that_remain + 1; // if first word is "Failed"
        }else{
          jQuery("#upload_status_"+key).removeClass('failed').addClass('uploaded');
        }
      }
    }
    // 4) repeat from #2 if some remain
    if(that_remain > 0){
      jQuery('div.loading-dialog span').text("Uploading to DCAS: Retrying "+that_remain+" files...");
      $billing.find('h3').text("Uploading to DCAS: Retrying "+that_remain+" files...");
      repeat_billing(for_month, incoming_path);
    }else{
      $billing.find('h3').text("All Payments are Uploaded.");
      Control.Modal.close();
    }
  });
};
