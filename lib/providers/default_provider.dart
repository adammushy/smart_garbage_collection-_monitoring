import 'package:flutter/material.dart';

class DefaultProvider with ChangeNotifier{
  var _data;

  get getData => _data;

  void setData(String newData) {
    _data = newData;
    notifyListeners();
  } 
}