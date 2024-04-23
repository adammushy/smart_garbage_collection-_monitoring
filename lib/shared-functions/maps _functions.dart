// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:http/http.dart' as http;
// import 'package:http/http.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:location/location.dart';

// import 'package:geolocator/geolocator.dart' as geolocator;

// locateUserPosition() async {
//   geolocator.Position cPosition =
//       await geolocator.Geolocator.getCurrentPosition(
//           desiredAccuracy: geolocator.LocationAccuracy.high);
//   userCurrentPosition = cPosition;

//   LatLng latLngPosition =
//       LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);

//   CameraPosition cameraPosition =
//       CameraPosition(target: latLngPosition, zoom: 14);

//   newGoogleMapController!
//       .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

//   // geolocator.Geolocator.getPositionStream().listen((position) {
//   //   userCurrentPosition = position;

//   //   // Update the user's location in Firebase
//   //   updateFirebaseUserLocation(position.latitude, position.longitude);

//   //   LatLng updatedPosition = LatLng(position.latitude, position.longitude);
//   //   newGoogleMapController!
//   //       .animateCamera(CameraUpdate.newLatLng(updatedPosition));
//   // });
// }

// void updateCurrentPosition() async {
//   User? user = FirebaseAuth.instance.currentUser;

//   if (user != null) {
//     String uid = user.uid;

//     geolocator.Position cPosition =
//         await geolocator.Geolocator.getCurrentPosition(
//       desiredAccuracy: geolocator.LocationAccuracy.high,
//     );

//     // Create a reference to the user's document in Firestore
//     DocumentReference userRef =
//         FirebaseFirestore.instance.collection('Chauffeurs').doc(uid);
//     print('-----CURRENT USER');

//     print(uid);
//     // Update the user's document with the current position
//     await userRef.update({
//       'Latitude': cPosition.latitude,
//       'Longitude': cPosition.longitude,
//       'timestamp': FieldValue.serverTimestamp(), // optional: store a timestamp
//     });

//     print("User position updated in Firestore.");
//   } else {
//     print("No user is currently logged in.");
//   }
// }

// void _onMapCreated(GoogleMapController controller) async {
//   mapController = controller;

//   // ----less than 40------------------
//   // almosts enpty

//   final Uint8List markerIcon =
//       await getBytesFromAsset('images/greendustbin.png', 50);

//   await FirebaseFirestore.instance
//       .collection("data")
//       .where(
//         "percentage",
//         isLessThanOrEqualTo: 60,
//       )
//       .where("state")
//       .snapshots()
//       .listen((event) {
//     setState(() {
//       bottomPaddingOfMap = 240;
//       for (var doc in event.docs) {
//         print(doc);
//         print(event.docs);

//         _markers.add(
//           Marker(
//               markerId: MarkerId(doc.id),
//               position: LatLng(doc.data()["Latitude"], doc.data()["Longitude"]),
//               infoWindow: InfoWindow(
//                   onTap: () {
//                     print("tApped");
//                   },
//                   title:
//                       "id : ${doc.data()["name"]}\n state: ${doc.data()["state"]}",
//                   snippet: "percentage : ${doc.data()["percentage"]}"),
//               icon: BitmapDescriptor.fromBytes(markerIcon)),
//         );
//       }
//     });
//   });

//   // marker for full dustbin

//   final Uint8List markerIcon1 =
//       await getBytesFromAsset('images/reddustbin.png', 50);

//   _controllerGoogleMap.complete(controller);
//   newGoogleMapController = controller;
//   await FirebaseFirestore.instance
//       .collection("data")
//       .where("percentage", isGreaterThan: 60)
//       .snapshots()
//       .listen((event) async {
//     //_markers={};
//     setState(() {
//       bottomPaddingOfMap = 240;

