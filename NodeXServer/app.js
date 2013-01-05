var express = require('express')
	, http = require('http')
	, net = require('net')
	, crypto=require('crypto')
	, VT100 = require('../vt100/vt100')
	, request = require('request')
var app = express();

var PORT=8800
var RAILS_PORT=8008;
var UNIX_PORT=8000;
var RAILS_IP="127.0.0.1"
function notify(id,data){
	request.post({
		uri:'http://localhost:'+RAILS_PORT+'/screens/notify/'+id,
		json:data
	});
}
function auth(id,data,cb){
	request.post({
		uri:'http://localhost:'+RAILS_PORT+'/screens/authenticate/'+id,
		json:data
	},cb);
}

app.configure(function(){
	RAILS_PORT=process.env.RAILS_PORT||RAILS_PORT;
	UNIX_PORT=process.env.NODE_UPORT||UNIX_PORT;
	PORT=process.env.NODE_PORT||PORT;
	app.use(express.bodyParser());
	app.use(express.methodOverride());
	app.use(app.router);
});

app.configure('development', function(){
	console.log('development')
	app.use(express.errorHandler());
});
app.configure('production', function(){
	console.log('production')
});

app.get('/:id',function(req,res){
	if(req.connection.remoteAddress!=RAILS_IP){res.end();return}
	var channel=ChannelData.channelActiveMap['#'+req.params.id];
	res.end(JSON.stringify(channel&&{info:channel.info,vt100:channel.vt100}));
});

app.post('/:id',function(req,res){
	if(req.connection.remoteAddress!=RAILS_IP){res.end();return}
	//var channel=ChannelData.channelActiveMap['#'+req.params.id];
	var channel=ChannelData.channelMap['#'+req.params.id];
	if(channel&&req.body.type=='chat')channel.chat({name:req.body.name,icon:req.body.icon,message:req.body.message});
	res.end();
})

var server=http.createServer(app).listen(PORT,function(){
	console.log("Express server listening on port " + PORT);
});



function md5(){return crypto.createHash('md5').update('a').digest()}
function md5_hex(){return crypto.createHash('md5').update('a').digest('hex')}


var socketio=require('socket.io');
var io_option={'destroy buffer size':10E6};
var io=socketio.listen(server,io_option);
io.set("log level",1);

io.sockets.on('connection',function(socket){
	console.log('connection!')
	socket.on('init',function(data){
		var channel=ChannelData.getChannelData(data.channel);
		console.log('joined',data.channel)
		channel.join(socket);
		socket.on('disconnect',function(){channel.leave(socket)});
	});
})

function ChannelData(id){
	this.channelID=id;
	this.castInfo={viewer:0,total_viewer:0,max_viewer:0,total_time:0};
	this.statistics=null;
	this.castSocket=null;
	this.castPassword=null;
	this.endTimer=null;
	this.vt100=null;
	this.info=null;
	this.notifyTimer=null;
	this.pauseCount=0;
	this.chatlist=null;
}
ChannelData.prototype.broadcast=function(type,data,except){
	if(this.castSocket){
		if(this.castSocket!=except)this.castSocket.emit(type,data);
		else except=null;
	}
	if(except)except.broadcast.to(this.channelID).emit(type,data);
	else io.sockets.in(this.channelID).emit(type,data);
}
ChannelData.prototype.getInitData=function(){
	return {info:this.info,casting:this.castSocket?true:false,vt100:this.vt100,viewer:this.castInfo,chatlist:this.chatlist};
}
ChannelData.prototype.getSlugData=function(){return this.channelID+(this.castPassword&&'#'+this.castPassword);}
ChannelData.prototype.getAdminData=function(){
	return {viewer:this.castInfo,chatlist:this.chatlist,slug:this.channelID+'#'+this.castPassword}
}
ChannelData.prototype.join=function(socket){
	socket.join(this.channelID);
	this.castInfo.viewer++;
	this.castInfo.total_viewer++;
	this.castInfo.max_viewer=Math.max(this.castInfo.max_viewer,this.castInfo.viewer);
	if(this.statistics){
		this.statistics.total_viewer++;
		this.statistics.max_viewer=Math.max(this.statistics.max_viewer,this.castInfo.viewer);
	}
	socket.emit('init',this.getInitData());
	this.broadcast('viewer',this.castInfo,socket)
}
ChannelData.prototype.leave=function(socket){
	socket.leave(this.channelID);
	this.castInfo.viewer--;
	this.broadcast('viewer',this.castInfo,socket)
	ChannelData.removeChannelData(this);
};
ChannelData.channelMap={};
ChannelData.channelActiveMap={};

