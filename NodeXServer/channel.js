var VT100=require_nocache('../vt100/vt100');
var print_log=require('./logger').create("./cast.log");
var request=require('request');
var LHash=require('./limitedhash')

function require_nocache(req){
  var module_load=module.constructor.prototype.load;
  var obj,err;
  module.constructor.prototype.load=function(filename){
    delete require.cache[filename];
    return module_load.call(this, filename);
  }
  try{obj=require(req);}catch(e){err=e}
  module.constructor.prototype.load=module_load;
  if(err)throw err;
  return obj;
}

function notify(id,data){
  request.post({
    uri:'http://localhost:'+Channel.RAILS_PORT+'/screens/notify/'+id,
    json:data
  });
}

function Channel(id){
  this.channelID=id;
  this.current={viewer:0,total_viewer:0,max_viewer:0,total_time:0};
  this.statistics=null;
  this.castSocket=null;
  this.castPassword=null;
  this.vt100=null;
  this.info=null;
  this.chatlist=null;
  this.updatedAt=new Date();
  this.state=Channel.OFFAIR;
  this.current_viewer_hash={}
  this.total_viewer_hash=new LHash()
}
Channel.OFFAIR='OFFAIR';
Channel.PAUSED='PAUSED';
Channel.ONAIR='ONAIR';
Channel.channelMap={};
Channel.NOTIFY_INTERVAL = 10*1000;
Channel.DESTROY_TIMEOUT = 5*60*1000;

