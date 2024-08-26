// import 'dart:html';
import 'dart:async';
// import 'dart:html';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:SGMCS/views/screens/maps/driversMap2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:location/location.dart';
import 'package:location/location.dart' as loc;
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ORServices extends StatefulWidget {
  const ORServices({super.key});

  @override
  State<ORServices> createState() => _ORServicesState();
}

class _ORServicesState extends State<ORServices> {
  late GoogleMapController mapController;

  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;

  final List<LatLng> polyPoints = [];
  final List<LatLng> polyPoints1 = []; // For holding Co-ordinates as LatLng
  final List<LatLng> polyPoints2 = [];
  // For holding Co-ordinates as LatLng
  final Set<Polyline> polyLines = {};
  final Set<Polyline> polyLines1 = {}; // For holding instance of Polyline
  final Set<Polyline> polyLines2 = {}; // For holding instance of Polyline

  var data, data1, data2;

  final Set<Marker> markers = {}; // For holding instance of Marker
  //! firestore marker bin/
  var marker = <Marker>[];
  Set<Marker> _markers = {};
  late BitmapDescriptor pinLocationIcon;

  late BitmapDescriptor customIcon;

// make sure to initialize before map loading
  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();

    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

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
    geolocator.Position cPosition =
        await geolocator.Geolocator.getCurrentPosition(
            desiredAccuracy: geolocator.LocationAccuracy.high);
    userCurrentPosition = cPosition;

