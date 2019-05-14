import 'package:flutter/material.dart';
import 'package:infomatterapp/widgets/widgets.dart';
import 'package:dynamic_theme/dynamic_theme.dart';

class MePage extends StatefulWidget{
  MePage({Key key}):
      super(key: key);
  @override
  State<MePage> createState() {
    // TODO: implement createState
    return MePageState();
  }
}

class MePageState extends State<MePage>{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ListView(
      children: <Widget>[
        ListTile(
          title: Text("设置"),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
              return SettingPage();
            }));
          },
        ),
        ListTile(
          title: Text("白天/夜间"),
          onTap: (){
            changeBrightness();
          },
        ),
      ],
    );
  }

  void changeBrightness() {
    DynamicTheme.of(context).setBrightness(
        Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark);
  }
}