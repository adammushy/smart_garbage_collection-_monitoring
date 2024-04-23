// ignore_for_file: unused_import, prefer_const_constructors

import 'dart:convert';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project_template/providers/data-provider.dart';
import 'package:flutter_project_template/views/screens/forms/report-form.dart';
import 'dart:async';
import 'dart:convert';
import 'package:open_route_service/open_route_service.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:provider/provider.dart';

class CitizenMap extends StatefulWidget {
  const CitizenMap({super.key});

  @override
  State<CitizenMap> createState() => _CitizenMapState();
}

// class _CitizenMapState extends State<CitizenMap> {
//   late GoogleMapController mapController;
//   final Completer<GoogleMapController> _controllerGoogleMap = Completer();
//   GoogleMapController? newGoogleMapCotroller;

//   final Set<Marker> _markers = {};
//   BitmapDescriptor? greenDustbinIcon;
//   BitmapDescriptor? yellowDustbinIcon;
//   BitmapDescriptor? redDustbinIcon;

//   // Variables to hold user's current position
//   LatLng? _userPosition;
//   StreamSubscription? _locationSubscription;

//   @override
//   void initState() {
//     super.initState();
//     _setupIcons();
//     _getCurrentLocation();
//   }

//   // Load custom marker icons
//   void _setupIcons() async {
//     final Uint8List greenIcon =
//         await _getBytesFromAsset('assets/images/greendustbin.png', 110);
//     final Uint8List yellowIcon =
//         await _getBytesFromAsset('assets/images/yellowdustbin.png', 110);
//     final Uint8List redIcon =
//         await _getBytesFromAsset('assets/images/reddustbin.png', 110);

//     greenDustbinIcon = BitmapDescriptor.fromBytes(greenIcon);
//     yellowDustbinIcon = BitmapDescriptor.fromBytes(yellowIcon);
//     redDustbinIcon = BitmapDescriptor.fromBytes(redIcon);
//   }

//   // Get bytes from asset
//   Future<Uint8List> _getBytesFromAsset(String path, int width) async {
//     final ByteData data = await rootBundle.load(path);
//     final ui.Codec codec = await ui
//         .instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
//     final ui.FrameInfo fi = await codec.getNextFrame();
//     return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
//         .buffer
//         .asUint8List();
//   }

//   // Get user's current location
//   Future<void> _getCurrentLocation() async {
//     _locationSubscription =
//         Geolocator.getPositionStream().listen((Position position) {
//       setState(() {
//         _userPosition = LatLng(position.latitude, position.longitude);
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _locationSubscription?.cancel();
//     super.dispose();
//   }

//   // Add marker to the map
//   Future<void> _addMarker(Map<String, dynamic> bin) async {
//     final double percentage = bin['percentage'];

//     BitmapDescriptor? icon;
//     if (percentage > 80) {
//       icon = redDustbinIcon;
//     } else if (percentage > 50) {
//       icon = yellowDustbinIcon;
//     } else {
//       icon = greenDustbinIcon;
//     }

//     if (icon != null) {
//       final Marker marker = Marker(
//         markerId: MarkerId(bin['id'].toString()),
//         position: LatLng(bin['lat'], bin['lon']),
//         infoWindow: InfoWindow(
//           title: "${bin['name']} \n State: ${bin['status']}",
//           snippet: "Percentage: ${bin['percentage']}%",
//         ),
//         icon: icon,
//       );

