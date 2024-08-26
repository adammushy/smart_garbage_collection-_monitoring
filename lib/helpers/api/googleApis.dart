import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleMapApi {
  //old api key
  // final String _url = "AIzaSyA0IGyoIXpmZ8DCSJj10aAwAkDEqvv4sfY";
  
  // my api key below
  final String _url = "${dotenv.env['googleApiKey']}";


  String get url => _url;
}
