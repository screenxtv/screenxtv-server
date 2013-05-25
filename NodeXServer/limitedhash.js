function LimitedHash(size){
  this.size=size || 256
  this.head={};
  this.tail={};
  this.head.n=this.tail;
  this.tail.p=this.head;
  this.length=0;
  this.map={};
}
LimitedHash.prototype={
  put:function(key,value){
    var k='#'+key
    var node=this.map[k];
    if(node){
      node.p.n=node.n;
      node.n.p=node.p;
      node.v=value;
    }else{
      node={k:k,v:value};
      this.length++;
      this.map[k]=node
    }
    node.n=this.head.n;
    node.p=this.head;
    node.n.p=node;
    node.p.n=node;
    if(this.length>this.size){
      this.length=this.size;
      var dn=this.tail.p;
      dn.n.p=dn.p;
      dn.p.n=dn.n
      delete this.map[dn.k];
    }
  },
  get:function(key){
    var node=this.map['#'+key]
    return node?node.v:null;
  }
}

module.exports=LimitedHash
