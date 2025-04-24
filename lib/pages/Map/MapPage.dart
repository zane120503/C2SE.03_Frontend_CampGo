import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:CampGo/services/api_service.dart';
import 'package:CampGo/models/campsite.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final MapController _mapController;
  final List<Marker> _markers = [];
  final TextEditingController _searchController = TextEditingController();
  LatLng? _currentPosition;
  bool _isLoading = false;
  double _currentZoom = 13.0;
  Campsite? _selectedSpot;
  bool _showSpotDetails = false;
  List<Campsite> _campsites = [];

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
    _loadCampsites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
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

  void _addCampsiteMarkers() {
    _markers.clear();
    for (var spot in _campsites) {
      _markers.add(
        Marker(
          point: spot.coordinates,
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
    // Thêm lại marker vị trí hiện tại nếu có
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          point: _currentPosition!,
          width: 40.0,
          height: 40.0,
          child: const Icon(
            Icons.location_on,
            color: Colors.blue,
            size: 40,
          ),
        ),
      );
    }
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
        _currentPosition = currentLocation;
        _addCampsiteMarkers(); // Cập nhật lại tất cả markers
      });

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
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
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
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
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
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  _selectedSpot!.rating.toStringAsFixed(1),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedSpot!.description,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 12),
                      if (_selectedSpot!.facilities.isNotEmpty) ...[
                        const Text(
                          'Tiện ích:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedSpot!.facilities.map((amenity) {
                            return Chip(
                              label: Text(amenity),
                              backgroundColor: Colors.green[50],
                              labelStyle: TextStyle(color: Colors.green[900]),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.attach_money, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedSpot!.priceRange.min} - ${_selectedSpot!.priceRange.max} VNĐ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (_selectedSpot!.contactInfo.phone != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.phone, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(_selectedSpot!.contactInfo.phone!),
                          ],
                        ),
                      ],
                      if (_selectedSpot!.openingHours.open != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text('${_selectedSpot!.openingHours.open} - ${_selectedSpot!.openingHours.close}'),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              _showReviewDialog();
                            },
                            icon: const Icon(Icons.rate_review),
                            label: const Text('Đánh giá'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
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
                  backgroundColor: Colors.green[700],
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoomOut',
                  onPressed: _zoomOut,
                  backgroundColor: Colors.green[700],
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
              backgroundColor: Colors.green[700],
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc địa điểm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Đánh giá cao'),
              onTap: () {
                // TODO: Implement rating filter
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Giá thấp'),
              onTap: () {
                // TODO: Implement price filter
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pool),
              title: const Text('Có hồ bơi'),
              onTap: () {
                // TODO: Implement facility filter
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewDialog() {
    final reviewController = TextEditingController();
    int rating = 5;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm đánh giá'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() {
                      rating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reviewController,
              decoration: const InputDecoration(
                hintText: 'Nhập đánh giá của bạn...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await APIService.addCampsiteReview(
                  _selectedSpot!.id,
                  reviewController.text,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã thêm đánh giá thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi thêm đánh giá: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Gửi'),
          ),
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
    final results = campsites.where((spot) =>
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
    final suggestions = campsites.where((spot) =>
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