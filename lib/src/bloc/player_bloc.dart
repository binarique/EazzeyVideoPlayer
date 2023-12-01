import 'dart:async';

import 'package:flutter/material.dart';

class PlayerBloc with ChangeNotifier {
  // Stream controller:::
  StreamController<Map> uiCommunication = StreamController.broadcast();

  PlayerBloc() {}
  // Function to send UI Message::
  //////////////////////////
  void sendMessage(Map message) {
    uiCommunication.add(message);
    notifyListeners();
  }

  @override
  void dispose() {
    // ignore: todo
    // TODO: implement dispose
    uiCommunication.done;
    super.dispose();
  }
}
