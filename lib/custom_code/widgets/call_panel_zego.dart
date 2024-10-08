// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:math' as math;
import 'dart:convert';
import 'dart:core';
import 'package:flutter/cupertino.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class CallPanelZego extends StatefulWidget {
  const CallPanelZego({
    super.key,
    this.width,
    this.height,
    required this.localUserID,
    required this.localUserName,
    required this.roomID,
  });

  final double? width;
  final double? height;
  final String localUserID;
  final String localUserName;
  final String roomID;

  @override
  State<CallPanelZego> createState() => _CallPanelZegoState();
}

class _CallPanelZegoState extends State<CallPanelZego> {
  Widget? localView;
  int? localViewID;
  Widget? remoteView;
  int? remoteViewID;

  @override
  void initState() {
    startListenEvent();
    loginRoom();
    super.initState();
  }

  @override
  void dispose() {
    stopListenEvent();

    logoutRoom();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceEvenly,
            spacing: 6,
            children: [
              SizedBox.square(
                dimension: MediaQuery.of(context).size.width * 0.1,
                child: localView ?? const SizedBox.shrink(),
              ),
              SizedBox.square(
                dimension: MediaQuery.of(context).size.width * 0.1,
                child: AspectRatio(
                  aspectRatio: 9.0 / 16.0,
                  child: remoteView ?? Container(color: Colors.transparent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<ZegoRoomLoginResult> loginRoom() async {
    // The value of `userID` is generated locally and must be globally unique.
    final user = ZegoUser(widget.localUserID, widget.localUserName);

    // The value of `roomID` is generated locally and must be globally unique.
    final roomID = widget.roomID;

    // onRoomUserUpdate callback can be received when "isUserStatusNotify" parameter value is "true".
    ZegoRoomConfig roomConfig = ZegoRoomConfig.defaultConfig()
      ..isUserStatusNotify = true;

    if (kIsWeb) {
      // ! ** Warning: ZegoTokenUtils is only for use during testing. When your application goes live,
      // ! ** tokens must be generated by the server side. Please do not generate tokens on the client side!
      roomConfig.token = ZegoTokenUtils.generateToken(FFAppConstants.appID,
          FFAppConstants.serverSecret, widget.localUserID);
    }
    // log in to a room
    // Users must log in to the same room to call each other.
    return ZegoExpressEngine.instance
        .loginRoom(roomID, user, config: roomConfig)
        .then((ZegoRoomLoginResult loginRoomResult) {
      debugPrint(
          'loginRoom: errorCode:${loginRoomResult.errorCode}, extendedData:${loginRoomResult.extendedData}');
      if (loginRoomResult.errorCode == 0) {
        startPreview();
        startPublish();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('loginRoom failed: ${loginRoomResult.errorCode}')));
      }
      return loginRoomResult;
    });
  }

  Future<ZegoRoomLogoutResult> logoutRoom() async {
    stopPreview();
    stopPublish();
    return ZegoExpressEngine.instance.logoutRoom(widget.roomID);
  }

  void startListenEvent() {
    // Callback for updates on the status of other users in the room.
    // Users can only receive callbacks when the isUserStatusNotify property of ZegoRoomConfig is set to `true` when logging in to the room (loginRoom).
    ZegoExpressEngine.onRoomUserUpdate =
        (roomID, updateType, List<ZegoUser> userList) {
      debugPrint(
          'onRoomUserUpdate: roomID: $roomID, updateType: ${updateType.name}, userList: ${userList.map((e) => e.userID)}');
    };
    // Callback for updates on the status of the streams in the room.
    ZegoExpressEngine.onRoomStreamUpdate =
        (roomID, updateType, List<ZegoStream> streamList, extendedData) {
      debugPrint(
          'onRoomStreamUpdate: roomID: $roomID, updateType: $updateType, streamList: ${streamList.map((e) => e.streamID)}, extendedData: $extendedData');
      if (updateType == ZegoUpdateType.Add) {
        for (final stream in streamList) {
          startPlayStream(stream.streamID);
        }
      } else {
        for (final stream in streamList) {
          stopPlayStream(stream.streamID);
        }
      }
    };
    // Callback for updates on the current user's room connection status.
    ZegoExpressEngine.onRoomStateUpdate =
        (roomID, state, errorCode, extendedData) {
      debugPrint(
          'onRoomStateUpdate: roomID: $roomID, state: ${state.name}, errorCode: $errorCode, extendedData: $extendedData');
    };

    ZegoExpressEngine.onPublisherStateUpdate =
        (streamID, state, errorCode, extendedData) {
      debugPrint(
          'onPublisherStateUpdate: streamID: $streamID, state: ${state.name}, errorCode: $errorCode, extendedData: $extendedData');
    };
  }

  void stopListenEvent() {
    ZegoExpressEngine.onRoomUserUpdate = null;
    ZegoExpressEngine.onRoomStreamUpdate = null;
    ZegoExpressEngine.onRoomStateUpdate = null;
    ZegoExpressEngine.onPublisherStateUpdate = null;
  }

  Future<void> startPreview() async {
    await ZegoExpressEngine.instance.createCanvasView((viewID) {
      localViewID = viewID;
      ZegoCanvas previewCanvas =
          ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
      ZegoExpressEngine.instance.startPreview(canvas: previewCanvas);
    }).then((canvasViewWidget) {
      setState(() => localView = canvasViewWidget);
    });
  }

  Future<void> stopPreview() async {
    ZegoExpressEngine.instance.stopPreview();
    if (localViewID != null) {
      await ZegoExpressEngine.instance.destroyCanvasView(localViewID!);
      if (mounted) {
        setState(() {
          localViewID = null;
          localView = null;
        });
      }
    }
  }

  Future<void> startPublish() async {
    // After calling the `loginRoom` method, call this method to publish streams.
    // The StreamID must be unique in the room.
    String streamID = '${widget.roomID}_${widget.localUserID}_call';
    return ZegoExpressEngine.instance.startPublishingStream(streamID);
  }

  Future<void> stopPublish() async {
    return ZegoExpressEngine.instance.stopPublishingStream();
  }

  Future<void> startPlayStream(String streamID) async {
    // Start to play streams. Set the view for rendering the remote streams.
    await ZegoExpressEngine.instance.createCanvasView((viewID) {
      remoteViewID = viewID;
      ZegoCanvas canvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
      ZegoExpressEngine.instance.startPlayingStream(
        streamID,
        canvas: canvas,
        config: ZegoPlayerConfig.defaultConfig(),
      );
    }).then((canvasViewWidget) {
      setState(() => remoteView = canvasViewWidget);
    });
  }

  Future<void> stopPlayStream(String streamID) async {
    ZegoExpressEngine.instance.stopPlayingStream(streamID);
    if (remoteViewID != null) {
      ZegoExpressEngine.instance.destroyCanvasView(remoteViewID!);
      if (mounted) {
        setState(() {
          remoteViewID = null;
          remoteView = null;
        });
      }
    }
  }
}

class ZegoTokenUtils {
  static String generateToken(int appid, String serverSecret, String userID,
      {int effectiveTimeInSeconds = 60 * 60 * 24, String payload = ''}) {
    debugPrint('! ${'*' * 80}');
    debugPrint(
        '! ** Warning: ZegoTokenUtils is only for use during testing. When your application goes live,');
    debugPrint(
        '! ** tokens must be generated by the server side. Please do not generate tokens on the client side!');
    debugPrint('! ${'*' * 80}');
    if (appid == 0) {
      throw Exception('appid Invalid');
    }
    if (userID == '') {
      throw Exception('userID Invalid');
    }
    if (serverSecret.length != 32) {
      throw Exception('serverSecret Invalid');
    }
    if (effectiveTimeInSeconds <= 0) {
      throw Exception('effectiveTimeInSeconds Invalid');
    }
    final tokenInfo = TokenInfo04(
      appid: appid,
      userID: userID,
      nonce: math.Random().nextInt(math.pow(2, 31).toInt()),
      ctime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      expire: 0,
      payload: payload,
    );
    tokenInfo.expire = tokenInfo.ctime + effectiveTimeInSeconds;
    // Convert token information to json
    final tokenJson = tokenInfo.toJson();

    // Randomly generated 16-byte string, used as AES encryption vector,
    // before the ciphertext for Base64 encoding to generate the final token
    final ivStr = createRandomString(16);
    final iv = encrypt.IV.fromUtf8(ivStr);

    final key = encrypt.Key.fromUtf8(serverSecret);
    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(tokenJson, iv: iv);

    final bytes1 = createUint8ListFromInt(tokenInfo.expire);
    final bytes2 = Uint8List.fromList([0, 16]);
    final bytes3 = Uint8List.fromList(utf8.encode(ivStr));
    final bytes4 = Uint8List.fromList([0, encrypted.bytes.length]);
    final bytes5 = encrypted.bytes;

    final bytes = Uint8List(4) + bytes1 + bytes2 + bytes3 + bytes4 + bytes5;
    final ret = '04${base64.encode(bytes)}';
    return ret;
  }

  static final _random = math.Random();
  static const _defaultPool =
      'ModuleSymbhasOwnPr-0123456789ABCDEFGHNRVfgctiUvz_KqYTJkLxpZXIjQW';

  static String createRandomString(int size, {String pool = _defaultPool}) {
    final len = pool.length;
    var id = '';
    var i = size;
    while (0 < i--) {
      id += pool[_random.nextInt(len)];
    }
    return id;
  }

  /// Creates a `Uint8List` by a hex string.
  static Uint8List createUint8ListFromHexString(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      final num = hex.substring(i, i + 2);
      final byte = int.parse(num, radix: 16);
      result[i ~/ 2] = byte;
    }

    return result;
  }

  /// Returns a hex string by a `Uint8List`.
  static String formatBytesAsHexString(Uint8List bytes) {
    final result = StringBuffer();
    for (var i = 0; i < bytes.lengthInBytes; i++) {
      final part = bytes[i];
      result.write('${part < 16 ? '0' : ''}${part.toRadixString(16)}');
    }

    return result.toString();
  }

  static Uint8List createUint8ListFromInt(int hex) {
    return createUint8ListFromHexString(hex.toRadixString(16));
  }
}

class TokenInfo04 {
  TokenInfo04(
      {required this.appid,
      required this.userID,
      required this.ctime,
      required this.expire,
      required this.nonce,
      required this.payload});
  int appid;
  String userID;
  int nonce;
  int ctime;
  int expire;
  String payload;

  String toJson() {
    return '{"app_id":$appid,"user_id":"$userID","nonce":$nonce,"ctime":$ctime,"expire":$expire,"payload":"$payload"}';
  }
}
