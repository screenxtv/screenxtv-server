function TerminalView(terminalElement,host,port,channelID,autoresize){
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
	function resizeUpdate(){
		if(!autoresize)return;
		var e=$(terminalElement);
		e.css("transform","none");
		var w=innerWidth-20,h=innerHeight-20;
		var w2=e.width(),h2=e.height();
		var scale=Math.min(w/w2,h/h2);
		console.log(scale)
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
	var socket=io.connect('http://'+host+":"+port);
	socket.on('connect',function(){
		socket.emit('init',{channel:channelID},function(){console.log('init')});
		window.socket=socket;
	});
	socket.on('init',initTerminal);
	socket.on('viewer',function(data){console.log('viewer',data);if(self.onViewerChange)self.onViewerChange(data)});
	socket.on('chat',function(data){console.log('chat',data);if(self.onChatArrive)self.onChatArrive(data)});
	socket.on('castStart',function(data){initTerminal(data);if(self.onCastStart)self.onCastStart()});
	socket.on('castData',function(data){updateTerminal(data)});
	socket.on('castWINCH',function(data){resizeTerminal(data.width,data.height)});
	socket.on('castEnd',function(){if(self.onCastEnd)self.onCastEnd()});
	this.resize=resizeUpdate;
	this.post=function(message){
		$.post('/post/'+channelID,{authenticity_token:csrf_token,message:message})
	}
}


