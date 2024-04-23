import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_project_template/constants/app_constants.dart';
import 'package:flutter_project_template/helpers/api/api_client_http.dart';

class DataManagementProvider extends ChangeNotifier {
  List _data = [];
  List get data => _data;

  Future<bool> fetchDustbins() async {
    try {
      var res = await ApiClientHttp(
        headers: <String, String>{'Content-type': 'application/json'},
      ).getRequest(AppConstants.trashcan);

      print("response:: $res");

      if (res == null) {
        return false;
      } else {
        List newData = res;

        _data = newData;
        notifyListeners(); // Notify listeners that data has been updated
        return true;
      }
    } catch (e) {
      print("Error : ${e.toString()}");
      return false;
    }
  }

  Future<Map<String, dynamic>> complain(ctx, data) async {
    try {
      var res = await ApiClientHttp(
              headers: <String, String>{'Content-type': 'application/json'})
          .postRequest(AppConstants.reportComplain, data, ctx);
          print("res :: $res");

      if (res == null) {
        return {"status": false, "msg": "failed to submit"};
      } else {
        var body = res;
        if (body['status']) {
          print("BODY :: $body");

          return {"status": true, "msg": "Submited succesfully"};
        }
        return {"status": false, "body": body};
      }
    } catch (e) {
      print("ERRORS :: $e");
      return {"status": false, "msg": "Error ${e.toString()}"};
    }
  }
}
