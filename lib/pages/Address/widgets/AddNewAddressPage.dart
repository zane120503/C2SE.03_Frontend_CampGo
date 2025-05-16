import 'dart:convert';
import 'package:CampGo/services/api_service.dart';
import 'package:CampGo/services/address_service.dart';
import 'package:CampGo/models/address_model.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

class AddNewAddressPage extends StatefulWidget {
  final List<AddressUser> existingAddresses;

  const AddNewAddressPage({
    super.key,
    required this.existingAddresses,
  });

  @override
  _AddNewAddressPageState createState() => _AddNewAddressPageState();
}

class _AddNewAddressPageState extends State<AddNewAddressPage> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _countryController = TextEditingController();
  bool isDefaultAddress = false;
  String selectedState = '';
  String selectedCity = '';
  String selectedWard = '';
  String selectedCountry = '';
  final _formKey = GlobalKey<FormState>();
  
  // Danh sách địa chỉ sẽ được lấy từ API
  List<String> _states = [];
  List<String> _districts = [];
  List<String> _wards = [];
  bool _isLoading = false;

  final APIService apiService = APIService();
  final AddressService addressService = AddressService();

  @override
  void initState() {
    super.initState();
    _loadAddressData();
  }

  Future<void> _loadAddressData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy danh sách tỉnh/thành phố
      final provinces = await addressService.getProvinces();
      setState(() {
        _states = provinces;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading address data: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải dữ liệu địa chỉ. Vui lòng thử lại sau.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadDistricts(String provinceName) async {
    if (provinceName.isEmpty) return;

    setState(() {
      _isLoading = true;
      _districts = [];
      _wards = [];
      selectedCity = '';
      selectedWard = '';
    });

    try {
      final districts = await addressService.getDistricts(provinceName);
      setState(() {
        _districts = districts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading districts: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải danh sách quận/huyện. Vui lòng thử lại sau.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadWards(String districtName) async {
    if (districtName.isEmpty) return;

    setState(() {
      _isLoading = true;
      _wards = [];
      selectedWard = '';
    });

    try {
      final wards = await addressService.getWards(districtName);
      setState(() {
        _wards = wards;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading wards: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải danh sách phường/xã. Vui lòng thử lại sau.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _submitAddress() {
    if (_fullNameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _streetController.text.isEmpty ||
        selectedState.isEmpty ||
        selectedCity.isEmpty ||
        _countryController.text.isEmpty ||
        _zipCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all information',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Kiểm tra zip code chỉ chứa số
    if (!RegExp(r'^[0-9]+$').hasMatch(_zipCodeController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Postal code must contain only numbers',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Kiểm tra country chỉ chứa chữ cái
    if (!RegExp(r'^[a-zA-ZÀ-ỹ\s]+$').hasMatch(_countryController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Country name must contain only letters',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final addressData = {
      'fullName': _fullNameController.text,
      'phoneNumber': _phoneController.text,
      'street': _streetController.text,
      'city': selectedState, // Tỉnh/Thành phố
      'district': selectedCity, // Quận/Huyện
      'ward': selectedWard, // Phường/Xã
      'country': _countryController.text,
      'zipCode': _zipCodeController.text,
      'isDefault': isDefaultAddress,
    };

    print('Sending address data: $addressData');
    Navigator.pop(context, addressData);
  }

  // Hàm lấy zip code dựa trên tỉnh/thành phố
  String _getZipCodeByCity(String city) {
    // Danh sách zip code cho các tỉnh/thành phố chính
    Map<String, String> cityZipCodes = {
      'Hà Nội': '100000',
      'TP Hồ Chí Minh': '700000',
      'Đà Nẵng': '550000',
      'Hải Phòng': '180000',
      'Cần Thơ': '900000',
      'Bình Dương': '590000',
      'Đồng Nai': '760000',
      'Bà Rịa - Vũng Tàu': '790000',
      'Hải Dương': '170000',
      'Thái Bình': '410000',
      'Nam Định': '420000',
      'Ninh Bình': '430000',
      'Thanh Hóa': '440000',
      'Nghệ An': '460000',
      'Hà Tĩnh': '480000',
      'Quảng Bình': '510000',
      'Quảng Trị': '520000',
      'Thừa Thiên Huế': '530000',
      'Quảng Nam': '560000',
      'Quảng Ngãi': '570000',
      'Bình Định': '590000',
      'Phú Yên': '620000',
      'Khánh Hòa': '650000',
      'Ninh Thuận': '660000',
      'Bình Thuận': '770000',
      'Kon Tum': '580000',
      'Gia Lai': '600000',
      'Đắk Lắk': '630000',
      'Đắk Nông': '640000',
      'Lâm Đồng': '670000',
      'Bình Phước': '830000',
      'Tây Ninh': '840000',
      'Bến Tre': '860000',
      'Trà Vinh': '870000',
      'Vĩnh Long': '890000',
      'Đồng Tháp': '930000',
      'An Giang': '950000',
      'Kiên Giang': '960000',
      'Cà Mau': '970000',
      'Bạc Liêu': '980000',
      'Sóc Trăng': '990000',
    };

    return cityZipCodes[city] ?? '000000';
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
          'Thêm địa chỉ mới',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'Thông tin liên hệ',
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
                            controller: _fullNameController,
                            label: 'Họ và tên',
                            showDivider: true,
                          ),
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Số điện thoại',
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Địa chỉ',
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
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownSearch<String>(
                                  popupProps: PopupProps.menu(
                                    showSearchBox: true,
                                    searchFieldProps: TextFieldProps(
                                      decoration: InputDecoration(
                                        hintText: "Tìm kiếm tỉnh/thành phố",
                                        prefixIcon: Icon(Icons.search),
                                      ),
                                    ),
                                    showSelectedItems: true,
                                  ),
                                  items: _states,
                                  dropdownDecoratorProps: DropDownDecoratorProps(
                                    dropdownSearchDecoration: InputDecoration(
                                      labelText: "Tỉnh/Thành phố",
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  onChanged: (String? value) {
                                    setState(() {
                                      selectedState = value ?? '';
                                      selectedCity = '';
                                      selectedWard = '';
                                    });
                                    if (value != null) {
                                      _loadDistricts(value);
                                    }
                                  },
                                  selectedItem: selectedState,
                                ),
                                const SizedBox(height: 16),
                                DropdownSearch<String>(
                                  enabled: selectedState.isNotEmpty && !_isLoading,
                                  popupProps: PopupProps.menu(
                                    showSearchBox: true,
                                    searchFieldProps: TextFieldProps(
                                      decoration: InputDecoration(
                                        hintText: "Tìm kiếm quận/huyện",
                                        prefixIcon: Icon(Icons.search),
                                      ),
                                    ),
                                    showSelectedItems: true,
                                  ),
                                  items: _districts,
                                  dropdownDecoratorProps: DropDownDecoratorProps(
                                    dropdownSearchDecoration: InputDecoration(
                                      labelText: "Quận/Huyện",
                                      border: OutlineInputBorder(),
                                      enabled: selectedState.isNotEmpty && !_isLoading,
                                    ),
                                  ),
                                  onChanged: (String? value) {
                                    setState(() {
                                      selectedCity = value ?? '';
                                      selectedWard = '';
                                    });
                                    if (value != null) {
                                      _loadWards(value);
                                    }
                                  },
                                  selectedItem: selectedCity,
                                ),
                                const SizedBox(height: 16),
                                DropdownSearch<String>(
                                  enabled: selectedCity.isNotEmpty && !_isLoading,
                                  popupProps: PopupProps.menu(
                                    showSearchBox: true,
                                    searchFieldProps: TextFieldProps(
                                      decoration: InputDecoration(
                                        hintText: "Tìm kiếm phường/xã",
                                        prefixIcon: Icon(Icons.search),
                                      ),
                                    ),
                                    showSelectedItems: true,
                                  ),
                                  items: _wards,
                                  dropdownDecoratorProps: DropDownDecoratorProps(
                                    dropdownSearchDecoration: InputDecoration(
                                      labelText: "Phường/Xã",
                                      border: OutlineInputBorder(),
                                      enabled: selectedCity.isNotEmpty && !_isLoading,
                                    ),
                                  ),
                                  onChanged: (String? value) {
                                    setState(() {
                                      selectedWard = value ?? '';
                                    });
                                  },
                                  selectedItem: selectedWard,
                                ),
                              ],
                            ),
                          ),
                          _buildTextField(
                            controller: _streetController,
                            label: 'Số nhà, tên đường',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Set as default address'),
                          Switch(
                            value: isDefaultAddress,
                            onChanged: (value) {
                              setState(() {
                                isDefaultAddress = value;
                              });
                            },
                            activeColor: Colors.red,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _countryController,
                      decoration: InputDecoration(
                        labelText: 'Country',
                        hintText: 'Enter country name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.flag),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter country name';
                        }
                        if (!RegExp(r'^[a-zA-ZÀ-ỹ\s]+$').hasMatch(value)) {
                          return 'Country name must contain only letters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _zipCodeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Postal code',
                        hintText: 'Enter postal code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.local_post_office),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter postal code';
                        }
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return 'Postal code must contain only numbers';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitAddress,
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
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool showDivider = false,
    TextInputType? keyboardType,
  }) {
    return Column(
                children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: label,
              border: InputBorder.none,
              labelStyle: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }
}
