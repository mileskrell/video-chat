import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_ip/get_ip.dart';

class SocketChat extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SocketChatState();
}

class _SocketChatState extends State<SocketChat> {
  Socket socket;
  ServerSocket serverSocket;

  String ownIPAddress = "z"; // dummy value because it can't be "" or null
  String otherIPAddress = "";

  String sendText = "";

  List<Message> messages = [];

  final otherIPController = TextEditingController();
  final sendMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    startReceiving();
  }

  void startReceiving() async {
    updateOwnIP();

    socket?.destroy();
    socket = null; // Because we check whether it's null or not later on.
    serverSocket?.close();
    final ss = await ServerSocket.bind(
      InternetAddress.anyIPv4,
      PORT,
    );
    ss.listen((socket) {
      if (otherIPAddress == "") {
        setState(() => otherIPAddress = socket.remoteAddress.address);
        otherIPController.text = otherIPAddress;
      }
      socket.listen((data) {
        setState(() {
          messages.add(Message(String.fromCharCodes(data).trim(), false));
        });
      });
    });
    setState(() => this.serverSocket = ss);
  }

  Function createSender(BuildContext context) {
    return () {
      () async {
        try {
          if (socket == null ||
              socket.remoteAddress.address != otherIPAddress) {
            socket?.destroy();
            socket = await Socket.connect(otherIPAddress, PORT);
          }
          socket.write(sendText + "\n");
          setState(() => messages.add(Message(sendText, true)));
          Scaffold.of(context).showSnackBar(
            SnackBar(content: Text("Message sent!")),
          );

          sendMessageController.clear();
          setState(() => sendText = "");
        } on SocketException {
          Scaffold.of(context).showSnackBar(
            SnackBar(content: Text("ERROR: Couldn't send message")),
          );
        }
      }();
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Socket test"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                color: Colors.red,
                child: Text("Restart"),
                onPressed: () {
                  serverSocket?.close();
                  socket?.destroy();
                  socket = null;
                },
              ),
              IntrinsicWidth(
                child: TextField(
                  controller: otherIPController,
                  decoration: InputDecoration(hintText: "IP address"),
                  onChanged: (input) => setState(() => otherIPAddress = input),
                ),
              ),
              IntrinsicWidth(
                child: TextField(
                  controller: sendMessageController,
                  decoration: InputDecoration(hintText: "Message text"),
                  onChanged: (input) => setState(() => sendText = input),
                ),
              ),
              Builder(
                builder: (context) => RaisedButton(
                  child: Text("Send message"),
                  onPressed: otherIPAddress != "" && sendText != ""
                      ? createSender(context)
                      : null,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: ownIPAddress == "z"
                    ? Text("Determining your IP address...")
                    : RichText(
                        text: TextSpan(children: [
                        TextSpan(
                            text: "Your IP address: ",
                            style: TextStyle(color: Colors.black)),
                        TextSpan(
                          text: ownIPAddress,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ])),
              ),
            ],
          ),
          if (messages.isEmpty)
            Text(
              "No messages yet!",
              style: TextStyle(fontSize: 22),
            ),
          if (messages.isNotEmpty)
            Flexible(
              child: ListView(
                  shrinkWrap: true,
                  children: messages.map(
                    (message) {
                      return ListTile(
                        title: Text(
                          message.text,
                          textAlign: message.ownMessage
                              ? TextAlign.end
                              : TextAlign.start,
                          style: TextStyle(
                            color:
                                message.ownMessage ? Colors.blue : null,
                          ),
                        ),
                        leading:
                            message.ownMessage ? null : Icon(Icons.tag_faces),
                        trailing: message.ownMessage
                            ? Icon(Icons.tag_faces, color: Colors.blue)
                            : null,
                      );
                    },
                  ).toList()),
            ),
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

const PORT = 5656;

class Message {
  final String text;
  final bool ownMessage;

  Message(this.text, this.ownMessage);
}
