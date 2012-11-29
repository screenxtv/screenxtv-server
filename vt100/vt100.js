function VT100(){
	if(arguments.length==1){
		var copy=arguments[0];
		for(i in copy)this[i]=copy[i];
		return;
	}
	this.W=arguments[0];
	this.H=arguments[1];
	this.line=[];
	for(var i=0;i<this.H;i++)this.line[i]=new VT100.Line();
	this.font=this.fontDefault=0x00088;
	this.scrollStart=0;this.scrollEnd=this.H-1;
	this.cursorX=0;this.cursorY=0;
	this.insertMode=false;
	this.escMode=0;
	this.escChar='';
}
VT100.prototype.getSubData=function(w,h){
	var lines=[];
	var emptyline=new VT100.Line();
	for(var y=0;y<h;y++){
		var lobj=this.line[y]||emptyline;
		var line={length:Math.min(w,lobj.length),chars:[],fonts:[]};
		lines[y]=line;
		for(var x=0;x<line.length;x++){
			line.chars[x]=lobj.chars[x];
			line.fonts[x]=lobj.fonts[x];
		}
	}
	return {W:w,H:h,line:lines};
}
VT100.prototype.getData=function(){}

VT100.Line=function(){
	this.length=0;
	this.chars=[];
	this.fonts=[];
};
VT100.prototype.resize=function(w,h){
	console.log(h);
	while(this.line.length>this.H)this.line.pop();
	this.W=w;
	this.H=h;
	while(this.line.length<this.H){
		this.scrollEnd++;
		this.line.push(new VT100.Line());
	}
	while(this.line.length>this.H){
		this.line.shift();
		this.scrollStart--;
		this.scrollEnd--;
		this.cursorY--;
	}
	for(var i=0;i<h;i++)if(!this.line[i])this.line[i]=new VT100.Line();
	if(this.scrollStart<0)this.scrollStart=0;
	if(this.scrollEnd<1)this.scrollEnd=1;
	if(this.cursorY<0)this.cursorY=0;
	if(this.cursorY>=this.H)this.cursorY=this.H-1;
}
VT100.prototype.write=function(c){
	try{
		switch(this.escMode){
			case 0:
				if(c=='\x1B')this.escMode=1;
				else if(c<'\x20')this.parseSpecial(c.charCodeAt(0));
				else{this.put(c);if(c.charCodeAt(0)>=0x2E80)this.put('');}
				return;
			case 1:
				if(c=='[')this.escMode=2;
				else if(c=='(')this.escMode=3;
				else if(c==')')this.escMode=4;
				else{this.parseEscape(c);this.escMode=0;}
				return;
			case 2:
				if(('A'<=c&&c<='Z')||('a'<=c&&c<='z')){this.parseEscapeK(c);this.escMode=0;this.escChar='';}
				else this.escChar+=c;
				return;
			case 3:this.parseEscapeL(c);this.escMode=0;return;
			case 4:this.parseEscapeR(c);this.escMode=0;return;
		}
	}catch(e){
		for(var i=0;i<this.H;i++)if(!this.line[i])this.line[i]=new VT100.Line();
	}
}
VT100.prototype.parseSpecial=function(c){
	switch(c){
		case 0x09:this.moveCursor(Math.floor(this.cursorX/8+1)*8,this.cursorY);return;
		case 0x08:this.moveCursor(this.cursorX-1,this.cursorY);return;
		case 0x0A:this.scrollCursor(this.cursorX,this.cursorY+1);return;
		case 0x0D:this.moveCursor(0,this.cursorY);return;
		case 0x07:if(this.onBell)this.onBell();return;
	}
}
var escmap={};
function esclog(c){if(escmap[c])return;escmap[c]=[{},[]];console.log("escape log: "+c);}
VT100.prototype.parseEscapeL=function(c){esclog("("+c)}
VT100.prototype.parseEscapeR=function(c){esclog(")"+c)}
VT100.prototype.parseEscape=function(c){esclog("^"+c)
	switch(c){
		case 'M':this.scrollCursor(this.cursorX,this.cursorY-1);break;
	}
}
VT100.prototype.parseEscapeK=function(cmd){esclog("["+cmd);
	var map=escmap["["+cmd];
	if(!map[0][this.escChar]){map[0][this.escChar]=1;map[1].push(this.escChar);}
	switch(cmd){
		case 'A':{
			if(this.escChar)this.scrollCursor(this.cursorX,this.cursorY-parseInt(this.escChar));
			else this.scrollCursor(this.cursorX,this.cursorY-1);
			return;
		}
		case 'B':{
			if(this.escChar)this.scrollCursor(this.cursorX,this.cursorY+parseInt(this.escChar));
			else this.scrollCursor(this.cursorX,this.cursorY+1);
			return;
		}
		case 'C':{
			if(this.escChar){this.moveCursor(this.cursorX+parseInt(this.escChar),this.cursorY);}
			else this.moveCursor(this.cursorX+1,this.cursorY);
			return;
		}
		case 'D':{
			if(this.escChar>0)this.moveCursor(this.cursorX-parseInt(this.escChar),this.cursorY);
			else this.moveCursor(this.cursorX-1,this.cursorY);
			return;
		}
		case 'H':case 'f':{
			if(this.escChar){
				var yx=this.escChar.split(";");
				this.moveCursor(parseInt(yx[1])-1,parseInt(yx[0])-1);
				return;
			}else this.moveCursor(0,0);
			return;
		}
		case 'J':{
			if(this.escChar=='1'){
				for(var i=0;i<=this.cursorY;i++)this.line[i].length=0;
				this.moveCursor(0,0);
			}else if(this.escChar=='2'){
				for(var i=0;i<this.H;i++)this.line[i].length=0;
				this.moveCursor(0,0);
			}else{
				for(var i=this.cursorY;i<this.H;i++)this.line[i].length=0;
				this.cursorX=0;
			}
			return;
		}
		case 'K':{
			if(this.escChar=='1'){
				for(var i=0;i<this.cursorX;i++){
					this.line[this.cursorY].chars[i]=' ';
					this.line[this.cursorY].fonts[i]=this.fontDefault;
				}
			}else if(this.escChar=='2'){
				this.line[this.cursorY].length=0;
			}else{
				this.line[this.cursorY].length=this.cursorX;
			}
			return;
		}
		case 'L':{
			var num=this.escChar?parseInt(this.escChar):1;
			this.cursorX=0;
			for(var i=this.scrollEnd;i>=this.cursorY;i--)this.linetmp[i]=this.line[i];
			for(var i=this.scrollEnd;i>=this.cursorY;i--){
				if(i-num<this.cursorY){
					(this.line[i]=this.linetmp[i-num+this.scrollEnd-this.cursorY+1]).length=0;
				}else this.line[i]=this.linetmp[i-num];
			}
			return;
		}
		case 'M':{
			var num=this.escChar?parseInt(this.escChar):1;
			for(var i=this.cursorY;i<=this.scrollEnd;i++)this.linetmp[i]=this.line[i];
			for(var i=this.cursorY;i<=this.scrollEnd;i++){
				if(i+num>this.scrollEnd)(this.line[i]=this.linetmp[i+num+this.cursorY-this.scrollEnd-1]).length=0;
				else this.line[i]=this.linetmp[i+num];
			}
			return;
		}
		case 'P':{
			var num=this.escChar?parseInt(this.escChar):1;
			var ln=this.line[this.cursorY];
			for(var i=this.cursorX;i<ln.length-num;i++){
				ln.chars[i]=ln.chars[i+num];
				ln.fonts[i]=ln.fonts[i+num];
			}
			ln.length-=num;
			return;
		}
		case 'h':case 'l':{
			var flag=(cmd=='h');
			switch(this.escChar){
				case '4':this.insertMode=flag;return;
			}
			return;
		}
		case 'm':{
			if(!this.escChar){this.font=this.fontDefault;return;}
			var params=this.escChar.split(";");
			for(var i=0;i<params.length;i++){
				var val=params[i]%10;
				var key=(params[i]-val)/10;
				if(key==0){
					if(val==0){this.font=this.fontDefault;continue;}
					else if(val==1)this.font|=0x00100;
					else if(val==4)this.font|=0x01000;
					else if(val==7)this.font|=0x10000;
				}else if(key==3){
					if(val<8)this.font=(this.font&0x1110f)|(val<<4);
				}else if(key==4){
					if(val<8)this.font=(this.font&0x111f0)|val;
				}
			}
			return;
		}
		case 'r':{
			var se=this.escChar.split(";");
			this.scrollStart=parseInt(se[0])-1;
			this.scrollEnd=parseInt(se[1])-1;
			return;
		}
	}
}
VT100.prototype.put=function(c){
	if(this.cursorX>=this.W)this.scrollCursor(0,this.cursorY+1);
	var ln=this.line[this.cursorY];
	if(!ln)return;
	if(this.insertMode){
		for(var i=ln.length;i>this.cursorX;i--){ln.chars[i]=ln.chars[i-1];ln.fonts[i]=ln.fonts[i-1];}
		ln.chars[this.cursorX]=c;
		ln.fonts[this.cursorX]=this.font;
		ln.length++;
		this.cursorX++;
	}else{
		ln.chars[this.cursorX]=c;
		ln.fonts[this.cursorX]=this.font;
		if(this.cursorX==ln.length)ln.length++;
		this.cursorX++;
	}
}
VT100.prototype.moveCursor=function(x,y){
	var ln=this.line[y];
	if(ln){
		var xn=x-ln.length;
		for(var i=0;i<xn;i++){ln.chars[ln.length]=' ';ln.fonts[ln.length]=this.fontDefault;ln.length++;}
	}
	this.cursorX=x;
	this.cursorY=y;
}
VT100.prototype.scrollCursor=function(x,y){
	if(this.cursorY<this.scrollStart||this.cursorY>this.scrollEnd){this.moveCursor(x,y);return;}
	if(y<this.scrollStart){
		var n=this.scrollStart-y;
		var linetmp=[];
		for(var i=this.scrollEnd;i>=this.scrollStart;i--)linetmp[i]=this.line[i];
		if(this.scrollEnd-n+1<0)for(var i=this.scrollEnd;i>=this.scrollStart;i--)this.line[i].length=0;else
		for(var i=this.scrollEnd;i>=this.scrollStart;i--){
			if(i-n<this.scrollStart)(this.line[i]=linetmp[i-n+1+this.scrollEnd-this.scrollStart]).length=0;
			else this.line[i]=linetmp[i-n];
		}
		y=this.scrollStart;
	}else if(y>this.scrollEnd){
		var n=y-this.scrollEnd;
		var linetmp=[];
		for(var i=this.scrollStart;i<=this.scrollEnd;i++)linetmp[i]=this.line[i];
		for(var i=this.scrollStart;i<=this.scrollEnd;i++){
			if(i+n>this.scrollEnd)(this.line[i]=linetmp[i+n-1-this.scrollEnd+this.scrollStart]).length=0;
			else this.line[i]=linetmp[i+n];
		}
		y=this.scrollEnd;
	}
	var ln=this.line[y];
	if(ln){
		var xn=x-ln.length;
		for(var i=0;i<xn;i++){ln.chars[ln.length]=' ';ln.fonts[ln.length]=this.fontDefault;ln.length++;}
	}
	this.cursorX=x;
	this.cursorY=y;
}


try{module.exports=VT100;}catch(e){}
