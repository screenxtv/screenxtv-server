$(function(){
  $.fn.autofit=function(recursive){
    $(this).each(function(){
      var obj=$(this);
      var parent=obj.parent();
      var margin=(obj.data('margin')||"").split(" ");
      for(var i=0;i<4;i++)margin[i]=parseInt(margin[i%margin.length])||0;
      var top=obj.data('margin-top');
      var bottom=obj.data('margin-bottom');
      if(top!=undefined||bottom!=undefined){
        obj.css({
          top:(top||0),
          height:(parent.height()-(top||0)-(bottom||0))
        });
      }
      var left=obj.data('margin-left');
      var right=obj.data('margin-right');
      if(left!=undefined||right!=undefined){
        obj.css({
          left:(left||0),
          width:(parent.width()-(left||0)-(right||0))
        });
      }
    });
  }
})


$(function(){
  var pulldown=".pulldown";
  var menu=".pulldown-menu";
  var target=".pulldown-target"
  $(document).on("click",menu,function(){
    var $pulldown=$(this).parents(pulldown);
    if($pulldown.hasClass("active")){
      $pulldown.removeClass("active");
    }else{
      $pulldown.addClass("active");
      function closeAll(e){
        var element=$(e.target)
        if(element.is(target)||element.parents(target).length)return;
        $(pulldown).removeClass("active");
        $(document).off("click",closeAll)
      }
      $(document).on("click",closeAll)
    }
  });
});