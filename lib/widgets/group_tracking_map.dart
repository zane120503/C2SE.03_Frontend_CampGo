import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/realtime_tracking_service.dart';
import 'package:CampGo/services/api_service.dart';
import 'package:CampGo/models/campsite.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

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
  final Map<String, String> _memberAvatars = {};
  final Map<String, bool> _fetchingAvatars = {};
  Timer? _debounceTimer;
  List<Campsite> _campsites = [];
  Campsite? _selectedCampsite;
  bool _showSpotDetails = false;
  List<LatLng> _routePoints = [];
  bool _isShowingRoute = false;
  bool _isNavigating = false;
  LatLng? _destinationPoint;
  double _remainingDistance = 0;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isShowingNavigationSheet = false;
  bool _showNavigationSheet = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _startLocationUpdates();
    _listenToGroupLocations();
    _loadCampsites();
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

  Future<void> _fetchAvatarUrl(String userId) async {
    // Kiểm tra nếu đang fetch hoặc đã có avatar thì bỏ qua
    if (_fetchingAvatars[userId] == true || _memberAvatars.containsKey(userId)) {
      return;
    }

    _fetchingAvatars[userId] = true;
    try {
      final response = await APIService.getUserProfileById(userId);
      if (mounted && response['success'] == true) {
        final userData = response['userData'];
        if (userData != null && userData['profileImage'] != null) {
          setState(() {
            _memberAvatars[userId] = userData['profileImage']['url'];
          });
        }
      }
    } catch (e) {
      print('Error fetching avatar for user $userId: $e');
    } finally {
      _fetchingAvatars[userId] = false;
    }
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

        // Debounce the avatar fetching
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            for (var userId in newPositions.keys) {
              _fetchAvatarUrl(userId);
            }
            _fetchAvatarUrl(widget.userId);
          }
        });

        if (mounted) {
          setState(() {
            _memberPositions = newPositions;
          });
        }
      }
    });
  }

  Future<void> _loadCampsites() async {
    try {
      final campsites = await APIService.getAllCampsites();
      setState(() {
        _campsites = campsites;
      });
    } catch (e) {
      print('Error loading campsites: $e');
    }
  }

  void moveToCurrentLocation() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 15.0);
    }
  }

  double _calculateRouteDistance(List<LatLng> points) {
    if (points.length < 2) return 0;
    double total = 0;
    final Distance distance = Distance();
    for (int i = 0; i < points.length - 1; i++) {
      total += distance.as(LengthUnit.Meter, points[i], points[i + 1]);
    }
    return total;
  }

  Future<void> _getDirections(LatLng destination) async {
    if (_currentPosition == null) return;
    try {
      final String baseUrl =
          'https://api.openrouteservice.org/v2/directions/driving-car';
      final String apiKey =
          '5b3ce3597851110001cf62482477b63bbe3b4be5943c784279c015e0';
      final response = await http.get(
        Uri.parse(
          '$baseUrl?api_key=$apiKey&start=${_currentPosition!.longitude},${_currentPosition!.latitude}&end=${destination.longitude},${destination.latitude}',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates =
            data['features'][0]['geometry']['coordinates'] as List;
        final points = coordinates.map<LatLng>((point) {
          return LatLng(point[1] as double, point[0] as double);
        }).toList();
        setState(() {
          _routePoints = points;
          _isShowingRoute = true;
          _remainingDistance = _calculateRouteDistance(points);
        });
      }
    } catch (e) {
      print('Error getting directions: $e');
    }
  }

  Future<void> _startNavigation(LatLng destination) async {
    setState(() {
      _isNavigating = true;
      _destinationPoint = destination;
    });
    // Hủy subscription cũ nếu có
    await _positionStreamSubscription?.cancel();
    // Bắt đầu theo dõi vị trí
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      final currentLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = currentLatLng;
      });
      // Tính khoảng cách đến đích
      double distanceInMeters = Geolocator.distanceBetween(
        currentLatLng.latitude,
        currentLatLng.longitude,
        destination.latitude,
        destination.longitude,
      );
      setState(() {
        _remainingDistance = distanceInMeters;
      });
      // Nếu đến gần đích (ví dụ: trong phạm vi 50m)
      if (distanceInMeters < 50) {
        _stopNavigation();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bạn đã đến nơi!')));
        return;
      }
      _getDirections(destination);
    });
    // Lấy đường đi ban đầu
    await _getDirections(destination);
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
      _destinationPoint = null;
      _remainingDistance = 0;
    });
    _positionStreamSubscription?.cancel();
  }

  void _hideSpotDetails() {
    setState(() {
      _showSpotDetails = false;
    });
  }

  void _hideSpotDetailsAndRoute() {
    setState(() {
      _showSpotDetails = false;
      _routePoints = [];
      _isShowingRoute = false;
      _isNavigating = false;
      _destinationPoint = null;
      _remainingDistance = 0;
      _positionStreamSubscription?.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(center: _currentPosition, zoom: 15.0),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.camp_go_frontend',
            ),
            MarkerLayer(
              markers: [
                // Markers cho các địa điểm cắm trại
                ..._campsites.map((spot) => Marker(
                  point: spot.coordinates,
                  width: 60.0,
                  height: 60.0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCampsite = spot;
                        _showSpotDetails = true;
                      });
                    },
                    child: Icon(
                      Icons.location_on,
                      color: Colors.green,
                      size: 40,
                    ),
                  ),
                )),
                // Markers cho các thành viên khác
                ..._memberPositions.entries.map((entry) {
                  return Marker(
                    point: entry.value,
                    width: 40,
                    height: 40,
                    child: _memberAvatars[entry.key] != null && _memberAvatars[entry.key]!.isNotEmpty
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(_memberAvatars[entry.key]!),
                            radius: 20,
                          )
                        : const Icon(
                            Icons.person_pin_circle,
                            color: Colors.red,
                            size: 40,
                          ),
                  );
                }),
              ],
            ),
            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    color: Colors.blue,
                    strokeWidth: 4,
                  ),
                ],
              ),
          ],
        ),
        if (_showSpotDetails && _selectedCampsite != null)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _hideSpotDetailsAndRoute,
              child: DraggableScrollableSheet(
                initialChildSize: 0.4,
                minChildSize: 0.2,
                maxChildSize: 0.9,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(
                              top: 8,
                              bottom: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              0,
                              8,
                              16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _selectedCampsite!.name,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      _selectedCampsite!.rating.toString(),
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      children: List.generate(5, (index) {
                                        return Icon(
                                          index < _selectedCampsite!.rating
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber,
                                          size: 20,
                                        );
                                      }),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${_selectedCampsite!.reviews.length} đánh giá)',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Địa điểm cắm trại • ${_selectedCampsite!.priceRange.min}-${_selectedCampsite!.priceRange.max}K VNĐ',
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                      ),
                                      child: Text(
                                        'Đang mở cửa',
                                        style: TextStyle(
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Đóng cửa lúc ${_selectedCampsite!.openingHours.close}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              children: [
                                _buildActionButton(
                                  icon: Icons.directions,
                                  label: 'Đường đi',
                                  onTap: () {
                                    _getDirections(
                                      _selectedCampsite!.coordinates,
                                    );
                                    setState(() {
                                      _showSpotDetails = false;
                                    });
                                  },
                                  color: Colors.blue,
                                ),
                                _buildActionButton(
                                  icon: Icons.navigation,
                                  label: 'Bắt đầu',
                                  onTap: () {
                                    _startNavigation(
                                      _selectedCampsite!.coordinates,
                                    );
                                    setState(() {
                                      _showSpotDetails = false;
                                      _showNavigationSheet = true;
                                    });
                                  },
                                  color: Colors.blue,
                                ),
                                _buildActionButton(
                                  icon: Icons.phone,
                                  label: 'Gọi',
                                  onTap: () {
                                    // TODO: Implement call
                                  },
                                  color: Colors.blue,
                                ),
                                _buildActionButton(
                                  icon: Icons.bookmark_border,
                                  label: 'Lưu',
                                  onTap: () {
                                    // TODO: Implement save
                                  },
                                  color: Colors.blue,
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          if (_selectedCampsite!.images.isNotEmpty) ...[
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedCampsite!.images.length,
                                itemBuilder: (context, index) {
                                  final img = _selectedCampsite!.images[index];
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        img.url,
                                        width: 160,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        if (_showNavigationSheet)
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.2,
            maxChildSize: 0.5,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  shrinkWrap: true,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Khoảng cách còn lại',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_remainingDistance / 1000).toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _showNavigationSheet = false;
                                _routePoints = [];
                              });
                              _stopNavigation();
                            },
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.stop, color: Colors.white, size: 32),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Dừng',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: CircleAvatar(
            backgroundColor: color ?? Colors.blue,
            child: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
