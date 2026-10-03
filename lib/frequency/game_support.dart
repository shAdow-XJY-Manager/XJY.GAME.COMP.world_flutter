import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'platform_native.dart' if (dart.library.js_interop) 'platform_web.dart' as platform;
import 'frequency_theme.dart';
export 'frequency_theme.dart';

Map<String,dynamic>? readMap(String key) {
  try { final raw=platform.readValue('frequency.$key'); if(raw==null)return null;if(raw.length>1000000){invalidSave();return null;} return Map<String,dynamic>.from(jsonDecode(raw) as Map); } catch (_) {invalidSave();return null;}
}
Map<String,dynamic> objectMap(dynamic value)=>value is Map?Map<String,dynamic>.from(value):<String,dynamic>{};
final saveWarning=ValueNotifier<String?>(null);
void invalidSave(){saveWarning.value='存档无法恢复，请重新开始。历史记录单独保存。';}
final storageAvailable=ValueNotifier<bool>(true);
bool saveMap(String key, Map<String,dynamic> value) {
  try {final okay=platform.writeValue('frequency.$key',jsonEncode(value));storageAvailable.value=okay;if(okay&&key.endsWith('.save'))saveWarning.value=null;return okay;}catch(_){storageAvailable.value=false;return false;}
}
List<Map<String,dynamic>> localRecords() {
  final container=readMap('results');if(container==null||container.isEmpty)return [];final raw=container['items'];if(raw is! List){invalidSave();return [];}
  return raw.whereType<Map>().where((r)=>['game','session','result','detail','at'].every((k)=>r[k] is String)).take(50).map((r)=>Map<String,dynamic>.from(r)).toList();
}
int _sessionCounter=0;
String newSession() => '${DateTime.now().microsecondsSinceEpoch}-${_sessionCounter++}';
void leaveForCenter()=>platform.navigate('/XJY.GAME.COMP.gameCenter/');
void openGame(String repo)=>platform.navigate('/$repo/');
void sound(bool enabled,[int kind=0]) {if(enabled)platform.tone(kind);}
bool recordResult(String gameId,String session,String result,String detail) {
  final list=localRecords();
  if(list.any((r)=>r['session']==session&&r['game']==gameId))return true;
  list.insert(0,{'game':gameId,'session':session,'result':result,'detail':detail,'at':DateTime.now().toIso8601String()});
  return saveMap('results',{'items':list.take(50).toList()});
}
Widget panel(Widget child,{EdgeInsets padding=const EdgeInsets.all(24)})=>Material(color:FrequencyPalette.surface,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12),side:const BorderSide(color:FrequencyPalette.border)),child:Padding(padding:padding,child:child));
Widget badge(String label)=>DecoratedBox(decoration:BoxDecoration(color:FrequencyPalette.elevated,borderRadius:BorderRadius.circular(8),border:Border.all(color:FrequencyPalette.border)),child:Padding(padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),child:Text(label,maxLines:1,style:const TextStyle(fontSize:14,color:FrequencyPalette.muted))));
Widget metric(String label,String value)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(color:FrequencyPalette.muted)),const SizedBox(height:4),Text(value,style:const TextStyle(fontSize:28,fontWeight:FontWeight.w800))]);
Widget statusText(String value)=>Semantics(liveRegion:true,child:Text(value,style:const TextStyle(fontSize:18,height:1.5)));
Widget sectionTitle(String title,String subtitle)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:32,fontWeight:FontWeight.w900)),const SizedBox(height:8),Text(subtitle,style:const TextStyle(color:FrequencyPalette.muted,fontSize:16)),const SizedBox(height:24)]);
Widget splitBoard(BuildContext context,bool active,Widget board,Widget details) {
  return LayoutBuilder(builder:(context,c)=>c.maxWidth>=820?Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(flex:3,child:board),const SizedBox(width:24),Expanded(flex:2,child:details)]):Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:active?[board,const SizedBox(height:24),details]:[details,const SizedBox(height:24),board]));
}
Future<void> rulesDialog(BuildContext context,String text)=>showDialog<void>(context:context,builder:(context)=>AlertDialog(title:const Text('玩法与操作'),content:SingleChildScrollView(child:Text(text)),actions:[FilledButton(onPressed:()=>Navigator.pop(context),child:const Text('明白了'))]));

