// ignore_for_file: prefer_const_constructors, prefer_final_fields, prefer_const_literals_to_create_immutables, unused_local_variable, sort_child_properties_last

import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:SGMCS/constants/app_constants.dart';
import 'package:SGMCS/shared-functions/snack_bar.dart';
import 'package:SGMCS/shared-preference-manager/preference-manager.dart';
import 'package:SGMCS/views/screens/auth/login_user.dart';
import 'package:SGMCS/views/screens/forms/breakdown-form.dart';
import 'package:SGMCS/views/screens/forms/driversreportlist.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:SGMCS/shared-functions/icon_maker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:wtf_sliding_sheet/wtf_sliding_sheet.dart';

import 'package:fan_side_drawer/fan_side_drawer.dart';

// import 'package:geocoder/geocoder.dart';
class DriversMap extends StatefulWidget {
  const DriversMap({super.key});

  @override
  State<DriversMap> createState() => _DriversMapState();

  static void showAsBottomSheet(
      BuildContext context, DocumentSnapshot<Object?> dustbin) {}
}

class _DriversMapState extends State<DriversMap> {
  late GoogleMapController mapController;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;
  final db = FirebaseFirestore.instance;
  bool isLoadingRoute = false;
  List<LatLng> highFillingLevelDustbins = [];
  final List<LatLng> polyPoints = [];
  final Set<Polyline> polyLines = {};
  final Set<Polyline> _polylines = {};
  final PolylinePoints _polylinePoints = PolylinePoints();
  Set<Marker> _markers = {};
  LatLng? _currentDustbinPosition;
  Position? userCurrentPosition;
  List<List<LatLng>> allroutespoints = [];

  // Define your API key
  static String _googleMapsApiKey = "AIzaSyA5FX2TxXRsH8VoGbwwOdzNl1Igj_3YsAA";
  // "${dotenv.env['googleApiKey']}"; // Replace with your actual API Key

  LocationPermission? _locationPermission;

  // distance and time api
  // State variables to store distance and duration
  double drivingDistance = 0.0; // Driving distance in meters
  int drivingDuration = 0; // diving time in secondsa
  double walkingDistance = 0.0; // walkn distance in meters
  int walkingDuration = 0; // waln time in seconds

  // Define travel mode options
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

  // Function to get route points from the Google Maps Directions API

