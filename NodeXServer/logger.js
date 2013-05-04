var fs=require('fs')

function logger(file){
  var queue;
  return function(msg){
    if(queue){queue.push(msg);return;}
    try{
      queue=[msg];
      fs.open(file,'a',function(err,fd){
        try{
          fs.write(fd,queue.join("\n")+"\n");
        }catch(e){}
        try{fs.close(fd);}catch(e){}
      })
    }catch(e){queue=null;}
  }
}

module.exports={create:logger};