function genRandomID(n){
	var name="";
	var chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
	for(var i=0;i<n;i++)name+=chars.charAt(chars.length*Math.random());
	return name;
}
ChannelData.genUniqID=function(n){
	for(var len=n||2;len<16;len++){
		var name=genRandomID(len);
		if(!ChannelData.channelMap['#'+name])return name;
	}
	return null;
}
ChannelData.getChannelData=function(id){
	var key='#'+id;
	var channel=ChannelData.channelMap[key];
	if(channel)return channel;
	return ChannelData.channelMap[key]=new ChannelData(id);
}
ChannelData.removeChannelData=function(channel){
	if(channel.chatlist==null&&channel.castInfo.viewer==0)
		delete ChannelData.channelMap['#'+channel.channelID];
}
ChannelData.prototype.notify=function(data){notify(this.channelID,this.private?{status:'private'}:data)}
ChannelData.prototype.createNotifyData=function(status){
	var time=Math.round((new Date()-this.startTime)/1000);
	return {
		status:status,
		total_viewer:this.statistics?this.statistics.total_viewer:0,
		max_viewer:this.statistics?this.statistics.max_viewer:0,
		total_time:this.statistics?this.statistics.total_time+time:0,

		vt100:JSON.stringify(this.vt100.getSubData(40,12)),
		title:this.info.title,
		color:this.info.color,
		current_viewer:this.castInfo.viewer,
		current_max_viewer:this.castInfo.max_viewer,
		current_total_viewer:this.castInfo.total_viewer,
		current_time:this.castInfo.total_time+time,
		pause_count:this.pauseCount
	};
}
ChannelData.prototype.notifyStatus=function(){
	if(this.notifyTimer)clearTimeout(this.notifyTimer);
	var info=this.info||{};
	if(this.private)this.notify();
	else{
		var data=this.createNotifyData();
		data.vt100=JSON.stringify(this.vt100.getSubData(40,12));

		this.notify(this.createNotifyData('update'))
	}
	this.pauseCount++;
	var channel=this;
	this.notifyTimer=setTimeout(function(){channel.notifyStatus()},10*1000);
}
ChannelData.prototype.chat=function(data){
	data.time=Math.floor(new Date().getTime()/1000);
	if(this.chatlist){
		this.chatlist.push(data);
		if(this.chatlist.length>256)this.chatlist.shift();
	}
	this.broadcast('chat',data);
}
ChannelData.prototype.castStart=function(socket,pswd,w,h,info,castInfo,chats){
	if(this.castPassword){
		if(this.castPassword!=pswd||this.private!=info.private)throw 'url already in use';
	}
	if(this.castSocket)this.castSocket.disconnect();
	if(this.chatlist==null)this.chatlist=chats||[];
	this.info=info;
	if(!this.statistics)this.statistics=castInfo||{total_viewer:0,max_viewer:0,total_time:0};
	if(!this.startTime)this.startTime=new Date();
	//this.private=info.private;
	this.castPassword=pswd;
	this.castSocket=socket;
	socket.emit('slug',this.getSlugData());
	socket.emit('init',this.getAdminData());
	this.vt100=new VT100(w,h);
	this.notifyStatus();
	this.broadcast('castStart',{info:this.info,vt100:this.vt100},socket);
	ChannelData.channelActiveMap['#'+this.channelID]=this;
	if(this.endTimer){clearTimeout(this.endTimer);this.endTimer=null;}
}
ChannelData.prototype.castWINCH=function(socket,w,h){
	if(this.castSocket!=socket)return;
	this.vt100.resize(w,h);
	this.broadcast('castWINCH',{width:w,height:h},socket);
	this.pauseCount=0;
}
ChannelData.prototype.castData=function(socket,data){
	if(this.castSocket!=socket)return;
	for(var i=0;i<data.length;i++)this.vt100.write(data[i]);
	this.broadcast('castData',data,socket);
	this.pauseCount=0;
}
ChannelData.prototype.castEnd=function(socket){
	if(this.castSocket!=socket)return;
	clearTimeout(this.notifyTimer);this.notifyTimer=null;
	this.notify(this.createNotifyData('castend'))
	this.broadcast('castEnd','castend',socket);
	var time=Math.round((new Date()-this.startTime)/1000);
	this.castSocket=null;
	this.startTime=null;
	this.castInfo.total_time+=time;
	if(this.statistics)this.statistics.total_time+=time;
	var channel=this;
	this.endTimer=setTimeout(function(){channel.ended()},10*60*1000);
}
ChannelData.prototype.ended=function(){
	this.castPassword=null;
	this.endTimer=null;
	this.vt100=null;
	this.info=null;
	this.chatlist=null;
	this.notify({status:'terminate'})
	this.broadcast('terminate','terminate');
	delete ChannelData.channelActiveMap['#'+this.channelID];
	ChannelData.removeChannelData(this);
}


