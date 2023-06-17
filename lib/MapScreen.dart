import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:google_maps_webservice/places.dart';

const apiKey =
    'AIzaSyD-pqNULR3iJPOr_Ejphv3jRCpv22jwHH0'; // Reemplaza con tu clave de API de Google Maps

class MapScreen extends StatefulWidget {
  final PlaceDetails? data;

  const MapScreen({Key? key, required this.data}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Set<Polyline> _polyLines = {};
  late GoogleMapsServices _googleMapsServices;

  @override
  void initState() {
    super.initState();
    _googleMapsServices = GoogleMapsServices(apiKey);
  }

  @override
  Widget build(BuildContext context) {
    final LatLng markerPosition = LatLng(
      widget.data?.geometry?.location?.lat ?? 0.0,
      widget.data?.geometry?.location?.lng ?? 0.0,
    );

    final List<Branch> branches = [
      Branch(
        id: '1',
        name: 'Sucursal 1',
        latitude: 21.123,
        longitude: -101.689,
      ),
      Branch(
        id: '2',
        name: 'Sucursal 2',
        latitude: 21.120,
        longitude: -101.671,
      ),
      Branch(
        id: '3',
        name: 'Sucursal 3',
        latitude: 21.156,
        longitude: -101.684,
      ),
      Branch(
        id: '4',
        name: 'Sucursal 4',
        latitude: 21.161,
        longitude: -101.704,
      ),
      Branch(
        id: '5',
        name: 'Sucursal 5',
        latitude: 21.150,
        longitude: -101.675,
      ),
    ];

    final Set<Marker> markers = branches.map((branch) {
      return Marker(
        markerId: MarkerId(branch.id),
        position: LatLng(branch.latitude, branch.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        onTap: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Name: ${branch.name}'),
                    Text('Latitude: ${branch.latitude}'),
                    Text('Longitude: ${branch.longitude}'),
                  ],
                ),
              );
            },
          );
        },
      );
    }).toSet();

    final LatLng center = _calculateCenter(branches);
    final double radius = _calculateRadius(branches, center);

    final Circle circle = Circle(
      circleId: CircleId('enclosingCircle'),
      center: center,
      radius: radius,
      fillColor: Colors.blue.withOpacity(0.3),
      strokeColor: Colors.blue,
      strokeWidth: 2,
    );

    final Marker locationMarker = Marker(
      markerId: MarkerId('selectedLocation'),
      position: markerPosition,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Name: ${widget.data?.name ?? ""}'),
                  Text(
                      'Formatted Address: ${widget.data?.formattedAddress ?? ""}'),
                ],
              ),
            );
          },
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('MapScreen'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: markerPosition,
          zoom: 15,
        ),
        markers: {...markers, locationMarker},
        circles: {circle},
        polylines: _polyLines,
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(left: 25, bottom: 20),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: FloatingActionButton(
            onPressed: () {
              int estimatedTime = branches.length * 30 ~/ 60;
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Estimated Travel Time'),
                        Text('$estimatedTime hours'),
                      ],
                    ),
                  );
                },
              );
              sendRequest(markerPosition, branches);
            },
            child: Icon(Icons.directions),
          ),
        ),
      ),
    );
  }

  LatLng _calculateCenter(List<Branch> branches) {
    double sumLat = 0.0;
    double sumLng = 0.0;

    for (Branch branch in branches) {
      sumLat += branch.latitude;
      sumLng += branch.longitude;
    }

    final double avgLat = sumLat / branches.length;
    final double avgLng = sumLng / branches.length;

    return LatLng(avgLat, avgLng);
  }

  double _calculateRadius(List<Branch> branches, LatLng center) {
    double maxDistance = 0.0;

    for (Branch branch in branches) {
      final double distance = _distanceBetweenLatLng(
          center, LatLng(branch.latitude, branch.longitude));
      if (distance > maxDistance) {
        maxDistance = distance;
      }
    }

    return maxDistance;
  }

  void createFinalRoute(List<LatLng> routePoints) {
    setState(() {
      _polyLines.add(Polyline(
        polylineId: PolylineId('finalRoute'),
        width: 4,
        points: routePoints,
        color: Colors.red,
      ));
    });
  }

  double _distanceBetweenLatLng(LatLng latLng1, LatLng latLng2) {
    return mp.SphericalUtil.computeDistanceBetween(
      mp.LatLng(latLng1.latitude, latLng1.longitude),
      mp.LatLng(latLng2.latitude, latLng2.longitude),
    ).toDouble();
  }

  Future<void> sendFinalRouteRequest(LatLng source, LatLng destination) async {
    String encodedPolyline = await _googleMapsServices.getRouteCoordinates(
      source,
      destination,
    );
    List<LatLng> points = _convertToLatLng(_decodePoly(encodedPolyline));
    createFinalRoute(points);

    // Calculate and show estimated travel time
    int estimatedTime = calculateEstimatedTime(points.length);
  }

  int calculateEstimatedTime(int numberOfStops) {
    const int minutesPerStop = 30;
    return numberOfStops * minutesPerStop;
  }

  Future<void> sendRequest(LatLng source, List<Branch> branches) async {
    List<LatLng> routePoints = [];
    LatLng currentLocation = source;

    branches.sort((a, b) {
      double distanceA = _distanceBetweenLatLng(
          currentLocation, LatLng(a.latitude, a.longitude));
      double distanceB = _distanceBetweenLatLng(
          currentLocation, LatLng(b.latitude, b.longitude));
      return distanceA.compareTo(distanceB);
    });

    for (int i = 0; i < branches.length; i++) {
      Branch branch = branches[i];
      String encodedPolyline = await _googleMapsServices.getRouteCoordinates(
        currentLocation,
        LatLng(branch.latitude, branch.longitude),
      );
      List<LatLng> points = _convertToLatLng(_decodePoly(encodedPolyline));
      routePoints.addAll(points);
      currentLocation = LatLng(branch.latitude, branch.longitude);
    }
    sendFinalRouteRequest(
      LatLng(branches.last.latitude, branches.last.longitude),
      source,
    );

    createRoute(routePoints);
  }

  void createRoute(List<LatLng> routePoints) {
    setState(() {
      _polyLines.add(Polyline(
        polylineId: PolylineId('route'),
        width: 4,
        points: routePoints,
        color: Colors.green,
      ));
    });
  }

  List<LatLng> _convertToLatLng(List points) {
    List<LatLng> result = <LatLng>[];
    for (int i = 0; i < points.length; i++) {
      if (i % 2 != 0) {
        result.add(LatLng(points[i - 1], points[i]));
      }
    }
    return result;
  }

  List _decodePoly(String poly) {
    var list = poly.codeUnits;
    var lList = [];
    int index = 0;
    int len = poly.length;
    int c = 0;
    do {
      var shift = 0;
      int result = 0;
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);
      if (result & 1 == 1) {
        result = ~result;
      }
      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);
    for (var i = 2; i < lList.length; i++) lList[i] += lList[i - 2];
    return lList;
  }

  Branch _findNearestBranch(LatLng source, List<Branch> branches) {
    Branch nearestBranch = branches[0];
    double minDistance = _distanceBetweenLatLng(
        source, LatLng(nearestBranch.latitude, nearestBranch.longitude));

    for (int i = 1; i < branches.length; i++) {
      double distance = _distanceBetweenLatLng(
          source, LatLng(branches[i].latitude, branches[i].longitude));
      if (distance < minDistance) {
        nearestBranch = branches[i];
        minDistance = distance;
      }
    }

    return nearestBranch;
  }
}

class GoogleMapsServices {
  final String apiKey;

  GoogleMapsServices(this.apiKey);

  Future<String> getRouteCoordinates(LatLng l1, LatLng l2) async {
    String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${l1.latitude},${l1.longitude}&destination=${l2.latitude},${l2.longitude}&key=$apiKey";
    http.Response response = await http.get(Uri.parse(url));
    Map values = jsonDecode(response.body);
    return values["routes"][0]["overview_polyline"]["points"];
  }
}

class Geometry {
  final Location? location;

  Geometry({this.location});

  factory Geometry.fromJson(Map<String, dynamic> json) {
    return Geometry(
      location: Location.fromJson(json['location']),
    );
  }
}

class Location {
  final double? lat;
  final double? lng;

  Location({this.lat, this.lng});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: json['lat'],
      lng: json['lng'],
    );
  }
}

class Branch {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  Branch({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}
