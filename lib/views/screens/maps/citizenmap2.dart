// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, depend_on_referenced_packages, deprecated_member_use, use_build_context_synchronously, unused_local_variable

import 'dart:typed_data';
import 'dart:convert';

import 'package:SGMCS/views/screens/maps/driversMap2.dart';
import 'package:SGMCS/views/screens/maps/orservices.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:SGMCS/views/screens/drawer/custom_drawer.dart';
import 'package:SGMCS/views/screens/forms/report-form.dart';
import 'package:SGMCS/views/screens/maps/dustbindetails.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'dart:convert';
import 'package:open_route_service/open_route_service.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:SGMCS/shared-functions/icon_maker.dart';
import 'package:SGMCS/shared-functions/routes.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:wtf_sliding_sheet/wtf_sliding_sheet.dart';
import 'package:location/location.dart';
import 'package:location/location.dart' as loc;

import 'package:fan_side_drawer/fan_side_drawer.dart';
import 'package:url_launcher/url_launcher.dart';

class CitizenMap2 extends StatefulWidget {
  const CitizenMap2({super.key});

  @override
  State<CitizenMap2> createState() => _CitizenMap2State();
}

class _CitizenMap2State extends State<CitizenMap2> {
  late GoogleMapController mapController;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;
  final db = FirebaseFirestore.instance;
  bool isLoadingRoute = false;

  final List<LatLng> polyPoints = [];
  final Set<Polyline> polyLines = {};
  final Set<Polyline> _polylines = {};
  final PolylinePoints _polylinePoints = PolylinePoints();
  Set<Marker> _markers = {};
  LatLng? _currentDustbinPosition;
  Position? userCurrentPosition;

  static String _googleMapsApiKey = "AIzaSyA5FX2TxXRsH8VoGbwwOdzNl1Igj_3YsAA";
  // "${dotenv.env['googleApiKey']}";

  LocationPermission? _locationPermission;

  double drivingDistance = 0.0;
  int drivingDuration = 0;
  double walkingDistance = 0.0;
  int walkingDuration = 0;

  double latitutd = 0.0;
  double longitude = 0.0;

  static const String travelModeDriving = "driving";
  static const String travelModeWalking = "walking";
  static const String travelModeTransit = "transit";
  static const String travelModeBicycling = "bicycling";

  bool _isBottomSheetExpanded = false;
  List<DocumentSnapshot> _dustbins = [];

  checkIfLocationPermissionAllowed() async {
    _locationPermission = await Geolocator.requestPermission();
    if (_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator.requestPermission();
    }
  }

