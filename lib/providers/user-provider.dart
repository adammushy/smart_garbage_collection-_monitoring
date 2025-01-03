import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:SGMCS/constants/app_constants.dart';
import 'package:SGMCS/helpers/api/api_client_http.dart';
import 'package:SGMCS/shared-preference-manager/preference-manager.dart';

class UserManagementProvider with ChangeNotifier {
  var _allUsers;

  get allUsers => _allUsers;

  Future<Map<String, dynamic>> userLogin(data, ctx) async {
    print(data);
    try {
      var res = await ApiClientHttp(
              headers: <String, String>{'Content-type': 'application/json'})
          .postRequest(AppConstants.loginUrl, data, ctx);
      print("RES :: $res");

      if (res == null) {
        return {"status": "Fail"};
      } else {
        print("RES :: $res");
        var body = res;
        print("body :: $body");

        if (body['login']) {
          var sharedPref = SharedPreferencesManager();
          await sharedPref.init();
          sharedPref.saveString(AppConstants.user,
              json.encode(body['user'])); // Encode user object to JSON
          sharedPref.saveString(
              AppConstants.token,
              json.encode(body[
                  'token'])); // Token is already a string, no need to encode
          return {"status": "true", "usertype": body['user']['usertype']};
        }
        return {"status": false, "body": body, "exception": false};
      }
    } catch (e) {
      debugPrint(e.toString());
      return {"status": false, "exception": e.toString()};
    }
  }

  Future<Map<String, dynamic>> registerUser(ctx, data) async {
    try {
      var res = await ApiClientHttp(
              headers: <String, String>{'Content-type': 'application/json'})
          .postRequest(AppConstants.registerUrl, data, ctx);
      print("RES :: $res");

      if (res == null) {
        return {"status": "Fail"};
      } else {
        print("RES :: $res");
        var body = res;
        if (body['save']) {
          return {"status": true};
        }
        print("body ${body}");
        return {"status": false, "body": body, "exception": false};
      }
      ;
    } catch (e) {
      return {"status": "Fail", "message": e.toString()};
    }
  }

  Future<bool> fetchAllUsers() async {
    try {
      var res = await ApiClientHttp(
              headers: <String, String>{"Content-Type": "application/json"})
          .getRequest(AppConstants.registerUrl);

      if (res == null) {
        print("RES ON NULl :: $res");
        return false;
      } else {
        var body = res;

        _allUsers = body;
        print("All USerss :: $_allUsers");
        notifyListeners();
        return true;
      }
    } catch (e) {
      return false;
    }
  }
}
