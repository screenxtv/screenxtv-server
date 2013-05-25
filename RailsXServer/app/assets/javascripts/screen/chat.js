function onSocialConnect(social){
  social_info=social;
  $(".social_connect").removeClass("active");
  $("#chatform").removeClass("login")
  $("#chatform").removeClass("twitter_enabled")
  if(social_info.main){
    var info=social_info[social_info.main];
    $(".social_connect."+social_info.main).addClass('active');
    if(social_info.main=='twitter')$("#mysocial span").css({display:'inline'})
    $("#form_icon").text('').append($("<img/>").attr('src',info.icon));
    $("#chatform form").css('padding-left',40);
  }else{
    $(".social_connect.anonymous").addClass('active');
    $("#form_icon").text('');
    $("#chatform form").css('padding-left','');
  }
  if(social_info.main=='user'){
    $("#chatform").addClass("login");
    if(social_info.twitter){
      $("#chatform").addClass("twitter_enabled")
      $("#chatlist").attr("data-margin-top",92);
    }else{
      $("#chatlist").attr("data-margin-top",80);
    }
  }
}


$(function(){
  $("#chatform form").mousedown(function(){$("#message").focus();})
  $("#message").focus(function(){$("#chatform form").css({'box-shadow':'0 0 8px blue','border-color':'#aaf'})})
  $("#message").blur(function(){$("#chatform form").css({'box-shadow':'none','border-color':''})})
  $(".social_connect").click(function(){
    var provider=$(this).data('provider');
    if(provider=='anonymous')social_info.main=null;
    else if(social_info[provider]){social_info.main=provider;}
    else{
      window.open('/oauth/'+provider+'/popup','socialconnect','width=600,height=400,toolbar=no,menubar=no,status=no');
      return;
    }
    $.post(
      "/oauth/switch",
      {authenticity_token:csrf_token, provider: provider},
      function(info){onSocialConnect(info);}
    );
    onSocialConnect(social_info)
  })
});


