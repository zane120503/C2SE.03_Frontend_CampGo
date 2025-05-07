import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:CampGo/services/api_service.dart';
import 'package:CampGo/models/campsite.dart';
import 'package:CampGo/models/campsite_review.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';

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
  final ImagePicker _picker = ImagePicker();

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
          SnackBar(content: Text('Error loading camping sites: $e',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
          ),
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

  void _showSpotInfo(Campsite spot) async {
    try {
      setState(() => _isLoading = true);
      final updatedSpot = await APIService.getCampsiteDetails(spot.id);
      final reviewsData = await APIService.getCampsiteReviews(spot.id);

      if (mounted) {
        setState(() {
          _selectedSpot = updatedSpot;
          if (reviewsData['success'] == true && reviewsData['data'] != null) {
            final reviews = reviewsData['data']['reviews'] as List<dynamic>;
            _selectedSpot = Campsite(
              id: _selectedSpot!.id,
              name: _selectedSpot!.name,
              location: _selectedSpot!.location,
              coordinates: _selectedSpot!.coordinates,
              description: _selectedSpot!.description,
              rating: _selectedSpot!.rating,
              reviews: reviews.map((review) => CampsiteReview.fromJson(review)).toList(),
              facilities: _selectedSpot!.facilities,
              images: _selectedSpot!.images,
              priceRange: _selectedSpot!.priceRange,
              contactInfo: _selectedSpot!.contactInfo,
              openingHours: _selectedSpot!.openingHours,
              isActive: _selectedSpot!.isActive,
              createdAt: _selectedSpot!.createdAt,
              updatedAt: _selectedSpot!.updatedAt,
            );
          }
          _showSpotDetails = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading spot details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading spot details: $e',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
          ),
        );
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
      print('Checking location service...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Location service is disabled'),
                content: const Text(
                  'Please enable location service to use this feature',
                ),
                actions: [
                  TextButton(
                    child: const Text('Open settings'),
                    onPressed: () async {
                      await Geolocator.openLocationSettings();
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text('Close'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
        throw Exception('Location service is disabled');
      }

      print('Checking location permission...');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Location permission denied'),
                content: const Text(
                  'Please go to settings to grant location access to the app',
                ),
                actions: [
                  TextButton(
                    child: const Text('Open settings'),
                    onPressed: () async {
                      await Geolocator.openAppSettings();
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text('Close'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
        throw Exception('Location permission denied permanently');
      }

      print('Getting current location...');
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
          content: Text('Current location updated',
          textAlign: TextAlign.center,
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(),
          textAlign: TextAlign.center,
          ),
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
        ).showSnackBar(const SnackBar(content: Text('You have arrived!',
        textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.green,
        ),
        );
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
          content: Text('Please enable location to use the route feature',
          textAlign: TextAlign.center,
          ),
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
            'Unable to load route information. Please try again later.',
            textAlign: TextAlign.center,
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
        title: const Text('Camping Map'),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CampsiteSearchDelegate(_campsites, _mapController, _showSpotInfo),
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
                                          '(${_selectedSpot!.reviews.length} Reviews)',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Camping site • ${_selectedSpot!.priceRange.min}-${_selectedSpot!.priceRange.max}K VNĐ',
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
                                            'Open now',
                                            style: TextStyle(
                                              color: Colors.green[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Closing time ${_selectedSpot!.openingHours.close}',
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
                                      label: 'Route',
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
                                      label: 'Start',
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
                                      label: 'Call',
                                      onTap: () {
                                        // TODO: Implement call
                                      },
                                      color: Colors.blue,
                                    ),
                                    _buildActionButton(
                                      icon: Icons.bookmark_border,
                                      label: 'Save',
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
                                    'Images',
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
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Reviews',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (_selectedSpot!.reviews.isEmpty)
                                      const Text(
                                        'No reviews yet',
                                        style: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      )
                                    else
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _selectedSpot!.reviews.length,
                                        itemBuilder: (context, index) {
                                          final review = _selectedSpot!.reviews[index] as CampsiteReview;
                                          return Card(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            child: Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      CircleAvatar(
                                                        backgroundImage: review.userProfileImageUrl != null
                                                            ? NetworkImage(review.userProfileImageUrl!)
                                                            : null,
                                                        child: review.userProfileImageUrl == null
                                                            ? Text(review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '?')
                                                            : null,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            review.userName,
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                          Row(
                                                            children: [
                                                              ...List.generate(5, (i) {
                                                                return Icon(
                                                                  i < review.rating
                                                                      ? Icons.star
                                                                      : Icons.star_border,
                                                                  color: Colors.amber,
                                                                  size: 16,
                                                                );
                                                              }),
                                                              const SizedBox(width: 8),
                                                              Text(
                                                                '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                                                                style: const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors.grey,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(review.comment),
                                                  if (review.images.isNotEmpty) ...[
                                                    const SizedBox(height: 8),
                                                    SizedBox(
                                                      height: 100,
                                                      child: ListView.builder(
                                                        scrollDirection: Axis.horizontal,
                                                        itemCount: review.images.length,
                                                        itemBuilder: (context, imageIndex) {
                                                          return Padding(
                                                            padding: const EdgeInsets.only(right: 8),
                                                            child: ClipRRect(
                                                              borderRadius: BorderRadius.circular(8),
                                                              child: Image.network(
                                                                review.images[imageIndex],
                                                                height: 100,
                                                                width: 100,
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
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                icon: Icon(Icons.rate_review),
                                label: Text('Write a review'),
                                onPressed: () {
                                  _showReviewDialog(_selectedSpot!);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                ),
                              ),
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
                                      'Remaining distance',
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
                                  label: 'Stop',
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

  void _showReviewDialog(Campsite spot) {
    double rating = 5;
    TextEditingController commentController = TextEditingController();
    List<XFile> selectedImages = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16, right: 16, top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Review campsite', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) => IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          rating = index + 1.0;
                        });
                      },
                    )),
                  ),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      labelText: 'Review content',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 2,
                    maxLines: 5,
                    textInputAction: TextInputAction.done,
                    onEditingComplete: () {
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.photo),
                        label: Text('Select images'),
                        onPressed: () async {
                          final images = await _picker.pickMultiImage();
                          if (images != null) {
                            setState(() {
                              selectedImages = images;
                            });
                          }
                        },
                      ),
                      SizedBox(width: 8),
                      Text('${selectedImages.length} images selected'),
                    ],
                  ),
                  if (selectedImages.isNotEmpty)
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Image.file(
                              File(selectedImages[index].path),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      List<File> imageFiles = selectedImages.map((xfile) => File(xfile.path)).toList();
                      print('Sending review with files: ${imageFiles.map((x) => x.path).toList()}');
                      final result = await APIService.addCampsiteReviewWithFiles(
                        spot.id,
                        rating,
                        commentController.text,
                        imageFiles,
                      );
                      print('Result of sending review: $result');
                      if (result['success'] == false) {
                        print('Error sending review: ${result['message']}');
                      }
                      Navigator.pop(context);
                      if (result['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Review successfully!',
                          textAlign: TextAlign.center,
                          ),
                          backgroundColor: Colors.green,
                          ),
                        );
                        _showSpotInfo(spot);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to send review!',
                          textAlign: TextAlign.center,
                          ),
                          backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Text('Send review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class CampsiteSearchDelegate extends SearchDelegate {
  final List<Campsite> campsites;
  final MapController mapController;
  final Function(Campsite) onSpotSelected;

  CampsiteSearchDelegate(this.campsites, this.mapController, this.onSpotSelected);

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
            // Di chuyển bản đồ đến vị trí của địa điểm được chọn
            mapController.move(spot.coordinates, 15.0);
            // Hiển thị thông tin chi tiết của địa điểm
            onSpotSelected(spot);
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
            // Di chuyển bản đồ đến vị trí của địa điểm được chọn
            mapController.move(spot.coordinates, 15.0);
            // Hiển thị thông tin chi tiết của địa điểm
            onSpotSelected(spot);
          },
        );
      },
    );
  }
}
