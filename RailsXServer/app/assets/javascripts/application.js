// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require_tree .


if(navigator.userAgent.toLowerCase().indexOf("msie")>=0){
  onload=function(){
    document.body.innerHTML=
    "<h1>You need a \"Web Browser\" to view a web site.</h1>"+
    "<a href='http://www.google.com/search?q=web%20browser%20install'>Search:web browser install</a>"
  }
}