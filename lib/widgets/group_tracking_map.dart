import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/realtime_tracking_service.dart';

class GroupTrackingMap extends StatefulWidget {
  final String groupId;
  final String userId;
  final String userName;

  const GroupTrackingMap({
    Key? key,
    required this.groupId,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<GroupTrackingMap> createState() => _GroupTrackingMapState();
}

class _GroupTrackingMapState extends State<GroupTrackingMap> {
  final RealtimeTrackingService _trackingService = RealtimeTrackingService();
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  Map<String, LatLng> _memberPositions = {};

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _startLocationUpdates();
    _listenToGroupLocations();
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_currentPosition!, 15.0);
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _startLocationUpdates() {
    Geolocator.getPositionStream().listen((Position position) {
      if (_currentPosition != null) {
        _trackingService.updateLocation(
          widget.groupId,
          widget.userId,
          position,
        );
      }
    });
  }

  void _listenToGroupLocations() {
    _trackingService.listenToGroupLocations(widget.groupId).listen((event) {
      if (event.snapshot.value != null) {
        final members = event.snapshot.value as Map<dynamic, dynamic>;
        final newPositions = <String, LatLng>{};

        members.forEach((key, value) {
          if (value['location'] != null) {
            final location = value['location'];
            newPositions[key.toString()] = LatLng(
              location['latitude'],
              location['longitude'],
            );
          }
        });

        setState(() {
          _memberPositions = newPositions;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(center: _currentPosition, zoom: 15.0),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.camp_go_frontend',
        ),
        MarkerLayer(
          markers: [
            // Marker cho vị trí hiện tại
            Marker(
              point: _currentPosition!,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_on,
                color: Colors.blue,
                size: 40,
              ),
            ),
            // Markers cho các thành viên khác
            ..._memberPositions.entries.map((entry) {
              return Marker(
                point: entry.value,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.person_pin_circle,
                  color: Colors.red,
                  size: 40,
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}
