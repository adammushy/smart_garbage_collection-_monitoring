import 'package:flutter/material.dart';
import 'package:SGMCS/constants/app_constants.dart';
import 'package:SGMCS/helpers/database-sqlf/database.dart';
import 'package:SGMCS/providers/default_provider.dart';
import 'package:SGMCS/shared-preference-manager/preference-manager.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  @override
  void initState() {
    super.initState();
    //Test Provider
    Provider.of<DefaultProvider>(context, listen: false).setData("");
    //Test Database
    final dbHelper = DBHelper();
    dbHelper.insertRecord({});
    //Test SharedPreferences
    var sharedPref = SharedPreferencesManager();
    sharedPref.init();
    sharedPref.saveString(AppConstants.token, "iiiiiiiiiiiiiiiiiiiiiiii");
    //For WebSocket
    channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.47.193:8000/chat-room-conversation/$chatId'),
    );
  }

  //For WebSocket
  var chatId = "1223";
  late WebSocketChannel channel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            //Test WebSocket
            StreamBuilder(
              stream: channel.stream,
              builder: (context, snapshot) {
                return Text(snapshot.hasData ? '${snapshot.data}' : 'xxx');
              },
            ),

            //Test Provider
            Consumer<DefaultProvider>(
                builder: (context, recordProvider, child) {
              return Text(recordProvider.getData.toString());
            }),
          ],
        ),
      ),
    );
  }
}
