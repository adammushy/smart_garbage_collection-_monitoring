import 'package:flutter/material.dart';

import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';

import 'package:geolocator/geolocator.dart' as geolocator;

class MapFunctions {
  static checkIfLocationPermissionAllowed() async {
    LocationPermission? _locationPermission;

    _locationPermission = await Geolocator.requestPermission();

    if (_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator.requestPermission();
    }
  }

  static double calculateDistance(double startLatitude, double startLongitude,
      double endLatitude, double endLongitude) {
    print(
        "Distance between Points :: ${Geolocator.distanceBetween(startLatitude, startLongitude, endLatitude, endLongitude)}");
    return Geolocator.distanceBetween(
        startLatitude, startLongitude, endLatitude, endLongitude);
  }

  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, show a message or handle accordingly
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, show a message or handle accordingly
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, show a message or handle accordingly
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted, and we can access the position
    return await Geolocator.getCurrentPosition();
  }

  
}
