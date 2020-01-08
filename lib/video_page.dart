import 'package:flutter/material.dart';
import 'package:flutter_webrtc/webrtc.dart';

class VideoPage extends StatefulWidget {
  final String displayName;
  final String remoteDisplayName;
  final RTCPeerConnection rtcPeerConnection;

  VideoPage(this.displayName, this.remoteDisplayName, this.rtcPeerConnection);

  @override
  State<StatefulWidget> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    () async {
      await localRenderer.initialize();
      await remoteRenderer.initialize();

      widget.rtcPeerConnection.onAddStream = (stream) {
        remoteRenderer.srcObject = stream;
      };
      widget.rtcPeerConnection.onRemoveStream = (stream) {
        remoteRenderer.srcObject = null;
      };

      final localStreams = widget.rtcPeerConnection.getLocalStreams();
      final remoteStreams = widget.rtcPeerConnection.getRemoteStreams();

      if (localStreams.isEmpty) {
      } else {
        setState(() => localRenderer.srcObject = localStreams.last);
      }
      if (remoteStreams.isEmpty) {
      } else {
        setState(() => remoteRenderer.srcObject = remoteStreams.last);
      }
    }();
  }

  @override
  void deactivate() {
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Video call")),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 200,
                height: 400,
                child: RTCVideoView(remoteRenderer),
              ),
              Text(widget.remoteDisplayName),
              Padding(padding: EdgeInsets.all(16)),
              Text(widget.displayName),
              Container(
                width: 200,
                height: 400,
                child: RTCVideoView(localRenderer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