//       for (var doc in event.docs) {
//         // print(doc.toString());
//         // print(event.docs);
//         _markers.add(
//           Marker(
//               markerId: MarkerId(doc.id),
//               position: LatLng(doc.data()["Latitude"], doc.data()["Longitude"]),
//               infoWindow: InfoWindow(
//                 anchor: Offset.zero,
//                 onTap: () {
//                   print("Tapped");
//                 },
//                 title:
//                     " Id : ${doc.data()["name"]} \n State : ${doc.data()["state"]}",
//                 snippet: "percentage : ${doc.data()["percentage"]} ",
//               ),
//               icon: BitmapDescriptor.fromBytes(markerIcon1)),
//         );
//         print(_markers);
//         print(event.docs);
//       }
//     });
// // -------------------TRYING TO DRAW POLYLINES
//     String url =
//         'https://api.openrouteservice.org/v2/directions/driving-car/geojson';
//     String apiKey =
//         // '5b3ce3597851110001cf62488a373729f5fe478ea1289b683c304eaa';
//         '5b3ce3597851110001cf624821e9458d5ce841e0a9246742079a3464';

//     // my api key

//     String journeyMode =
//         'driving-car'; // Change it if you want or make it variable
//     // List<List<double>> points = <List<double>>[];

//     List<List<double>> points = [];
//     geolocator.Position cPosition =
//         await geolocator.Geolocator.getCurrentPosition(
//       desiredAccuracy: geolocator.LocationAccuracy.high,
//     );
//     points.add([cPosition.longitude, cPosition.latitude]);

//     print("point with current location");
//     print(points);
// // ---------------OLD VERSION---------------
// //  initialize an empty list distList to store points and distances.
//     List distList = [];
//     var docs = event.docs;

//     // iterate through the docs list obtained from the Firestore event. For each document, you extract latitude, longitude, and create a point list.
//     for (var element in docs) {
//       double latitude = element.get("Latitude");
//       double longitude = element.get("Longitude");
//       List point = [element.get("Longitude"), element.get("Latitude")];
//       // points.add([element.get("Longitude"), element.get("Latitude")]);

// // calculate the distance between the current position (cPosition) and the latitude, longitude obtained from the document.
//       double distance = await Geolocator.distanceBetween(
//         cPosition.latitude,
//         cPosition.longitude,
//         latitude,
//         longitude,
//       );
//       distance = distance / 1000;
// // The result is stored in a map obj with keys "point" and "distance".
// // The map is printed, and then added to the distList.
//       Map<String, dynamic> obj = {"point": point, "distance": "$distance km"};

//       print(obj);
//       distList.add(obj);
//       print(distList);
//       // points.add([distance, latitude, longitude, element.get("name")]);
//     }
//     // Sort the distList by the dist key in ascending order then printing the sorted list
//     distList.sort((a, b) => a["distance"].compareTo(b["distance"]));
//     print("________SORTED");
//     print(distList);

// // Loop through the distList and add the points to the points list
//     for (var obj in distList) {
//       // Get the point from the map
//       List<dynamic> point = obj["point"];
//       print("______POINt");
//       print(point);
//       // Add the point to the points list
//       points.add(point.cast<double>());

//       print("-----final result-----");
//       print(points);
//     }

// // ---------------OLD VERSION---------------
//     print(points);
//     // print("***------------------******");
//     var body = json.encode({
//       "coordinates": points,
//       "radiuses": [10000]
//     });
//     print("-------body--------");
//     print(body);
//     print(url);

//     Response response = await http.post(Uri.parse(url),
//         body: body,
//         headers: {"Content-Type": "application/json", "Authorization": apiKey});
//     print('-------RESPONSE CONTENT---------');
//     print(
//         "headers: ${response.headers} \n body: ${response.body} \n request: ${response.request}");
//     print("------------RESPONSE-------");
//     print(response.statusCode);
//     setState(() {
//       if (response.statusCode == 200) {
//         String datastr = response.body;
//         var data = jsonDecode(datastr);
//         LineString ls =
//             LineString(data['features'][0]['geometry']['coordinates']);

//         for (int i = 0; i < ls.lineString.length; i++) {
//           polyPoints.add(LatLng(ls.lineString[i][1], ls.lineString[i][0]));
//         }
//         if (polyPoints.length == ls.lineString.length) {
//           Polyline polyline = Polyline(
//             width: 4,
//             polylineId: PolylineId("polyline"),
//             color: Color.fromARGB(198, 37, 196, 1),
//             points: polyPoints,
//           );
//           polyLines.add(polyline);
//         }
//       } else {
//         print("----------------------------the response ----------");
//         print(response.statusCode);
//       }
//     });
//   });
//   setState(() {});
//   locateUserPosition();
//   updateCurrentPosition();
// }
