import 'dart:convert';

import 'package:SGMCS/shared-preference-manager/preference-manager.dart';
import 'package:flutter/material.dart';
import 'package:SGMCS/constants/app_constants.dart';
import 'package:SGMCS/helpers/api/api_client_http.dart';

class DataManagementProvider with ChangeNotifier {
  List _data = [];
  List get data => _data;

  var _personalReportList;
  var _allReportList;

  get allReportList => _allReportList;
  get personalReportList => _personalReportList;
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
              headers: <String, String>{"Content-Type": "application/json"})
          .postRequest(AppConstants.reportComplain, data, ctx);
      print("res :: $res");

      if (res == null) {
        return {"status": false, "msg": "failed to submit"};
      } else {
        var body = res;
        if (body['success']) {
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

  Future<Map<String, dynamic>> report(ctx, data) async {
    try {
      var res = await ApiClientHttp(
              headers: <String, String>{'Content-type': 'application/json'})
          .postRequest(AppConstants.reportBreakdown, data, ctx);
      print("res :: $res");

      if (res == null) {
        return {"status": false, "msg": "failed to submit"};
      } else {
        var body = res;
        if (body['save']) {
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

  Future<bool> getDriverReport() async {
    try {
      var sharedRef = SharedPreferencesManager();
      var user = jsonDecode(await sharedRef.getString(AppConstants.user));
      var res = await ApiClientHttp(
              headers: <String, String>{"Content-Type": "application/json"})
          .getRequest("${AppConstants.reportBreakdown}?id=${user['id']}&q=s");

      if (res == null) {
        return false;
      } else {
        var body = res;
        _personalReportList = body['data'];
        print("Body :: $body");
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("${e.toString()}");
      return false;
    }
  }

  Future<bool> getAllReport() async {
    try {
      var sharedRef = SharedPreferencesManager();
      var user = jsonDecode(await sharedRef.getString(AppConstants.user));
      var res = await ApiClientHttp(
              headers: <String, String>{"Content-Type": "application/json"})
          .getRequest("${AppConstants.reportBreakdown}?q=a");

      if (res == null) {
        return false;
      } else {
        var body = res;
        // _personalReportList = body['data'];
        _allReportList = body['data'];
        print("All Reports :: $_allReportList");
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("${e.toString()}");
      return false;
    }
  }
}
