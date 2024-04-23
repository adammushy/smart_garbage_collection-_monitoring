// // ignore_for_file: prefer_const_constructors, sort_child_properties_last

// // import 'dart:js_interop';
// import 'dart:typed_data';
// import 'dart:convert';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'dart:async';
// import 'dart:convert';
// import 'package:open_route_service/open_route_service.dart';
// import 'package:location/location.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geolocator/geolocator.dart' as geolocator;
// import 'package:flutter_project_template/shared-functions/icon_maker.dart';
// import 'package:flutter_project_template/shared-functions/routes.dart';
// import 'package:http/http.dart';
// import 'package:http/http.dart' as http;

// class DriversMap extends StatefulWidget {
//   const DriversMap({super.key});

//   @override
//   State<DriversMap> createState() => _DriversMapState();
// }

// class _DriversMapState extends State<DriversMap> {
//   late GoogleMapController mapController;
//   final Completer<GoogleMapController> _controllerGoogleMap = Completer();
//   GoogleMapController? newGoogleMapController;
//   final db = FirebaseFirestore.instance;

//   final List<LatLng> polyPoints = [];
//   final Set<Polyline> polyLines = {};
//   final Set<Polyline> _polylines = {};
//   final PolylinePoints _polylinePoints = PolylinePoints();
//   Set<Marker> _markers = {};
//   LatLng? _currentDustbinPosition;
//   Position? userCurrentPosition;

//   // Define your API key
//   static const String _googleMapsApiKey =
//       "AIzaSyD79hEbrrlDT2ko8JSpUrjgzIv7PjAwSTk"; // Replace with your actual API Key

//   LocationPermission? _locationPermission;

//   checkIfLocationPermissionAllowed() async {
//     _locationPermission = await geolocator.Geolocator.requestPermission();

//     if (_locationPermission == geolocator.LocationPermission.denied) {
//       _locationPermission = await geolocator.Geolocator.requestPermission();
//     }
//   }

//   // Function to get routingqpoints from origin to destination

//   Future<List<LatLng>> getRoutePoints(String origin, String destination) async {
//     final response = await http.get(
//       Uri.parse(
//         "https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=driving&key=$_googleMapsApiKey",
//       ),
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       final route = data["routes"][0]["overview_polyline"]["points"];

//       final decoder = PolylinePoints();
//       List<PointLatLng> decodedPoints = decoder.decodePolyline(route);

//       // Convert List<PointLatLng> to List<LatLng>
//       List<LatLng> points = decodedPoints
//           .map((point) => LatLng(point.latitude, point.longitude))
//           .toList();

//       return points;
//     } else {
//       throw Exception("Failed to get directions");
//     }
//   }

//   // Function to clear the  current opened route route
//   void clearRoute() {
//     setState(() {
//       polyLines.clear();
//     });
//   }

//   // Function to recalculate the route when the origin or destination changes
//   void recalculateRoute() async {
//     // Clear existing polylines
//     clearRoute();

//     // Recalculate the route if there's a dustbin position available
//     if (_currentDustbinPosition != null) {
//       await showRouteToDustbin(_currentDustbinPosition!);
//     }
//   }

//   void _startPositionListener() {
//     Geolocator.getPositionStream().listen((Position newPosition) {
//       setState(() {
//         userCurrentPosition = newPosition;
//       });
//       // Recalculate the route
//       recalculateRoute();
//     });
//   }

//   Future<void> showRouteToDustbin(LatLng dustbinPosition) async {
//     // Get the user's current position
//     final geolocator.Position currentPosition =
//         await geolocator.Geolocator.getCurrentPosition(
//       desiredAccuracy: geolocator.LocationAccuracy.high,
//     );

//     // Convert the current position to a LatLng
//     final LatLng origin =
//         LatLng(currentPosition.latitude, currentPosition.longitude);

//     // Calculate the route points using the origin (current position) and destination (dustbin position)
//     final List<LatLng> routePoints = await getRoutePoints(
//         "${origin.latitude},${origin.longitude}",
//         "${dustbinPosition.latitude},${dustbinPosition.longitude}");

//     // Create a polyline for the route
//     final Polyline routePolyline = Polyline(
//       polylineId: PolylineId("route_to_dustbin"),
//       points: routePoints,
//       color: Colors.blue,
//       width: 5,
//     );

//     // Update the state to add the polyline to the map
//     setState(() {
//       polyLines.add(routePolyline);
//     });

//     // Center the map around the route
//     final bounds = LatLngBounds(
//       southwest: routePoints.reduce((a, b) => LatLng(
//             a.latitude < b.latitude ? a.latitude : b.latitude,
//             a.longitude < b.longitude ? a.longitude : b.longitude,
//           )),
//       northeast: routePoints.reduce((a, b) => LatLng(
//             a.latitude > b.latitude ? a.latitude : b.latitude,
//             a.longitude > b.longitude ? a.longitude : b.longitude,
//           )),
//     );

//     mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
//   }

//   void _onMapCreated(GoogleMapController controller) async {
//     mapController = controller;
//     await _loadMarkers();

//     locateUserPosition();
//   }

