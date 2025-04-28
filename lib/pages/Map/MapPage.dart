import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:CampGo/services/api_service.dart';
import 'package:CampGo/models/campsite.dart';
import 'package:http/http.dart' as http;

class CampingSpot {
  final String id;
  final String name;
  final LatLng location;
  final String description;
  final double rating;
  final List<String> facilities;
  final List<String> images;
  final Map<String, dynamic> priceRange;
  final Map<String, dynamic> contactInfo;
  final Map<String, dynamic> openingHours;

  CampingSpot({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.rating,
    required this.facilities,
    required this.images,
    required this.priceRange,
    required this.contactInfo,
    required this.openingHours,
  });

  factory CampingSpot.fromJson(Map<String, dynamic> json) {
    return CampingSpot(
      id: json['_id'] ?? '',
      name: json['campsiteName'] ?? '',
      location: LatLng(json['latitude'] ?? 0.0, json['longitude'] ?? 0.0),
      description: json['description'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      facilities: List<String>.from(json['facilities'] ?? []),
      images: List<String>.from(json['images']?.map((img) => img['url']) ?? []),
      priceRange: json['priceRange'] ?? {},
      contactInfo: json['contactInfo'] ?? {},
      openingHours: json['openingHours'] ?? {},
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final List<Marker> _markers = [];
  final List<Marker> _groupMarkers = [];
  final TextEditingController _searchController = TextEditingController();
  LatLng? _currentPosition;
  bool _isLoading = false;
  double _currentZoom = 13.0;
  Campsite? _selectedSpot;
  bool _showSpotDetails = false;
  List<Campsite> _campsites = [];
  List<LatLng> _routePoints = [];
  bool _isShowingRoute = false;
  bool _isNavigating = false;
  bool _isShowingNavigationSheet = false;
  bool _isGroupMode = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  LatLng? _destinationPoint;
  double _remainingDistance = 0;
  Timer? _updateTimer;
  String? _avatarUrl;

  // Vị trí mặc định (Đà Nẵng)
  static const LatLng _defaultLocation = LatLng(16.0544, 108.2022);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _loadAvatar();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
    _loadCampsites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    _animationController.dispose();
    _positionStreamSubscription?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCampsites() async {
    try {
      setState(() => _isLoading = true);
      final campsites = await APIService.getAllCampsites();

      setState(() {
        _campsites = campsites;
        _addCampsiteMarkers();
      });
    } catch (e) {
      print('Error loading campsites: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải địa điểm cắm trại: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAvatar() async {
    String? avatarUrl;
    try {
      final response = await APIService.getUserProfile();
      if (response['success'] == true && response['userData'] != null) {
        final userData = response['userData'];
        var profileImage = userData['profileImage'];
        if (profileImage is String) {
          avatarUrl = profileImage;
        } else if (profileImage is Map && profileImage['url'] != null) {
          avatarUrl = profileImage['url'];
        }
      }
    } catch (e) {
      print('Error loading avatar from API: $e');
    }
    setState(() {
      _avatarUrl = avatarUrl;
    });
  }

  void _addCampsiteMarkers() {
    _markers.clear();
    for (var spot in _campsites) {
      _markers.add(
        Marker(
          point: spot.coordinates,
          width: 60.0,
          height: 60.0,
          child: GestureDetector(
            onTap: () => _showSpotInfo(spot),
            child: Icon(
              Icons.location_on,
              color: _getMarkerColor(spot.rating),
              size: 40,
            ),
          ),
        ),
      );
    }
    // Thêm marker vị trí hiện tại nếu có và KHÔNG ở group mode
    if (_currentPosition != null && !_isGroupMode) {
      _markers.add(
        Marker(
          point: _currentPosition!,
          width: 44.0,
          height: 44.0,
          child: _avatarUrl != null
              ? CircleAvatar(
                  backgroundImage: NetworkImage(_avatarUrl!),
                  radius: 22,
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.8),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 24),
                ),
        ),
      );
    }
    setState(() {});
  }

  void _updateGroupMarkers(List<LatLng> memberLocations, [List<String?>? avatarUrls]) {
    _groupMarkers.clear();
    for (int i = 0; i < memberLocations.length; i++) {
      final avatarUrl = avatarUrls != null && avatarUrls.length > i ? avatarUrls[i] : null;
      _groupMarkers.add(
        Marker(
          point: memberLocations[i],
          width: 44.0,
          height: 44.0,
          child: avatarUrl != null && avatarUrl.isNotEmpty
              ? CircleAvatar(
                  backgroundImage: NetworkImage(avatarUrl),
                  radius: 22,
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 24),
                ),
        ),
      );
    }
    setState(() {});
  }

  Color _getMarkerColor(double rating) {
    if (rating >= 4.5) return Colors.green[700]!;
    if (rating >= 4.0) return Colors.green[500]!;
    if (rating >= 3.5) return Colors.orange;
    return Colors.red;
  }

  IconData _getMarkerIcon(List<String> facilities) {
    if (facilities.contains('Hồ bơi')) return Icons.pool;
    if (facilities.contains('BBQ')) return Icons.outdoor_grill;
    if (facilities.contains('Wifi')) return Icons.wifi;
    return Icons.park;
  }

  void _showSpotInfo(Campsite spot) async {
    try {
      setState(() => _isLoading = true);
      final updatedSpot = await APIService.getCampsiteDetails(spot.id);

      if (mounted) {
        setState(() {
          _selectedSpot = updatedSpot;
          _showSpotDetails = true;
        });
        _animationController.forward();
        _mapController.move(spot.coordinates, 15);
      }
    } catch (e) {
      print('Error loading spot details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải chi tiết địa điểm: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _hideSpotDetails() {
    _animationController.reverse().then((_) {
      setState(() {
        _showSpotDetails = false;
      });
    });
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      print('Kiểm tra dịch vụ vị trí...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Dịch vụ vị trí đang tắt'),
                content: const Text(
                  'Vui lòng bật dịch vụ vị trí để sử dụng tính năng này',
                ),
                actions: [
                  TextButton(
                    child: const Text('Mở cài đặt'),
                    onPressed: () async {
                      await Geolocator.openLocationSettings();
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text('Đóng'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
        throw Exception('Dịch vụ vị trí đang tắt');
      }

      print('Kiểm tra quyền truy cập vị trí...');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Quyền truy cập vị trí bị từ chối');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Quyền truy cập vị trí bị từ chối'),
                content: const Text(
                  'Vui lòng vào cài đặt để cấp quyền truy cập vị trí cho ứng dụng',
                ),
                actions: [
                  TextButton(
                    child: const Text('Mở cài đặt'),
                    onPressed: () async {
                      await Geolocator.openAppSettings();
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text('Đóng'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
        throw Exception('Quyền truy cập vị trí bị từ chối vĩnh viễn');
      }

      print('Đang lấy vị trí hiện tại...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      if (!mounted) return;

      final currentLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = currentLocation;
        _addCampsiteMarkers(); // Cập nhật lại tất cả markers
      });

      _mapController.move(currentLocation, 20.0); // Zoom lớn hơn khi về vị trí hiện tại

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật vị trí hiện tại'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _zoomIn() {
    _currentZoom = _mapController.camera.zoom + 1;
    _mapController.move(_mapController.camera.center, _currentZoom);
  }

  void _zoomOut() {
    _currentZoom = _mapController.camera.zoom - 1;
    _mapController.move(_mapController.camera.center, _currentZoom);
  }

  Future<void> _startNavigation(LatLng destination) async {
    setState(() {
      _isNavigating = true;
      _isShowingNavigationSheet = true;
      _destinationPoint = destination;
    });
    _animationController.forward();

    // Hủy subscription cũ nếu có
    await _positionStreamSubscription?.cancel();

    // Bắt đầu theo dõi vị trí
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Cập nhật khi di chuyển 10 mét
      ),
    ).listen((Position position) async {
      final currentLatLng = LatLng(position.latitude, position.longitude);

      // Cập nhật vị trí hiện tại
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

      // Cập nhật đường đi mỗi 30 giây
      _updateTimer?.cancel();
      _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (_isNavigating && _destinationPoint != null) {
          _getDirections(_destinationPoint!);
        }
      });
    });

    // Lấy đường đi ban đầu
    await _getDirections(destination);
  }

  void _stopNavigation() {
    _animationController.reverse().then((_) {
      setState(() {
        _isNavigating = false;
        _isShowingNavigationSheet = false;
        _destinationPoint = null;
        _routePoints = [];
        _remainingDistance = 0;
      });
    });
    _positionStreamSubscription?.cancel();
    _updateTimer?.cancel();
  }

  Future<void> _getDirections(LatLng destination) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng bật vị trí để sử dụng tính năng chỉ đường'),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

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

        setState(() {
          _routePoints =
              coordinates.map((point) {
                return LatLng(point[1] as double, point[0] as double);
              }).toList();
          _isShowingRoute = true;
        });

        if (!_isNavigating) {
          // Chỉ fit bounds khi không trong chế độ điều hướng
          final bounds = LatLngBounds.fromPoints(_routePoints);
          _mapController.fitBounds(
            bounds,
            options: const FitBoundsOptions(padding: EdgeInsets.all(50.0)),
          );
        }
      }
    } catch (e) {
      print('Error getting directions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể tải thông tin chỉ đường. Vui lòng thử lại sau.',
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearRoute() {
    setState(() {
      _routePoints = [];
      _isShowingRoute = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ Cắm trại'),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CampsiteSearchDelegate(_campsites),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition ?? _defaultLocation,
              initialZoom: _currentZoom,
              minZoom: 3,
              maxZoom: 18,
              onTap: (tapPosition, point) {
                setState(() {
                  _showSpotDetails = false;
                  if (_isShowingRoute && !_isNavigating) {
                    _clearRoute();
                  }
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.campgo.app',
              ),
              MarkerLayer(markers: [..._markers, ..._groupMarkers]),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blue,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
            ],
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (_showSpotDetails && _selectedSpot != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: _hideSpotDetails,
                child: Container(
                  color: Colors.black.withOpacity(0.3),
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
                                            _selectedSpot!.name,
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
                                          _selectedSpot!.rating.toString(),
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Row(
                                          children: List.generate(5, (index) {
                                            return Icon(
                                              index < _selectedSpot!.rating
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: Colors.amber,
                                              size: 20,
                                            );
                                          }),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${_selectedSpot!.reviews.length} đánh giá)',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Địa điểm cắm trại • ${_selectedSpot!.priceRange.min}-${_selectedSpot!.priceRange.max}K VNĐ',
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
                                          'Đóng cửa lúc ${_selectedSpot!.openingHours.close}',
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
                                          _selectedSpot!.coordinates,
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
                                          _selectedSpot!.coordinates,
                                        );
                                        setState(() {
                                          _showSpotDetails = false;
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
                              if (_selectedSpot!.images.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'Hình ảnh',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 200,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _selectedSpot!.images.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          left: 16.0,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            _selectedSpot!.images[index].url,
                                            width: 300,
                                            height: 200,
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
            ),
          if (_isNavigating && _isShowingNavigationSheet)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(_animation),
                child: Container(
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Khoảng cách còn lại',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${(_remainingDistance / 1000).toStringAsFixed(1)} km',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionButton(
                                  icon: Icons.stop_circle,
                                  label: 'Dừng',
                                  onTap: _stopNavigation,
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            left: 16,
            top: 16,
            child: FloatingActionButton(
              heroTag: 'location',
              onPressed: _getCurrentLocation,
              backgroundColor: Colors.white,
              child: const Icon(
                Icons.my_location,
                color: Colors.blue,
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: FloatingActionButton(
              heroTag: 'createGroup',
              onPressed: () {
                Navigator.pushNamed(context, '/group-tracking');
              },
              backgroundColor: Colors.blue,
              child: const Icon(
                Icons.group_add,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class CampsiteSearchDelegate extends SearchDelegate {
  final List<Campsite> campsites;

  CampsiteSearchDelegate(this.campsites);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results =
        campsites
            .where(
              (spot) =>
                  spot.name.toLowerCase().contains(query.toLowerCase()) ||
                  spot.description.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final spot = results[index];
        return ListTile(
          title: Text(spot.name),
          subtitle: Text(spot.description),
          onTap: () {
            close(context, spot);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions =
        campsites
            .where(
              (spot) =>
                  spot.name.toLowerCase().contains(query.toLowerCase()) ||
                  spot.description.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final spot = suggestions[index];
        return ListTile(
          title: Text(spot.name),
          subtitle: Text(spot.description),
          onTap: () {
            query = spot.name;
            showResults(context);
          },
        );
      },
    );
  }
}