  Future<List<List<LatLng>>> getRoutePoints(
      String origin, String destination, String mode) async {
    final response = await http.get(
      Uri.parse(
        "https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=$mode&key=$_googleMapsApiKey",
      ),
    );
    print('RESPONSE on citizen map: ${response}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data.containsKey('routes') && data['routes'].isNotEmpty) {
        List<List<LatLng>> allRoutes = [];

        for (var routeData in data['routes']) {
          final route = routeData['overview_polyline']['points'];

          final decoder = PolylinePoints();
          List<PointLatLng> decodedPoints = decoder.decodePolyline(route);

          List<LatLng> points = decodedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          allRoutes.add(points);
        }

        return allRoutes;
      } else {
        throw Exception(
            "No routes found for the specified origin and destination.");
      }
    } else {
      throw Exception(
          "Failed to get directions with status code: ${response.statusCode}");
    }
  }

  Future<double> getRouteDistance(LatLng start, LatLng end) async {
    final apiKey = 'AIzaSyA5FX2TxXRsH8VoGbwwOdzNl1Igj_3YsAA';
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json?units=metric&origins=${start.latitude},${start.longitude}&destinations=${end.latitude},${end.longitude}&key=$apiKey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('DATA route distance: ${data}');
      final distance = data['rows'][0]['elements'][0]['distance']['value'];
      return distance / 1000; // Convert meters to kilometers
    } else {
      print('Failed to load distance');
      throw Exception('Failed to load distance');
    }
  }

  void clearRoute() {
    setState(() {
      polyLines.clear();
    });
  }

  void recalculateRoute() async {
    clearRoute();
    if (_currentDustbinPosition != null) {
      await showRouteToDustbin(_currentDustbinPosition!);
    }
  }

  void onCameraMove(CameraPosition position) {}

  Future<int> getRouteDuration(LatLng start, LatLng end, String mode) async {
    final apiKey = 'AIzaSyD79hEbrrlDT2ko8JSpUrjgzIv7PjAwSTk';
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&mode=$mode&key=$apiKey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final duration = data['routes'][0]['legs'][0]['duration']['value'];
      return duration ~/ 60; // Convert seconds to minutes
    } else {
      print('Failed to load duration');
      throw Exception('Failed to load duration');
    }
  }

  void _displayRoutes(
      List<List<LatLng>> drivingRoutes, List<List<LatLng>> walkingRoutes) {
    for (int i = 0; i < drivingRoutes.length; i++) {
      final List<LatLng> drivingRoutePoints = drivingRoutes[i];

      final Polyline drivingRoutePolyline = Polyline(
        polylineId: PolylineId("driving_route_to_dustbin_$i"),
        points: drivingRoutePoints,
        width: 5,
        color: Colors.green,
      );

      setState(() {
        polyLines.add(drivingRoutePolyline);
      });
    }

    for (int i = 0; i < walkingRoutes.length; i++) {
      final List<LatLng> walkingRoutePoints = walkingRoutes[i];

      final Polyline walkingRoutePolyline = Polyline(
        polylineId: PolylineId("walking_route_to_dustbin_$i"),
        points: walkingRoutePoints,
        width: 3,
        patterns: [PatternItem.dash(50.0), PatternItem.gap(10.0)],
        color: Colors.blue,
      );

      setState(() {
        polyLines.add(walkingRoutePolyline);
      });
    }
  }

  Future<Position> _getUserLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> showRouteToDustbin(LatLng dustbinPosition) async {
    setState(() {
      isLoadingRoute = true;
    });

    try {
      final Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.high,
      );

      LatLng origin =
          LatLng(currentPosition.latitude, currentPosition.longitude);

      mapController.animateCamera(CameraUpdate.newLatLng(origin));

      // Calculate route for driving mode
      final List<List<LatLng>> drivingRoutes = await getRoutePoints(
        "${origin.latitude},${origin.longitude}",
        "${dustbinPosition.latitude},${dustbinPosition.longitude}",
        travelModeDriving,
      );

      // Calculate route for walking mode
      final List<List<LatLng>> walkingRoutes = await getRoutePoints(
        "${origin.latitude},${origin.longitude}",
        "${dustbinPosition.latitude},${dustbinPosition.longitude}",
        travelModeWalking,
      );

      // Display polylines for both routes
      _displayRoutes(drivingRoutes, walkingRoutes);

      // Get distance and duration for driving mode
      final drivingDistance = await getRouteDistance(origin, dustbinPosition);
      final drivingDuration = await getRouteDuration(
        origin,
        dustbinPosition,
        travelModeDriving,
      );

      // Get distance and duration for walking mode
      final walkingDistance = await getRouteDistance(origin, dustbinPosition);
      final walkingDuration = await getRouteDuration(
        origin,
        dustbinPosition,
        travelModeWalking,
      );

      // Show dialog with route information
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Route Information"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    "Driving Distance: ${drivingDistance.toStringAsFixed(2)} km"),
                Text("Driving Duration: $drivingDuration minutes"),
                SizedBox(height: 10),
                Text(
                    "Walking Distance: ${walkingDistance.toStringAsFixed(2)} km"),
                Text("Walking Duration: $walkingDuration minutes"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          );
        },
      );

      // Update user's position when moving
      geolocator.Geolocator.getPositionStream().listen((Position newPosition) {
        setState(() {
          origin = LatLng(newPosition.latitude, newPosition.longitude);
        });

        mapController.animateCamera(CameraUpdate.newLatLng(origin));
      });
    } catch (e) {
      print('Error in showRouteToDustbin: $e');
    } finally {
      setState(() {
        isLoadingRoute = false;
      });
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    _controllerGoogleMap.complete(controller);

    await _loadMarkers();
    await _loadDustbins();
  }

  // Function to load dustbin icons
  Future<Map<String, Uint8List>> _loadDustbinIcons() async {
    final Uint8List greenIcon =
        await getBytesFromAsset('assets/images/greendustbin.png', 90);
    final Uint8List yellowIcon =
        await getBytesFromAsset('assets/images/yellowdustbin.png', 90);
    final Uint8List orangeIcon =
        await getBytesFromAsset('assets/images/orangedustbin.png', 90);
    final Uint8List redIcon =
        await getBytesFromAsset('assets/images/reddustbin.png', 90);

    return {
      "green": greenIcon,
      "yellow": yellowIcon,
      "orange": orangeIcon,
      "red": redIcon,
    };
  }

  Future<void> _loadMarkers() async {
    final Map<String, Uint8List> icons = await _loadDustbinIcons();

    await db.collection("data").snapshots().listen((event) {
      setState(() {
        _markers.clear();
        // highFillingLevelDustbins.clear(); // Clear previous list

        for (var doc in event.docs) {
          final position =
              LatLng(doc.data()["Latitude"], doc.data()["Longitude"]);
          final int percentage = doc.data()["percentage"];
          final Uint8List markerIcon;

          // Select the appropriate icon based on the percentage
          if (percentage <= 40) {
            markerIcon = icons["green"]!;
          } else if (percentage <= 60) {
            markerIcon = icons["yellow"]!;
          } else if (percentage < 90) {
            markerIcon = icons["orange"]!;
          } else {
            markerIcon = icons["red"]!;
            // highFillingLevelDustbins
            //     .add(position); // Add to the list if 90% or above
          }

          final marker = Marker(
            markerId: MarkerId(doc.id),
            position: position,
            infoWindow: InfoWindow(
              title:
                  "id : ${doc.data()["name"]}\n state: ${doc.data()["state"]}",
              snippet: "percentage : $percentage",
              onTap: () => showRouteToDustbin(position),
            ),
            icon: BitmapDescriptor.fromBytes(markerIcon),
          );

          _markers.add(marker);
        }

        // print("HIGHEST FILLED DUSTBINS :: $highFillingLevelDustbins");
      });
    });
  }

  @override
  void initState() {
    super.initState();
    checkIfLocationPermissionAllowed();
    _loadDustbins();
    _listenToPositionStream();
  }

  void _listenToPositionStream() {
    Geolocator.getPositionStream().listen((Position newPosition) {
      LatLng newLatLng = LatLng(newPosition.latitude, newPosition.longitude);
      mapController.animateCamera(CameraUpdate.newLatLng(newLatLng));
    });
  }

  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(),
        drawer: Drawer(
          width: 255,
          child: FanSideDrawer(
            menuItems: [
              DrawerMenuItem(
                title: "Report",
                onMenuTapped: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportForm(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            SlidingSheet(
              margin: EdgeInsets.only(left: 4, right: 4),
              elevation: 8,
              cornerRadius: 16,
              snapSpec: const SnapSpec(
                snap: true,
                snappings: [0.05, 1.0],
                positioning: SnapPositioning.relativeToAvailableSpace,
              ),
              body: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(-6.76438766, 39.22930733),
                      zoom: 14.4746,
                    ),
                    markers: _markers,
                    polylines: polyLines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    compassEnabled: true,
                    mapToolbarEnabled: true,
                    zoomControlsEnabled: true,
                    zoomGesturesEnabled: true,
                    onCameraMove: onCameraMove,
                    onMapCreated: _onMapCreated,
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedSize(
                      curve: Curves.easeIn,
                      duration: const Duration(milliseconds: 120),
                      child: Container(
                        height: 120,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20),
                            topLeft: Radius.circular(20),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 18),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Visibility(
                                    visible: polyLines.isNotEmpty,
                                    child: ElevatedButton(
                                      child: const Text("Navigate"),
                                      onPressed: () async {
                                        await launchUrl(Uri.parse(
                                            'google.navigation:q=${latitutd},${longitude}&key=AIzaSyA5FX2TxXRsH8VoGbwwOdzNl1Igj_3YsAA'));
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.fromLTRB(
                                            10, 10, 10, 10),
                                        textStyle: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  ),
                                  Spacer(),
                                  Visibility(
                                    visible: polyLines.isNotEmpty,
                                    child: ElevatedButton(
                                      child: const Text("Cancel route"),
                                      onPressed: clearRoute,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.fromLTRB(
                                            20, 10, 20, 10),
                                        textStyle: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              builder: (context, state) {
                return Container(
                  height: 400,
                  child: FutureBuilder<Position>(
                    future: Geolocator.getCurrentPosition(
                      desiredAccuracy: geolocator.LocationAccuracy.high,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text("Error retrieving location"));
                      } else if (!snapshot.hasData) {
                        return Center(
                            child: Text("Location data not available"));
                      } else {
                        Position userPosition = snapshot.data!;
                        return ListView.builder(
                          itemCount: _dustbins.length,
                          itemBuilder: (context, index) {
                            var dustbin = _dustbins[index];
                            final data = dustbin.data() as Map<String, dynamic>;
                            print("DATA  :: $data");
                            print("DUSTBIN  :: $dustbin");

                            IconData iconData;
                            Color iconColor;

                            Color textColor;
                            Color buttonColor;

                            // Determine text color and button color based on percentage

                            String imageAsset;
                            if (dustbin['percentage'] <= 30) {
                              textColor = Colors.green; // Green
                              iconData = Icons.delete;
                              iconColor = Colors.green;
                              imageAsset = 'assets/images/greendustbin.png';
                            } else if (dustbin['percentage'] > 30 &&
                                dustbin['percentage'] <= 50) {
                              iconData = Icons.delete;
                              iconColor = Colors.yellow;
                              textColor = Colors.yellow; // Yellow

                              imageAsset = 'assets/images/yellowdustbin.png';
                            } else if (dustbin['percentage'] > 50 &&
                                dustbin['percentage'] <= 80) {
                              iconData = Icons.delete;
                              iconColor = Colors.orange;
                              textColor = Colors.orange; // Orange

                              imageAsset = 'assets/images/orangedustbin.png';
                            } else {
                              textColor = Colors.red; // Red
                              iconData = Icons.delete;
                              iconColor = Colors.red;
                              imageAsset = 'assets/images/reddustbin.png';
                            }
                            double distance = Geolocator.distanceBetween(
                              userPosition.latitude,
                              userPosition.longitude,
                              data["Latitude"] ?? 0.0,
                              data["Longitude"] ?? 0.0,
                            );

                            // Calculate the route distance using getRouteDistance
                            Future<double> distanceFuture = getRouteDistance(
                              LatLng(userPosition.latitude,
                                  userPosition.longitude),
                              LatLng(data["Latitude"], data["Longitude"]),
                            );

                            return ListTile(
                              onLongPress: () {
                                // showAsBottomSheet(context, dustbin);
                              },
                              title: Row(
                                children: [
                                  Text(
                                    ' ${data["name"] ?? "N/A"}',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Spacer(),

                                  SizedBox(width: 8),
                                  Icon(iconData,
                                      color: iconColor) // Large dustbin icon
                                ],
                              ),
                              subtitle: data['state'] != null
                                  ? Text(
                                      'Status: ${data['state']}',
                                      style: TextStyle(color: Colors.grey),
                                    )
                                  : Text("null"),
                              onTap: () {
                                // Handle tap on a dustbin
                                // For example, show route to this dustbin
                              },
                              leading: InkWell(
                                onTap: () {
                                  showAsBottomSheet(context, dustbin, distance);
                                  // DriversMap.showAsBottomSheet(
                                  //     context, dustbin);
                                },
                                child: Column(
                                  children: [
                                    Text(
                                        '${(distance / 1000).toStringAsFixed(2)}',
                                        style: TextStyle(
                                            color: iconColor, fontSize: 24)),
                                    Text("Km",
                                        style: TextStyle(
                                            color: iconColor, fontSize: 12))
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                );
              },
              headerBuilder: (context, state) {
                return Container(
                  height: 50,
                  width: double.infinity,
                  color: Colors.green,
                  alignment: Alignment.center,
                  child: Text(
                    'Nearby Dustbins',
                    style: TextStyle(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadDustbins() async {
    try {
      // Get the user's current position
      Position userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.high,
      );
      final LatLng userLatLng =
          LatLng(userPosition.latitude, userPosition.longitude);

      final QuerySnapshot dustbinsSnapshot =
          await FirebaseFirestore.instance.collection('data').get();

      // Retrieve the dustbin documents
      _dustbins = dustbinsSnapshot.docs;

      // Calculate route distance for each dustbin
      List<Future<Map<String, dynamic>>> distanceFutures =
          _dustbins.map((dustbin) async {
        final data = dustbin.data() as Map<String, dynamic>?;

        if (data == null) {
          print("Error: Dustbin data is null");
          return {
            "dustbin": dustbin,
            "distance":
                double.infinity, // Assign a large distance if data is null
          };
        }

        final double? latitude = data["Latitude"] as double?;
        final double? longitude = data["Longitude"] as double?;

        if (latitude == null || longitude == null) {
          print(
              "Error: Latitude or Longitude is null for dustbin: ${dustbin.id}");
          return {
            "dustbin": dustbin,
            "distance": double
                .infinity, // Assign a large distance if coordinates are null
          };
        }

        final LatLng dustbinPosition = LatLng(latitude, longitude);
        double routeDistance =
            await getRouteDistance(userLatLng, dustbinPosition);
        print("dustbin: $dustbin, distance: $routeDistance");
        return {"dustbin": dustbin, "distance": routeDistance};
      }).toList();

      // Wait for all distances to be calculated
      List<Map<String, dynamic>> distances = await Future.wait(distanceFutures);

      // Sort distances in ascending order
      distances.sort((a, b) =>
          (a["distance"] as double).compareTo(b["distance"] as double));

      setState(() {
        // Update _dustbins with sorted order
        _dustbins =
            distances.map((e) => e["dustbin"] as DocumentSnapshot).toList();
        print("Sorted DUSTBINS LIST :: ${_dustbins}");
      });
    } catch (e) {
      print("Error loading dustbins: $e");
    }
  }

  void showAsBottomSheet(BuildContext context, dustbin, distance) async {
    final result = await showSlidingBottomSheet(context, builder: (context) {
      return SlidingSheetDialog(
        elevation: 8,
        cornerRadius: 16,
        snapSpec: SnapSpec(
          snap: true,
          snappings: [0.4, 0.7, 1.0],
          positioning: SnapPositioning.relativeToAvailableSpace,
        ),
        builder: (context, state) {
          final int percentage = dustbin['percentage'];

          Color textColor;
          Color buttonColor;

          // Determine text color and button color based on percentage

          String imageAsset;
          if (dustbin['percentage'] <= 30) {
            textColor = Colors.green; // Green

            imageAsset = 'assets/images/greendustbin.png';
          } else if (dustbin['percentage'] > 30 &&
              dustbin['percentage'] <= 50) {
            textColor = Colors.yellow; // Yellow

            imageAsset = 'assets/images/yellowdustbin.png';
          } else if (dustbin['percentage'] > 50 &&
              dustbin['percentage'] <= 80) {
            textColor = Colors.orange; // Orange

            imageAsset = 'assets/images/orangedustbin.png';
          } else {
            textColor = Colors.red; // Red
            imageAsset = 'assets/images/reddustbin.png';
          }

          return Container(
            height: 500,
            padding: EdgeInsets.all(16),
            color: Colors.white, // Adjust as needed
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dustbin['state']}',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      decoration: TextDecoration.none),
                ),
                SizedBox(height: 16),
                Center(
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(imageAsset),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    '${dustbin['name']}',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        decoration: TextDecoration.none),
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        // '${dustbin['percentage']}%',
                        '${(distance / 1000).toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            decoration: TextDecoration.none),
                      ),
                      SizedBox(
                        width: 4,
                      ),
                      Text(
                        "km",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            decoration: TextDecoration.none),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // Generate route to this dustbin
                      // Call the function to generate the route here
                      showRouteToDustbin(
                        LatLng(dustbin['Latitude'], dustbin['Longitude']),
                      );

                      setState(() {
                        latitutd = dustbin['Latitude'];
                        longitude = dustbin['Longitude'];
                      });
                      Navigator.pop(context);
                    },
                    style: ButtonStyle(
                      maximumSize: MaterialStatePropertyAll(Size(240, 80)),
                      minimumSize: MaterialStatePropertyAll(Size(200, 60)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Generate Route', style: TextStyle(fontSize: 16)),
                        Icon(Icons.directions, size: 32)
                      ],
                    ),
                  ),
                ),
                // SizedBox(height: 16),
                // Center(
                //   child: ElevatedButton(
                //     onPressed: () async {
                //       // Generate route to this dustbin
                //       // Call the function to generate the route here
                //       Position userPosition = await _getUserLocation();

                //       await launchUrl(Uri.parse(
                //           'google.navigation:q=${dustbin['Latitude']},${dustbin['Longitude']}&key=AIzaSyA5FX2TxXRsH8VoGbwwOdzNl1Igj_3YsAA'));

                //       Navigator.pop(context);
                //     },
                //     style: ButtonStyle(
                //       maximumSize: MaterialStatePropertyAll(Size(240, 80)),
                //       minimumSize: MaterialStatePropertyAll(Size(200, 60)),
                //     ),
                //     child: Row(
                //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //       children: [
                //         Text('Generate Direction',
                //             style: TextStyle(fontSize: 16)),
                //         Icon(Icons.directions, size: 32)
                //       ],
                //     ),
                //   ),
                // ),
              ],
            ),
          );
        },
      );
    });

    print("RESULT :: $result"); // This is the result.
  }
}
