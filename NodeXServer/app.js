var express = require('express')
	, http = require('http')
	, net = require('net')
	, crypto=require('crypto')
	, VT100 = require('./vt100/vt100')
	, request = require('request')
var app = express();

var PORT=8080
var RAILS_PORT=80;
var UNIX_PORT=8000;

function notify(id,data){
	request.post({
		uri:'http://localhost:'+RAILS_PORT+'/screen_notify/'+id,
		json:data
	});
}



app.configure(function(){
    RAILS_PORT=process.env.RAILS_PORT||RAILS_PORT;
    UNIX_PORT=process.env.NODE_UPORT||UNIX_PORT;
	app.set('port',process.env.NODE_PORT||PORT);
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
	var channel=ChannelData.channelActiveMap['#'+req.params.id];
    res.end(JSON.stringify(channel&&{info:channel.info,vt100:channel.vt100}));
});

app.post('/:id',function(req,res){
	var channel=ChannelData.channelActiveMap['#'+req.params.id];
	if(channel&&req.body.type=='chat')channel.chat({name:req.body.name,message:req.body.message});
	res.end();
})

var server=http.createServer(app).listen(app.get('port'),function(){
	console.log("Express server listening on port " + app.get('port'));
});



function md5(){return crypto.createHash('md5').update('a').digest()}
function md5_hex(){return crypto.createHash('md5').update('a').digest('hex')}


var socketio=require('socket.io');
var io=socketio.listen(server);
io.set("log level",0);

io.sockets.on('connection',function(socket){
	socket.on('init',function(data){
		channel=ChannelData.getChannelData(data.channel);
		channel.join(socket);
		socket.on('disconnect',function(){channel.leave(socket)});
	});
})

function ChannelData(id){
	this.channelID=id;
	this.viewerCount=0;
	this.castSocket=null;
	this.castPassword=null;
	this.endTimer=null;
	this.vt100=null;
	this.info=null;
	this.notifyTimer=null;
	this.pauseCount=0;
	this.chatlist=[];
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
	return {info:this.info,casting:this.castSocket?true:false,vt100:this.vt100,viewer:this.viewerCount,chatlist:this.chatlist};
}
ChannelData.prototype.getSlugData=function(){return this.channelID+'#'+this.castPassword;}
ChannelData.prototype.getAdminData=function(){
	return {viewer:this.viewerCount,chatlist:this.chatlist,slug:this.channelID+'#'+this.castPassword}
}
ChannelData.prototype.join=function(socket){
	socket.join(this.channelID);
	this.viewerCount++;
	socket.emit('init',this.getInitData());
	this.broadcast('viewer',this.viewerCount,socket)
}
ChannelData.prototype.leave=function(socket){
	socket.leave(this.channelID);
	this.viewerCount--;
	this.broadcast('viewer',this.viewerCount,socket)
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
ChannelData.genUniqID=function(){
	for(var len=2;len<16;len++){
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
	if(channel.chatlist==null&&channel.viewerCount==0)
		delete ChannelData.channelMap['#'+channel.channelID];
}
ChannelData.prototype.notify=function(data){notify(this.channelID,data)}
ChannelData.prototype.notifyStatus=function(){
	if(this.notifyTimer)clearTimeout(this.notifyTimer);
	var info=this.info||{};
	this.notify({
		status:'update',
		vt100:JSON.stringify(this.vt100.getSubData(40,12)),
		title:info.title,
		color:info.color,
		viewer:this.viewerCount,
		pause:this.pauseCount
	})
	this.pauseCount++;
	var channel=this;
	this.notifyTimer=setTimeout(function(){channel.notifyStatus()},10*1000);
}
ChannelData.prototype.chat=function(data){
	if(!this.chatlist)return;
	data.time=new Date().getTime();
	this.chatlist.push(data);
	if(this.chatlist.length>256)this.chatlist.shift();
	this.broadcast('chat',data);
}
ChannelData.prototype.castStart=function(socket,pswd,w,h,info){
	//console.log(w,h,info);
	if(this.castPassword&&this.castPassword!=pswd)throw 'url already in use';
	if(this.castSocket)this.castSocket.disconnect();
	if(this.chatlist==null)this.chatlist=[];
	this.info=info;
	this.castPassword=pswd;
	this.castSocket=socket;
	socket.emit('slug',this.getSlugData());
	socket.emit('init',this.getAdminData());
	this.vt100=new VT100(w,h);
	this.notifyStatus();
	this.broadcast('castStart',{info:this.info,vt100:this.vt100},socket);
	ChannelData.channelActiveMap['#'+this.channelID]=this;
	//console.log(this.channelID);
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
	this.notify({status:'castend'})
	this.broadcast('castEnd','castend',socket);
	this.castSocket=null;
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
	var key={data:[],lengthRead:0,lengthReadSize:1,length:0};
	var val={data:[],lengthRead:0,lengthReadSize:2,length:0};
	var current=key;
	usocket.on('data',function(data){
		for(var i=0;i<data.length;){
			if(current.lengthRead<current.lengthReadSize){
				current.lengthRead++;
				current.length=(current.length<<8)|data[i++];
			}else{
				if(current.data.length<current.length){
					var rlen=current.length-current.data.length;
					var dlen=data.length-i;
					var len=Math.min(rlen,dlen);
					for(var j=0;j<len;j++)current.data.push(data[i++]);
				}
				if(current.data.length==current.length){
					if(current==key)current=val;
					else{
					    try{ondata(new Buffer(key.data).toString(),new Buffer(val.data).toString());}catch(e){console.log(e)}
						current=key;
					}
					current.length=current.lengthRead=0;
					current.data=[];
				}
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
		var kv=(data.slug||"").split('#');
		//console.log(data);
		if(!kv[0])kv[0]=ChannelData.genUniqID();
		if(!kv[1])kv[1]=genRandomID(8);
		channel=ChannelData.getChannelData(kv[0]);
		try{
			channel.castStart(iosocket,kv[1],data.width,data.height,data.info||{});
		}catch(e){
			console.log(e);
			iosocket.emit('error',e);
			iosocket.disconnect();
			return;
		}
	}
	usocket.on('error',function(){if(channel)channel.castEnd(iosocket);channel=null;});
	usocket.on('close',function(){if(channel)channel.castEnd(iosocket);channel=null;});
}).listen(UNIX_PORT,null,null,function(err){
	console.log("ScreenxTV server listening on port "+UNIX_PORT)
});

process.on('uncaughtException',function(err){
    console.log('Caught exception:',err);
});

