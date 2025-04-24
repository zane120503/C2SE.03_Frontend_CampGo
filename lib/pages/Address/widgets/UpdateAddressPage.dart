import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:CampGo/services/api_service.dart';
import 'package:CampGo/models/address_model.dart';

class UpdateAddressPage extends StatefulWidget {
  final AddressUser address;

  const UpdateAddressPage({
    super.key,
    required this.address,
  });

  @override
  _UpdateAddressPageState createState() => _UpdateAddressPageState();
}

class _UpdateAddressPageState extends State<UpdateAddressPage> {
  final APIService _apiService = APIService();
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _countryController;
  late TextEditingController _zipCodeController;
  late TextEditingController _wardController;
  bool isDefaultAddress = false;
  String selectedState = '';
  String selectedCity = '';
  String selectedWard = '';
  String selectedCountry = '';

  // Danh sách tỉnh thành
  final List<String> _states = [
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
  final Map<String, List<String>> _citiesByState = {
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
    'Sơn Trà': [
      'Phường An Hải Bắc', 'Phường An Hải Đông', 'Phường An Hải Tây',
      'Phường Mân Thái', 'Phường Nại Hiên Đông', 'Phường Phước Mỹ',
      'Phường Thọ Quang'
    ],
    'Ngũ Hành Sơn': [
      'Phường Hòa Hải', 'Phường Hòa Quý', 'Phường Khuê Mỹ',
      'Phường Mỹ An'
    ],
    'Liên Chiểu': [
      'Phường Hòa Hiệp Bắc', 'Phường Hòa Hiệp Nam', 'Phường Hòa Khánh Bắc',
      'Phường Hòa Khánh Nam', 'Phường Hòa Minh'
    ],
    'Cẩm Lệ': [
      'Phường Hòa An', 'Phường Hòa Phát', 'Phường Hòa Thọ Đông',
      'Phường Hòa Thọ Tây', 'Phường Hòa Xuân', 'Phường Khuê Trung'
    ],
  };

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.address.fullName);
    _phoneController = TextEditingController(text: widget.address.phoneNumber);
    _streetController = TextEditingController(text: widget.address.street);
    _cityController = TextEditingController(text: widget.address.city);
    _countryController = TextEditingController(text: widget.address.country);
    _zipCodeController = TextEditingController(text: widget.address.zipCode);
    _wardController = TextEditingController(text: widget.address.ward);
    isDefaultAddress = widget.address.isDefault;
    selectedState = widget.address.city; // city là Tỉnh/Thành phố
    selectedCity = widget.address.district; // district là Quận/Huyện
    selectedWard = widget.address.ward; // Lấy phường/xã đã chọn trước đó
    selectedCountry = widget.address.country;

    // Đảm bảo danh sách phường/xã được load khi khởi tạo
    if (selectedCity.isNotEmpty && !_wardsByCity.containsKey(selectedCity)) {
      _wardsByCity[selectedCity] = [selectedWard];
    }
  }

  Future<void> _updateAddress() async {
    if (_fullNameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _streetController.text.isEmpty ||
        selectedState.isEmpty ||
        selectedCity.isEmpty ||
        selectedWard.isEmpty ||
        _countryController.text.isEmpty ||
        _zipCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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
        const SnackBar(
          content: Text('Zip code must contain only numbers',
          textAlign: TextAlign.center,),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Kiểm tra country chỉ chứa chữ cái
    if (!RegExp(r'^[a-zA-ZÀ-ỹ\s]+$').hasMatch(_countryController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Country name must contain only letters',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Kiểm tra số điện thoại có đúng 10 chữ số
    if (!RegExp(r'^[0-9]{10}$').hasMatch(_phoneController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              'Phone number must contain exactly 10 digits',
              textAlign: TextAlign.center,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.fixed,
          margin: null,
          shape: RoundedRectangleBorder(),
        ),
      );
      return;
    }

    try {
      Map<String, dynamic> addressData = {
        'fullName': _fullNameController.text,
        'phoneNumber': _phoneController.text,
        'street': _streetController.text,
        'city': selectedState,
        'district': selectedCity,
        'ward': selectedWard,
        'country': _countryController.text,
        'zipCode': _zipCodeController.text,
        'isDefault': isDefaultAddress,
      };

      final response = await _apiService.updateAddress(widget.address.id, addressData);
      
      if (response) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
              child: Text(
                'Update address successfully!',
                textAlign: TextAlign.center,
              ),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.fixed,
            margin: null,
            shape: RoundedRectangleBorder(),
          ),
        );
        Navigator.pop(context, addressData);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
              child: Text(
                'Cannot update address',
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
              'Error: $e',
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
          onPressed: () {
            Navigator.pop(context, {
              'fullName': _fullNameController.text,
              'phoneNumber': _phoneController.text,
              'street': _streetController.text,
              'city': selectedState,
              'state': selectedCity,
              'ward': selectedWard,
              'country': _countryController.text,
              'zipCode': _zipCodeController.text,
              'isDefault': isDefaultAddress,
            });
          },
        ),
        title: const Text(
          'Update Address',
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
                  borderRadius: BorderRadius.circular(8),
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
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                          return 'Phone number must contain exactly 10 digits';
                        }
                        return null;
                      },
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
                  borderRadius: BorderRadius.circular(8),
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
                                  hintText: "Search for province/City",
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
                                  hintText: "Search for district/County",
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
                                  hintText: "Search for ward/Village",
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
                  borderRadius: BorderRadius.circular(8),
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
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                onPressed: _updateAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Update',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
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
    FormFieldValidator<String>? validator,
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
    _cityController.dispose();
    _countryController.dispose();
    _zipCodeController.dispose();
    _wardController.dispose();
    super.dispose();
  }
}
