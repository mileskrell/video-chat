import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_ip/get_ip.dart';

class SocketTestPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SocketTestPageState();
}

class _SocketTestPageState extends State<SocketTestPage> {
  SocketState socketState = SocketState.STOPPED;
  Socket socket;
  ServerSocket serverSocket;

  String ownIPAddress = "z"; // dummy value because it can't be "" or null
  String otherIPAddress;

  String sendText;
  String messageText;

  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Socket test"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                color: Colors.green,
                child: Text("Send"),
                onPressed: socketState == SocketState.SENDING
                    ? null
                    : () {
                        serverSocket?.close();
                        setState(() => socketState = SocketState.SENDING);
                      },
              ),
              RaisedButton(
                color: Colors.blue,
                child: Text("Receive"),
                onPressed: socketState == SocketState.RECEIVING
                    ? null
                    : () async {
                        updateOwnIP();

                        socket?.destroy();
                        socket = null; // Because we check whether it's null or not later on.
                        // TODO: Fix the UI so we're not doing that
                        setState(() => socketState = SocketState.RECEIVING);
                        serverSocket?.close();
                        final ss = await ServerSocket.bind(
                          InternetAddress.anyIPv4,
                          PORT,
                        );
                        ss.listen((socket) {
                          socket.listen((data) {
                            setState(() {
                              messageText = String.fromCharCodes(data).trim();
                            });
                          });
                        });
                        setState(() {
                          this.serverSocket = ss;
                        });
                      },
              ),
              RaisedButton(
                color: Colors.red,
                child: Text("Stop"),
                onPressed: socketState == SocketState.STOPPED
                    ? null
                    : () {
                        serverSocket?.close();
                        socket?.destroy();
                        socket = null;
                        setState(() => socketState = SocketState.STOPPED);
                      },
              ),
            ],
          ),
          socketState == SocketState.SENDING
              ? Column(
                  children: <Widget>[
                    IntrinsicWidth(
                      child: TextField(
                        decoration: InputDecoration(hintText: "IP address"),
                        onChanged: (input) =>
                            setState(() => otherIPAddress = input),
                      ),
                    ),
                    IntrinsicWidth(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(hintText: "Message text"),
                        onChanged: (input) => setState(() => sendText = input),
                      ),
                    ),
                    Builder(
                      builder: (context) => RaisedButton(
                        child: Text("Send message"),
                        onPressed: () async {
                          socket ??= await Socket.connect(otherIPAddress, PORT);
                          socket.write(sendText + "\n");
                          Scaffold.of(context).showSnackBar(
                            SnackBar(content: Text("Message sent!")),
                          );
                          controller.clear();
                          setState(() => sendText = null);
                        },
                      ),
                    )
                  ],
                )
              : socketState == SocketState.RECEIVING
                  ? Column(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            ownIPAddress == "z"
                                ? "Determining your IP address..."
                                : "Your IP address: $ownIPAddress",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(messageText ?? "latest message will appear here"),
                      ],
                    )
                  : Container(),
        ],
      ),
    );
  }

  void updateOwnIP() async {
    // This seems to return an empty string when not connected, but the docs say
    // it can also return null.
    var ip = await GetIp.ipAddress;
    setState(() => ownIPAddress = ip);
  }
}

enum SocketState {
  SENDING,
  RECEIVING,
  STOPPED,
}

const PORT = 5656;
