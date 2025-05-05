import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class RealtimeTrackingService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Tạo nhóm mới
  Future<String> createGroup(
    String groupName,
    String userId,
    String userName,
  ) async {
    final groupRef = _database.child('groups').push();
    final groupId = groupRef.key!;

    await groupRef.set({
      'name': groupName,
      'created_at': ServerValue.timestamp,
      'created_by': userId,
      'members': {
        userId: {
          'name': userName,
          'location': {
            'latitude': 0,
            'longitude': 0,
            'last_updated': ServerValue.timestamp,
          },
        },
      },
    });

    return groupId;
  }

  // Tham gia nhóm
  Future<void> joinGroup(String groupId, String userId, String userName) async {
    await _database.child('groups/$groupId/members/$userId').set({
      'name': userName,
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
    return snapshot.value as Map<String, dynamic>?;
  }

  // Rời nhóm
  Future<void> leaveGroup(String groupId, String userId) async {
    await _database.child('groups/$groupId/members/$userId').remove();

    // Kiểm tra xem còn thành viên nào trong nhóm không
    final snapshot = await _database.child('groups/$groupId/members').get();
    if (snapshot.value == null ||
        (snapshot.value is Map && (snapshot.value as Map).isEmpty)) {
      // Nếu không còn thành viên nào, xóa nhóm
      await deleteGroup(groupId);
    }
  }

  // Xóa nhóm
  Future<void> deleteGroup(String groupId) async {
    await _database.child('groups/$groupId').remove();
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
    final allGroups = await getAllGroups();
    if (allGroups == null) return null;

    // Chuyển shortCode về chữ hoa để so sánh
    shortCode = shortCode.toUpperCase();

    for (var entry in allGroups.entries) {
      final groupId = entry.key;
      // Tính toán shortCode cho groupId này
      var bytes = utf8.encode(groupId);
      var digest = sha1.convert(bytes);
      String base36 = BigInt.parse(digest.toString(), radix: 16).toRadixString(36);
      String calculatedShortCode = base36.substring(0, 6).toUpperCase();
      
      if (calculatedShortCode == shortCode) {
        return groupId;
      }
    }
    return null;
  }
}
