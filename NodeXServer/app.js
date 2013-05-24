var express=require('express');
var http=require('http');
var net=require('net');
var request=require('request');
var Channel=require('./channel');
var app = express();
var PORT=8800
var RAILS_PORT=8008;
var UNIX_PORT=8000;
var RAILS_IP="127.0.0.1"

Channel.RAILS_PORT=RAILS_PORT
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



function filter(req){return req.connection.remoteAddress==RAILS_IP}
function apigetinfo(channelID){
	var channel=Channel.channelMap['#'+channelID];
	return JSON.stringify(channel&&{info:channel.info,vt100:channel.vt100});
}
function apipost(channelID,reqbody){
	var channel=Channel.channelMap['#'+channelID];
	if(!channel||reqbody.type!='chat')return;
	channel.chat(reqbody);
}
app.get('/:id',function(req,res){
	if(!filter(req)){res.end();return;}
	res.end(apigetinfo(req.params.id));
});
app.get('/:room/:id',function(req,res){
	if(!filter(req)){res.end();return;}
	res.end(apigetinfo(req.params.room+'/'+req.params.id));
});

app.post('/:id',function(req,res){
	if(!filter(req)){res.end();return;}
	apipost(req.params.id,req.body);
	res.end();
});
app.post('/:room/:id',function(req,res){
	if(!filter(req)){res.end();return;}
	apipost(req.params.room+'/'+req.params.id,req.body);
	res.end();
});
app.get('/admin/reload/',function(req,res){
	if(!filter(req)){res.end();return;}
	Channel.reloadVT100();
	res.end();
});

var server=http.createServer(app).listen(PORT,function(){
	console.log("Express server listening on port " + PORT);
});

var socketio=require('socket.io');
var io_option={'destroy buffer size':10E6};
var io=socketio.listen(server,io_option);
Channel.io = io;
io.set("log level",1);

io.sockets.on('connection',function(socket){
	console.log('connection!')
	socket.on('init',function(data){
		var channel=Channel.getChannel(data.channel);
		console.log('joined',data.channel)
		channel.join(socket);
		socket.on('disconnect',function(){channel.leave(socket)});
	});
})





net.createServer(function(usocket){
	var channel=null;
	var iosocket={
		emit:function(key,value){if(usocket.writable)usocket.write(key+"\n"+JSON.stringify(value)+"\n")},
		disconnect:function(){usocket.end();}
	}
	var key={lengthRead:0,lengthReadSize:1,length:0,position:0};
	var val={lengthRead:0,lengthReadSize:2,length:0,position:0};
	var current=key;
	var trafficParam=0,trafficTime=0;
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
				    try{ondata(key.data.toString(),val.data.toString());}catch(e){console.log('callondata',e)}
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
    }catch(e){console.log('ondata',e,key,value);}
	}
	function onwinch(size){
		try{
			var w=parseInt(size.width),h=parseInt(size.height);
			channel.castWINCH(iosocket,w,h);
		}catch(e){console.log('onwinch',e);}
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

		var info=data.info||{};
		if(data.private){
			info.private=true
			if(data.private_url){
				var kv=data.private_url.split('#');
				var url='private/'+kv[0];
				console.log(url)
				var key=kv[1]||Channel.genRandomID(16);
				try{
					channel=Channel.getChannel(url);
					channel.castStart(iosocket,key,width,height,info);
					return;
				}catch(e){}
			}
			try{
				var url=Channel.genUniqID(16,'private/');
				channel=Channel.getChannel(url);
				channel.castStart(iosocket,Channel.genRandomID(16),width,height,info);
			}catch(e){
				console.log('private',e);
				iosocket.emit('error',e);
				iosocket.disconnect();
			}
			return;
		}

		var kv=(data.slug||"").split('#');
		var width=data.width,height=data.height;
		var url=kv[0],castkey=data.auth_key||kv[1]||Channel.genRandomID(16);
		if(!url.match("^[a-zA-Z0-9_]*$")){
			iosocket.emit('errtype','url');
			iosocket.emit('error','invalid url');
			iosocket.disconnect();
			return;
		}
		var randsize=4,anonymousflag=false;
		if(!url){
			anonymousflag=true;
			url=Channel.genUniqID(randsize++);
		}

		function cb(err,result,data){
			console.log('cb',data)
			if(!data){
				iosocket.emit('error','unknown')
				iosocket.disconnect();
			}
			if(!data.cast){
				if(anonymousflag){
					auth(Channel.genUniqID(randsize<8?randsize++:8),{},cb);
				}else{
					iosocket.emit('error',data.error)
					iosocket.disconnect();
				}
			}else{
				try{
					channel=Channel.getChannel(url);
					if(data.info){
						channel.castStart(iosocket,url+"/"+castkey,width,height,info,data.info,data.chats);
					}else{
						channel.castStart(iosocket,castkey,width,height,info,null,null);
					}
				}catch(e){
					console.log('cb',e);
					iosocket.emit('error',e);
					iosocket.disconnect();
				}
			}
		}
		auth(url,{user:data.user,auth_key:data.auth_key},cb);
	}
	function onclose(){if(channel)channel.castStop(iosocket);channel=null;}
	usocket.on('error',onclose);
	usocket.on('close',onclose);
}).listen(UNIX_PORT,null,null,function(err){
	console.log("NodeX listening on port "+UNIX_PORT)
});

process.on('uncaughtException',function(err){
 	console.log('Caught exception:',err);
});

