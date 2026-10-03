import 'dart:collection';

class RoomGame {
  static const width=6,height=8;
  final int chapter;int position=42,progress=0,steps=0,mistakes=0;final Set<int> collected={};bool won=false;
  static const walls={7,8,10,13,16,19,20,22,25,28,31,32,34};
  static const switches=[6,29],tokens=[11,18,35],gate=17,exit=5;
  RoomGame([this.chapter=0]);
  List<int> get code=>chapter==0?[0,1]:chapter==1?[1,0]:[0,1,0];
  bool get open=>progress==code.length;
  bool passable(int cell)=>cell>=0&&cell<48&&!walls.contains(cell)&&(cell!=gate||open);
  bool adjacent(int a,int b)=>(a~/6-b~/6).abs()+(a%6-b%6).abs()==1;
  List<int>? pathTo(int cell){if(!passable(cell))return null;final queue=Queue<int>()..add(position);final previous=<int,int>{position:-1};while(queue.isNotEmpty){final current=queue.removeFirst();if(current==cell){final path=<int>[];var p=cell;while(p!=position){path.insert(0,p);p=previous[p]!;}return path;}for(final next in [current-6,current+6,current-1,current+1]){if(passable(next)&&adjacent(current,next)&&!previous.containsKey(next)){previous[next]=current;queue.add(next);}}}return null;}
  bool move(int target){if(won||!passable(target)||!adjacent(position,target))return false;position=target;steps++;if(tokens.contains(target))collected.add(target);if(target==exit&&collected.length==3&&open)won=true;return true;}
  String interact(){if(won)return '本房间已完成。';final index=switches.indexOf(position);if(index>=0){if(open)return '信号门已经解锁。';if(index==code[progress]){progress++;return open?'信号门已解锁，收集全部三枚标记后前往出口。':'顺序正确，继续激活下一节点。';}progress=0;mistakes++;return '顺序不匹配，已重置。查看旁边的信号顺序。';}if(position==exit)return '需要三枚标记和完整信号顺序。';return '走到 A 或 B 节点上，再按交互。';}
  Map<String,dynamic> toJson()=>{'version':1,'chapter':chapter,'position':position,'progress':progress,'steps':steps,'mistakes':mistakes,'collected':collected.toList(),'won':won};
  static RoomGame? fromJson(Map<String,dynamic> j){try{if(j['version']!=1)return null;final level=j['chapter'] as int;if(level<0||level>2)return null;final g=RoomGame(level);g.position=j['position'] as int;g.progress=j['progress'] as int;g.steps=j['steps'] as int;g.mistakes=j['mistakes'] as int;g.collected.addAll(List<int>.from(j['collected'] as List));g.won=j['won']==true;if(g.progress<0||g.progress>g.code.length||g.steps<0||g.mistakes<0||!g.passable(g.position)||g.collected.any((i)=>!tokens.contains(i))||(g.won&&(!g.open||g.collected.length!=3||g.position!=exit)))return null;return g;}catch(_){return null;}}
}
