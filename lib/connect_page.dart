import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:get_ip/get_ip.dart';

class ConnectPage extends StatefulWidget {
  final String displayName;

  ConnectPage({Key key, this.displayName}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  String ownIPAddress = "z"; // dummy value because it can't be "" or null
  String otherIPAddress = "";
  StreamSubscription<ConnectivityResult> subscription;

  void updateOwnIP() async {
    // This seems to return an empty string when not connected, but the docs say
    // it can also return null.
    var ip = await GetIp.ipAddress;
    setState(() => ownIPAddress = ip);
  }

  @override
  void initState() {
    super.initState();
    updateOwnIP();
    subscription = Connectivity().onConnectivityChanged.listen((result) {
      // This setState() call is necessary because updateOwnIP() seems to
      // occasionally return old data, e.g. when called immediately after
      // turning off mobile data.
      setState(() => ownIPAddress = null);
      updateOwnIP();
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Connect to device"),
      ),
      body: Center(
        child: ownIPAddress == null || ownIPAddress == ""
            ? Text(
                "Can't get local IP address. Please ensure you're connected to Wi-Fi and try again.",
                textAlign: TextAlign.center,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text("Hello, ${widget.displayName}!"),
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.black),
                        children: ownIPAddress == "z"
                            ? [
                                TextSpan(
                                  text: "Acquiring local IP address…",
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                )
                              ]
                            : [
                                TextSpan(text: "Your local IP address is "),
                                TextSpan(
                                  text: ownIPAddress,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                )
                              ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "Enter local IP address of the device you wish to connect to.",
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IntrinsicWidth(
                    child: TextField(
                      decoration: InputDecoration(hintText: "IP address"),
                      onChanged: (input) {
                        setState(() => otherIPAddress = input);
                      },
                    ),
                  ),
                  Builder(
                    builder: (context) => RaisedButton(
                      child: Text("Connect"),
                      onPressed: otherIPAddress == ""
                          ? null
                          : () => Scaffold.of(context).showSnackBar(SnackBar(
                              content: Text("Hello, $otherIPAddress!"))),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