  Future<List<List<LatLng>>> getRoutePoints(
      String origin, String destination, String mode) async {
    final response = await http.get(
      Uri.parse(
        "https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=$mode&key=$_googleMapsApiKey",
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Ensure the 'routes' list exists and contains at least one route
      if (data.containsKey('routes') && data['routes'].isNotEmpty) {
        List<List<LatLng>> allRoutes = [];

        // Iterate through each route
        for (var routeData in data['routes']) {
          final route = routeData['overview_polyline']['points'];

          // Decode the polyline
          final decoder = PolylinePoints();
          List<PointLatLng> decodedPoints = decoder.decodePolyline(route);

          // Convert List<PointLatLng> to List<LatLng>
          List<LatLng> points = decodedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          allRoutes.add(points);
          setState(() {
            allroutespoints.add(points);
          });
        }
        print("ALL ROUTES ${allRoutes}");
        print("NUMBER OF ROUTES ${allRoutes.length}");

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

  // Function to clear the current opened route
  void clearRoute() {
    setState(() {
      polyLines.clear();
    });
  }

  // Function to recalculate the route when the origin or destination changes
  void recalculateRoute() async {
    // Clear existing polylines
    clearRoute();

    // Recalculate the route if there's a dustbin position available
    if (_currentDustbinPosition != null) {
      await showRouteToDustbin(_currentDustbinPosition!);
    }
  }

// Function to handle camera movement events
  void onCameraMove(CameraPosition position) {
    // You can add logic here to adjust the camera based on the current polyline or markers
    // recalculateRoute();
  }

  Future<void> showRouteToDustbin(LatLng dustbinPosition) async {
    // Set isLoadingRoute to true to indicate that the route calculation process has started
    setState(() {
      isLoadingRoute = true;
    });

    try {
      // Get the user's current position
      final Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.high,
      );

      // Convert the current position to a LatLng
      LatLng origin =
          LatLng(currentPosition.latitude, currentPosition.longitude);

      // Move the camera to the user's current position
      mapController.animateCamera(CameraUpdate.newLatLng(origin));

      // Calculate the route points using the origin and destination
      final List<List<LatLng>> allRoutes = await getRoutePoints(
        "${origin.latitude},${origin.longitude}",
        "${dustbinPosition.latitude},${dustbinPosition.longitude}",
        "driving", // Specify travel mode here (e.g., "walking" or "bicycling")
      );

      // Iterate through each route and create polylines
      for (int i = 0; i < allRoutes.length; i++) {
        final List<LatLng> routePoints = allRoutes[i];

        // Create a polyline for the route
        final Polyline routePolyline = Polyline(
          polylineId: PolylineId("route_to_dustbin_$i"),
          points: routePoints,
          width: i == 0
              ? 5
              : 2, // Main route has thicker width, other routes have thinner width
          color: i == 0
              ? Colors.green
              : Colors.grey, // Main route is green, other routes are grey
          patterns:
              i == 0 ? [] : [PatternItem.dot], // Dotted line for other routes
        );

        // Update the state to add the polyline to the map
        setState(() {
          polyLines.add(routePolyline);
        });
      }

      // Subscribe to continuous location updates
      geolocator.Geolocator.getPositionStream().listen((Position newPosition) {
        // Update the user's current position
        setState(() {
          origin = LatLng(newPosition.latitude, newPosition.longitude);
        });

        // Move the camera to the updated position
        mapController.animateCamera(CameraUpdate.newLatLng(origin));
      });
    } catch (e) {
      print('Error in showRouteToDustbin: $e');
      ShowMToast(context).errorToast(
          message: "Error in showRouteToDustbin: $e",
          alignment: Alignment.center);
    } finally {
      // Set isLoadingRoute to false to indicate that the route calculation process is complete
      setState(() {
        isLoadingRoute = false;
      });
    }
  }

  Future<void> showRouteToHighFillingDustbins() async {
    if (highFillingLevelDustbins.isEmpty) {
      print("No dustbins with filling level 90% and above.");
      return;
    }

    setState(() {
      isLoadingRoute = true;
    });

    try {
      // Get the user's current position
      final Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.high,
      );

      // Convert the current position to a LatLng
      LatLng origin =
          LatLng(currentPosition.latitude, currentPosition.longitude);

      // Create a list of all destinations including the origin
      List<LatLng> allDestinations = [origin, ...highFillingLevelDustbins];

      // Iterate through each pair of consecutive points to calculate the route
      for (int i = 0; i < allDestinations.length - 1; i++) {
        final LatLng start = allDestinations[i];
        final LatLng end = allDestinations[i + 1];

        final List<List<LatLng>> routePoints = await getRoutePoints(
          "${start.latitude},${start.longitude}",
          "${end.latitude},${end.longitude}",
          "driving", // Specify travel mode here
        );

        // Create a polyline for each segment of the route
        for (int j = 0; j < routePoints.length; j++) {
          final List<LatLng> points = routePoints[j];

          final Polyline routePolyline = Polyline(
            polylineId: PolylineId("route_segment_$i _ $j"),
            points: points,
            width: j == 0 ? 5 : 2,
            color: j == 0 ? Colors.blue : Colors.grey,
            patterns: j == 0 ? [] : [PatternItem.dot],
          );

          setState(() {
            polyLines.add(routePolyline);
          });
        }
      }

      // Move the camera to the user's current position
      mapController.animateCamera(CameraUpdate.newLatLng(origin));
    } catch (e) {
      print('Error in showRouteToHighFillingDustbins: $e');
      ShowMToast(context).errorToast(
          message: "Error in showRouteToHighFillingDustbins: $e",
          alignment: Alignment.center);
    } finally {
      setState(() {
        isLoadingRoute = false;
      });
    }
  }

  double calculateDistance(LatLng p1, LatLng p2) {
    const double R = 6371000; // Radius of Earth in meters
    final double lat1 = p1.latitude * pi / 180;
    final double lat2 = p2.latitude * pi / 180;
    final double dLat = (p2.latitude - p1.latitude) * pi / 180;
    final double dLon = (p2.longitude - p1.longitude) * pi / 180;

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distance = R * c;

    return distance; // Distance in meters
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    _controllerGoogleMap.complete(controller);

    // Load markers from Firestore
    await _loadMarkers();
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
    final Uint8List errorIcon =
        await getBytesFromAsset('assets/images/dustbin_error.png', 90);

    return {
      "green": greenIcon,
      "yellow": yellowIcon,
      "orange": orangeIcon,
      "red": redIcon,
      "error": errorIcon,
    };
  }

  Future<void> _loadMarkers() async {
    final Map<String, Uint8List> icons = await _loadDustbinIcons();
    // Get the user's current position
    final Position currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: geolocator.LocationAccuracy.high,
    );

    LatLng userPosition =
        LatLng(currentPosition.latitude, currentPosition.longitude);
    await db.collection("data").snapshots().listen((event) {
      setState(() {
        _markers.clear();
        highFillingLevelDustbins.clear(); // Clear previous list

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
          } else if (percentage >= 90 && percentage <= 100) {
            markerIcon = icons["red"]!;
            highFillingLevelDustbins
                .add(position); // Add to the list if 90% or above

            // Sort the waypoints based on distance from the user's position
            highFillingLevelDustbins.sort((a, b) =>
                calculateDistance(userPosition, a)
                    .compareTo(calculateDistance(userPosition, b)));
          } else {
            markerIcon = icons["error"]!;
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

        print("HIGHEST FILLED DUSTBINS :: $highFillingLevelDustbins");
      });
    });
  }

  @override
  void initState() {
    super.initState();
    // _startPositionListener();
    checkIfLocationPermissionAllowed();
    _loadDustbins();
  }

  // Function to show the modal bottom sheet with a list of buttons
  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.my_location),
              title: Text('My Location'),
              onTap: () async {
                Navigator.pop(context); // Close the bottom sheet
                Position currentPosition = await Geolocator.getCurrentPosition(
                  desiredAccuracy: geolocator.LocationAccuracy.high,
                );
                LatLng userPosition =
                    LatLng(currentPosition.latitude, currentPosition.longitude);
                mapController?.animateCamera(
                  CameraUpdate.newLatLng(userPosition),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.directions),
              title: Text('Show Route'),
              onTap: () {
                showRouteToHighFillingDustbins();
                Navigator.pop(context); // Close the bottom sheet
                // Add functionality to show route here
              },
            ),
            ListTile(
              leading: Icon(Icons.clear),
              title: Text('Clear Map'),
              onTap: () {
                Navigator.pop(context); // Close the bottom sheet
                // Add functionality to clear map here
              },
            ),
            // Add more ListTiles for additional buttons
          ],
        );
      },
    );
  }

  // ),
  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // key: sKey,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
                onPressed: () {
                  showRouteToHighFillingDustbins();
                },
                icon: Icon(Icons.directions))
          ],
        ),
        drawer: Drawer(
          width: 255,
          child: FanSideDrawer(
            menuItems: [
              DrawerMenuItem(
                title: "Breakdown Report",
                onMenuTapped: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BreakDownForm(),
                    ),
                  );
                },
              ),
              DrawerMenuItem(
                title: "My Reports",
                icon: Icons.list,
                onMenuTapped: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportListScreen(),
                    ),
                  );
                },
              ),
              DrawerMenuItem(
                title: "Log Out",
                icon: Icons.logout,
                onMenuTapped: () {
                  SharedPreferencesManager()
                      .clearPreferenceByKey(AppConstants.isLogin);
                  SharedPreferencesManager()
                      .clearPreferenceByKey(AppConstants.user);
                  ;
                  Navigator.pop(context);

                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Login(),
                      ));
                },
              )
            ],
          ),
        ),
        body: Stack(children: [
          SlidingSheet(
            margin: EdgeInsets.only(left: 4, right: 4),
            elevation: 8,
            cornerRadius: 16,
            snapSpec: const SnapSpec(
              // Enable snapping. This is true by default.
              snap: true,
              // Set custom snapping points.
              snappings: [0.05, 1.0],
              // Define to what the snappings relate to. from the bottom to top
              // the total available space that the my bottomsheet can expand to.
              positioning: SnapPositioning.relativeToAvailableSpace,
            ),
            // The body widget will be displayed under the SlidingSheet
            // and a parallax effect can be applied to it.
            body: Stack(
              children: [
                GoogleMap(
                  myLocationEnabled:
                      true, // Disable the default my location button
                  myLocationButtonEnabled: false,
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(-6.76438766, 39.22930733),
                    zoom: 14,
                  ),
                  onMapCreated: _onMapCreated,
                  onCameraMove: onCameraMove,
                  markers: _markers,
                  polylines: polyLines,
                  indoorViewEnabled: true,
                ),
                Visibility(
                  visible: isLoadingRoute,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),

                // Custom "My Location" button
                Positioned(
                  bottom: 100,
                  right: 10,
                  // left: 20,
                  child: FloatingActionButton(
                    onPressed: () async {
                      _showOptions(context);
                    },
                    child: Icon(Icons.my_location),
                  ),
                ),
                Visibility(
                  visible: polyLines.isEmpty,
                  child: Positioned(
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
                                  ElevatedButton(
                                    child: const Text("Refresh"),
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => DriversMap()),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.fromLTRB(
                                          10, 10, 10, 10),
                                      textStyle: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900),
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
                ),
                Visibility(
                  visible: polyLines.isNotEmpty,
                  child: Positioned(
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
                                  ElevatedButton(
                                    child: const Text("Navigate"),
                                    onPressed: () async {
                                      // Constructing the Google Maps URL with waypoints
                                      String googleMapsUrl =
                                          'https://www.google.com/maps/dir/?api=1';

                                      List<LatLng> waypoints =
                                          highFillingLevelDustbins;
                                      print('WAYPOINTS: ${waypoints}');

                                      // Add the destination (last point)
                                      googleMapsUrl +=
                                          '&destination=${waypoints.last.latitude},${waypoints.last.longitude}';

                                      // Add waypoints (for points between start and end)
                                      if (waypoints.length > 1) {
                                        googleMapsUrl += '&waypoints=';
                                        for (int i = 1;
                                            i < waypoints.length - 1;
                                            i++) {
                                          googleMapsUrl +=
                                              '${waypoints[i].latitude},${waypoints[i].longitude}|';
                                        }
                                        googleMapsUrl = googleMapsUrl.substring(
                                            0,
                                            googleMapsUrl.length -
                                                1); // Remove last '|'
                                      }

                                      // Optional: Travel mode can be driving, walking, bicycling, etc.
                                      googleMapsUrl += '&travelmode=driving';

                                      // Log the final URL for debugging
                                      print('Google Maps URL: $googleMapsUrl');

                                      // Launch Google Maps with the constructed URL
                                      if (await canLaunchUrl(
                                          Uri.parse(googleMapsUrl))) {
                                        await launchUrl(
                                            Uri.parse(googleMapsUrl));
                                      } else {
                                        print(
                                            "Could not launch the Google Maps URL");
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.fromLTRB(
                                          10, 10, 10, 10),
                                      textStyle: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900),
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
                ),
                Positioned(
                    bottom: _isBottomSheetExpanded ? 20 : null,
                    // left: 0,
                    right: 20,
                    child: Container()),
              ],
            ),

            builder: (context, state) {
              // This is the content of the sheet that will get
              // scrolled, if the content is bigger than the available
              // height of the sheet.
              return Container(
                height: 400,
                child: ListView.builder(
                  itemCount: _dustbins.length,
                  itemBuilder: (context, index) {
                    final dustbin = _dustbins[index];

                    final DocumentSnapshot<Object?> dustbinSnapshot =
                        _dustbins[index];
                    final Map<String, dynamic> dustbinData =
                        dustbinSnapshot.data() as Map<String, dynamic>;

                    // Null check for _dustbins
                    if (dustbin != null) {
                      IconData iconData;
                      Color iconColor;

                      Color textColor;
                      Color buttonColor;

                      final Map<String, dynamic> dustbinData =
                          dustbin.data() as Map<String, dynamic>;

                      String imageAsset;

                      // Determine icon and color based on percentage
                      int percentage = dustbinData['percentage'];
                      if (percentage <= 30) {
                        iconData = Icons.delete;
                        iconColor = Colors.green;
                        imageAsset = 'assets/images/greendustbin.png';
                      } else if (percentage <= 50) {
                        iconData = Icons.delete;
                        iconColor = Colors.yellow;
                        imageAsset = 'assets/images/yellowdustbin.png';
                      } else if (percentage <= 80) {
                        iconData = Icons.delete;
                        iconColor = Colors.orange;
                        imageAsset = 'assets/images/orangedustbin.png';
                      } else {
                        iconData = Icons.delete;
                        iconColor = Colors.red;
                        imageAsset = 'assets/images/reddustbin.png';
                      }

                      // // Determine text color and button color based on percentage

                      // String imageAsset;
                      // if (dustbin['percentage'] <= 30) {
                      //   textColor = Colors.green; // Green
                      //   iconData = Icons.delete;
                      //   iconColor = Colors.green;
                      //   imageAsset = 'assets/images/greendustbin.png';
                      // } else if (dustbin['percentage'] > 30 &&
                      //     dustbin['percentage'] <= 50) {
                      //   iconData = Icons.delete;
                      //   iconColor = Colors.yellow;
                      //   textColor = Colors.yellow; // Yellow

                      //   imageAsset = 'assets/images/yellowdustbin.png';
                      // } else if (dustbin['percentage'] > 50 &&
                      //     dustbin['percentage'] <= 80) {
                      //   iconData = Icons.delete;
                      //   iconColor = Colors.orange;
                      //   textColor = Colors.orange; // Orange

                      //   imageAsset = 'assets/images/orangedustbin.png';
                      // } else {
                      //   textColor = Colors.red; // Red
                      //   iconData = Icons.delete;
                      //   iconColor = Colors.red;
                      //   imageAsset = 'assets/images/reddustbin.png';
                      // }
                      return ListTile(
                          onLongPress: () {
                            showAsBottomSheet(context, dustbin);
                          },
                          title: Row(
                            children: [
                              Text(
                                dustbin['name'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Spacer(),

                              SizedBox(width: 8),
                              Icon(iconData,
                                  color: iconColor) // Large dustbin icon
                            ],
                          ),
                          subtitle: dustbin['state'] != null
                              ? Text(
                                  'Status: ${dustbin['state']}',
                                  style: TextStyle(color: Colors.grey),
                                )
                              : Text("null"),
                          onTap: () {
                            // Handle tap on a dustbin
                            // For example, show route to this dustbin
                          },
                          leading: InkWell(
                            onTap: () {
                              showAsBottomSheet(context, dustbin);
                            },
                            child: Text('${dustbin['percentage']}%',
                                style:
                                    TextStyle(color: iconColor, fontSize: 24)),
                          ));
                    } else {
                      // Return a placeholder widget if _dustbins is null
                      return SizedBox(); // You can replace this with any widget you want
                    }
                  },
                ),
              );

              // child:Container() ,
            },
            headerBuilder: (context, state) {
              return Container(
                height: 50,
                width: double.infinity,
                color: Colors.green,
                alignment: Alignment.center,
                child: Text(
                  'Dustbin List',
                  style: TextStyle(),
                ),
              );
            },
          ),
        ]),
        // floatingActionButtonLocation: FloatingActionButtonLocation.,
        // floatingActionButton: IconButton(
        //     onPressed: () {
        //       // Navigator.push(context,
        //       //     MaterialPageRoute(builder: (context) => ORServices()));
        //       showRouteToHighFillingDustbins();
        //     },
        //     icon: Icon(Icons.directions)),
      ),
    );
  }

  Future<void> _loadDustbins() async {
    final QuerySnapshot dustbinsSnapshot =
        await FirebaseFirestore.instance.collection('data').get();

    setState(() {
      // Sort dustbins by percentage in descending order
      _dustbins = dustbinsSnapshot.docs;
      _dustbins.sort((a, b) => b['percentage'].compareTo(a['percentage']));

      print("DUSTBINS :: ${_dustbins}");
    });
  }

  void showAsBottomSheet(BuildContext context, dustbin) async {
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
                  child: Text(
                    '${dustbin['percentage']}%',
                    style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        decoration: TextDecoration.none),
                  ),
                ),
                // Text(
                //   '${dustbin['state'] ?? 'Unknown'}',
                //   style: TextStyle(fontSize: 18),
                // ),
                SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // Generate route to this dustbin
                      // Call the function to generate the route here
                      showRouteToDustbin(
                        LatLng(dustbin['Latitude'], dustbin['Longitude']),
                      );
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
              ],
            ),
          );
        },
      );
    });

    print("RESULT :: $result"); // This is the result.
  }
}

class LineString {
  LineString(this.lineString);
  List<dynamic> lineString;
}
