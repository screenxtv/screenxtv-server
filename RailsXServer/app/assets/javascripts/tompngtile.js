function tompngTile(s,outer,w,mw,mh){
	outer=$(outer||document.body);
	if(!mw)mw=10;
	if(!mh)mh=10;
	if(!w)w=100;
	var arr=[];
	var inner=$(s);
	for(var i=0;i<inner.length;i++){
		var o=$(inner[i]);
		o.css('width',w);
		o[0].height='auto';
		var h=o.height();
		arr[i]={width:w,height:h,obj:o};
		o.css({position:'absolute',width:w,height:h,margin:0});
	}
	outer.text("");
	for(var i=0;i<arr.length;i++)arr[i].obj.appendTo(outer);
	
	var timer=null;
	window.onresize=function(){
		if(timer)clearTimeout(timer);
		timer=setTimeout(update,250);
	}
	function update(){
		timer=null;
		var width=window.innerWidth;
		var n=Math.floor((width-mw)/(w+mw));
		if(n==0)n=1;
		if(n>arr.length)n=arr.length;
		var pos=[];for(var i=0;i<n;i++)pos[i]=mh;
		var mx=(width-n*w)/(n+1);
		if(mx<0)mx=0;
		for(var i=0;i<arr.length;i++){
			var o=arr[i];
			var y=pos[0],x=0;
			for(var j=0;j<n;j++)if(pos[j]<y){x=j;y=pos[j];}
			o.obj.css({left:mx+x*(w+mx),top:pos[x]});
			pos[x]+=(o.height=o.obj.height())+mh;
		}
		var hmax=0;
		for(var i=0;i<n;i++)if(hmax<pos[i])hmax=pos[i];
		outer.css({height:hmax});
	}
	update();
	inner.css('-webkit-transition','all 0.2s')
}