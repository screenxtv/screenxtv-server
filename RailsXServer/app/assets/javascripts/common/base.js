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
  $(".popupbutton").live('click',function(){
    var classactive='popupbutton_active';
    var flag=$(this).hasClass(classactive);
    $('.popupbutton').removeClass(classactive);
    if(!flag)$(this).addClass(classactive);
  })
})
$(function(){
  function closeAll(){

  }
  $(document).on("click","pulldown",function(){
    var target=$($(this).data('target'));
    if(target.hasClass("")){

    }

  })


})