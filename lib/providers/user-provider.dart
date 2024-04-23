import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_project_template/constants/app_constants.dart';
import 'package:flutter_project_template/helpers/api/api_client_http.dart';
import 'package:flutter_project_template/shared-preference-manager/preference-manager.dart';

class UserManagementProvider extends ChangeNotifier {
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
          return {"status": "true",
          
          "usertype": body['user']['usertype']};
        }
        return {"status": false, "body": body, "exception": false};
      }
    } catch (e) {
      debugPrint(e.toString());
      return {"status": false, "exception": e.toString()};
    }
  }

  Future<Map<String, dynamic>> registerUser(ctx,data) async {
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
}
