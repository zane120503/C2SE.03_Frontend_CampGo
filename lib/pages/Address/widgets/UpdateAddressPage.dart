import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:CampGo/services/api_service.dart';
import 'package:CampGo/services/address_service.dart';
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
  final AddressService _addressService = AddressService();
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _streetController;
  late TextEditingController _countryController;
  late TextEditingController _zipCodeController;
  bool isDefaultAddress = false;
  String selectedState = '';
  String selectedCity = '';
  String selectedWard = '';
  String selectedCountry = '';
  
  // Danh sách địa chỉ sẽ được lấy từ API
  List<String> _states = [];
  List<String> _districts = [];
  List<String> _wards = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.address.fullName);
    _phoneController = TextEditingController(text: widget.address.phoneNumber);
    _streetController = TextEditingController(text: widget.address.street);
    _countryController = TextEditingController(text: widget.address.country);
    _zipCodeController = TextEditingController(text: widget.address.zipCode);
    isDefaultAddress = widget.address.isDefault;
    selectedState = widget.address.city;
    selectedCity = widget.address.district;
    selectedWard = widget.address.ward;
    selectedCountry = widget.address.country;

    _loadAddressData();
  }

  Future<void> _loadAddressData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provinces = await _addressService.getProvinces();
      setState(() {
        _states = provinces;
        _isLoading = false;
      });
      
      // Load districts và wards nếu đã có dữ liệu
      if (selectedState.isNotEmpty) {
        await _loadDistricts(selectedState);
      }
      if (selectedCity.isNotEmpty) {
        await _loadWards(selectedCity);
      }
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
      final districts = await _addressService.getDistricts(provinceName);
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
      final wards = await _addressService.getWards(districtName);
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
        SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin',
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
          content: Text('Mã bưu điện phải chỉ chứa số',
          textAlign: TextAlign.center,),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Kiểm tra country chỉ chứa chữ cái
    if (!RegExp(r'^[a-zA-ZÀ-ỹ\s]+$').hasMatch(_countryController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tên quốc gia chỉ được chứa chữ cái',
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
          content: Text(
            'Số điện thoại phải có đúng 10 chữ số',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
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
            content: Text(
              'Cập nhật địa chỉ thành công!',
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, addressData);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không thể cập nhật địa chỉ',
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi: $e',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cập nhật địa chỉ',
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
                          const Text('Đặt làm địa chỉ mặc định'),
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
                        labelText: 'Quốc gia',
                        hintText: 'Nhập tên quốc gia',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.flag),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên quốc gia';
                        }
                        if (!RegExp(r'^[a-zA-ZÀ-ỹ\s]+$').hasMatch(value)) {
                          return 'Tên quốc gia chỉ được chứa chữ cái';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _zipCodeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Mã bưu điện',
                        hintText: 'Nhập mã bưu điện',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.local_post_office),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mã bưu điện';
                        }
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return 'Mã bưu điện phải chỉ chứa số';
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cập nhật',
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
    _countryController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }
}
