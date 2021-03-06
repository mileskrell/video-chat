import 'package:flutter/material.dart';
import 'package:video_chat/connect_page.dart';

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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: IntrinsicWidth(
                child: TextField(
                  decoration: InputDecoration(hintText: "Display name"),
                  onChanged: (input) {
                    setState(() => displayNameInput = input);
                  },
                ),
              ),
            ),
            RaisedButton(
              child: Text("Login"),
              onPressed: displayNameInput.isEmpty
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return ConnectPage(displayName: displayNameInput);
                        }),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
