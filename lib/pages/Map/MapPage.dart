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
import 'package:url_launcher/url_launcher.dart';
import 'package:CampGo/pages/Campsite Owner/CampsiteOwnerPage.dart';

class CampingSpot {
  final String id;
  final String name;
  final LatLng location;
  final String description;
  final double rating;
  final List<String> facilities;
  final List<CampsiteImage> images;
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
    // Lấy danh sách ảnh từ trường images (mảng) hoặc image (object)
    List<CampsiteImage> images = [];
    if (json['images'] != null && json['images'] is List && json['images'].isNotEmpty) {
      images = (json['images'] as List)
          .where((img) => img is Map && img['url'] != null)
          .map((img) => CampsiteImage.fromJson(img))
          .toList();
    } else if (json['image'] != null && json['image'] is Map && json['image']['url'] != null) {
      images = [CampsiteImage.fromJson(json['image'])];
    }

    // Đảm bảo facilities là List<String>
    List<String> facilities = [];
    if (json['facilities'] != null) {
      if (json['facilities'] is String) {
        try {
          facilities = List<String>.from(jsonDecode(json['facilities']));
        } catch (e) {
          facilities = [];
        }
      } else if (json['facilities'] is List) {
        facilities = List<String>.from(json['facilities'].map((f) => f.toString()));
      }
    }

    return CampingSpot(
      id: json['_id'] ?? '',
      name: json['campsiteName'] ?? '',
      location: LatLng(json['latitude'] ?? 0.0, json['longitude'] ?? 0.0),
      description: json['description'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      facilities: facilities,
      images: images,
      priceRange: json['priceRange'] ?? {},
      contactInfo: json['contactInfo'] ?? {},
      openingHours: json['openingHours'] ?? {},
    );
  }
}

class CampsiteImage {
  final String url;
  final String publicId;

  CampsiteImage({
    required this.url,
    required this.publicId,
  });

  factory CampsiteImage.fromJson(Map<String, dynamic> json) {
    return CampsiteImage(
      url: json['url'] ?? '',
      publicId: json['public_id'] ?? '',
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

    // Bắt đầu lắng nghe vị trí realtime
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Cập nhật khi di chuyển 5 mét
      ),
    ).listen((Position position) {
      final currentLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = currentLocation;
        _addCampsiteMarkers();

        // Nếu đang navigation, tính lại khoảng cách đến đích
        if (_isNavigating && _destinationPoint != null) {
          double distanceInMeters = Geolocator.distanceBetween(
            currentLocation.latitude,
            currentLocation.longitude,
            _destinationPoint!.latitude,
            _destinationPoint!.longitude,
          );
          _remainingDistance = distanceInMeters;

          // Nếu đã đến nơi (ví dụ < 50m), dừng navigation
          if (_remainingDistance < 50) {
            _stopNavigation();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You have arrived!', textAlign: TextAlign.center),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      });
    });
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
      print('Parsed images: \\${updatedSpot.images.map((e) => e.url).toList()}');
      print('Parsed facilities: \\${updatedSpot.facilities}');
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

    // KHÔNG tạo lại _positionStreamSubscription ở đây nữa
    // Chỉ cần cập nhật route mỗi 30 giây nếu đang navigation
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isNavigating && _destinationPoint != null) {
        _getDirections(_destinationPoint!);
      }
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
    // KHÔNG cancel _positionStreamSubscription ở đây nữa
    _updateTimer?.cancel();
  }