//   Future<void> _loadMarkers() async {
//     final Uint8List markerIcon =
//         await getBytesFromAsset('assets/images/greendustbin.png', 70);

//     await db
//         .collection("data")
//         .where("percentage", isLessThanOrEqualTo: 60)
//         .where("state")
//         .snapshots()
//         .listen((event) {
//       setState(() {
//         _markers.clear();
//         for (var doc in event.docs) {
//           final position =
//               LatLng(doc.data()["Latitude"], doc.data()["Longitude"]);
//           final marker = Marker(
//             markerId: MarkerId(doc.id),
//             position: position,
//             infoWindow: InfoWindow(
//               title:
//                   "id : ${doc.data()["name"]}\n state: ${doc.data()["state"]}",
//               snippet: "percentage : ${doc.data()["percentage"]}",
//               onTap: () => showRouteToDustbin(position),
//             ),
//             icon: BitmapDescriptor.fromBytes(markerIcon),
//           );
//           _markers.add(marker);
//         }
//       });
//     });

//     final Uint8List markerIconFull =
//         await getBytesFromAsset('assets/images/reddustbin.png', 70);

//     await db
//         .collection("data")
//         .where("percentage", isGreaterThan: 60)
//         .snapshots()
//         .listen((event) {
//       setState(() {
//         for (var doc in event.docs) {
//           final position =
//               LatLng(doc.data()["Latitude"], doc.data()["Longitude"]);
//           final marker = Marker(
//             markerId: MarkerId(doc.id),
//             position: position,
//             infoWindow: InfoWindow(
//               title:
//                   "id : ${doc.data()["name"]}\n state: ${doc.data()["state"]}",
//               snippet: "percentage : ${doc.data()["percentage"]}",
//               onTap: () => showRouteToDustbin(position),
//             ),
//             icon: BitmapDescriptor.fromBytes(markerIconFull),
//           );
//           _markers.add(marker);
//         }
//       });
//     });
//   }


//   void calculateDistance() async {}

//   // Position? userCurrentPosition;
//   var geoLocator = Geolocator();

//   locateUserPosition() async {
//     checkIfLocationPermissionAllowed();
//     geolocator.Position currentPosition =
//         await geolocator.Geolocator.getCurrentPosition(
//             desiredAccuracy: geolocator.LocationAccuracy.high);

//     userCurrentPosition = currentPosition;
//     LatLng latLngPosition =
//         LatLng(currentPosition!.latitude, currentPosition!.longitude);
//     CameraPosition cameraPosition =
//         CameraPosition(target: latLngPosition, zoom: 14);

//     newGoogleMapController!
//         .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
//   }

//   @override
//   void initState() {
//     super.initState();
//     _startPositionListener();
//     checkIfLocationPermissionAllowed();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           GoogleMap(
//             myLocationEnabled: true,
//             myLocationButtonEnabled: true,
//             mapType: MapType.normal,
//             initialCameraPosition: CameraPosition(
//                 target: LatLng(-6.76438766, 39.22930733), zoom: 14),
//             onMapCreated: _onMapCreated,
//             markers: _markers,
//             polylines: polyLines,
//           ),
//           Positioned(
//             // bottom: 100
//             top: 0,
//             left: 0,
//             right: 0,
//             child: AnimatedSize(
//               curve: Curves.easeIn,
//               duration: const Duration(milliseconds: 120),
//               child: Container(
//                 height: 120,
//                 decoration: const BoxDecoration(
//                   borderRadius: BorderRadius.only(
//                     topRight: Radius.circular(20),
//                     topLeft: Radius.circular(20),
//                   ),
//                 ),
//                 child: Padding(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
//                   child: Column(
//                     children: [
//                       Row(
//                         children: [
//                           ElevatedButton(
//                             child: const Text(
//                               " Refresh ",
//                             ),
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => DriversMap(),
//                                 ),
//                               );
//                             },
//                             style: ElevatedButton.styleFrom(
//                                 padding:
//                                     const EdgeInsets.fromLTRB(10, 10, 10, 10),
//                                 textStyle: const TextStyle(
//                                     fontSize: 24, fontWeight: FontWeight.w900)),
//                           ),
//                           Spacer(),
//                           Visibility(
//                             visible: polyLines.isNotEmpty,
//                             child: ElevatedButton(
//                               child: Text(
//                                 // "Faults",
//                                 "Cancel route",
//                               ),
//                               onPressed: () {
//                                 // Navigator.push(
//                                 //     context,
//                                 //     MaterialPageRoute(
//                                 //         builder: (context) => panne()));
//                                 // Navigator.push(
//                                 //     context,
//                                 //     MaterialPageRoute(
//                                 //         builder: (context) => DustbinListPage()));
//                                 clearRoute();
//                               },
//                               style: ElevatedButton.styleFrom(
//                                   padding:
//                                       const EdgeInsets.fromLTRB(20, 10, 20, 10),
//                                   textStyle: const TextStyle(
//                                       fontSize: 24,
//                                       fontWeight: FontWeight.w900)),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class LineString {
//   LineString(this.lineString);
//   List<dynamic> lineString;
// }
