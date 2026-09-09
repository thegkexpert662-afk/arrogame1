import 'package:flutter/material.dart';
enum ArrowDirection{up,right,down,left}
extension ArrowDirectionX on ArrowDirection{Offset get vector=>switch(this){ArrowDirection.up=>const Offset(0,-1),ArrowDirection.right=>const Offset(1,0),ArrowDirection.down=>const Offset(0,1),ArrowDirection.left=>const Offset(-1,0)};}
class Arrow{final String id;double x,y,length;final ArrowDirection direction;Arrow(this.id,this.x,this.y,this.length,this.direction);Arrow copy()=>Arrow(id,x,y,length,direction);}
