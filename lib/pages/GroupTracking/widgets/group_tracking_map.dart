import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/realtime_tracking_service.dart';
import 'package:CampGo/services/api_service.dart';
import 'package:CampGo/models/campsite.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:CampGo/models/campsite_review.dart';
import 'package:url_launcher/url_launcher.dart';

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
  List<CampsiteReview> _reviews = [];
  final ImagePicker _picker = ImagePicker();
  int _totalReviews = 0;

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
        ).showSnackBar(const SnackBar(content: Text('You have arrived!')));
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

  Future<void> _showSpotInfo(Campsite spot) async {
    try {
      setState(() => _showSpotDetails = false);
      final updatedSpot = await APIService.getCampsiteDetails(spot.id);
      final reviewsData = await APIService.getCampsiteReviews(spot.id);
      if (mounted) {
        setState(() {
          _selectedCampsite = updatedSpot;
          if (reviewsData['success'] == true && reviewsData['data'] != null) {
            final reviews = reviewsData['data']['reviews'] as List<dynamic>;
            _reviews = reviews.map((review) => CampsiteReview.fromJson(review)).toList();
            _totalReviews = reviewsData['data']['summary']?['totalReviews'] ?? _reviews.length;
          } else {
            _reviews = [];
            _totalReviews = 0;
          }
          _showSpotDetails = true;
        });
      }
    } catch (e) {
      print('Error loading spot details: $e');
      if (mounted) {
        setState(() => _showSpotDetails = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading spot details: $e', textAlign: TextAlign.center), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCallDialog(String phoneNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gọi điện'),
        content: Text(phoneNumber, style: const TextStyle(fontSize: 20, color: Colors.blue)),
        actions: [
          TextButton(
            onPressed: () async {
              final uri = Uri(scheme: 'tel', path: phoneNumber);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
              Navigator.of(context).pop();
            },
            child: Text('Gọi $phoneNumber'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
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
                      _showSpotInfo(spot);
                    },
                    child: Icon(
                      Icons.location_on,
                      color: _getMarkerColor(spot.rating),
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
                                      '($_totalReviews Reviews)',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Camping site • ${_selectedCampsite!.priceRange.min}-${_selectedCampsite!.priceRange.max}K VNĐ',
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
                                      'Closing time ${_selectedCampsite!.openingHours.close}',
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
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildActionButton(
                                  icon: Icons.directions,
                                  label: 'Route',
                                  onTap: () {
                                    _getDirections(_selectedCampsite!.coordinates);
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
                                    _startNavigation(_selectedCampsite!.coordinates);
                                    setState(() {
                                      _showSpotDetails = false;
                                      _showNavigationSheet = true;
                                    });
                                  },
                                  color: Colors.blue,
                                ),
                                _buildActionButton(
                                  icon: Icons.phone,
                                  label: 'Call',
                                  onTap: () {
                                    final phone = _selectedCampsite?.contactInfo.phone ?? '';
                                    if (phone.isNotEmpty) {
                                      _showCallDialog(phone);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Không có số điện thoại!')),
                                      );
                                    }
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
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Reviews',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                if (_reviews.isEmpty)
                                  const Text(
                                    'No reviews yet',
                                    style: TextStyle(color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  )
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _reviews.length,
                                    itemBuilder: (context, index) {
                                      final review = _reviews[index];
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
                                                    backgroundImage: review.userProfileImageUrl != null ? NetworkImage(review.userProfileImageUrl!) : null,
                                                    child: review.userProfileImageUrl == null ? Text(review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '?') : null,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                      Row(
                                                        children: [
                                                          ...List.generate(5, (i) {
                                                            return Icon(i < review.rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 16);
                                                          }),
                                                          const SizedBox(width: 8),
                                                          Text('${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                                const SizedBox(height: 12),
                                Center(
                                  child: ElevatedButton.icon(
                                    icon: Icon(Icons.rate_review),
                                    label: Text('Write a review'),
                                    onPressed: () {
                                      _showReviewDialog(_selectedCampsite!);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[700],
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
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
                      'Remaining distance',
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
                            'Stop',
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
                          SnackBar(content: Text('Review successfully!', textAlign: TextAlign.center), backgroundColor: Colors.green),
                        );
                        _showSpotInfo(spot); // Load lại review
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to send review!', textAlign: TextAlign.center), backgroundColor: Colors.red),
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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Color _getMarkerColor(double rating) {
    if (rating >= 4.5) return Colors.green[700]!;
    if (rating >= 4.0) return Colors.green[500]!;
    if (rating >= 3.5) return Colors.orange;
    return Colors.red;
  }
}
