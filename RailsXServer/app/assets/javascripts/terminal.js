function Terminal(element,w,h,color){
	var div=this.main=element
	div.innerHTML="";
	var pre=this.text=document.createElement("PRE");
	var cur=this.cursor=document.createElement("DIV");
	div.style.overflow="hidden";
	pre.style.userSelect=pre.style.WebkitUserSelect=pre.style.KhtmlUserSelect="text";
	pre.style.fontFamily="Osaka-Mono,MS-Gothic,MS-Mincho,SimSun,monospace";
	pre.style.lineHeight="1em";
	pre.style.display="inline";
	cur.style.position="absolute";cur.style.opacity=cur.style.MozOpacity=0.5;
	var front=document.createElement("DIV");
	front.style.userSelect=front.style.WebkitUserSelect=front.style.KhtmlUserSelect="none";
	front.style.position="relative";front.style.left=front.style.top=front.style.width=front.style.height=0;
	front.appendChild(cur);
	div.appendChild(front);
	div.appendChild(pre);
	var obj=this;
	this.vt100=new VT100(w,h);
	this.vt100.onBell=function(){if(obj.onBell)obj.onBell();}
	this.W=w;this.H=h;
	this.calcSize();
	this.setColor(color?color:Terminal.defaultColorMap.white);
}
Terminal.prototype.resize=function(w,h){
	this.W=w;this.H=h;
	this.vt100.resize(w,h);
	for(var i=0;i<h;i++)if(!this.vt100.line[i])this.vt100.line[i]=new VT100.Line(w);
	this.calcSize();
}
Terminal.prototype.write=function(c){this.vt100.write(c);}
Terminal.prototype.setColor=function(color){
	this.color=color;
	this.main.style.background=color.background;
	this.cursor.style.background=color.cursor;
	if(color.backgroundColor)this.main.style.backgroundColor=color.backgroundColor;
	this.updateView();
}
Terminal.prototype.calcSize=function(){
	this.text.innerHTML="<div><span>_</span></div>";
	this.char_w=this.text.firstChild.firstChild.offsetWidth;
	this.char_h=this.text.firstChild.offsetHeight;
	this.cursor.style.width=this.char_w+"px";
	this.cursor.style.height=this.char_h+"px";
	this.main.style.width=this.char_w*this.W+"px";
	this.main.style.height=this.char_h*this.H+"px";
	this.text.innerHTML="";
};
Terminal.prototype.setSpanFont=function(span,font){
	var highlight=font&0x00100;
	var flip=font&0x10000;
	if(font&0x01000)span.style.textDecoration="underline";
	var fg=(highlight?this.color.highlight:this.color.normal)[(font&0x000f0)>>4];
	var bg=(highlight?this.color.highlight:this.color.normal)[font&0x0000f];
	if(flip){
		span.style.color=bg?bg:this.color.backgroundColor||this.color.background;
		span.style.background=fg?fg:highlight?this.color.emphasis:this.color.foreground;
	}else{
		span.style.color=fg?fg:highlight?this.color.emphasis:this.color.foreground;
		span.style.background=bg?bg:null;
	}
};
Terminal.prototype.createHalfChar=function(s){
	var span=document.createElement("SPAN");
	span.textContent=s;
	var w2=Math.floor(this.char_w/1);
	span.style.marginRight=-w2+"px";
	span.style.marginLeft=-(this.char_w-w2)+"px";
	return span;
}
Terminal.prototype.updateView=function(){
	this.text.innerHTML="";
	for(var i=0;i<this.vt100.H;i++){
		var s="";
		var div=document.createElement("SPAN");div.style.display="block";
		div.style.height=this.char_h+"px";
		var fontprev=-1;
		var specialhalfprev=-1;
		var line=this.vt100.line[i];
		if(!line)line=new VT100.Line();
		for(var j=0;j<line.length;j++){
			var font=line.fonts[j];if(fontprev<0)fontprev=font;
			var c=line.chars[j];
			var cc=c.charCodeAt(0);
			var specialhalf=(cc>=0x80&&cc<0x2E80);
			if(font==fontprev&&specialhalf==specialhalfprev){
				s+=c;
			}else{
				if(s){
					var span=document.createElement("SPAN");
					if(specialhalfprev){
						for(var k=0;k<s.length;k++)span.appendChild(this.createHalfChar(s.charAt(k)));
					}else span.textContent=s;
					this.setSpanFont(span,fontprev);
					div.appendChild(span);
				}
				s=c;
				fontprev=font;
				specialhalfprev=specialhalf;
			}
		}
		var span=document.createElement("SPAN");
		if(specialhalfprev){
			for(var k=0;k<s.length;k++)span.appendChild(this.createHalfChar(s.charAt(k)));
		}else span.textContent=s;
		this.setSpanFont(span,fontprev);
		div.appendChild(span);
		div.appendChild(document.createElement("BR"));
		this.text.appendChild(div);
	}
	this.cursor.style.left=this.char_w*this.vt100.cursorX+"px";
	this.cursor.style.top=this.char_h*this.vt100.cursorY+"px";
};
Terminal.defaultColorMap={
	white:{
		normal:["#000","#F00","#0F0","#AA0","#00F","#F0F","#0AA","#BBB"],
		highlight:["#666","#F60","#0F6","#AF0","#60F","#F0A","#06A","#BBB"],
		foreground:"black",background:"white",emphasis:"#600",cursor:"#00F"
	},
	black:{
		normal:["#FFF","#F66","#4F4","#FF0","#88F","#F0F","#0FF","#444"],
		highlight:["#AAA","#F00","#6F6","#AA0","#66F","#F6F","#6FF","#444"],
		foreground:"white",background:"black",emphasis:"#FAA",cursor:"#CCF"
	},
	novel:{
		normal:["#000000","#990000","#00A600","#999900","#0000B3","#B300B3","#00A6B3","#BFBFBF"],
		highlight:["#000000","#990000","#00A600","#999900","#0000B3","#B300B3","#00A6B3","#BFBFBF"],
		foreground:"#532D2C",background:"#DFDBC3",emphasis:"#A1320B",cursor:"#000000"
	},
	green:{
		normal:["#000000","#990000","#00A600","#999900","#0000B3","#B300B3","#00A6B3","#BFBFBF"],
		highlight:["#000000","#990000","#00A600","#999900","#0000B3","#B300B3","#00A6B3","#BFBFBF"],
		foreground:"#BFFFBF",background:"#001F00",emphasis:"#7FFF7F",cursor:"#FFFFFF"
	},
};