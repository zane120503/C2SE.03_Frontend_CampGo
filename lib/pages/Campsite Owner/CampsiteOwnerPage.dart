import 'package:flutter/material.dart';
import 'package:CampGo/models/campsite_owner_model.dart';
import 'package:CampGo/services/api_service.dart';
import 'widgets/NewCampsiteOwner.dart';
import 'widgets/UpdateCampsiteOwner.dart';

class CampsiteOwnerPage extends StatefulWidget {
  @override
  _CampsiteOwnerPageState createState() => _CampsiteOwnerPageState();
}

class _CampsiteOwnerPageState extends State<CampsiteOwnerPage> {
  List<CampsiteOwnerModel> campsites = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCampsites();
  }

  Future<void> _loadCampsites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await APIService.getMyCampsites();
      setState(() {
        campsites = data.map<CampsiteOwnerModel>((e) => CampsiteOwnerModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addNewCampsite() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewCampsiteOwnerPage()),
    );
    if (result == true) {
      _loadCampsites();
    }
  }

  Future<void> _editCampsite(CampsiteOwnerModel campsite) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateCampsiteOwnerPage(campsite: campsite),
      ),
    );
    if (result == true) {
      _loadCampsites();
    }
  }

  Future<void> _deleteCampsite(String? campsiteId) async {
    if (campsiteId == null) return;
    try {
      final result = await APIService.deleteCampsite(campsiteId);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
              child: Text(
                'Delete campsite successfully!',
                textAlign: TextAlign.center,
              ),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.fixed,
            margin: null,
            shape: RoundedRectangleBorder(),
          ),
        );
        _loadCampsites();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
              child: Text(
                result['message'] ?? 'Delete campsite failed!',
                textAlign: TextAlign.center,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.fixed,
            margin: null,
            shape: RoundedRectangleBorder(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              'Error: ${e.toString()}',
              textAlign: TextAlign.center,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.fixed,
          margin: null,
          shape: RoundedRectangleBorder(),
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58.0),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 30, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Manage Campsite',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
        ),
      ),
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFEDECF2),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: Container(
            margin: const EdgeInsets.only(top: 10),
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.red,
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading campsite list...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Error: $_error',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: campsites.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.landscape,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'No campsite',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Add new campsite to start',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : SingleChildScrollView(
                                    padding: EdgeInsets.only(
                                      top: 10,
                                      left: 16,
                                      right: 16,
                                      bottom: 16,
                                    ),
                                    child: Column(
                                      children: campsites.map((campsite) {
                                        return Dismissible(
                                          key: Key(campsite.id ?? DateTime.now().toString()),
                                          direction: DismissDirection.endToStart,
                                          background: Container(
                                            margin: EdgeInsets.only(bottom: 16),
                                            alignment: Alignment.centerRight,
                                            padding: EdgeInsets.only(right: 20),
                                            decoration: BoxDecoration(
                                              color: Colors.red[100],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                          ),
                                          confirmDismiss: (direction) async {
                                            return await showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text('Confirm delete'),
                                                content: Text('Are you sure you want to delete this campsite?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.of(context).pop(false),
                                                    child: Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.of(context).pop(true),
                                                    child: Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          onDismissed: (direction) => _deleteCampsite(campsite.id),
                                          child: Card(
                                            margin: EdgeInsets.only(bottom: 16),
                                            elevation: 2,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          campsite.name ?? 'No name',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                      InkWell(
                                                        onTap: () => _editCampsite(campsite),
                                                        child: Icon(
                                                          Icons.edit,
                                                          size: 22,
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    campsite.location,
                                                    style: TextStyle(
                                                      color: Colors.black87,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children: campsite.facilities.map((facility) => Chip(
                                                      label: Text(facility),
                                                      backgroundColor: Colors.red.withOpacity(0.1),
                                                      labelStyle: TextStyle(color: Colors.red, fontSize: 12),
                                                    )).toList(),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Camping site • ' +
                                                      ((campsite.minPrice == 0 && campsite.maxPrice == 0)
                                                        ? 'Free'
                                                        : '${formatPrice(campsite.minPrice)} - ${formatPrice(campsite.maxPrice)} USD'),
                                                    style: TextStyle(
                                                      color: (campsite.minPrice == 0 && campsite.maxPrice == 0)
                                                          ? Colors.green
                                                          : Colors.black87,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text('Phone number: ${campsite.phone}', style: TextStyle(fontSize: 14)),
                                                  if (campsite.email.isNotEmpty)
                                                    Text('Email: ${campsite.email}', style: TextStyle(fontSize: 14)),
                                                  if (campsite.website.isNotEmpty)
                                                    Text('Website: ${campsite.website}', style: TextStyle(fontSize: 14)),
                                                  if (campsite.openHour.isNotEmpty && campsite.closeHour.isNotEmpty)
                                                    Text('Open hours: ${campsite.openHour} - ${campsite.closeHour}', style: TextStyle(fontSize: 14)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                          ),
                          Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                            child: SizedBox(
                              width: 200,
                              child: ElevatedButton.icon(
                                onPressed: _addNewCampsite,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                icon: Icon(Icons.add, color: Colors.white),
                                label: Text(
                                  'Add new campsite',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}
