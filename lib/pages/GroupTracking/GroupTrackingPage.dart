import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/realtime_tracking_service.dart';
import 'widgets/group_tracking_map.dart';
import '../../providers/auth_provider.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'dart:io';
import '../../services/api_service.dart';

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
  File? _selectedImage;
  List<File> _selectedImages = [];
  Map<String, String> _chatAvatars = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroupInfo();
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

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to use this feature',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final groupName = _groupNameController.text;
    final groupId = await _trackingService.createGroup(
      groupName,
      user.id,
      user.fullName,
    );

    setState(() {
      _currentGroupId = groupId;
      _isCreator = true;
      _groupInfo = {'name': groupName}; // Gán tạm tên nhóm để UI hiển thị ngay
    });

    await _loadGroupInfo(); // Cập nhật lại groupInfo thật sự từ backend

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

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to use this feature',
        textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
        user.fullName,
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
      SnackBar(content: Text('Group code copied to clipboard: $shortCode'),
      backgroundColor: Colors.green,
      ),
    );
  }

  void _showMembersDialog() {
    if (_groupInfo == null || _groupInfo!['members'] == null) return;

    final members = _groupInfo!['members'] as Map<dynamic, dynamic>;
    final memberCount = members.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          children: [
            const Text(
              'Danh sách thành viên',
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
                'Tổng số: $memberCount thành viên',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members.entries.elementAt(index);
              final memberInfo = member.value as Map<dynamic, dynamic>;
              final memberName = memberInfo['name'] as String;
              final isCreator = memberInfo['isCreator'] == true;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCreator ? Colors.blue : Colors.grey,
                    child: Icon(
                      isCreator ? Icons.star : Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          memberName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
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
                            'Chủ nhóm',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    'ID: ${member.key}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Đóng',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
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
    final double menuWidth = 280;
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

  void _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _pickMultipleImages() async {
    try {
      print('Bắt đầu chọn ảnh...');
      final List<AssetEntity>? assets = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          maxAssets: 10,
          requestType: RequestType.image,
          textDelegate: AssetPickerTextDelegate(),
          specialPickerType: SpecialPickerType.noPreview,
          selectedAssets: [],
          themeColor: Colors.blue,
        ),
      );
      
      if (assets != null && assets.isNotEmpty) {
        print('Đã chọn ${assets.length} ảnh');
        _selectedImages = [];
        for (final asset in assets) {
          final file = await asset.file;
          if (file != null) {
            print('Đã lấy được file ảnh: ${file.path}');
            _selectedImages.add(file);
          }
        }
        
        // Sau khi chọn xong, upload và gửi từng ảnh
        if (_selectedImages.isNotEmpty && _currentGroupId != null) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final user = authProvider.user;
          if (user != null) {
            String avatarUrl = '';
            if (user.profileImage != null && user.profileImage!['url'] != null) {
              avatarUrl = user.profileImage!['url'];
            }
            
            for (final img in _selectedImages) {
              try {
                print('Bắt đầu upload ảnh: ${img.path}');
                String? imageUrl = await _trackingService.uploadImageToFirebaseStorage(
                  img, 
                  _currentGroupId!, 
                  user.id
                );
                
                if (imageUrl != null && imageUrl.isNotEmpty) {
                  print('Upload ảnh thành công, URL: $imageUrl');
                  print('Bắt đầu gửi tin nhắn với ảnh...');
                  
                  await _trackingService.sendMessage(
                    _currentGroupId!,
                    user.id,
                    user.fullName,
                    '',
                    avatarUrl,
                    imageUrl: imageUrl,
                  );
                  print('Đã gửi tin nhắn với ảnh thành công');
                } else {
                  print('Lỗi: Không nhận được URL ảnh sau khi upload');
                }
              } catch (e) {
                print('Lỗi khi xử lý ảnh ${img.path}: $e');
              }
            }
            
            setState(() {
              _selectedImages.clear();
            });
          } else {
            print('Lỗi: Không tìm thấy thông tin người dùng');
          }
        } else {
          print('Lỗi: Không có ảnh được chọn hoặc không có groupId');
        }
      } else {
        print('Không có ảnh nào được chọn');
      }
    } catch (e) {
      print('Lỗi khi chọn ảnh: $e');
    }
  }

  Future<String?> _getAvatarUrl(String userId) async {
    if (_chatAvatars.containsKey(userId)) {
      return _chatAvatars[userId];
    }
    try {
      final response = await APIService.getUserProfileById(userId);
      if (response['success'] == true) {
        final userData = response['userData'];
        if (userData != null && userData['profileImage'] != null) {
          setState(() {
            _chatAvatars[userId] = userData['profileImage']['url'];
          });
          return userData['profileImage']['url'];
        }
      }
    } catch (e) {
      print('Lỗi lấy avatar cho user $userId: $e');
    }
    return null;
  }

  void _openChatSheet(String groupId, String userId, String userName, String avatarUrl) {
    if (_chatSheetOpen) return;
    _chatSheetOpen = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Text(
                    'Chat nhóm',
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
                      return ListView.builder(
                        controller: scrollController,
                        reverse: false,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg['userId'] == userId;
                          final showUserName = index == 0 || messages[index - 1]['userId'] != msg['userId'];
                          return FutureBuilder<String?>(
                            future: (msg['avatarUrl'] == null || msg['avatarUrl'] == '') ? _getAvatarUrl(msg['userId']) : Future.value(msg['avatarUrl']),
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
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 4),
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
                        icon: const Icon(Icons.photo, color: Colors.purple),
                        onPressed: _pickMultipleImages,
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.pink),
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                      if (_selectedImage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImage!,
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
                                      _selectedImage = null;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            children: [
                              if (_selectedImage != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          _selectedImage!,
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
                                              _selectedImage = null;
                                            });
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.5),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              TextField(
                                controller: _chatController,
                                decoration: const InputDecoration(
                                  hintText: 'Nhập tin nhắn...',
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
                            ],
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
                                // Gửi text nếu có
                                await _trackingService.sendMessage(
                                  _currentGroupId!,
                                  user.id,
                                  user.fullName,
                                  text,
                                  avatarUrl,
                                );
                                _chatController.clear();
                              }
                              
                              if (_selectedImage != null) {
                                // Gửi ảnh nếu có
                                String? imageUrl = await _trackingService.uploadImageToFirebaseStorage(
                                  _selectedImage!,
                                  _currentGroupId!,
                                  user.id
                                );
                                await _trackingService.sendMessage(
                                  _currentGroupId!,
                                  user.id,
                                  user.fullName,
                                  '',
                                  avatarUrl,
                                  imageUrl: imageUrl,
                                );
                                setState(() {
                                  _selectedImage = null;
                                });
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
            IconButton(
              icon: const Icon(Icons.people),
              tooltip: 'Members list',
              onPressed: _showMembersDialog,
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
              child: Column(
                children: [
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'chat',
                    tooltip: 'Chat nhóm',
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
                ],
              ),
            ),
        ],
      ),
    );
  }
}
