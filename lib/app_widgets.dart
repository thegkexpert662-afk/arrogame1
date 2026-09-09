import 'package:flutter/material.dart';

const bg = Color(0xFFFFF8E8), brown = Color(0xFF70461F), orange = Color(0xFFF08A24), blue = Color(0xFF39A8F5);

class AppScaffold extends StatelessWidget {
  final String title; final Widget body; final Widget? trailing;
  const AppScaffold({super.key, required this.title, required this.body, this.trailing});
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: bg, appBar: AppBar(backgroundColor: bg, elevation: 0, centerTitle: true, leading: IconButton(icon: const Icon(Icons.arrow_back, color: brown), onPressed: ()=>Navigator.pop(context)), title: Text(title, style: const TextStyle(color: brown,fontWeight: FontWeight.bold)), actions: [if(trailing!=null) trailing!]), body: body);
}

Widget primary(BuildContext c, String text, VoidCallback onTap) => SizedBox(width: double.infinity, height: 56, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: brown, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))), onPressed: onTap, child: Text(text,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold))));
Widget softButton(String text, IconData icon, VoidCallback onTap) => Expanded(child: Padding(padding:const EdgeInsets.all(6),child: FilledButton(style:FilledButton.styleFrom(backgroundColor:Colors.white,foregroundColor:brown,padding:const EdgeInsets.symmetric(vertical:18),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18))),onPressed:onTap,child:Column(children:[Icon(icon,size:30),const SizedBox(height:6),Text(text)]))));
