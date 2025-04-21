import 'package:CampGo/services/api_service.dart';
import 'package:CampGo/models/address_model.dart';
import 'package:CampGo/pages/Address/widgets/AddNewAddressPage.dart';
import 'package:CampGo/pages/Address/widgets/UpdateAddressPage.dart'; 
import 'package:CampGo/services/data_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class AddressPage extends StatefulWidget {
  const AddressPage({super.key});

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  List<AddressUser> addresses = [];
  final DataService dataService = DataService();
  final APIService apiService = APIService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadAddresses();
  }

  Future<void> _checkAuthAndLoadAddresses() async {
    final token = await dataService.getToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
              child: Text(
                'Please login to view address',
                textAlign: TextAlign.center,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.fixed,
            margin: null,
            shape: RoundedRectangleBorder(),
          ),
        );
        Navigator.pop(context);
      }
      return;
    }
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading addresses...'); // Debug log
      final token = await dataService.getToken();
      print('Current token: $token'); // Debug log

      final response = await apiService.getAddresses();
      print('Response from getAddresses: $response'); // Debug log
      
      if (response['success'] == true) {
        final List<dynamic> addressData = response['data'] ?? [];
        print('Address data: $addressData'); // Debug log
        
        setState(() {
          addresses = addressData.map((data) {
            print('Processing address with ward: ${data['ward']}'); // Debug log cho phường/xã
            return AddressUser(
              id: data['_id'] ?? '',
              userId: data['user_id'] ?? '',
              fullName: data['fullName'] ?? '',
              phoneNumber: data['phoneNumber'] ?? '',
              street: data['street'] ?? '',
              district: data['district'] ?? '',
              city: data['city'] ?? '',
              ward: data['ward'] ?? '', // Kiểm tra giá trị ward
              country: data['country'] ?? '',
              zipCode: data['zipCode'] ?? '',
              isDefault: data['isDefault'] ?? false,
              createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
              updatedAt: DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String()),
              v: data['__v'] ?? 0,
            );
          }).toList();
          print('Processed addresses with wards: ${addresses.map((a) => a.ward).toList()}'); // Debug log cho danh sách phường/xã
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Cannot load address list');
      }
    } catch (e) {
      print('Error loading addresses: $e');
      setState(() {
        addresses = [];
        _isLoading = false;
      });
      if (mounted) {
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

  void _deleteAddress(String addressId) async {
    try {
      bool success = await apiService.deleteAddress(addressId);
      if (success) {
        setState(() {
          addresses.removeWhere((address) => address.id == addressId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
              child: Text(
                'Address deleted successfully',
                textAlign: TextAlign.center,
              ),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.fixed,
            margin: null,
            shape: RoundedRectangleBorder(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
              child: Text(
                'Cannot delete address',
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

  void _setDefaultAddress(String addressId) async {
    try {
      bool success = await apiService.setDefaultAddress(addressId);
      if (success) {
        setState(() {
          addresses = addresses.map((address) {
            return AddressUser(
              id: address.id,
              userId: address.userId,
              fullName: address.fullName,
              phoneNumber: address.phoneNumber,
              street: address.street,
              district: address.district,
              city: address.city,
              ward: address.ward,
              country: address.country,
              zipCode: address.zipCode,
              isDefault: address.id == addressId,
              createdAt: address.createdAt,
              updatedAt: address.updatedAt,
              v: address.v,
            );
          }).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
              child: Text(
                'Address set as default',
                textAlign: TextAlign.center,
              ),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.fixed,
            margin: null,
            shape: RoundedRectangleBorder(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
              child: Text(
                'Cannot set address as default',
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

  Future<void> _updateAddress(AddressUser address) async {
    try {
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => UpdateAddressPage(address: address),
        ),
      );

      if (result != null) {
        // Validate required fields
        if (result['fullName']?.isEmpty ?? true ||
            result['phoneNumber']?.isEmpty ?? true ||
            result['street']?.isEmpty ?? true ||
            result['city']?.isEmpty ?? true ||
            result['district']?.isEmpty ?? true ||
            result['country']?.isEmpty ?? true ||
            result['zipCode']?.isEmpty ?? true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Center(
                child: Text(
                  'Please fill in all required information',
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
        
        Map<String, dynamic> addressData = {
          'fullName': result['fullName'],
          'phoneNumber': result['phoneNumber'],
          'street': result['street'],
          'city': result['city'],     
          'district': result['district'], 
          'ward': result['ward'],
          'country': result['country'],
          'zipCode': result['zipCode'],
          'isDefault': result['isDefault'] ?? false,
        };

        bool success = await apiService.updateAddress(address.id, addressData);

        if (success) {
          setState(() {
            int index = addresses.indexWhere((a) => a.id == address.id);
            if (index != -1) {
              addresses[index] = AddressUser(
                id: address.id,
                userId: address.userId,
                fullName: result['fullName'],
                phoneNumber: result['phoneNumber'],
                street: result['street'] ?? address.street,
                district: result['district'] ?? address.district,
                city: result['city'] ?? address.city,
                ward: result['ward'] ?? address.ward,
                country: result['country'],
                zipCode: result['zipCode'],
                isDefault: result['isDefault'] ?? false,
                createdAt: address.createdAt,
                updatedAt: DateTime.now(),
                v: address.v,
              );
              if (result['isDefault'] ?? false) {
                _setDefaultAddress(address.id);
              }
            }
          });
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
      }
    } catch (e) {
      print("Error updating address: $e");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58.0),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 30, color: Colors.black),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
          title: const Text(
            'Address',
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
                          'Loading address...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: addresses.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No address found',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Add a new address to start',
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
                                  children: addresses.map((address) {
                                    return Dismissible(
                                      key: Key(address.id),
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
                                            content: Text('Are you sure you want to delete this address?'),
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
                                      onDismissed: (direction) => _deleteAddress(address.id),
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
                                                  Text(
                                                    address.fullName,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    address.phoneNumber,
                                                    style: TextStyle(
                                                      color: Colors.black87,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                address.street,
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                '${address.ward}, ${address.district}, ${address.city}',
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                address.country,
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              SizedBox(height: 12),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  if (address.isDefault)
                                                    Container(
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.check_circle,
                                                            color: Colors.red,
                                                            size: 16,
                                                          ),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            'Default',
                                                            style: TextStyle(
                                                              color: Colors.red,
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  else
                                                    TextButton.icon(
                                                      onPressed: () => _setDefaultAddress(address.id),
                                                      icon: Icon(Icons.check_circle_outline,
                                                          color: Colors.red),
                                                      label: Text(
                                                        'Set default',
                                                        style: TextStyle(color: Colors.red),
                                                      ),
                                                      style: TextButton.styleFrom(
                                                        padding: EdgeInsets.zero,
                                                        minimumSize: Size(0, 0),
                                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                      ),
                                                    ),
                                                  InkWell(
                                                    onTap: () => _updateAddress(address),
                                                    child: Icon(
                                                      Icons.edit,
                                                      size: 22,
                                                      color: const Color.fromARGB(255, 255, 0, 0),
                                                    ),
                                                  ),
                                                ],
                                              ),
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
                        padding: EdgeInsets.all(16),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push<Map<String, dynamic>>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddNewAddressPage(
                                  existingAddresses: addresses,
                                ),
                              ),
                            );

                            if (result != null) {
                              // Validate required fields
                              if (result['fullName']?.isEmpty ?? true ||
                                  result['phoneNumber']?.isEmpty ?? true ||
                                  result['street']?.isEmpty ?? true ||
                                  result['city']?.isEmpty ?? true ||
                                  result['district']?.isEmpty ?? true ||
                                  result['country']?.isEmpty ?? true ||
                                  result['zipCode']?.isEmpty ?? true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Center(
                                      child: Text(
                                        'Please fill in all required information',
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

                              final response = await apiService.addAddress(result);
                              if (response['success']) {
                                setState(() {
                                  addresses = [];
                                });
                                _loadAddresses();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Center(
                                        child: Text(
                                          response['message'] ?? 'Address added successfully',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.fixed,
                                      margin: null,
                                      shape: RoundedRectangleBorder(),
                                    ),
                                  );
                                }
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Center(
                                        child: Text(
                                          response['message'] ?? 'Cannot add address',
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
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          icon: Icon(Icons.add_location_alt, color: Colors.white),
                          label: Text('Add new address', style: TextStyle(color: Colors.white)),
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
