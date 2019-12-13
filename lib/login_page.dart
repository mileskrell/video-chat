import 'package:flutter/material.dart';
import 'package:video_chat/video_page.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String displayNameInput = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IntrinsicWidth(
              child: TextField(
                decoration: InputDecoration(hintText: "Display name"),
                onChanged: (input) => displayNameInput = input,
              ),
            ),
            FlatButton(
              child: Text("Login"),
              onPressed: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                return VideoPage(displayName: displayNameInput);
              })),
            ),
          ],
        ),
      ),
    );
  }
}