Channel.prototype={
  broadcast:function(type,data,except){
    if(this.castSocket){
      if(this.castSocket!=except)this.castSocket.emit(type,data);
      else except=null;
    }
    if(except)except.broadcast.to(this.channelID).emit(type,data);
    else Channel.io.sockets.in(this.channelID).emit(type,data);
  },
  getInitData:function(){
    return {info:this.info,casting:this.castSocket?true:false,vt100:this.vt100,viewer:this.current,chatlist:this.chatlist};
  },
  getSlugData:function(){return this.channelID.split('/').pop()+'#'+this.castPassword;},
  getAdminData:function(){
    return {viewer:this.current,chatlist:this.chatlist,slug:this.channelID+'#'+this.castPassword}
  },
  join:function(socket,sid){
    socket.join(this.channelID);
    if(sid){
      var n=this.current_viewer_hash[sid]||0;
      this.current_viewer_hash[sid]=n+1;
      if(n==0)this.current.viewer++;
      if(!this.total_viewer_hash.get(sid)){
        this.total_viewer_hash.put(sid,1);
        this.current.total_viewer++;
      }
    }else{
      this.current.viewer++;
      this.current.total_viewer++;
    }
    this.current.max_viewer=Math.max(this.current.max_viewer,this.current.viewer);
    if(this.statistics){
      this.statistics.total_viewer++;
      this.statistics.max_viewer=Math.max(this.statistics.max_viewer,this.current.viewer);
    }
    socket.emit('init',this.getInitData());
    this.broadcast('viewer',this.current,socket)
  },
  leave:function(socket,sid){
    socket.leave(this.channelID);
    if(sid){
      var n=--this.current_viewer_hash[sid];
      if(n==0){
        this.current.viewer--;
        delete this.current_viewer_hash[sid];
      }
    }else{
      this.current.viewer--;
    }
    this.broadcast('viewer',this.current,socket)
    Channel.removeChannel(this);
  },
  startNotify:function(){
    var channel=this;
    this.notifyTimer=setInterval(function(){channel.notifyUpdate();},Channel.NOTIFY_INTERVAL);
  },
  stopNotify:function(){
    if(this.notifyTimer){clearInterval(this.notifyTimer);}
    this.notifyTimer=null;
  },
  startEndTimer:function(){
    var channel=this;
    this.endTimer=setTimeout(function(){channel.endTimer=null;channel.castEnd();},Channel.DESTROY_TIMEOUT);
  },
  stopEndTimer:function(){
    if(this.endTimer){clearTimeout(this.endTimer);}
    this.endTimer=null;
  },
  notify:function(data){if(!this.private)notify(this.channelID,data)},
  createNotifyData:function(status){
    var time=Math.round((new Date()-this.startTime)/1000);
    var pause_time=Math.round((new Date()-this.updatedAt)/1000);
    return {
      status:status,
      cast_count:this.statistics?this.statistics.cast_count:1,
      total_viewer:this.statistics?this.statistics.total_viewer:0,
      max_viewer:this.statistics?this.statistics.max_viewer:0,
      total_time:this.statistics?this.statistics.total_time+time:0,

      vt100:JSON.stringify(this.vt100.getSubData(40,12)),
      title:this.info.title,
      color:this.info.color,
      current_viewer:this.current.viewer,
      current_max_viewer:this.current.max_viewer,
      current_total_viewer:this.current.total_viewer,
      current_time:this.current.total_time+time,
      pause_count:pause_time
    };
  },
  notifyUpdate:function(){
    this.notify(this.createNotifyData('update'))
    this.updatedAt=new Date();
  },
  chat:function(data){
    data.time=Math.floor(new Date().getTime()/1000);
    if(this.chatlist){
      this.chatlist.push(data);
      if(this.chatlist.length>256)this.chatlist.shift();
    }
    this.broadcast('chat',data);
  },
  castStart:function(socket,pswd,w,h,info,castInfo,chats){
    if(this.castPassword&&this.castPassword!=pswd)throw 'url already in use';
    if(this.castSocket)this.castSocket.disconnect();
    this.castPassword=pswd;
    this.castSocket=socket;
    this.vt100=new VT100(w,h);
    this.info=info;
    if(this.state==Channel.OFFAIR){
      this.chatlist=chats||[];
      this.private=info.private?true:false;
      if(castInfo)castInfo.cast_count++;
      this.statistics=castInfo;
      if(!this.private)this.notify(this.createNotifyData('start'));
    }else{
      this.stopEndTimer();
      if(!this.private)this.notify(this.createNotifyData('update'));
    }
    this.state=Channel.ONAIR;
    if(!this.startTime)this.startTime=new Date();
    if(this.private)socket.emit('private_url',this.getSlugData());
    else socket.emit('slug',this.getSlugData());
    socket.emit('init',this.getAdminData());
    if(!this.private)this.startNotify();
    print_log(JSON.stringify({time:new Date().getTime(),url:this.channelID,info:info}))
    this.broadcast('castStart',{info:this.info,vt100:this.vt100},socket);
  },
  castStop:function(socket){
    console.log('stop',this.castSocket==socket)
    if(this.castSocket!=socket)return;
    if(!this.private)this.notify(this.createNotifyData('stop'))
    this.broadcast('castEnd','castend',socket);
    var time=Math.round((new Date()-this.startTime)/1000);
    this.castSocket=null;
    this.startTime=null;
    this.current.total_time+=time;
    if(this.statistics)this.statistics.total_time+=time;
    this.stopNotify();
    this.startEndTimer();
    this.state=Channel.PAUSED;
  },
  castEnd:function(){
    this.castPassword=null;
    this.vt100=null;
    this.info=null;
    this.chatlist=null;
    this.statistics=null;
    if(!this.private)this.notify({status:'end'})
    this.broadcast('terminate','terminate');
    Channel.removeChannel(this);
    this.state=Channel.OFFAIR;
  },
  castWINCH:function(socket,w,h){
    if(this.castSocket!=socket)return;
    this.vt100.resize(w,h);
    this.broadcast('castWINCH',{width:w,height:h},socket);
    this.updatedAt=new Date();
  },
  castData:function(socket,data){
    if(this.castSocket!=socket)return;
    for(var i=0;i<data.length;i++)this.vt100.write(data[i]);
    this.broadcast('castData',data,socket);
    this.updatedAt=new Date();
  }
}


Channel.genRandomID=function(n){
  var name="";
  var chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  for(var i=0;i<n;i++)name+=chars.charAt(chars.length*Math.random());
  return name;
}

Channel.genUniqID=function(n){
  for(var len=n||4;len<=16||len==n;len++){
    var name=Channel.genRandomID(len);
    if(!Channel.channelMap['#'+name])return name;
  }
  return null;
}
Channel.getChannel=function(id){
  var key='#'+id;
  var channel=Channel.channelMap[key];
  if(channel)return channel;
  return Channel.channelMap[key]=new Channel(id);
}
Channel.removeChannel=function(channel){
  if(channel.state==Channel.OFFAIR&&channel.current.viewer==0)delete Channel.channelMap['#'+channel.channelID];
}
Channel.reloadVT100=function(){VT100=require_nocache('../vt100/vt100');}


module.exports=Channel;
