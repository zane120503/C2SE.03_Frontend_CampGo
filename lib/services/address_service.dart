import 'dart:convert';
import 'package:http/http.dart' as http;

class AddressService {
  static const String _baseUrl = 'https://online-gateway.ghn.vn/api/v1';
  static const String _token = 'Token 5c3c3a3c-3c3a-3c3a-3c3a-3c3a3c3a3c3a'; // Token mẫu, bạn cần đăng ký để lấy token thật

  // Lấy danh sách tỉnh/thành phố
  Future<List<String>> getProvinces() async {
    return [
      'Hà Nội',
      'TP Hồ Chí Minh',
      'Đà Nẵng',
      'Hải Phòng',
      'Cần Thơ',
      'Bình Dương',
      'Đồng Nai',
      'Bà Rịa - Vũng Tàu',
      'Hải Dương',
      'Thái Bình',
      'Nam Định',
      'Ninh Bình',
      'Thanh Hóa',
      'Nghệ An',
      'Hà Tĩnh',
      'Quảng Bình',
      'Quảng Trị',
      'Thừa Thiên Huế',
      'Quảng Nam',
      'Quảng Ngãi',
      'Bình Định',
      'Phú Yên',
      'Khánh Hòa',
      'Ninh Thuận',
      'Bình Thuận',
      'Kon Tum',
      'Gia Lai',
      'Đắk Lắk',
      'Đắk Nông',
      'Lâm Đồng',
      'Bình Phước',
      'Tây Ninh',
      'Bến Tre',
      'Trà Vinh',
      'Vĩnh Long',
      'Đồng Tháp',
      'An Giang',
      'Kiên Giang',
      'Cà Mau',
      'Bạc Liêu',
      'Sóc Trăng',
    ];
  }

  // Lấy danh sách quận/huyện theo tỉnh/thành phố
  Future<List<String>> getDistricts(String provinceName) async {
    switch (provinceName) {
      case 'Hà Nội':
        return [
          'Ba Đình',
          'Hoàn Kiếm',
          'Hai Bà Trưng',
          'Đống Đa',
          'Cầu Giấy',
          'Thanh Xuân',
          'Hoàng Mai',
          'Long Biên',
          'Tây Hồ',
          'Nam Từ Liêm',
          'Bắc Từ Liêm',
          'Hà Đông',
          'Sơn Tây',
          'Ba Vì',
          'Chương Mỹ',
          'Đan Phượng',
          'Đông Anh',
          'Gia Lâm',
          'Hoài Đức',
          'Mê Linh',
          'Mỹ Đức',
          'Phú Xuyên',
          'Phúc Thọ',
          'Quốc Oai',
          'Sóc Sơn',
          'Thạch Thất',
          'Thanh Oai',
          'Thanh Trì',
          'Thường Tín',
          'Ứng Hòa',
        ];
      case 'TP Hồ Chí Minh':
        return [
          'Quận 1',
          'Quận 2',
          'Quận 3',
          'Quận 4',
          'Quận 5',
          'Quận 6',
          'Quận 7',
          'Quận 8',
          'Quận 9',
          'Quận 10',
          'Quận 11',
          'Quận 12',
          'Quận Bình Thạnh',
          'Quận Bình Tân',
          'Quận Gò Vấp',
          'Quận Phú Nhuận',
          'Quận Tân Bình',
          'Quận Tân Phú',
          'Quận Thủ Đức',
          'Huyện Bình Chánh',
          'Huyện Cần Giờ',
          'Huyện Củ Chi',
          'Huyện Hóc Môn',
          'Huyện Nhà Bè',
        ];
      case 'Đà Nẵng':
        return [
          'Quận Hải Châu',
          'Quận Thanh Khê',
          'Quận Sơn Trà',
          'Quận Ngũ Hành Sơn',
          'Quận Liên Chiểu',
          'Quận Cẩm Lệ',
          'Huyện Hòa Vang',
          'Huyện Hoàng Sa',
        ];
      case 'Hải Phòng':
        return [
          'Quận Hồng Bàng',
          'Quận Ngô Quyền',
          'Quận Lê Chân',
          'Quận Hải An',
          'Quận Kiến An',
          'Quận Đồ Sơn',
          'Quận Dương Kinh',
          'Huyện Thủy Nguyên',
          'Huyện An Dương',
          'Huyện An Lão',
          'Huyện Kiến Thụy',
          'Huyện Tiên Lãng',
          'Huyện Vĩnh Bảo',
          'Huyện Cát Hải',
          'Huyện Bạch Long Vĩ',
        ];
      case 'Cần Thơ':
        return [
          'Quận Ninh Kiều',
          'Quận Bình Thủy',
          'Quận Cái Răng',
          'Quận Ô Môn',
          'Quận Thốt Nốt',
          'Huyện Phong Điền',
          'Huyện Cờ Đỏ',
          'Huyện Thới Lai',
          'Huyện Vĩnh Thạnh',
        ];
      default:
        return [];
    }
  }

  // Lấy danh sách phường/xã theo quận/huyện
  Future<List<String>> getWards(String districtName) async {
    switch (districtName) {
      case 'Quận 1':
        return [
          'Phường Bến Nghé',
          'Phường Bến Thành',
          'Phường Cầu Kho',
          'Phường Cầu Ông Lãnh',
          'Phường Cô Giang',
          'Phường Đa Kao',
          'Phường Nguyễn Cư Trinh',
          'Phường Nguyễn Thái Bình',
          'Phường Phạm Ngũ Lão',
          'Phường Tân Định',
        ];
      case 'Quận Hải Châu':
        return [
          'Phường Hải Châu 1',
          'Phường Hải Châu 2',
          'Phường Hòa Cường Bắc',
          'Phường Hòa Cường Nam',
          'Phường Hòa Thuận Đông',
          'Phường Hòa Thuận Tây',
          'Phường Nam Dương',
          'Phường Phước Ninh',
          'Phường Thạch Thang',
          'Phường Thanh Bình',
          'Phường Thuận Phước',
        ];
      case 'Ba Đình':
        return [
          'Phường Phúc Xá',
          'Phường Trúc Bạch',
          'Phường Vĩnh Phúc',
          'Phường Cống Vị',
          'Phường Liễu Giai',
          'Phường Nguyễn Trung Trực',
          'Phường Quán Thánh',
          'Phường Ngọc Hà',
          'Phường Điện Biên',
          'Phường Đội Cấn',
          'Phường Ngọc Khánh',
          'Phường Kim Mã',
          'Phường Giảng Võ',
          'Phường Thành Công',
        ];
      case 'Quận Ninh Kiều':
        return [
          'Phường An Bình',
          'Phường An Cư',
          'Phường An Hòa',
          'Phường An Khánh',
          'Phường An Nghiệp',
          'Phường An Phú',
          'Phường Cái Khế',
          'Phường Hưng Lợi',
          'Phường Tân An',
          'Phường Thới Bình',
          'Phường Xuân Khánh',
        ];
      case 'Quận Hồng Bàng':
        return [
          'Phường Hạ Lý',
          'Phường Hoàng Văn Thụ',
          'Phường Hùng Vương',
          'Phường Minh Khai',
          'Phường Phạm Hồng Thái',
          'Phường Phan Bội Châu',
          'Phường Quán Toan',
          'Phường Quang Trung',
          'Phường Sở Dầu',
          'Phường Thượng Lý',
          'Phường Trại Chuối',
        ];
      default:
        return [];
    }
  }
} 