  Future<void> _getDirections(LatLng destination) async {
    print('_getDirections called, _currentPosition: [32m[1m[4m[7m$_currentPosition[0m');
    if (_currentPosition == null) {
      print('ERROR: _currentPosition is null!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng bật định vị để sử dụng tính năng chỉ đường',
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
      print('Directions API status: [34m${response.statusCode}[0m');
      print('Directions API body: ${response.body}');

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
                                    SizedBox(height: 4),
                                    Text(
                                      _selectedSpot!.location,
                                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                                    ),
                                    SizedBox(height: 6),
                                    const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    Text(
                                      _selectedSpot!.description,
                                      style: TextStyle(fontSize: 14, color: Colors.black87),
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
                                      'Camping site • ' +
                                        ((_selectedSpot!.priceRange.min == 0 && _selectedSpot!.priceRange.max == 0)
                                          ? 'Free'
                                          : '${formatPrice(_selectedSpot!.priceRange.min)} - ${formatPrice(_selectedSpot!.priceRange.max)} USD'),
                                      style: TextStyle(
                                        color: (_selectedSpot!.priceRange.min == 0 && _selectedSpot!.priceRange.max == 0)
                                            ? Colors.green
                                            : Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if ((_selectedSpot!.openingHours.open != null && _selectedSpot!.openingHours.open?.isNotEmpty == true) &&
                                        (_selectedSpot!.openingHours.close != null && _selectedSpot!.openingHours.close?.isNotEmpty == true))
                                      Text(
                                        'Opening hours • ${_selectedSpot!.openingHours.open} - ${_selectedSpot!.openingHours.close}',
                                        style: TextStyle(
                                          color: const Color.fromARGB(255, 56, 56, 56),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    if ((_selectedSpot!.contactInfo.email != null && _selectedSpot!.contactInfo.email.toString().isNotEmpty))
                                      Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Text('Email: ${_selectedSpot!.contactInfo.email}', style: TextStyle(fontSize: 14, color: Colors.black87)),
                                      ),
                                    if ((_selectedSpot!.contactInfo.website != null && _selectedSpot!.contactInfo.website.toString().isNotEmpty))
                                      Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: GestureDetector(
                                          onTap: () async {
                                            final url = _selectedSpot!.contactInfo.website?.toString() ?? '';
                                            if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
                                              await launchUrl(Uri.parse(url));
                                            }
                                          },
                                          child: Text('Website: ${_selectedSpot!.contactInfo.website}', style: TextStyle(fontSize: 14, color: Colors.blue, decoration: TextDecoration.underline)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildActionButton(
                                      icon: Icons.turn_right,
                                      label: 'Đường đi',
                                      onTap: () {
                                        _getDirections(_selectedSpot!.coordinates);
                                        setState(() {
                                          _showSpotDetails = false;
                                        });
                                      },
                                      color: Color(0xFF00838F),
                                      filled: true,
                                    ),
                                    SizedBox(width: 16),
                                    _buildActionButton(
                                      icon: Icons.navigation,
                                      label: 'Bắt đầu',
                                      onTap: () {
                                        _startNavigation(_selectedSpot!.coordinates);
                                        setState(() {
                                          _showSpotDetails = false;
                                        });
                                      },
                                      color: Color(0xFF00838F),
                                    ),
                                    SizedBox(width: 16),
                                    _buildActionButton(
                                      icon: Icons.phone,
                                      label: 'Gọi',
                                      onTap: () {
                                        final phone = _selectedSpot?.contactInfo.phone ?? '';
                                        if (phone.isNotEmpty) {
                                          _showCallDialog(phone);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Không có số điện thoại!')),
                                          );
                                        }
                                      },
                                      color: Color(0xFF00838F),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                              if (_selectedSpot!.images.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 200,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _selectedSpot!.images.length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.only(left: 16.0),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
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
                                )
                              else
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('Không có hình ảnh'),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: const Text(
                                        'Reviews',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (_selectedSpot!.reviews.isEmpty)
                                      Center(
                                        child: const Text(
                                          'No reviews yet',
                                          style: TextStyle(
                                            color: Colors.grey,
                                          ),
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
                                                            child: Image.network(
                                                              review.images[imageIndex],
                                                              height: 100,
                                                              width: 100,
                                                              fit: BoxFit.cover,
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
    bool filled = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: filled ? Colors.white : color, size: 23),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : color,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
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
                          return Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Image.file(
                                  File(selectedImages[index].path),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedImages.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.close, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
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

  void _showCallDialog(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể thực hiện cuộc gọi!')),
      );
    }
  }

  Future<void> _openCampsiteOwnerPage() async {
    final shouldReload = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CampsiteOwnerPage()),
    );
    if (shouldReload == true) {
      _loadCampsites();
    }
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

String formatPrice(dynamic price) {
  if (price == null) return '0';
  if (price is int) return '${price.toString()}';
  if (price is double) return '${price.toStringAsFixed(0)}';
  if (price is String) return '${double.tryParse(price)?.toStringAsFixed(0) ?? '0'}';
  return '${price.toString()}';
}