//       setState(() {
//         _markers.add(marker);
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GoogleMap(
//       markers: Set<Marker>.from(_markers),
//       initialCameraPosition: CameraPosition(
//         target: _userPosition ??
//             LatLng(0, 0), // Center the map on user's position if available
//         zoom: 10,
//       ),
//       onMapCreated: (GoogleMapController controller) {
//         _controllerGoogleMap.complete(controller);
//       },
//       onTap: (LatLng position) {
//         // Clear markers when map is tapped
//         setState(() {
//           _markers.clear();
//         });
//       },
//     );
//   }
// }

class _CitizenMapState extends State<CitizenMap> {
  late GoogleMapController mapController;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapCotroller;

  final Set<Marker> _markers = {};
  BitmapDescriptor? greenDustbinIcon;
  BitmapDescriptor? yellowDustbinIcon;
  BitmapDescriptor? redDustbinIcon;

  // Variables to hold user's current position
  LatLng? _userPosition;
  StreamSubscription? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _setupIcons();
    _getCurrentLocation();
    _fetchData(); // Fetch data when the widget is initialized
    _listenForDataChanges(); // Listen for real-time data changes
  }

  // Load custom marker icons
  void _setupIcons() async {
    final Uint8List greenIcon =
        await _getBytesFromAsset('assets/images/greendustbin.png', 110);
    final Uint8List yellowIcon =
        await _getBytesFromAsset('assets/images/yellowdustbin.png', 110);
    final Uint8List redIcon =
        await _getBytesFromAsset('assets/images/reddustbin.png', 110);

    greenDustbinIcon = BitmapDescriptor.fromBytes(greenIcon);
    yellowDustbinIcon = BitmapDescriptor.fromBytes(yellowIcon);
    redDustbinIcon = BitmapDescriptor.fromBytes(redIcon);
  }

  // Fetch data from the provider
  void _fetchData() {
    final provider =
        Provider.of<DataManagementProvider>(context, listen: false);
    print("provider ::: $provider");
    try {
      provider.fetchDustbins().then((success) {
        if (success) {
          print('SUCCESS fetch data');

          // Data fetched successfully, add markers based on the data
          for (var bin in provider.data) {
            print("BIN :: $bin");
            _addMarker(bin);
          }
        } else {
          // Failed to fetch data, handle accordingly
          print('Failed to fetch data');
        }
      });
    } catch (e) {
      print("Errors :: ${e.toString()}");
    }
  }

// Listen for real-time data changes
  void _listenForDataChanges() {
    final provider =
        Provider.of<DataManagementProvider>(context, listen: false);
    provider.addListener(() {
      // Handle data changes here
      _updateMarkers(provider.data.cast<Map<String, dynamic>>());
    });
  }

  // Update markers when data changes
  void _updateMarkers(List<Map<String, dynamic>> data) {
    setState(() {
      _markers.clear();
      for (var bin in data) {
        _addMarker(bin);
      }
    });
  }

  // Get bytes from asset
  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    final ByteData data = await rootBundle.load(path);
    final ui.Codec codec = await ui
        .instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    final ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  // Get user's current location
  Future<void> _getCurrentLocation() async {
    _locationSubscription =
        Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        _userPosition = LatLng(position.latitude, position.longitude);
      });
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  // Add marker to the map
  Future<void> _addMarker(Map<String, dynamic> bin) async {
    final double percentage = double.parse(bin['percentage']);

    BitmapDescriptor? icon;
    if (percentage > 80) {
      icon = redDustbinIcon;
    } else if (percentage > 50) {
      icon = yellowDustbinIcon;
    } else {
      icon = greenDustbinIcon;
    }

    if (icon != null) {
      final Marker marker = Marker(
        markerId: MarkerId(bin['id'].toString()),
        position: LatLng(bin['lat'], bin['lon']),
        infoWindow: InfoWindow(
          title: "${bin['name']} \n State: ${bin['status']}",
          snippet: "Percentage: ${bin['percentage']}%",
        ),
        icon: icon,
        onTap: () {
          _showMarkerInfo(bin);
        },
      );

      setState(() {
        _markers.add(marker);
      });
      print("marker :: ${_markers}");
    }
  }

  // Show marker information in an alert dialog
  Future<void> _showMarkerInfo(Map<String, dynamic> bin) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Dustbin Information"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Name: ${bin['name']}"),
              Text("State: ${bin['status']}"),
              Text("Percentage: ${bin['percentage']}%"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
            TextButton(
              onPressed: () {
                _generateRoute(bin);
              },
              child: Text('Directions'),
            ),
          ],
        );
      },
    );
  }

  // Generate route from user's current position to the selected dustbin
  void _generateRoute(Map<String, dynamic> bin) {
    // Implement route generation logic here
    // You can use packages like flutter_polyline_points to draw polylines on the map
    // Calculate the route using the user's position and the dustbin's position
    // Display the route on the map
  }
  void handleMenuItemSelected(BuildContext context, String value) {
    switch (value) {
      case 'terms_privacy':
        // Navigator.push(
        //     context,
        //     MaterialPageRoute(
        //       builder: (context) => TermsAndPrivacyPage(),
        //     ));
        break;
      case 'invite_friends':
        break;
      case 'logout':
        // normalEmergingShowDialogWithNoGif();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      GoogleMap(
        markers: Set<Marker>.from(_markers),
        initialCameraPosition: CameraPosition(
          target: _userPosition ??
              LatLng(0, 0), // Center the map on user's position if available
          zoom: 10,
        ),
        onMapCreated: (GoogleMapController controller) {
          _controllerGoogleMap.complete(controller);
        },
        myLocationEnabled: true,
        onTap: (LatLng position) {
          // Clear markers when map is tapped
          setState(() {
            _markers.clear();
          });
        },
      ),
      Positioned(
        top: 16,
        right: 16,
        child: FloatingActionButton(
          onPressed: () {
            // Navigate to the report screen when the button is pressed
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ReportForm()),
            );
          },
          child: Icon(Icons.add),
        ),
      ),
    ]);
  }
}

class LineString {
  LineString(this.lineString);
  List<dynamic> lineString;
}
