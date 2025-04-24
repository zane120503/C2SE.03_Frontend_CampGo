import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:CampGo/services/places_service.dart';
import 'package:CampGo/services/api_service.dart';

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
      location: LatLng(
        json['latitude'] ?? 0.0,
        json['longitude'] ?? 0.0,
      ),
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

class _MapPageState extends State<MapPage> {
  late final MapController _mapController;
  final List<Marker> _markers = [];
  final TextEditingController _searchController = TextEditingController();
  final PlacesService _placesService = PlacesService();
  LatLng? _currentPosition;
  bool _isLoading = false;
  bool _isSearching = false;
  List<Place> _searchResults = [];
  double _currentZoom = 13.0;
  CampingSpot? _selectedSpot;
  bool _showSpotDetails = false;
  List<CampingSpot> _campingSpots = [];

  // Vị trí mặc định (Đà Nẵng)
  static const LatLng _defaultLocation = LatLng(16.0544, 108.2022);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // Tự động lấy vị trí khi mở bản đồ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
    _loadCampingSpots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadCampingSpots() async {
    try {
      setState(() => _isLoading = true);
      final response = await APIService.getCampingSpots();
      
      if (response['success'] == true) {
        final List<dynamic> spotsData = response['data'];
        setState(() {
          _campingSpots = spotsData.map((spot) => CampingSpot.fromJson(spot)).toList();
          _addCampingSpotMarkers();
        });
      }
    } catch (e) {
      print('Error loading camping spots: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải địa điểm cắm trại: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addCampingSpotMarkers() {
    _markers.clear();
    for (var spot in _campingSpots) {
      _markers.add(
        Marker(
          point: spot.location,
          width: 40.0,
          height: 40.0,
          child: GestureDetector(
            onTap: () => _showSpotInfo(spot),
            child: const Icon(
              Icons.park,
              color: Colors.green,
              size: 40,
            ),
          ),
        ),
      );
    }
  }

  void _showSpotInfo(CampingSpot spot) async {
    try {
      setState(() => _isLoading = true);
      final response = await APIService.getCampingSpotDetails(spot.id);
      
      if (response['success'] == true) {
        final updatedSpot = CampingSpot.fromJson(response['data']);
        setState(() {
          _selectedSpot = updatedSpot;
          _showSpotDetails = true;
        });
        _mapController.move(spot.location, 15);
      }
    } catch (e) {
      print('Error loading spot details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải chi tiết địa điểm: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    try {
      print('Kiểm tra dịch vụ vị trí...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Hiển thị dialog yêu cầu bật dịch vụ vị trí
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Dịch vụ vị trí đang tắt'),
                content: const Text('Vui lòng bật dịch vụ vị trí để sử dụng tính năng này'),
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
        // Hiển thị dialog hướng dẫn người dùng cấp quyền
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Quyền truy cập vị trí bị từ chối'),
                content: const Text('Vui lòng vào cài đặt để cấp quyền truy cập vị trí cho ứng dụng'),
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
        // Xóa marker vị trí hiện tại cũ nếu có
        _markers.removeWhere((marker) => 
          marker.child is Icon && 
          (marker.child as Icon).color == Colors.blue
        );
        
        _currentPosition = currentLocation;
        // Thêm marker vị trí hiện tại mới
        _markers.add(
          Marker(
            point: currentLocation,
            width: 40.0,
            height: 40.0,
            child: const Icon(
              Icons.location_on,
              color: Colors.blue,
              size: 40,
            ),
          ),
        );
      });

      // Di chuyển map đến vị trí hiện tại với animation
      _mapController.move(currentLocation, 15.0);
      
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

  // Thêm marker cho địa điểm
  void _addPlaceMarker(Place place) {
    setState(() {
      _markers.add(
        Marker(
          point: place.location,
          width: 120.0,
          height: 60.0,
          child: Column(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  place.name,
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // Hiển thị chi tiết địa điểm
  Future<void> _showPlaceDetails(Place place) async {
    try {
      final details = await _placesService.getPlaceDetails(place.id);
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (details.photos.isNotEmpty)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(details.photos.first),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      details.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        Text(' ${details.rating}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(details.address),
                    if (details.phoneNumber != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone),
                          Text(' ${details.phoneNumber}'),
                        ],
                      ),
                    ],
                    if (details.website != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.language),
                          Text(' ${details.website}'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  // Tìm kiếm địa điểm
  Future<void> _searchLocation(String query) async {
    setState(() => _isSearching = true);
    try {
      final results = await _placesService.searchPlaces(query, _currentPosition);
      setState(() {
        _searchResults = results;
        _markers.removeWhere(
          (marker) => marker.point != _currentPosition,
        );
        for (final place in results) {
          _addPlaceMarker(place);
        }
      });

      if (results.isNotEmpty) {
        final bounds = _calculateBounds(results);
        _mapController.fitBounds(
          bounds,
          options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
        );
      }
    } catch (e) {
      print('Error searching location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tìm kiếm: $e')),
      );
    } finally {
      setState(() => _isSearching = false);
    }
  }

  // Tính toán bounds cho camera
  LatLngBounds _calculateBounds(List<Place> places) {
    double? minLat, maxLat, minLng, maxLng;

    for (final place in places) {
      if (minLat == null || place.location.latitude < minLat) {
        minLat = place.location.latitude;
      }
      if (maxLat == null || place.location.latitude > maxLat) {
        maxLat = place.location.latitude;
      }
      if (minLng == null || place.location.longitude < minLng) {
        minLng = place.location.longitude;
      }
      if (maxLng == null || place.location.longitude > maxLng) {
        maxLng = place.location.longitude;
      }
    }

    return LatLngBounds(
      LatLng(minLat!, minLng!),
      LatLng(maxLat!, maxLng!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ Cắm trại'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CampingSpotSearchDelegate(_campingSpots),
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
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.campgo.app',
              ),
              MarkerLayer(
                markers: _markers,
              ),
            ],
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (_showSpotDetails && _selectedSpot != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _selectedSpot!.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              Text(_selectedSpot!.rating.toStringAsFixed(1)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_selectedSpot!.description),
                      const SizedBox(height: 8),
                      if (_selectedSpot!.facilities.isNotEmpty) ...[
                        const Text(
                          'Tiện ích:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Wrap(
                          spacing: 8,
                          children: _selectedSpot!.facilities.map((amenity) {
                            return Chip(
                              label: Text(amenity),
                              backgroundColor: Colors.blue.shade100,
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (_selectedSpot!.priceRange.isNotEmpty) ...[
                        const Text(
                          'Khoảng giá:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_selectedSpot!.priceRange['min']} - ${_selectedSpot!.priceRange['max']} VNĐ',
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Implement directions
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tính năng chỉ đường đang phát triển'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.directions),
                            label: const Text('Chỉ đường'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Implement reviews
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tính năng đánh giá đang phát triển'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.rate_review),
                            label: const Text('Đánh giá'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            right: 16,
            bottom: 96,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoomIn',
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoomOut',
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'location',
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}

class CampingSpotSearchDelegate extends SearchDelegate {
  final List<CampingSpot> spots;

  CampingSpotSearchDelegate(this.spots);

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
    final results = spots.where((spot) =>
        spot.name.toLowerCase().contains(query.toLowerCase()) ||
        spot.description.toLowerCase().contains(query.toLowerCase())).toList();

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
    final suggestions = spots.where((spot) =>
        spot.name.toLowerCase().contains(query.toLowerCase()) ||
        spot.description.toLowerCase().contains(query.toLowerCase())).toList();

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