class GameFrame extends StatefulWidget {
  final String title,subtitle,gameId;
  final Widget child;
  final bool playing;
  final VoidCallback onRestart,onRules;
  final VoidCallback? onExit;
  final ValueChanged<bool> onPause;
  final ValueChanged<bool>? onSound;
  const GameFrame({super.key,required this.title,required this.subtitle,required this.gameId,required this.child,required this.onRestart,required this.onRules,required this.onPause,this.onSound,this.onExit,this.playing=true});
  @override State<GameFrame> createState()=>_GameFrameState();
}
class _GameFrameState extends State<GameFrame> with WidgetsBindingObserver {
  bool paused=false,audio=false;
  @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);platform.watchSuspension((){if(mounted&&!paused)_pause(true);});}
  @override void dispose(){WidgetsBinding.instance.removeObserver(this);platform.unwatchSuspension();super.dispose();}
  @override void didChangeAppLifecycleState(AppLifecycleState state){if(state!=AppLifecycleState.resumed && !paused)_pause(true);}
  void _pause(bool value){setState(()=>paused=value);widget.onPause(value);}
  void _freezeForPanel(){if(widget.playing&&!paused)_pause(true);}
  void _showRules(){_freezeForPanel();widget.onRules();}
  void _records(){_freezeForPanel();final items=localRecords().where((r)=>r['game']==widget.gameId).toList();showDialog<void>(context:context,builder:(context)=>AlertDialog(title:const Text('本地对局记录'),content:SizedBox(width:480,child:items.isEmpty?Text(saveWarning.value??'完成一局后，结果会保存在这台设备。'):SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:items.map<Widget>((r)=>ListTile(contentPadding:EdgeInsets.zero,title:Text('${r['result']} · ${r['detail']}'),subtitle:Text('${r['at']}'.split('.').first))).toList()))),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('关闭'))]));}
  @override Widget build(BuildContext context)=>CallbackShortcuts(bindings:{const SingleActivator(LogicalKeyboardKey.escape):(){if(widget.playing||paused)_pause(!paused);}},child:Scaffold(appBar:AppBar(leading:IconButton(tooltip:'返回游戏中心',onPressed:(){widget.onExit?.call();leaveForCenter();},icon:const Icon(Icons.arrow_back)),title:Text(widget.title,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:20)),actions:[PopupMenuButton<String>(tooltip:'规则与记录',onOpened:_freezeForPanel,onSelected:(value){if(value=='rules'){_showRules();}else{_records();}},itemBuilder:(_)=>const [PopupMenuItem(value:'rules',child:Text('玩法与操作')),PopupMenuItem(value:'records',child:Text('本地记录'))]),IconButton(tooltip:audio?'关闭声音':'打开声音',onPressed:(){setState(()=>audio=!audio);widget.onSound?.call(audio);sound(audio);},icon:Icon(audio?Icons.volume_up_outlined:Icons.volume_off_outlined)),IconButton(tooltip:paused?'继续':widget.playing?'暂停':'开始对局后可暂停',onPressed:widget.playing||paused?()=>_pause(!paused):null,icon:Icon(paused?Icons.play_arrow:Icons.pause))]),body:Stack(children:[AbsorbPointer(absorbing:paused,child:ExcludeFocus(excluding:paused,child:SingleChildScrollView(padding:EdgeInsets.all(MediaQuery.sizeOf(context).width<700?16.0:24.0),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1120),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text(widget.subtitle,style:const TextStyle(color:FrequencyPalette.muted)),const SizedBox(height:24),ValueListenableBuilder<String?>(valueListenable:saveWarning,builder:(_,text,__)=>text==null?const SizedBox.shrink():Padding(padding:const EdgeInsets.only(bottom:16),child:Text(text,style:const TextStyle(color:FrequencyPalette.error,fontSize:16)))),widget.child,const SizedBox(height:24),Wrap(spacing:12,runSpacing:12,children:[OutlinedButton.icon(onPressed:widget.onRestart,icon:const Icon(Icons.restart_alt),label:const Text('重新开始')),TextButton(onPressed:_showRules,child:const Text('查看规则'))]),const SizedBox(height:16),ValueListenableBuilder<bool>(valueListenable:storageAvailable,builder:(_,okay,__)=>Text(okay?'进度保存在当前设备 · Esc 暂停 · 声音默认关闭':'存储不可用：本次进度仅在当前页面保留，请勿关闭。',style:TextStyle(color:okay?FrequencyPalette.muted:FrequencyPalette.error,fontSize:14)))])))))),if(paused)Positioned.fill(child:ColoredBox(color:FrequencyPalette.background.withValues(alpha:0.94),child:Center(child:panel(Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.pause_circle_outline,size:48,color:FrequencyPalette.accent),const SizedBox(height:16),const Text('已暂停',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),const SizedBox(height:8),const Text('回到游戏后，手动继续。'),const SizedBox(height:24),FilledButton(onPressed:()=>_pause(false),child:const Text('继续游戏'))])))))]) ));
}

class KeyboardBoard extends StatefulWidget {
  final int columns,count;
  final Widget Function(int,FocusNode) cell;
  final double aspect,gap;
  const KeyboardBoard({super.key,required this.columns,required this.count,required this.cell,this.aspect=1,this.gap=8});
  @override State<KeyboardBoard> createState()=>_KeyboardBoardState();
}
class _KeyboardBoardState extends State<KeyboardBoard>{
  late final nodes=List.generate(widget.count,(_)=>FocusNode());int cursor=0;
  @override void dispose(){for(final n in nodes){n.dispose();}super.dispose();}
  void move(int dx,int dy){final active=nodes.indexWhere((n)=>n.hasFocus);if(active>=0)cursor=active;final x=(cursor%widget.columns+dx).clamp(0,widget.columns-1).toInt(),y=(cursor~/widget.columns+dy).clamp(0,(widget.count-1)~/widget.columns).toInt();cursor=y*widget.columns+x;final node=nodes[cursor];node.requestFocus();if(node.context!=null){Scrollable.ensureVisible(node.context!);}}
  @override Widget build(BuildContext context)=>CallbackShortcuts(bindings:{const SingleActivator(LogicalKeyboardKey.arrowLeft):()=>move(-1,0),const SingleActivator(LogicalKeyboardKey.arrowRight):()=>move(1,0),const SingleActivator(LogicalKeyboardKey.arrowUp):()=>move(0,-1),const SingleActivator(LogicalKeyboardKey.arrowDown):()=>move(0,1)},child:GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:widget.columns,mainAxisSpacing:widget.gap,crossAxisSpacing:widget.gap,childAspectRatio:widget.aspect),itemCount:widget.count,itemBuilder:(_,i)=>widget.cell(i,nodes[i])));
}
