import 'package:flutter/material.dart';
import 'package:CampGo/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class NewCampsiteOwnerPage extends StatefulWidget {
  @override
  State<NewCampsiteOwnerPage> createState() => _NewCampsiteOwnerPageState();
}

class _NewCampsiteOwnerPageState extends State<NewCampsiteOwnerPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _openHourController = TextEditingController();
  final TextEditingController _closeHourController = TextEditingController();
  List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();
  List<TextEditingController> _facilitiesControllers = [TextEditingController()];

  @override
  void initState() {
    super.initState();
    _openHourController.addListener(() {
      final text = _openHourController.text;
      if (text.length == 2 && !text.contains(':')) {
        _openHourController.text = text + ':';
        _openHourController.selection = TextSelection.fromPosition(TextPosition(offset: _openHourController.text.length));
      }
    });
    _closeHourController.addListener(() {
      final text = _closeHourController.text;
      if (text.length == 2 && !text.contains(':')) {
        _closeHourController.text = text + ':';
        _closeHourController.selection = TextSelection.fromPosition(TextPosition(offset: _closeHourController.text.length));
      }
    });
  }

  Future<void> _pickImages() async {
    final List<XFile>? picked = await _picker.pickMultiImage();
    if (picked != null && picked.isNotEmpty) {
      // Lọc chỉ giữ file jpg, jpeg, png
      final validImages = picked.where((x) {
        final ext = x.name.toLowerCase();
        return ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png');
      }).toList();
      if (validImages.length != picked.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Only photos accepted jpg, jpeg, png!',
            textAlign: TextAlign.center,
            ), // Thêm dòng này    
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _images = validImages;
      });
    }
  }

  void _addFacilityField() {
    setState(() {
      _facilitiesControllers.add(TextEditingController());
    });
  }

  void _removeFacilityField(int index) {
    setState(() {
      if (_facilitiesControllers.length > 1) {
        _facilitiesControllers.removeAt(index);
      }
    });
  }

  String formatPrice(dynamic price) {
    if (price == null) return '0';
    if (price is int) return '${price.toString()}';
    if (price is double) return '${price.toStringAsFixed(0)}';
    if (price is String) return '${double.tryParse(price)?.toStringAsFixed(0) ?? '0'}';
    return '${price.toString()}';
  }

  Future<void> _submitCampsite() async {
    if (_formKey.currentState!.validate()) {
      final minPrice = _minPriceController.text.trim().isEmpty ? 0.0 : double.tryParse(_minPriceController.text.trim()) ?? 0.0;
      final maxPrice = _maxPriceController.text.trim().isEmpty ? 0.0 : double.tryParse(_maxPriceController.text.trim()) ?? 0.0;
      if (minPrice > maxPrice) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(child: Text('Minimum price must be less than maximum price', textAlign: TextAlign.center)),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      try {
        final facilities = _facilitiesControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
        final images = _images.map((x) => File(x.path)).toList();
        final result = await APIService.createOrUpdateCampsiteOwner(
          name: _nameController.text.trim(),
          location: _locationController.text.trim(),
          latitude: double.tryParse(_latitudeController.text.trim().replaceAll(',', '.')) ?? 0,
          longitude: double.tryParse(_longitudeController.text.trim().replaceAll(',', '.')) ?? 0,
          description: _descriptionController.text.trim(),
          facilities: facilities,
          minPrice: minPrice,
          maxPrice: maxPrice,
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          website: _websiteController.text.trim(),
          openHour: _openHourController.text.trim(),
          closeHour: _closeHourController.text.trim(),
          images: images,
        );
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Center(
                child: Text(
                  'Add campsite successfully!',
                  textAlign: TextAlign.center,
                ),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.fixed,
              margin: null,
              shape: RoundedRectangleBorder(),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Center(
                child: Text(
                  result['message'] ?? 'Add campsite failed!',
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add new campsite',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFEDECF2),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Basic information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: 'Campsite Name',
                        showDivider: true,
                        validator: (value) => value == null || value.isEmpty ? 'Please enter the name' : null,
                      ),
                      _buildTextField(
                        controller: _locationController,
                        label: 'Address',
                        showDivider: true,
                        validator: (value) => value == null || value.isEmpty ? 'Please enter the address' : null,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _latitudeController,
                              label: 'Latitude',
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              validator: (value) => value == null || value.isEmpty ? 'Please enter the latitude' : null,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _longitudeController,
                              label: 'Longitude',
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              validator: (value) => value == null || value.isEmpty ? 'Please enter the longitude' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Description and facilities',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        maxLines: 3,
                        showDivider: true,
                        validator: (value) => value == null || value.isEmpty ? 'Please enter the description' : null,
                      ),
                      Column(
                        children: [
                          for (int i = 0; i < _facilitiesControllers.length; i++)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _facilitiesControllers[i],
                                    label: 'Facility ${i + 1}',
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: _facilitiesControllers.length > 1
                                      ? () => _removeFacilityField(i)
                                      : null,
                                ),
                              ],
                            ),
                          if (_facilitiesControllers.any((c) => c.text.trim().isNotEmpty))
                            Wrap(
                              spacing: 8,
                              children: _facilitiesControllers
                                  .where((c) => c.text.trim().isNotEmpty)
                                  .map((c) => Chip(label: Text(c.text.trim())))
                                  .toList(),
                            ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _addFacilityField,
                              icon: Icon(Icons.add),
                              label: Text('Add facility'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Contact information and price',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _minPriceController,
                              label: 'Minimum price',
                              keyboardType: TextInputType.text,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z\s]')),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _maxPriceController,
                              label: 'Maximum price',
                              keyboardType: TextInputType.text,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z\s]')),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if ((_minPriceController.text.trim().isNotEmpty || _maxPriceController.text.trim().isNotEmpty))
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Camping site • ' +
                              ((_minPriceController.text.trim().isEmpty && _maxPriceController.text.trim().isEmpty)
                                ? 'Free'
                                : '${formatPrice(double.tryParse(_minPriceController.text.trim()) ?? 0)} - '
                                  '${formatPrice(double.tryParse(_maxPriceController.text.trim()) ?? 0)} USD'),
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone number',
                        keyboardType: TextInputType.phone,
                        showDivider: true,
                        validator: (value) {
                          if (value != null && value.isNotEmpty && value.length > 10) {
                            return 'Phone number cannot be more than 10 digits';
                          }
                          return null;
                        },
                      ),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        showDivider: true,
                      ),
                      _buildTextField(
                        controller: _websiteController,
                        label: 'Website',
                        keyboardType: TextInputType.url,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Open hours',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _openHourController,
                          label: 'Open hours',
                          keyboardType: TextInputType.text,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z:]')),
                          ],
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final regex = RegExp(r'^(\d{2}):(\d{2})$');
                              if (RegExp(r'^[0-9:]+$').hasMatch(value)) {
                                if (!regex.hasMatch(value)) {
                                  return 'Invalid time format. Format: HH:mm';
                                }
                                final parts = value.split(':');
                                final h = int.tryParse(parts[0]) ?? -1;
                                final m = int.tryParse(parts[1]) ?? -1;
                                if (h < 0 || h > 23 || m < 0 || m > 59) {
                                  return 'Invalid time format. Format: 00-23:00-59';
                                }
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _closeHourController,
                          label: 'Close hours',
                          keyboardType: TextInputType.text,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z:]')),
                          ],
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final regex = RegExp(r'^(\d{2}):(\d{2})$');
                              if (RegExp(r'^[0-9:]+$').hasMatch(value)) {
                                if (!regex.hasMatch(value)) {
                                  return 'Invalid time format. Format: HH:mm';
                                }
                                final parts = value.split(':');
                                final h = int.tryParse(parts[0]) ?? -1;
                                final m = int.tryParse(parts[1]) ?? -1;
                                if (h < 0 || h > 23 || m < 0 || m > 59) {
                                  return 'Invalid time format. Format: 00-23:00-59';
                                }
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Images',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: Icon(Icons.add_a_photo),
                        label: Text('Choose image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 180, 180, 180),
                        ),
                      ),
                      SizedBox(height: 12),
                      _images.isEmpty
                          ? Text('No image selected')
                          : SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _images.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: Image.file(
                                          File(_images[index].path),
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
                                              _images.removeAt(index);
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
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitCampsite,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Complete',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool showDivider = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              labelText: label,
              border: InputBorder.none,
              labelStyle: TextStyle(color: Colors.grey[600]),
            ),
            validator: validator,
            inputFormatters: inputFormatters,
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }

  @override
  void dispose() {
    for (var c in _facilitiesControllers) {
      c.dispose();
    }
    _nameController.dispose();
    _locationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _descriptionController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _openHourController.dispose();
    _closeHourController.dispose();
    super.dispose();
  }
}
