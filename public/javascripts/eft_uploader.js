// Functions: start_billing & repeat_billing
// Purpose: Repeatedly request that the eft files are uploaded, until they are all successfully uploaded.
// Method: Call the submit_payments action, receive the results (json), and then call it again if there are any left undone.
var start_billing = function(for_month, outgoing_bucket, free_dcas_lock){
  // 1) Setup
  //  Everything goes in the #time_to_bill div.
  var $billing = jQuery('#time_to_bill');
  $billing.find('span').remove();
  $billing.find('p').remove();
  if(jQuery('#time_to_bill ul').length===0) $billing.append("<ul></ul>");
  jQuery('div.loading-dialog span').text("Uploading files to DCAS...");
  $billing.find('h3').text("Uploading files to DCAS...");
  repeat_billing(for_month, outgoing_bucket, free_dcas_lock);
};
var repeat_billing = function(for_month, outgoing_bucket, free_dcas_lock){
  var $billing = jQuery('#time_to_bill');
  var $billing_files = jQuery('#time_to_bill ul');
  // 2) Call the action
  jQuery.getJSON((outgoing_bucket ? '/malibu/eft/submit_payments?for_month='+for_month+'&outgoing_bucket='+outgoing_bucket : '/malibu/eft/submit_payments?for_month='+for_month)+"&free_dcas_lock=#{free_dcas_lock}", function(data){
    console.log(data);
    var key, that_remain=0, stores=[], msgs=[], store, msg;
    // 3) Integrate results
    for(key in data){
      if(data.hasOwnProperty(key)){
        if(key == 'error'){
          alert(data[key]);
        }else{
          stores.push({'key':key, 'msg':data[key]});
        }
      }
    }
    stores.sort(function(a,b){
      if(a.key > b.key) return 1;
      else if(a.key < b.key) return -1;
      else return 0;
    });
    for(i in stores){
      if(stores.hasOwnProperty(i)){
        key = stores[i].key;
        store = key.split('--')[0];
        msg = stores[i].msg;
        if(jQuery("#upload_status_"+key).length===0){
          $billing_files.append("<li class='file_upload_status'>"+store.charAt(0).toUpperCase()+store.substr(1)+" - <span id='upload_status_"+key+"'>"+msg+"</span></li>");
        }else{
          jQuery("#upload_status_"+key).text(msg);
        }
        if(msg.split(' ')[0] === "Failed"){
          jQuery("#upload_status_"+key).parent().addClass('failed');
          that_remain = that_remain + 1; // if first word is "Failed"
        }else if(msg === "Uploaded."){
          jQuery("#upload_status_"+key).parent().removeClass('failed').addClass('uploaded');
        }else{
          that_remain = that_remain + 1; // files that weren't even tried yet.
        }
      }
    }
    // 4) repeat from #2 if some remain
    if(that_remain > 0){
      jQuery('div.loading-dialog span').text("Uploading to DCAS: Retrying "+that_remain+" files...");
      $billing.find('h3').text("Uploading to DCAS: Retrying "+that_remain+" files...");
      repeat_billing(for_month, outgoing_bucket, free_dcas_lock);
    }else{
      $billing.find('h3').text("All Payments are Uploaded.");
      Control.Modal.close();
    }
  });
};
