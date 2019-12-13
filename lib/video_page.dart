import 'package:flutter/material.dart';

class VideoPage extends StatefulWidget {
  final String displayName;

  VideoPage({Key key, this.displayName}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Flutter Video Chat"),),
      body: Center(
        child: Text("Hello, ${widget.displayName}!"),
      ),
    );
  }
}