    LatLng latLngPosition =
        LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);

    CameraPosition cameraPosition =
        CameraPosition(target: latLngPosition, zoom: 14);

    newGoogleMapController!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    // geolocator.Geolocator.getPositionStream().listen((position) {
    //   userCurrentPosition = position;

    //   // Update the user's location in Firebase
    //   updateFirebaseUserLocation(position.latitude, position.longitude);

    //   LatLng updatedPosition = LatLng(position.latitude, position.longitude);
    //   newGoogleMapController!
    //       .animateCamera(CameraUpdate.newLatLng(updatedPosition));
    // });
  }

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
  //       'timestamp':
  //           FieldValue.serverTimestamp(), // optional: store a timestamp
  //     });

  //     print("User position updated in Firestore.");
  //   } else {
  //     print("No user is currently logged in.");
  //   }
  // }
  // void updateFirebaseUserLocation(double latitude, double longitude) {
  //   FirebaseFirestore.instance
  //       .collection("Chauffeurs")
  //       .doc(currentFirebaseUser!.uid)// Replace with the actual user ID
  //       .set({
  //     "latitude": latitude,
  //     "longitude": longitude,
  //     "timestamp": FieldValue.serverTimestamp(),
  //   }, SetOptions(merge: true));
  // }

  void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;

    // ----less than 40------------------
    // almosts enpty

    final Uint8List markerIcon =
        await getBytesFromAsset('assets/images/greendustbin.png', 50);

    await FirebaseFirestore.instance
        .collection("data")
        .where(
          "percentage",
          isLessThanOrEqualTo: 60,
        )
        .where("state")
        .snapshots()
        .listen((event) {
      setState(() {
        bottomPaddingOfMap = 240;
        for (var doc in event.docs) {
          print(doc);
          print(event.docs);

          _markers.add(
            Marker(
                markerId: MarkerId(doc.id),
                position:
                    LatLng(doc.data()["Latitude"], doc.data()["Longitude"]),
                infoWindow: InfoWindow(
                    onTap: () {
                      print("tApped");
                    },
                    title:
                        "id : ${doc.data()["name"]}\n state: ${doc.data()["state"]}",
                    snippet: "percentage : ${doc.data()["percentage"]}"),
                icon: BitmapDescriptor.fromBytes(markerIcon)),
          );
        }
      });
    });

    // marker for full dustbin

    final Uint8List markerIcon1 =
        await getBytesFromAsset('assets/images/reddustbin.png', 50);

    _controllerGoogleMap.complete(controller);
    newGoogleMapController = controller;
    await FirebaseFirestore.instance
        .collection("data")
        .where("percentage", isGreaterThan: 85)
        .snapshots()
        .listen((event) async {
      //_markers={};
      setState(() {
        bottomPaddingOfMap = 240;

        for (var doc in event.docs) {
          // print(doc.toString());
          // print(event.docs);
          _markers.add(
            Marker(
                markerId: MarkerId(doc.id),
                position:
                    LatLng(doc.data()["Latitude"], doc.data()["Longitude"]),
                infoWindow: InfoWindow(
                  anchor: Offset.zero,
                  onTap: () {
                    print("Tapped");
                  },
                  title:
                      " Id : ${doc.data()["name"]} \n State : ${doc.data()["state"]}",
                  snippet: "percentage : ${doc.data()["percentage"]} ",
                ),
                icon: BitmapDescriptor.fromBytes(markerIcon1)),
          );
          print(_markers);
          print(event.docs);
        }
      });
// -------------------TRYING TO DRAW POLYLINES
      String url =
          'https://api.openrouteservice.org/v2/directions/driving-car/geojson';
      String apiKey =
          // '5b3ce3597851110001cf62488a373729f5fe478ea1289b683c304eaa';
          '${dotenv.env['openRouteApiKey']}';

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

      print("point with current location");
      print(points);
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

        print(obj);
        distList.add(obj);
        print(distList);
        // points.add([distance, latitude, longitude, element.get("name")]);
      }
      // Sort the distList by the dist key in ascending order then printing the sorted list
      distList.sort((a, b) => a["distance"].compareTo(b["distance"]));
      print("________SORTED");
      print(distList);

// Loop through the distList and add the points to the points list
      for (var obj in distList) {
        // Get the point from the map
        List<dynamic> point = obj["point"];
        print("______POINt");
        print(point);
        // Add the point to the points list
        points.add(point.cast<double>());

        print("-----final result-----");
        print(points);
      }

// ---------------OLD VERSION---------------
      print(points);
      // print("***------------------******");
      var body = json.encode({
        "coordinates": points,
        "radiuses": [10000]
      });
      print("-------body--------");
      print(body);
      print(url);

      Response response = await http.post(Uri.parse(url), body: body, headers: {
        "Content-Type": "application/json",
        "Authorization": apiKey
      });
      print('-------RESPONSE CONTENT---------');
      print(
          "headers: ${response.headers} \n body: ${response.body} \n request: ${response.request}");
      print("------------RESPONSE-------");
      print(response.statusCode);
      setState(() {
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
    setState(() {});
    locateUserPosition();
    // updateCurrentPosition();
  }

  final Set<Marker> _marker = Set<Marker>();
  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
//////!
  double searchLocationContainerHeight = 220;
  double bottomPaddingOfMap = 0;

//! current location
  late PolylinePoints polylinePoints;

  late StreamSubscription<LocationData> subscription;

  LocationData? currentLocation;
  late LocationData destinationLocation;
  late LocationData destination;

  // late Location location;
  Completer<GoogleMapController> _controller = Completer();

  void updatePinsOnMap() async {
    CameraPosition cameraPosition = CameraPosition(
      zoom: 20,
      tilt: 80,
      bearing: 30,
      target: LatLng(
          currentLocation!.latitude ?? 0.0, currentLocation!.longitude ?? 0.0),
    );

    final GoogleMapController controller = await _controller.future;

    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    var sourcePosition = LatLng(
        currentLocation!.latitude ?? 0.0, currentLocation!.longitude ?? 0.0);

    setState(() {
      _marker.removeWhere((marker) => marker.mapsId.value == 'sourcePosition');

      _marker.add(Marker(
        markerId: const MarkerId('sourcePosition'),
        position: sourcePosition,
      ));
    });
  }

  // double bottomPaddingOfMap = 0;
  // @override
  // void initState() {
  //   // _onMapCreated(controller);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: sKey,
      // drawer: Container(
      //   width: 265,
      //   child: Theme(
      //     data: Theme.of(context).copyWith(
      //       canvasColor: Colors.black,
      //     ),
      //     child: MyDrawer(),
      //   ),
      // ),
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => DriversMap()));
            },
            icon: Icon(Icons.arrow_back)),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
            onMapCreated: _onMapCreated,
            markers: _markers,

            mapType: MapType.normal,
            myLocationEnabled: true,
            // zoomGesturesEnabled: true,
            // zoomControlsEnabled: true,
            initialCameraPosition: const CameraPosition(
              target: LatLng(-6.76438766, 39.22930733),
              zoom: 14,
            ),
            polylines: polyLines,
          ),

          //custom hamburger button for drawer
          Positioned(
            top: 20,
            left: 20,
            child: GestureDetector(
              onTap: () {
                sKey.currentState!.openDrawer();
              },
              child: const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(
                  Icons.menu,
                  color: Color.fromARGB(136, 0, 0, 0),
                ),
              ),
            ),
          ),

          //ui for searching location
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedSize(
              curve: Curves.easeIn,
              duration: const Duration(milliseconds: 120),
              child: Container(
                height: 120,
                decoration: const BoxDecoration(
                  color: ui.Color.fromARGB(221, 81, 81, 81),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    topLeft: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ElevatedButton(
                            child: const Text(
                              " Refresh ",
                            ),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ORServices()));
                            },
                            style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                // primary: Colors.green,
                                backgroundColor: Colors.green,
                                textStyle: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.w900)),
                          ),
                          Spacer(),
                          // ElevatedButton(
                          //   child: const Text(
                          //     "Faults",
                          //   ),
                          //   onPressed: () {
                          //     // Navigator.push(
                          //     //     context,
                          //     //     MaterialPageRoute(
                          //     //         builder: (context) => panne()));
                          //     Navigator.push(
                          //         context,
                          //         MaterialPageRoute(
                          //             builder: (context) => DustbinListPage()));
                          //   },
                          //   style: ElevatedButton.styleFrom(
                          //       padding:
                          //           const EdgeInsets.fromLTRB(20, 10, 20, 10),
                          //       primary: Colors.lightBlue,
                          //       textStyle: const TextStyle(
                          //           fontSize: 24, fontWeight: FontWeight.w900)),
                          // ),
                        ],
                      ),
                      // Row(
                      //   children: [
                      //     ElevatedButton(
                      //         onPressed: () async {
                      //           final QuerySnapshot<Map<String, dynamic>>
                      //               querySnapshot = await FirebaseFirestore
                      //                   .instance
                      //                   .collection("data")
                      //                   .get();
                      //           print("******MY CURRENT LOCATION******");

                      //           // Loop through the documents and access their data
                      //           for (var docSnapshot in querySnapshot.docs) {
                      //             final data = docSnapshot.data();
                      //             // Access specific fields like 'Latitude' and 'Longitude'
                      //             final lat = data['Latitude'];
                      //             final lon = data['Longitude'];
                      //             print('Latitude: $lat, Longitude: $lon');
                      //           }
                      //           print(userCurrentPosition!.latitude);
                      //           print(userCurrentPosition!.longitude);
                      //           print(currentLocation!.latitude);
                      //           print(currentLocation!.longitude);

                      //         },
                      //         child: Text("data"))
                      //   ],
                      // )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//Create a new class to hold the Co-ordinates we've received from the response data

class LineString {
  LineString(this.lineString);
  List<dynamic> lineString;
}
