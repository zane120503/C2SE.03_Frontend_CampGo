import 'package:CampGo/pages/Account%20&%20Security/widgets/EditProfilePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/realtime_tracking_service.dart';
import 'widgets/group_tracking_map.dart';
import '../../providers/auth_provider.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';

class GroupTrackingPage extends StatefulWidget {
  const GroupTrackingPage({super.key});

  @override
  State<GroupTrackingPage> createState() => _GroupTrackingPageState();
}

class _GroupTrackingPageState extends State<GroupTrackingPage> {
  final RealtimeTrackingService _trackingService = RealtimeTrackingService();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupIdController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  String? _currentGroupId;
  bool _isCreator = false;
  Map<String, dynamic>? _groupInfo;
  final GlobalKey _menuKey = GlobalKey();
  OverlayEntry? _menuOverlayEntry;
  final GlobalKey<State<GroupTrackingMap>> _mapKey = GlobalKey<State<GroupTrackingMap>>();
  bool _chatSheetOpen = false;
  Map<String, String> _chatAvatars = {};
  final ImagePicker _imagePicker = ImagePicker();
  ScrollController _chatScrollController = ScrollController();
  bool _isUploadingImage = false;
  List<Map<String, dynamic>> _pendingMessages = [];
  Map<String, String> _memberAvatars = {};
  int _unreadMessages = 0;
  DateTime? _lastChatOpenTime;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroupInfo();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _currentUserId = authProvider.user?.id;
    });
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupIdController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupInfo() async {
    if (_currentGroupId == null) return;

    try {
      final info = await _trackingService.getGroupInfo(_currentGroupId!);
      if (mounted) {
        setState(() {
          _groupInfo = info;
        });
      }
    } catch (e) {
      print('Error loading group info: $e');
    }
  }

  // Hàm chuyển groupId thành mã phòng 6 ký tự
  String shortRoomCode(String longId) {
    var bytes = utf8.encode(longId);
    var digest = sha1.convert(bytes);
    String base36 = BigInt.parse(digest.toString(), radix: 16).toRadixString(36);
    return base36.substring(0, 6).toUpperCase();
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    print('DEBUG user.firstName:  {user?.firstName}, user.lastName:  {user?.lastName}');
    // Kiểm tra tên
    if (user == null || user.firstName.trim().isEmpty || user.lastName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check your personal information before creating a group!', textAlign: TextAlign.center),
          backgroundColor: Color.fromARGB(255, 254, 118, 0),
        ),
      );
      // Chuyển sang trang EditProfilePage sau khi show SnackBar
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => EditProfilePage()),
        );
      });
      return;
    }

    print('DEBUG user.firstName:  {user.firstName}, user.lastName:  {user.lastName}');

    final groupName = _groupNameController.text;
    final groupId = await _trackingService.createGroup(
      groupName,
      user.id,
      user.firstName,
      user.lastName,
    );

    // Đợi load group info từ backend trước khi cập nhật UI
    await _trackingService.getGroupInfo(groupId).then((info) {
      setState(() {
        _currentGroupId = groupId;
        _isCreator = true;
        _groupInfo = info;
      });
    });

    if (mounted) {
      final shortCode = shortRoomCode(groupId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group created with code: $shortCode',
        textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _joinGroup() async {
    if (_groupIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group code',
        textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Kiểm tra độ dài mã nhóm
    if (_groupIdController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group code must be 6 characters',
        textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    // Kiểm tra tên
    if (user == null || user.firstName.trim().isEmpty || user.lastName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please update your full name before joining a group!', textAlign: TextAlign.center),
          backgroundColor: Colors.red,
        ),
      );
      // Chuyển sang trang EditProfilePage sau khi show SnackBar
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => EditProfilePage()),
        );
      });
      return;
    }

    print('DEBUG user.firstName:  {user.firstName}, user.lastName:  {user.lastName}');

    // Hiển thị loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Tìm groupId từ mã 6 ký tự
      final fullGroupId = await _trackingService.findGroupIdByShortCode(_groupIdController.text);
      
      // Đóng loading
      Navigator.of(context).pop();
      
      if (fullGroupId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group not found',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Kiểm tra xem nhóm có tồn tại không
      final groupExists = await _trackingService.checkGroupExists(fullGroupId);
      if (!groupExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group does not exist',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _trackingService.joinGroup(
        fullGroupId,
        user.id,
        user.firstName,
        user.lastName,
      );

      final isCreator = await _trackingService.isGroupCreator(
        fullGroupId,
        user.id,
      );

      setState(() {
        _currentGroupId = fullGroupId;
        _isCreator = isCreator;
      });

      _loadGroupInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined group',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Đóng loading nếu có lỗi
      Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to join group',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _leaveGroup(String userId) async {
    if (_currentGroupId == null) return;

    await _trackingService.leaveGroup(_currentGroupId!, userId);

    setState(() {
      _currentGroupId = null;
      _isCreator = false;
      _groupInfo = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Successfully left group',
    textAlign: TextAlign.center,
    ),
    backgroundColor: Colors.green,
    ),
    );
  }

  Future<void> _deleteGroup() async {
    if (_currentGroupId == null) return;

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Delete group'),
                content: const Text(
                  'Are you sure you want to delete this group? All members will be removed from the group.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmed) {
      await _trackingService.deleteGroup(_currentGroupId!);

      setState(() {
        _currentGroupId = null;
        _isCreator = false;
        _groupInfo = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Group deleted',
      textAlign: TextAlign.center,
      ),
      backgroundColor: Colors.green,
      ),
    );
    }
  }

  void _copyGroupId() {
    if (_currentGroupId == null) return;
    final shortCode = shortRoomCode(_currentGroupId!);
    Clipboard.setData(ClipboardData(text: shortCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Group code copied to clipboard: $shortCode',
      textAlign: TextAlign.center,
      ),
      backgroundColor: Colors.green,
      ),
    );
  }

  Future<String?> _getMemberAvatarUrl(String userId) async {
    if (_memberAvatars.containsKey(userId)) {
      return _memberAvatars[userId];
    }
    try {
      final response = await APIService.getUserProfileById(userId);
      if (response['success'] == true) {
        final userData = response['userData'];
        if (userData != null && userData['profileImage'] != null) {
          setState(() {
            _memberAvatars[userId] = userData['profileImage']['url'];
          });
          return userData['profileImage']['url'];
        }
      }
    } catch (e) {
      print('Lỗi lấy avatar cho user $userId: $e');
    }
    return null;
  }

  void _showMembersDialog() {
    if (_currentGroupId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: StreamBuilder<DatabaseEvent>(
          stream: _trackingService.listenToGroupInfo(_currentGroupId!),
          builder: (context, snapshot) {
            int memberCount = 0;
            Map<dynamic, dynamic> members = {};
            
            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
              if (data['members'] != null) {
                members = data['members'] as Map<dynamic, dynamic>;
                memberCount = members.length;
              }
            }

            return Column(
              children: [
                const Text(
                  'Member list',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Total: $memberCount members',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        content: StreamBuilder<DatabaseEvent>(
          stream: _trackingService.listenToGroupInfo(_currentGroupId!),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            final members = data['members'] as Map<dynamic, dynamic>? ?? {};
            
            return Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members.entries.elementAt(index);
                  final memberInfo = member.value as Map<dynamic, dynamic>;
                  final memberFirstName = memberInfo['firstName'] ?? '';
                  final memberLastName = memberInfo['lastName'] ?? '';
                  final memberName = (memberFirstName + ' ' + memberLastName).trim().isNotEmpty
                    ? (memberFirstName + ' ' + memberLastName).trim()
                    : (memberInfo['fullName'] ?? memberInfo['name'] ?? 'User');
                  final isCreator = memberInfo['isCreator'] == true;
                  final memberId = member.key.toString();
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: FutureBuilder<String?>(
                        future: _getMemberAvatarUrl(memberId),
                        builder: (context, snapshot) {
                          final avatarUrl = snapshot.data;
                          if (avatarUrl != null && avatarUrl.isNotEmpty) {
                            return CircleAvatar(
                              backgroundImage: NetworkImage(avatarUrl),
                            );
                          } else {
                            return CircleAvatar(
                              backgroundColor: isCreator ? Colors.blue : Colors.grey,
                              child: Icon(
                                isCreator ? Icons.star : Icons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                            );
                          }
                        },
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              memberName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (isCreator)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Group leader',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  void _showCustomMenu(BuildContext context, double top) {
    final double menuWidth = 250;
    final double right = 0; // Sát lề phải, có thể chỉnh về 0 nếu muốn sát hẳn
    _menuOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: top,
        right: right,
        child: Material(
          color: Colors.transparent,
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SizedBox(
              width: menuWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      _menuOverlayEntry?.remove();
                      _menuOverlayEntry = null;
                      _copyGroupId();
                    },
                    child: ListTile(
                      leading: const Icon(Icons.copy),
                      title: Text('Copy code: ${_currentGroupId != null ? shortRoomCode(_currentGroupId!) : ''}'),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      _menuOverlayEntry?.remove();
                      _menuOverlayEntry = null;
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final user = authProvider.user;
                      if (user != null) _leaveGroup(user.id);
                    },
                    child: const ListTile(
                      leading: Icon(Icons.exit_to_app),
                      title: Text('Leave group'),
                    ),
                  ),
                  if (_isCreator)
                    InkWell(
                      onTap: () {
                        _menuOverlayEntry?.remove();
                        _menuOverlayEntry = null;
                        _deleteGroup();
                      },
                      child: const ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete group', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_menuOverlayEntry!);
  }

  void _openChatSheet(String groupId, String userId, String userName, String avatarUrl) {
    if (_chatSheetOpen) return;
    _chatSheetOpen = true;
    setState(() {
      _lastChatOpenTime = DateTime.now();
      _unreadMessages = 0;
    });
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.80,
          minChildSize: 0.5,
          maxChildSize: 0.94,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Text(
                    'Group Chat',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: StreamBuilder<DatabaseEvent>(
                    stream: _trackingService.listenToMessages(groupId),
                    builder: (context, snapshot) {
                      List<Map<String, dynamic>> messages = [];
                      if (snapshot.hasData && snapshot.data!.snapshot.value is Map) {
                        final data = snapshot.data!.snapshot.value as Map;
                        data.forEach((key, value) {
                          if (value is Map) {
                            messages.add({...value, 'key': key});
                          }
                        });
                        messages.sort((a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));
                      }
                      List<Map<String, dynamic>> allMessages = [...messages];
                      _pendingMessages.removeWhere((pending) =>
                        pending['imageLocalPath'] != null &&
                        messages.any((msg) =>
                          msg['imageUrl'] != null && msg['imageUrl'] != '' &&
                          msg['userId'] == pending['userId'] &&
                          (msg['timestamp'] ?? 0) >= (pending['timestamp'] ?? 0)
                        )
                      );
                      allMessages.addAll(_pendingMessages);
                      // Sau khi build xong, scroll xuống cuối
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_chatScrollController.hasClients) {
                          _chatScrollController.jumpTo(_chatScrollController.position.maxScrollExtent);
                        }
                      });
                      return ListView.builder(
                        controller: _chatScrollController,
                        reverse: false,
                        itemCount: allMessages.length,
                        itemBuilder: (context, index) {
                          final msg = allMessages[index];
                          final isMe = msg['userId'] == userId;
                          final showUserName = index == 0 || allMessages[index - 1]['userId'] != msg['userId'];
                          final isUploading = msg['isUploading'] == true;
                          if (isUploading && msg['imageLocalPath'] != null) {
                            print('Render temporary image: ' + msg['imageLocalPath']);
                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Opacity(
                                      opacity: 0.5,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          File(msg['imageLocalPath']),
                                          width: 180,
                                          height: 180,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            print('Error loading local image: $error');
                                            return Container(
                                              width: 180,
                                              height: 180,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.image_not_supported),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    const CircularProgressIndicator(),
                                  ],
                                ),
                              ),
                            );
                          }
                          return FutureBuilder<String?>(
                            future: (msg['avatarUrl'] == null || msg['avatarUrl'] == '') ? _getMemberAvatarUrl(msg['userId']) : Future.value(msg['avatarUrl']),
                            builder: (context, snapshot) {
                              final avatarUrl = snapshot.data;
                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  child: Row(
                                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (!isMe)
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundImage: avatarUrl != null && avatarUrl != '' ? NetworkImage(avatarUrl) : null,
                                          child: (avatarUrl == null || avatarUrl == '') ? const Icon(Icons.person, size: 20) : null,
                                        ),
                                      if (!isMe) const SizedBox(width: 8),
                                      Flexible(
                                        child: Column(
                                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                          children: [
                                            if (showUserName)
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 2),
                                                child: Text(
                                                  msg['userName'] ?? '',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: isMe ? Colors.orange : Colors.blue,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            if (msg['imageUrl'] != null && msg['imageUrl'] != '')
                                              GestureDetector(
                                                onTap: () => _showFullScreenImage(context, msg['imageUrl']),
                                                child: Container(
                                                  margin: const EdgeInsets.only(top: 4, bottom: 4),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: Image.network(
                                                      msg['imageUrl'],
                                                      width: 180,
                                                      height: 180,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            else
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: isMe ? Colors.orange[200] : Colors.grey[200],
                                                  borderRadius: BorderRadius.only(
                                                    topLeft: const Radius.circular(16),
                                                    topRight: const Radius.circular(16),
                                                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                                                    bottomRight: Radius.circular(isMe ? 4 : 16),
                                                  ),
                                                ),
                                                child: Text(
                                                  msg['content'] ?? '',
                                                  style: const TextStyle(fontSize: 15),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (isMe) const SizedBox(width: 8),
                                      if (isMe)
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundImage: avatarUrl != null && avatarUrl != '' ? NetworkImage(avatarUrl) : null,
                                          child: (avatarUrl == null || avatarUrl == '') ? const Icon(Icons.person, size: 20) : null,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.red),
                        onPressed: () async {
                          final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera);
                          if (pickedFile != null && _currentGroupId != null) {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final user = authProvider.user;
                            if (user != null) {
                              // Copy file về documents directory để tránh bị iOS xóa quá sớm
                              final appDir = await getApplicationDocumentsDirectory();
                              final fileName = pickedFile.path.split('/').last;
                              final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
                              print('Local image path (after copy): ' + savedImage.path);
                              setState(() {
                                _isUploadingImage = true;
                                _pendingMessages.add({
                                  'userId': user.id,
                                  'userName': user.fullName,
                                  'avatarUrl': user.profileImage != null && user.profileImage!['url'] != null ? user.profileImage!['url'] : '',
                                  'imageLocalPath': savedImage.path, // dùng path mới
                                  'isUploading': true,
                                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                                });
                              });
                              String avatarUrl = '';
                              if (user.profileImage != null && user.profileImage!['url'] != null) {
                                avatarUrl = user.profileImage!['url'];
                              }
                              String? imageUrl;
                              try {
                                imageUrl = await APIService.uploadImageToServer(savedImage);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to send image!', textAlign: TextAlign.center), backgroundColor: Colors.red),
                                );
                              }
                              if (imageUrl != null && imageUrl.isNotEmpty) {
                                await _trackingService.sendMessage(
                                  _currentGroupId!,
                                  user.id,
                                  user.fullName,
                                  '', // Không có nội dung text
                                  avatarUrl,
                                  imageUrl: imageUrl,
                                );
                              }
                              setState(() => _isUploadingImage = false);
                            }
                          }
                        },
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: TextField(
                            controller: _chatController,
                            decoration: const InputDecoration(
                              hintText: 'Enter message...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            minLines: 1,
                            maxLines: 3,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (value) async {
                              final text = value.trim();
                              if (text.isNotEmpty && _currentGroupId != null) {
                                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                final user = authProvider.user;
                                if (user != null) {
                                  String avatarUrl = '';
                                  if (user.profileImage != null && user.profileImage!['url'] != null) {
                                    avatarUrl = user.profileImage!['url'];
                                  }
                                  await _trackingService.sendMessage(
                                    _currentGroupId!,
                                    user.id,
                                    user.fullName,
                                    text,
                                    avatarUrl,
                                  );
                                  _chatController.clear();
                                }
                              }
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: () async {
                          final text = _chatController.text.trim();
                          if (_currentGroupId != null) {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final user = authProvider.user;
                            if (user != null) {
                              String avatarUrl = '';
                              if (user.profileImage != null && user.profileImage!['url'] != null) {
                                avatarUrl = user.profileImage!['url'];
                              }
                              if (text.isNotEmpty) {
                                await _trackingService.sendMessage(
                                  _currentGroupId!,
                                  user.id,
                                  user.fullName,
                                  text,
                                  avatarUrl,
                                );
                                _chatController.clear();
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      _chatSheetOpen = false;
    });
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Container(
            color: Colors.black,
            child: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              loadingBuilder: (context, event) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.error, color: Colors.white, size: 42),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group tracking')),
        body: const Center(
          child: Text('Please login to use this feature'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          _currentGroupId != null
              ? _groupInfo != null && _groupInfo!['name'] != null
                  ? _groupInfo!['name']
                  : 'Group Tracking'
              : 'Group Tracking',
        ),
        actions: [
          if (_currentGroupId != null) ...[
            StreamBuilder<DatabaseEvent>(
              stream: _trackingService.listenToGroupInfo(_currentGroupId!),
              builder: (context, snapshot) {
                int memberCount = 0;
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  if (data['members'] != null) {
                    memberCount = (data['members'] as Map).length;
                  }
                }
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.people),
                      tooltip: 'Members list',
                      onPressed: _showMembersDialog,
                    ),
                    if (memberCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            memberCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            Builder(
              builder: (context) {
                return IconButton(
                  key: _menuKey,
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'Menu',
                  onPressed: () {
                    if (_menuOverlayEntry != null) {
                      _menuOverlayEntry?.remove();
                      _menuOverlayEntry = null;
                    } else {
                      final RenderBox button = _menuKey.currentContext!.findRenderObject() as RenderBox;
                      final Offset position = button.localToGlobal(Offset.zero);
                      final double top = position.dy + button.size.height + 3;
                      _showCustomMenu(context, top);
                    }
                  },
                );
              },
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          if (_currentGroupId == null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _groupNameController,
                    decoration: const InputDecoration(
                      labelText: 'New group name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _createGroup,
                    child: const Text('Create new group'),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _groupIdController,
                    decoration: const InputDecoration(
                      labelText: 'Group Code',  
                    ),
                    maxLength: 6,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(letterSpacing: 8.0),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        return TextEditingValue(
                          text: newValue.text.toUpperCase(),
                          selection: newValue.selection,
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _joinGroup,
                    child: const Text('Join group'),
                  ),
                ],
              ),
            )
          else
            GroupTrackingMap(
              key: _mapKey,
              groupId: _currentGroupId!,
              userId: user.id,
              userName: user.fullName,
            ),
          if (_currentGroupId != null)
            Positioned(
              left: 10,
              top: 8,
              child: Row(
                children: [
                  FloatingActionButton(
                    heroTag: 'location',
                    tooltip: 'Current location',
                    backgroundColor: Colors.white,
                    onPressed: () {
                      final state = _mapKey.currentState as dynamic;
                      state?.moveToCurrentLocation();
                    },
                    child: const Icon(Icons.my_location, color: Colors.blue),
                  ),
                  const SizedBox(width: 16),
                  Stack(
                    children: [
                      FloatingActionButton(
                        heroTag: 'chat',
                        tooltip: 'Group Chat',
                        backgroundColor: Colors.white,
                        onPressed: () {
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          final user = authProvider.user;
                          if (user != null && _currentGroupId != null) {
                            String avatarUrl = '';
                            if (user.profileImage != null && user.profileImage!['url'] != null) {
                              avatarUrl = user.profileImage!['url'];
                            }
                            final userId = user.id;
                            final userName = user.fullName;
                            _openChatSheet(_currentGroupId!, userId, userName, avatarUrl);
                          }
                        },
                        child: const Icon(Icons.chat_bubble, color: Colors.orange),
                      ),
                      if (_currentGroupId != null)
                        StreamBuilder<DatabaseEvent>(
                          stream: _trackingService.listenToMessages(_currentGroupId!),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.snapshot.value != null && !_chatSheetOpen) {
                              final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                              int unreadCount = 0;
                              
                              data.forEach((key, value) {
                                if (value is Map) {
                                  final message = Map<String, dynamic>.from(value);
                                  // Kiểm tra nếu tin nhắn không phải của user hiện tại và được gửi sau lần mở chat cuối
                                  if (message['userId'] != _currentUserId && 
                                      (_lastChatOpenTime == null || 
                                       (message['timestamp'] as int) > _lastChatOpenTime!.millisecondsSinceEpoch)) {
                                    unreadCount++;
                                  }
                                }
                              });
                              
                              // Cập nhật số tin nhắn chưa đọc
                              if (unreadCount != _unreadMessages) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  setState(() {
                                    _unreadMessages = unreadCount;
                                  });
                                });
                              }
                              
                              if (_unreadMessages > 0) {
                                return Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      _unreadMessages > 5 ? '5+' : _unreadMessages.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          if (_isUploadingImage)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
