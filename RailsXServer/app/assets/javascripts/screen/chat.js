function addChat(chat,addedFlag){
  var div=$("<div class='chat'><img><div class='name'/><div class='message'/><div class='time'/></div>");
  if(addedFlag)chat.time=new Date().getTime()/1000;
  else chat.time=Math.min(new Date().getTime()/1000,chat.time);
  var imgsrc=chat.icon;
  if(!imgsrc)imgsrc="/assets/anonymous.png"
  div.children().eq(0).attr("src",imgsrc);
  if(chat.name)div.children().eq(1).text(chat.name);
  div.children().eq(2).text(chat.message);
  var time=div.children().eq(3);
  var chatlist=$("#chatlist");
  var wrap=$("<div class='chat_wrap'/>");
  wrap.append(div)
  var updateFunc=function(){
    var sec=Math.round(new Date().getTime()/1000-chat.time);
    var s10=Math.floor(sec/10)*10;
    var min=Math.floor(sec/60);
    var hour=Math.floor(min/60);
    var day=Math.floor(hour/24);
    if(day)day+=(day==1?'day':'days')+' ago';
    if(hour)hour+=(hour==1?'hour':'hours')+' ago';
    if(min)min+='min'+' ago';
    if(s10)s10+='sec'+' ago';
    time.text(day||hour||min||s10||'just now');
  }
  updateFunc();
  chatlist.prepend(wrap);
  if(addedFlag){
    animate(
      function(t){
        var h=div.outerHeight();
        if(t<1){
          div.css({top:-h*(1-t)});
          wrap.css({height:h*t});
        }else{
          div.css({top:''});
          wrap.css({height:''});
        }
      },200);
  }
  chatArray.push({obj:wrap,update:updateFunc});
  if(chatArray.length>256)chatArray.shift().obj.remove();
}
function animate(f,time){
  var starttime=new Date();
  function func(){
    var t=(new Date()-starttime)/time
    if(t>=1)t=1;
    try{f(t)}catch(e){console.log(e);}
    if(t<1)setTimeout(func,10);
  }
  setTimeout(func,10);
  try{f(0)}catch(e){console.log(e)}
}
function updateTime(){
  for(var i=0;i<chatArray.length;i++)chatArray[i].update();
}
setInterval(updateTime,1000);
var chatArray=[];
function clearChat(){
  chatArray=[];
  $("#chatlist").text('');
}

function postSubmitCheck(e){
  if(e.keyCode!=13||e.metaKey||e.altKey||e.shiftKey||e.ctrlKey)return true;
  post();
  return false;
}



var patterns=[
    [/https?:\/\/[^ ]+/g,function(e,s){$("<a />").attr("href",s).attr("target","_blank").text(s).appendTo(e)}]
]
function chatMessageParse(element,text){
  function parse(e,s,i){
    var p=patterns[i];
    if(!p){
      $("<span />").text(s).appendTo(e);
      return;
    }
    var list=s.split(p[0]);
    var joinlist=s.match(p[0]);
    for(var j=0;j<list.length;j++){
      if(list[j])parse(e,list[j],i+1);
      if(joinlist&&joinlist[j])p[1](e,joinlist[j]);
    }
  }
  var lines=text.split("\n"); 
  for(var i=0,line;line=lines[i];i++){
    var div=$("<div />");
    parse(div,line,0);
    element.append(div);
  }
}

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
  $("#chatform form").mousedown(function(){$("#message").focus();return false;})
  $("#message").focus(function(){$("#chatform form").css('box-shadow','0 0 8px blue')})
  $("#message").blur(function(){$("#chatform form").css('box-shadow','none')})
  $(".social_connect").click(function(){
    var provider=$(this).data('provider');
    if(provider=='anonymous')social_info.main=null;
    else if(social_info[provider]){social_info.main=provider;}
    else{
      window.open('/auth/'+provider+'?popup','socialconnect','width=600,height=400,toolbar=no,menubar=no,status=no');
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

$(function(){
  addChat({name:'aaa',message:'gbbbb'})
  addChat({name:'aaa',message:'gbbbb'})
  addChat({name:'aaa',message:'gbbbb'})
  addChat({name:'aaa',message:'gbbbb'})
  addChat({name:'aaa',message:'gbbbb'})
});