net.createServer(function(usocket){
	var channel=null;
	var iosocket={
		emit:function(key,value){if(usocket.writable)usocket.write(key+"\n"+JSON.stringify(value)+"\n")},
		disconnect:function(){usocket.end();}
	}
	var key={lengthRead:0,lengthReadSize:1,length:0,position:0};
	var val={lengthRead:0,lengthReadSize:2,length:0,position:0};
	var current=key;
	var trafficParam=trafficTime=0;
	var trafficSpan=1,trafficBps=256*1000;
	usocket.setKeepAlive(true,60*1000);
	usocket.on('data',function(data){
		var i=0;
		while(i<data.length){
			if(current.lengthRead<current.lengthReadSize){
				current.lengthRead++;
				current.length=(current.length<<8)|data[i++];
				if(current.lengthRead==current.lengthReadSize){
					current.data=new Buffer(current.length);
					current.position=0;
				}
				continue;
			}
			if(current.position<current.length){
				var rlen=current.length-current.position;
				var dlen=data.length-i;
				var len=Math.min(rlen,dlen);
				for(var j=0;j<len;j++)current.data[current.position++]=data[i++];
			}
			if(current.position==current.length){
				if(current==key)current=val;
				else{
				    try{ondata(key.data.toString(),val.data.toString());}catch(e){console.log(e)}
					current=key;
				}
				current.length=current.lengthRead=0;
			}
		}

		var time=new Date();
		var dt=time-trafficTime;
		var exp=Math.exp(-dt/(1000*trafficSpan));
		trafficTime=time;
		trafficParam=trafficParam*exp+(dt?data.length*(1-exp)*(1000*trafficSpan)/dt:data.length);
		var currentBps=trafficParam/trafficSpan;
		if(currentBps>trafficBps/2){
			var time=Math.round(1000*65536*currentBps/trafficBps/trafficBps);
			if(time>0){
				usocket.pause();
				setTimeout(function(){usocket.resume()},time)
			}
		}
	})
	function ondata(key,value){
	    try{
		switch(key){
			case 'init':oninit(JSON.parse(value));break;
			case 'chat':if(channel)channel.chat({name:'admin',message:value});break;
			case 'data':if(channel)channel.castData(iosocket,value);break;
			case 'winch':if(channel)onwinch(JSON.parse(value));break;
			default:return;
		}
	    }catch(e){console.log(e);}
	}
	function onwinch(size){
		try{
			var w=parseInt(size.width),h=parseInt(size.height);
			channel.castWINCH(iosocket,w,h);
		}catch(e){console.log(e);}
	}
	function oninit(data){
		if(data.user&&data.password){
			console.log(data.user+" "+data.password);
			auth(data.user,{user:data.user,password:data.password},function(err,result,data){
				console.log(data)
				if(data&&data.auth_key)iosocket.emit('auth',data.auth_key)
				else iosocket.emit('error',data?data.error||data:'unknown');
				iosocket.disconnect();
			});
			return;
		}
		var kv=(data.slug||"").split('#');
		var info=data.info||{};
		var width=data.width,height=data.height;
		var url=kv[0],castkey=kv[1]||genRandomID(16);
		if(!url.match("^[a-zA-Z0-9_]*$")){
			iosocket.emit('errtype','url');
			iosocket.emit('error','invalid url');
			iosocket.disconnect();
			return;
		}
		var randsize=4,anonymousflag=false;
		if(!url){
			anonymousflag=true;
			url=ChannelData.genUniqID(randsize++);
		}

		function cb(err,result,data){
			console.log(data)
			if(!data||!data.cast){
				if(anonymousflag){
					auth(ChannelData.genUniqID(randsize<8?randsize++:8),{},cb);
				}else{
					iosocket.emit('error',data&&data.error?data.error:'unknown')
					iosocket.disconnect();
				}
			}else{
				try{
					channel=ChannelData.getChannelData(url);
					channel.castStart(iosocket,castkey,width,height,info,data.info,data.chats);
				}catch(e){
					console.log('cb',e);
					iosocket.emit('error',e);
					iosocket.disconnect();
				}
			}
		}
		auth(url,{user:data.user,auth_key:data.auth_key},cb);
	}
	usocket.on('error',function(){if(channel)channel.castEnd(iosocket);channel=null;});
	usocket.on('close',function(){if(channel)channel.castEnd(iosocket);channel=null;});
}).listen(UNIX_PORT,null,null,function(err){
	console.log("NodeX listening on port "+UNIX_PORT)
});

process.on('uncaughtException',function(err){
	console.log('Caught exception:',err);
});

