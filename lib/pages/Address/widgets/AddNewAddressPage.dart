import 'dart:convert';
import 'package:CampGo/services/api_service.dart';
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
  
  // Danh sách tỉnh thành
  List<String> _states = [
    'Hà Nội', 'TP Hồ Chí Minh', 'Đà Nẵng', 'Hải Phòng', 'Cần Thơ',
    'An Giang', 'Bà Rịa - Vũng Tàu', 'Bắc Giang', 'Bắc Kạn', 'Bạc Liêu',
    'Bắc Ninh', 'Bến Tre', 'Bình Định', 'Bình Dương', 'Bình Phước',
    'Bình Thuận', 'Cà Mau', 'Cao Bằng', 'Đắk Lắk', 'Đắk Nông',
    'Điện Biên', 'Đồng Nai', 'Đồng Tháp', 'Gia Lai', 'Hà Giang',
    'Hà Nam', 'Hà Tĩnh', 'Hải Dương', 'Hậu Giang', 'Hòa Bình',
    'Hưng Yên', 'Khánh Hòa', 'Kiên Giang', 'Kon Tum', 'Lai Châu',
    'Lâm Đồng', 'Lạng Sơn', 'Lào Cai', 'Long An', 'Nam Định',
    'Nghệ An', 'Ninh Bình', 'Ninh Thuận', 'Phú Thọ', 'Phú Yên',
    'Quảng Bình', 'Quảng Nam', 'Quảng Ngãi', 'Quảng Ninh', 'Quảng Trị',
    'Sóc Trăng', 'Sơn La', 'Tây Ninh', 'Thái Bình', 'Thái Nguyên',
    'Thanh Hóa', 'Thừa Thiên Huế', 'Tiền Giang', 'Trà Vinh', 'Tuyên Quang',
    'Vĩnh Long', 'Vĩnh Phúc', 'Yên Bái'
  ];

  // Map quận/huyện theo tỉnh thành
  Map<String, List<String>> _citiesByState = {
    'Hà Nội': [
      'Ba Đình', 'Hoàn Kiếm', 'Hai Bà Trưng', 'Đống Đa', 'Tây Hồ', 'Cầu Giấy', 
      'Thanh Xuân', 'Hoàng Mai', 'Long Biên', 'Nam Từ Liêm', 'Bắc Từ Liêm', 'Hà Đông',
      'Sơn Tây', 'Ba Vì', 'Chương Mỹ', 'Đan Phượng', 'Đông Anh', 'Gia Lâm',
      'Hoài Đức', 'Mê Linh', 'Mỹ Đức', 'Phú Xuyên', 'Phúc Thọ', 'Quốc Oai',
      'Sóc Sơn', 'Thạch Thất', 'Thanh Oai', 'Thanh Trì', 'Thường Tín', 'Ứng Hòa'
    ],
    'TP Hồ Chí Minh': [
      'Quận 1', 'Quận 3', 'Quận 4', 'Quận 5', 'Quận 6', 'Quận 7', 'Quận 8',
      'Quận 10', 'Quận 11', 'Quận 12', 'Quận Bình Tân', 'Quận Bình Thạnh',
      'Quận Gò Vấp', 'Quận Phú Nhuận', 'Quận Tân Bình', 'Quận Tân Phú',
      'Thành phố Thủ Đức', 'Huyện Bình Chánh', 'Huyện Cần Giờ', 'Huyện Củ Chi',
      'Huyện Hóc Môn', 'Huyện Nhà Bè'
    ],
    'Đà Nẵng': [
      'Hải Châu', 'Thanh Khê', 'Sơn Trà', 'Ngũ Hành Sơn', 'Liên Chiểu', 
      'Cẩm Lệ', 'Hòa Vang', 'Hoàng Sa'
    ],
  };

  // Map phường/xã theo quận/huyện
  Map<String, List<String>> _wardsByCity = {
    'Hải Châu': [
      'Phường Hải Châu 1', 'Phường Hải Châu 2', 'Phường Nam Dương', 
      'Phường Phước Ninh', 'Phường Bình Hiên', 'Phường Bình Thuận',
      'Phường Hòa Thuận Đông', 'Phường Hòa Thuận Tây', 'Phường Thạch Thang',
      'Phường Thanh Bình', 'Phường Thuận Phước', 'Phường Hòa Cường Bắc',
      'Phường Hòa Cường Nam'
    ],
    'Thanh Khê': [
      'Phường An Khê', 'Phường Chính Gián', 'Phường Hòa Khê', 
      'Phường Tam Thuận', 'Phường Tân Chính', 'Phường Thạc Gián',
      'Phường Thanh Khê Đông', 'Phường Thanh Khê Tây', 'Phường Vĩnh Trung',
      'Phường Xuân Hà'
    ],
    // Thêm các phường/xã khác cho các quận/huyện khác
  };

  final APIService apiService = APIService();

  @override
  void initState() {
    super.initState();
    _loadAddressData();
  }

  Future<void> _loadAddressData() async {
    try {
      final response = await apiService.getAddresses();
      if (response['success'] == true) {
        setState(() {
          if (response['data']['provinces'] != null) {
            _states = List<String>.from(response['data']['provinces']);
          }
          if (response['data']['districts'] != null) {
            _citiesByState = Map<String, List<String>>.from(
              response['data']['districts'].map((key, value) => MapEntry(
                key,
                List<String>.from(value),
              )),
            );
          }
        });
      }
    } catch (e) {
      print('Error loading address data: $e');
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
          content: Text('Please fill in all information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Kiểm tra zip code chỉ chứa số
    if (!RegExp(r'^[0-9]+$').hasMatch(_zipCodeController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Postal code must contain only numbers'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Kiểm tra country chỉ chứa chữ cái
    if (!RegExp(r'^[a-zA-ZÀ-ỹ\s]+$').hasMatch(_countryController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Country name must contain only letters'),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add new address',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
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
                  'Contact information',
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
                        label: 'Full name',
                        showDivider: true,
                      ),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone number',
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Address',
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
                                    hintText: "Search Province/City",
                                    prefixIcon: Icon(Icons.search),
                                  ),
                                ),
                                showSelectedItems: true,
                              ),
                              items: _states,
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: "Province/City",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              onChanged: (String? value) {
                                setState(() {
                                  selectedState = value ?? '';
                                  selectedCity = '';
                                  selectedWard = '';
                                });
                              },
                              selectedItem: selectedState,
                            ),
                            const SizedBox(height: 16),
                            DropdownSearch<String>(
                              enabled: selectedState.isNotEmpty,
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                searchFieldProps: TextFieldProps(
                                  decoration: InputDecoration(
                                    hintText: "Search District/County",
                                    prefixIcon: Icon(Icons.search),
                                  ),
                                ),
                                showSelectedItems: true,
                              ),
                              items: _citiesByState[selectedState] ?? [],
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: "District/County",
                                  border: OutlineInputBorder(),
                                  enabled: selectedState.isNotEmpty,
                                ),
                              ),
                              onChanged: (String? value) {
                                setState(() {
                                  selectedCity = value ?? '';
                                  selectedWard = '';
                                });
                              },
                              selectedItem: selectedCity,
                            ),
                            const SizedBox(height: 16),
                            DropdownSearch<String>(
                              enabled: selectedCity.isNotEmpty,
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                searchFieldProps: TextFieldProps(
                                  decoration: InputDecoration(
                                    hintText: "Search Ward/Village",
                                    prefixIcon: Icon(Icons.search),
                                  ),
                                ),
                                showSelectedItems: true,
                              ),
                              items: _wardsByCity[selectedCity] ?? [],
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: "Ward/Village",
                                  border: OutlineInputBorder(),
                                  enabled: selectedCity.isNotEmpty,
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
                        label: 'House number, Street name',
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
