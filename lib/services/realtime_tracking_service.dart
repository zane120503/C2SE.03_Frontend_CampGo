import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:CampGo/services/share_service.dart';
import 'package:CampGo/config/config.dart';

class RealtimeTrackingService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Tạo nhóm mới
  Future<String> createGroup(
    String groupName,
    String userId,
    String firstName,
    String lastName,
  ) async {
    final groupRef = _database.child('groups').push();
    final groupId = groupRef.key!;

    // Tạo mã ngắn
    var bytes = utf8.encode(groupId);
    var digest = sha1.convert(bytes);
    String base36 = BigInt.parse(digest.toString(), radix: 16).toRadixString(36);
    String shortCode = base36.substring(0, 6).toUpperCase();

    // Lưu thông tin nhóm
    await groupRef.set({
      'name': groupName,
      'created_at': ServerValue.timestamp,
      'created_by': userId,
      'short_code': shortCode,
      'members': {
        userId: {
          'name': (firstName + ' ' + lastName).trim(),
          'firstName': firstName,
          'lastName': lastName,
          'location': {
            'latitude': 0,
            'longitude': 0,
            'last_updated': ServerValue.timestamp,
          },
        },
      },
    });

    // Lưu mapping giữa mã ngắn và ID dài
    await _database.child('group_codes/$shortCode').set({
      'group_id': groupId,
      'created_at': ServerValue.timestamp,
    });

    return groupId;
  }

  // Tham gia nhóm
  Future<void> joinGroup(String groupId, String userId, String firstName, String lastName) async {
    await _database.child('groups/$groupId/members/$userId').set({
      'name': (firstName + ' ' + lastName).trim(),
      'firstName': firstName,
      'lastName': lastName,
      'location': {
        'latitude': 0,
        'longitude': 0,
        'last_updated': ServerValue.timestamp,
      },
    });
  }

  // Cập nhật vị trí
  Future<void> updateLocation(
    String groupId,
    String userId,
    Position position,
  ) async {
    await _database.child('groups/$groupId/members/$userId/location').update({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'last_updated': ServerValue.timestamp,
    });
  }

  // Lắng nghe thay đổi vị trí của các thành viên
  Stream<DatabaseEvent> listenToGroupLocations(String groupId) {
    return _database.child('groups/$groupId/members').onValue;
  }

  // Lấy thông tin nhóm
  Future<Map<String, dynamic>?> getGroupInfo(String groupId) async {
    final snapshot = await _database.child('groups/$groupId').get();
    if (snapshot.value is Map) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }

  // Rời nhóm
  Future<void> leaveGroup(String groupId, String userId) async {
    print('Rời nhóm: $groupId, userId: $userId');
    try {
      await _database.child('groups/$groupId/members/$userId').remove();
      print('Đã xóa user $userId khỏi group $groupId');
    } catch (e) {
      print('Lỗi khi xóa user khỏi group: $e');
    }

    // Kiểm tra xem còn thành viên nào trong nhóm không
    try {
      final snapshot = await _database.child('groups/$groupId/members').get();
      if (snapshot.value == null ||
          (snapshot.value is Map && (snapshot.value as Map).isEmpty)) {
        // Nếu không còn thành viên nào, xóa nhóm
        await deleteGroup(groupId);
        print('Đã xóa group $groupId vì không còn thành viên nào');
      }
    } catch (e) {
      print('Lỗi khi kiểm tra/xóa group sau khi rời nhóm: $e');
    }
  }

  // Xóa nhóm
  Future<void> deleteGroup(String groupId) async {
    print('Bắt đầu xóa nhóm: ' + groupId);
    // Lấy mã ngắn của nhóm
    final groupSnapshot = await _database.child('groups/$groupId').get();
    if (groupSnapshot.exists) {
      final groupData = groupSnapshot.value as Map<dynamic, dynamic>;
      final shortCode = groupData['short_code'] as String?;
      print('shortCode của nhóm: ' + (shortCode ?? 'null'));
      // Xóa mapping nếu có
      if (shortCode != null) {
        await _database.child('group_codes/$shortCode').remove();
        print('Đã xóa mapping group_codes/$shortCode');
      }
    } else {
      print('Không tìm thấy nhóm với groupId này!');
    }
    // Xóa node members nếu còn
    try {
      await _database.child('groups/$groupId/members').remove();
      print('Đã xóa node members của nhóm $groupId');
    } catch (e) {
      print('LỖI khi xóa node members: $e');
    }
    // Xóa lại node group để đảm bảo không còn key rỗng
    try {
      await _database.child('groups/$groupId').remove();
      print('Đã xóa nhóm groups/$groupId');
      // Kiểm tra lại node members
      final checkMembers = await _database.child('groups/$groupId/members').get();
      print('Kiểm tra lại node members sau khi xóa: ${checkMembers.value}');
      if (checkMembers.exists) {
        await _database.child('groups/$groupId/members').remove();
        print('Đã xóa lại node members của nhóm $groupId (lần 2)');
        // Thử xóa lại node group lần nữa
        await _database.child('groups/$groupId').remove();
        print('Đã xóa lại nhóm groups/$groupId (lần 2)');
      }
    } catch (e) {
      print('LỖI khi xóa nhóm groups/$groupId: $e');
    }
  }

  // Kiểm tra người tạo nhóm
  Future<bool> isGroupCreator(String groupId, String userId) async {
    final snapshot = await _database.child('groups/$groupId/created_by').get();
    return snapshot.value == userId;
  }

  // Kiểm tra nhóm có tồn tại không
  Future<bool> checkGroupExists(String groupId) async {
    final snapshot = await _database.child('groups/$groupId').get();
    return snapshot.exists;
  }

  // Lấy danh sách tất cả các nhóm
  Future<Map<String, dynamic>?> getAllGroups() async {
    final snapshot = await _database.child('groups').get();
    return snapshot.value as Map<String, dynamic>?;
  }

  // Tìm groupId từ mã 6 ký tự
  Future<String?> findGroupIdByShortCode(String shortCode) async {
    // Chuyển shortCode về chữ hoa để so sánh
    shortCode = shortCode.toUpperCase();
    
    // Tìm trong bảng mapping
    final snapshot = await _database.child('group_codes/$shortCode').get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      return data['group_id'] as String;
    }
    return null;
  }

  // Gửi tin nhắn trong nhóm
  Future<void> sendMessage(String groupId, String userId, String userName, String content, String avatarUrl, {String? imageUrl}) async {
    final messageRef = _database.child('groups/$groupId/messages').push();
    await messageRef.set({
      'userId': userId,
      'userName': userName,
      'avatarUrl': avatarUrl,
      'content': content,
      'imageUrl': imageUrl ?? '',
      'timestamp': ServerValue.timestamp,
    });
  }

  // Lắng nghe tin nhắn realtime trong nhóm
  Stream<DatabaseEvent> listenToMessages(String groupId) {
    return _database.child('groups/$groupId/messages').orderByChild('timestamp').onValue;
  }

  // Lắng nghe thay đổi thông tin nhóm
  Stream<DatabaseEvent> listenToGroupInfo(String groupId) {
    return _database.child('groups/$groupId').onValue;
  }
}
