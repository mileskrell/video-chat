import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:get_ip/get_ip.dart';
import 'package:video_chat/video_page.dart';

class ConnectPage extends StatefulWidget {
  final String displayName;

  ConnectPage({Key key, this.displayName}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  String ownIPAddress = "z"; // dummy value because it can't be "" or null
  String otherIPAddress = "";
  String remoteDisplayName;
  StreamSubscription<ConnectivityResult> subscription;

  RTCPeerConnection rtcPeerConnection;
  MediaStream localStream;

  bool hasSentOffer = false;

  RTCSessionDescription localOffer;
  RTCSessionDescription remoteOffer;
  RTCSessionDescription localAnswer;
  RTCSessionDescription remoteAnswer;

  void updateOwnIP() async {
    // This seems to return an empty string when not connected, but the docs say
    // it can also return null.
    var ip = await GetIp.ipAddress;
    setState(() => ownIPAddress = ip);
  }

  void startReceiving() async {
    final ss = await ServerSocket.bind(InternetAddress.anyIPv4, PORT);
    ss.listen((socket) {
      if (otherIPAddress == "") {
        setState(() => otherIPAddress = socket.remoteAddress.address);
      }
      socket.listen((data) async {
        final receivedNameSdpMap =
            jsonDecode(String.fromCharCodes(data));
        remoteDisplayName = receivedNameSdpMap["name"];
        final sdp = receivedNameSdpMap["sdp"];

        if (!hasSentOffer) {
          // Then we must be receiving an offer
          this.remoteOffer = RTCSessionDescription(sdp, "offer");
          rtcPeerConnection.setRemoteDescription(remoteOffer);

          // Send answer
          this.localAnswer = await rtcPeerConnection.createAnswer({});
          rtcPeerConnection.setLocalDescription(localAnswer);
          Socket.connect(socket.remoteAddress, PORT).then((returnSocket) async {
            final message = JsonEncoder().convert({
              "name": widget.displayName,
              "sdp": localAnswer.sdp,
            });
            returnSocket.write(message);
            await returnSocket.flush();
          });

          pushVideoPage();
        } else {
          // Then we must be receiving an answer to our offer
          this.remoteAnswer = RTCSessionDescription(sdp, "answer");
          rtcPeerConnection.setRemoteDescription(remoteAnswer);

          pushVideoPage();
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    updateOwnIP();
    startReceiving();
    subscription = Connectivity().onConnectivityChanged.listen((result) {
      // This setState() call is necessary because updateOwnIP() seems to
      // occasionally return old data, e.g. when called immediately after
      // turning off mobile data.
      setState(() => ownIPAddress = null);
      updateOwnIP();
    });
    () async {
      rtcPeerConnection = await createPeerConnection({
        "iceServers": [
          {"urls": "stun:stun.l.google.com:19302"}
        ]
      }, {});
      localStream = await navigator.getUserMedia(
        {
          "video": {"mandatory": {}},
          "audio": true
        },
      );
      rtcPeerConnection.addStream(localStream);
    }();
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
                      "Enter local IP address of the device you wish to connect to, or wait for someone else to connect to you.",
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
                          : () async => sendOfferAndAwaitAnswer(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<RTCSessionDescription> sendOfferAndAwaitAnswer() async {
    hasSentOffer = true;

    localOffer = await rtcPeerConnection.createOffer({});
    rtcPeerConnection.setLocalDescription(localOffer);
    final socket = await Socket.connect(otherIPAddress, PORT);
    final message = JsonEncoder().convert({
      "name": widget.displayName,
      "sdp": localOffer.sdp,
    });
    socket.write(message);
    await socket.flush();
//    socket?.destroy(); // The other device can use this socket to send its answer
  }

  void pushVideoPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VideoPage(widget.displayName, remoteDisplayName, rtcPeerConnection),
      ),
    );
  }
}

const PORT = 5657;
