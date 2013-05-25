function TerminalView(terminalElement,host,port,channelID,autoresize){
	var nodesessionid=null;
	try{
		nodesessionid=localStorage.nodesessionid
		if(!nodesessionid){
			var val="",ch="0123456789abcdefghijklmnopqrstuvwxyz";
			for(var i=0;i<16;i++)val+=ch.charAt(ch.length*Math.random()|0)
			localStorage.nodesessionid=nodesessionid=val
		}
	}catch(e){}
	var self=this;
	var terminal;
	function initTerminal(){
		console.log(arguments);
		switch(arguments.length){
			case 1:{
				var vt100=new VT100(arguments[0].vt100);
				var info=arguments[0].info||{};
				terminal=new Terminal(terminalElement,vt100.W,vt100.H,Terminal.defaultColorMap[info.color]);
				terminal.vt100=new VT100(vt100);
			}break;
			case 2:{
				var width=arguments[0],height=arguments[1];
				terminal=new Terminal(terminalElement,width,height);
			}break;
			default:return;
		}
		terminal.updateView();
		resizeUpdate();
	}
	function resizeTerminal(w,h){
		var e=$(terminalElement);
		e.css("transform","none");
		terminal.resize(w,h);
		terminal.updateView();
		resizeUpdate();
	}
	var width,height;
	function resizeUpdate(){
		if(!autoresize)return;
		if(arguments.length==2){
			width=arguments[0];
			height=arguments[1];
		}
		var e=$(terminalElement);
		e.css("transform","none");
		var w=width-20,h=height-20;
		var w2=e.width(),h2=e.height();
		var scale=Math.min(w/w2,h/h2);
		var ww=w2*scale,hh=h2*scale;
		e.css("transform-origin","0 0");
		e.css("transform","scale("+scale+")");
		e.css({position:"absolute",left:(w-ww)/2,top:0});
	}
	var delay_string="",delay_timer=null;
	function updateTerminal(data){
		delay_string+=data;
		delay_func();
	}
	function delay_func(){
		if(delay_timer)return;
		if(!delay_string)return;
		for(var i=0;i<delay_string.length;i++)terminal.write(delay_string.charAt(i));
		terminal.updateView();
		delay_string="";
		delay_timer=setTimeout(function(){delay_timer=0;delay_func();},100);
	}
	var socket=io.connect('http://'+host+":"+port,{'reconnect':true,'reconnection delay':500,'max reconnection attempts':10});
	socket.on('connect',function(){
		socket.emit('init',{channel:channelID, sid:nodesessionid},function(){console.log('init')});
	});
	var sendings=[];
	sendings.remove=function(k){var i=this.indexOf(k);if(i<0)return false;this.splice(i,1);return 1}
	socket.on('reconnect_failed',function(){socket=null;if(self.onClose)self.onClose();})
	socket.on('disconnect',function(){})
	socket.on('init',function(data){if(terminalElement)initTerminal(data);if(self.onInit)self.onInit(data);});
	socket.on('viewer',function(data){console.log('viewer',data);if(self.onViewerChange)self.onViewerChange(data)});
	socket.on('chat',function(data){
		if(sendings.remove(data.rand)&&self.onChatSendDone)self.onChatSendDone(data.rand)
		if(self.onChatArrive)self.onChatArrive(data)
	});
	socket.on('castStart',function(data){if(terminalElement)initTerminal(data);if(self.onCastStart)self.onCastStart(data)});
	socket.on('castData',function(data){if(terminalElement)updateTerminal(data)});
	socket.on('castWINCH',function(data){resizeTerminal(data.width,data.height)});
	socket.on('castEnd',function(){if(self.onCastEnd)self.onCastEnd()});
	this.resize=resizeUpdate;
	this.post=function(message,twitter){
		if(!socket)return;
		var rand=(Math.random()+"").substr(1);
		sendings.push(rand);
		data={authenticity_token:csrf_token,message:message,rand:rand};
		if(twitter)data.post_to_twitter=true;
		if(self.onChatSendStart)self.onChatSendStart(rand);
		$.ajax({
			type:'post',
			url:'/screens/post/'+channelID,
			data:data,
			error:function(data){
				if(sendings.remove(rand)&&self.onChatSendFailed)self.onChatSendFailed(rand);
			}
		})
	}
}

$(function(){
	var chatArray=[];

	if(window.social_info)onSocialConnect(social_info);
	if(window.title)$("#terminaltitle").text(title);
	if(!channelID)return;
	if(window.chats){
		for(var i=0;i<chats.length;i++)addChat(chats[i])
	}
	function terminalViewInit(){
		terminalview=new TerminalView(document.getElementById("terminal"),host,port,channelID,true)
		terminalview.onChatArrive=function(chat){
			try{
				addChat(chat,true);
			}catch(e){console.log(chat)}
		}
		terminalview.onInit=function(data){
			if(!data.vt100){
				$("#terminal").text('OFF AIR');
				window.onresize();
			}
			var title=data.info?data.info.title:""
			$("#terminaltitle").text(title);
			document.title=(title?title+" - ":"")+"ScreenX TV";
			if(data.casting)terminalview.onCastStart();
			else terminalview.onCastEnd();
			if(data.chatlist){
				clearChat();
				for(var i=0;i<data.chatlist.length;i++){
					var chat=data.chatlist[i];
					try{
						addChat(chat);
					}catch(e){console.log(chat)}
				}
			}
			terminalview.onViewerChange(data.viewer);
		}
		terminalview.onCastStart=function(data){
			$("#terminal").css({opacity:1})
		}
		terminalview.onCastEnd=function(){
			$("#terminal").css({opacity:0.5})
		}
		terminalview.onViewerChange=function(info){
			$("#viewer").text(info.viewer+"/"+info.total_viewer);
		}
		terminalview.onChatSendStart=function(){$("#chat_status").text('...').show()}
		terminalview.onChatSendDone=function(){$("#chat_status").fadeOut()}
		terminalview.onChatSendFailed=function(){$("#chat_status").html('&times').show().delay(1000).fadeOut()}
		terminalview.onClose=function(){
			setTimeout(function(){console.log('restart');
				terminalViewInit();
			},10*1000);
		}
	}
	terminalViewInit();
	window.hoge=terminalview
	




	function post(){
		var message=$("#message").val();
		$("#message").val("")
		if(!message.trim())return;
		var twit=$("#twitpost")[0];
		terminalview.post(message,twit&&twit.checked);
	}





	function addChat(chat,addedFlag){
	  var div=$("<div class='chat'><a><img></a><div class='name'/><div class='message'/><div class='time'/></div>");
	  if(addedFlag)chat.time=new Date().getTime()/1000;
	  else chat.time=Math.min(new Date().getTime()/1000,chat.time);
	  var imgsrc=chat.icon;
	  if(!imgsrc)imgsrc="/assets/anonymous.png"
	  div.find("img").attr("src",imgsrc);
		if(chat.url){div.find("a").attr({href:chat.url,target:'_blank'})}
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
	
	function clearChat(){
	  chatArray=[];
	  $("#chatlist").text('');
	}

	function postSubmitCheck(e){
	  if(e.keyCode!=13||e.metaKey||e.altKey||e.shiftKey||e.ctrlKey)return true;
	  post();
	  return false;
	}
	window.postSubmitCheck=postSubmitCheck


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
})


