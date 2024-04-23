
import 'dart:typed_data';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:open_route_service/open_route_service.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:flutter_project_template/shared-functions/icon_maker.dart';
import 'package:flutter_project_template/shared-functions/routes.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;


Future<void> onMapcreatedd(Function setStateCallback)async{
  late GoogleMapController mapController;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;
  final db = FirebaseFirestore.instance;

  final List<LatLng> polyPoints = [];
  final Set<Polyline> polyLines = {};

  void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
//  final Set<Marker> markers = {}; // For holding instance of Marker
    //! firestore marker bin/
    // var marker = <Marker>[];
    Set<Marker> _markers = {};
    // fetchin dustbin with low level
    final Uint8List markerIcon =
        await getBytesFromAsset('assets/images/greendustbins.png', 50);

    await db
        .collection("data")
        .where("percentage", isLessThanOrEqualTo: 60)
        .where("state")
        .snapshots()
        .listen((event) {
      setStateCallback(() {
        for (var doc in event.docs) {
          _markers.add(
            Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(
                  doc.data()["Latitude"],
                  doc.data()["Longitude"],
                ),
                infoWindow: InfoWindow(
                  onTap: () {
                    print("To be used latter");
                  },
                  title:
                      "id : ${doc.data()["name"]}\n state: ${doc.data()["state"]}",
                  snippet: "percentage : ${doc.data()["percentage"]}",
                ),
                icon: BitmapDescriptor.fromBytes(markerIcon)),
          );
        }
      });
    });

    // for full dustbins?
    final Uint8List markerIconFull =
        await getBytesFromAsset('assets/images/reddustbin.png', 50);

    await db
        .collection("data")
        .where("percentage", isGreaterThan: 60)
        .snapshots()
        .listen((event) async {
      setStateCallback(() {
        for (var doc in event.docs) {
          _markers.add(
            Marker(
              markerId: MarkerId(doc.id),
              infoWindow: InfoWindow(
                title:
                    "id : ${doc.data()["name"]}\n state: ${doc.data()["state"]}",
                snippet: "percentage : ${doc.data()["percentage"]}",
              ),
              icon: BitmapDescriptor.fromBytes(markerIconFull),
            ),
          );
        }
      });
      // generate routes for all full dustbins
      String url =
          'https://api.openrouteservice.org/v2/directions/driving-car/geojson';
      String apiKey =
          // '5b3ce3597851110001cf62488a373729f5fe478ea1289b683c304eaa';
          '5b3ce3597851110001cf624821e9458d5ce841e0a9246742079a3464';

      // my api key

      String journeyMode =
          'driving-car'; // Change it if you want or make it variable
      // List<List<double>> points = <List<double>>[];

      List<List<double>> points = [];
      geolocator.Position cPosition =
          await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.high,
      );
      points.add([cPosition.longitude, cPosition.latitude]);

// ---------------OLD VERSION---------------
//  initialize an empty list distList to store points and distances.
      List distList = [];
      var docs = event.docs;

      // iterate through the docs list obtained from the Firestore event. For each document, you extract latitude, longitude, and create a point list.
      for (var element in docs) {
        double latitude = element.get("Latitude");
        double longitude = element.get("Longitude");
        List point = [element.get("Longitude"), element.get("Latitude")];
        // points.add([element.get("Longitude"), element.get("Latitude")]);

// calculate the distance between the current position (cPosition) and the latitude, longitude obtained from the document.
        double distance = await Geolocator.distanceBetween(
          cPosition.latitude,
          cPosition.longitude,
          latitude,
          longitude,
        );
        distance = distance / 1000;
// The result is stored in a map obj with keys "point" and "distance".
// The map is printed, and then added to the distList.
        Map<String, dynamic> obj = {"point": point, "distance": "$distance km"};

        distList.add(obj);

        // points.add([distance, latitude, longitude, element.get("name")]);
      }
      // Sort the distList by the dist key in ascending order then printing the sorted list
      distList.sort((a, b) => a["distance"].compareTo(b["distance"]));

// Loop through the distList and add the points to the points list
      for (var obj in distList) {
        // Get the point from the map
        List<dynamic> point = obj["point"];

        // Add the point to the points list
        points.add(point.cast<double>());
      }

// ---------------OLD VERSION---------------

      // print("***------------------******");
      var body = json.encode({
        "coordinates": points,
        "radiuses": [10000]
      });

      Response response = await http.post(Uri.parse(url), body: body, headers: {
        "Content-Type": "application/json",
        "Authorization": apiKey
      });

      setStateCallback(() {
        if (response.statusCode == 200) {
          String datastr = response.body;
          var data = jsonDecode(datastr);
          LineString ls =
              LineString(data['features'][0]['geometry']['coordinates']);

          for (int i = 0; i < ls.lineString.length; i++) {
            polyPoints.add(LatLng(ls.lineString[i][1], ls.lineString[i][0]));
          }
          if (polyPoints.length == ls.lineString.length) {
            Polyline polyline = Polyline(
              width: 4,
              polylineId: PolylineId("polyline"),
              color: Color.fromARGB(198, 37, 196, 1),
              points: polyPoints,
            );
            polyLines.add(polyline);
          }
        } else {
          print("----------------------------the response ----------");
          print(response.statusCode);
        }
      });
    });
  }

  // void updateCurrentPosition() async {

  // }

  void calculateDistance() async {}

  Position? userCurrentPosition;
  var geoLocator = Geolocator();

  LocationPermission? _locationPermission;

  checkIfLocationPermissionAllowed() async {
    _locationPermission = await geolocator.Geolocator.requestPermission();

    if (_locationPermission == geolocator.LocationPermission.denied) {
      _locationPermission = await geolocator.Geolocator.requestPermission();
    }
  }

  locateUserPosition() async {
    geolocator.Position currentPosition =
        await geolocator.Geolocator.getCurrentPosition(
            desiredAccuracy: geolocator.LocationAccuracy.high);

    userCurrentPosition = currentPosition;
    LatLng latLngPosition =
        LatLng(currentPosition!.latitude, currentPosition!.longitude);
    CameraPosition cameraPosition =
        CameraPosition(target: latLngPosition, zoom: 14);

    newGoogleMapController!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

  }

  
}



class LineString {
  LineString(this.lineString);
  List<dynamic> lineString;
}
