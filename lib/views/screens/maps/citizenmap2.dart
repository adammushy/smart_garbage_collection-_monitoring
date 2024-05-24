import 'dart:typed_data';
import 'dart:convert';

import 'package:SGMCS/views/screens/maps/driversMap2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:SGMCS/views/screens/drawer/custom_drawer.dart';
import 'package:SGMCS/views/screens/forms/report-form.dart';
import 'package:SGMCS/views/screens/maps/dustbindetails.dart';
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

  static const String _googleMapsApiKey =
      "AIzaSyD79hEbrrlDT2ko8JSpUrjgzIv7PjAwSTk";

  LocationPermission? _locationPermission;

  double drivingDistance = 0.0;
  int drivingDuration = 0;
  double walkingDistance = 0.0;
  int walkingDuration = 0;

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
    final apiKey = 'AIzaSyD79hEbrrlDT2ko8JSpUrjgzIv7PjAwSTk';
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json?units=metric&origins=${start.latitude},${start.longitude}&destinations=${end.latitude},${end.longitude}&key=$apiKey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
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

  // Future<void> showRouteToDustbin(LatLng dustbinPosition) async {
  //   setState(() {
  //     isLoadingRoute = true;
  //   });

  //   try {
  //     final Position currentPosition = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: geolocator.LocationAccuracy.high,
  //     );

  //     LatLng origin =
  //         LatLng(currentPosition.latitude, currentPosition.longitude);

  //     mapController.animateCamera(CameraUpdate.newLatLng(origin));

  //     final List<List<LatLng>> allRoutes = await getRoutePoints(
  //       "${origin.latitude},${origin.longitude}",
  //       "${dustbinPosition.latitude},${dustbinPosition.longitude}",
  //       "driving",
  //     );
  //     print("ROUTES ::: $allRoutes");

  //     for (int i = 0; i < allRoutes.length; i++) {
  //       final List<LatLng> routePoints = allRoutes[i];

  //       final Polyline routePolyline = Polyline(
  //         polylineId: PolylineId("route_to_dustbin_$i"),
  //         points: routePoints,
  //         width: i == 0 ? 5 : 2,
  //         color: i == 0 ? Colors.green : Colors.grey,
  //         patterns: i == 0 ? [] : [PatternItem.dot],
  //       );

  //       setState(() {
  //         polyLines.add(routePolyline);
  //       });
  //       print("ROUTES ::: $polyLines");
  //     }

  //     double distance = await getRouteDistance(origin, dustbinPosition);
  //     int drivingDuration =
  //         await getRouteDuration(origin, dustbinPosition, 'driving');
  //     int walkingDuration =
  //         await getRouteDuration(origin, dustbinPosition, 'walking');

  //     showDialog(
  //       context: context,
  //       builder: (context) {
  //         return AlertDialog(
  //           title: Text("Route Information"),
  //           content: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Text("Total Distance: ${distance.toStringAsFixed(2)} km"),
  //               Text("Estimated Driving Time: $drivingDuration minutes"),
  //               Text("Estimated Walking Time: $walkingDuration minutes"),
  //             ],
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context),
  //               child: Text("OK"),
  //             ),
  //           ],
  //         );
  //       },
  //     );

  //     geolocator.Geolocator.getPositionStream().listen((Position newPosition) {
  //       setState(() {
  //         origin = LatLng(newPosition.latitude, newPosition.longitude);
  //       });

  //       mapController.animateCamera(CameraUpdate.newLatLng(origin));
  //     });
  //   } catch (e) {
  //     print('Error in showRouteToDustbin: $e');
  //   } finally {
  //     setState(() {
  //       isLoadingRoute = false;
  //     });
  //   }
  // }
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

  Future<void> _loadMarkers() async {
    final Uint8List markerIcon =
        await getBytesFromAsset('assets/images/greendustbin.png', 90);

    await db
        .collection("data")
        .where("percentage", isLessThanOrEqualTo: 60)
        .where("state")
        .snapshots()
        .listen((event) {
      setState(() {
        _markers.clear();
        for (var doc in event.docs) {
          final position =
              LatLng(doc.data()["Latitude"], doc.data()["Longitude"]);
          final marker = Marker(
            markerId: MarkerId(doc.id),
            position: position,
            infoWindow: InfoWindow(
              title:
                  "id : ${doc.data()["name"]}\n state: ${doc.data()["state"]}",
              snippet: "percentage : ${doc.data()["percentage"]}",
              onTap: () => showRouteToDustbin(position),
            ),
            icon: BitmapDescriptor.fromBytes(markerIcon),
          );
          _markers.add(marker);
        }
      });
    });

    final Uint8List markerIconFull =
        await getBytesFromAsset('assets/images/reddustbin.png', 90);

    await db
        .collection("data")
        .where("percentage", isGreaterThan: 60)
        .snapshots()
        .listen((event) {
      setState(() {
        for (var doc in event.docs) {
          final position =
              LatLng(doc.data()["Latitude"], doc.data()["Longitude"]);
          final marker = Marker(
            markerId: MarkerId(doc.id),
            position: position,
            infoWindow: InfoWindow(
              title:
                  "id : ${doc.data()["name"]}\n state: ${doc.data()["state"]}",
              snippet: "percentage : ${doc.data()["percentage"]}",
              onTap: () => showRouteToDustbin(position),
            ),
            icon: BitmapDescriptor.fromBytes(markerIconFull),
          );
          _markers.add(marker);
        }
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
              )
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
                                  // showAsBottomSheet(context, dustbin);
                                  DriversMap.showAsBottomSheet(
                                      context, dustbin);
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
                    'This is the header',
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
}
