import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/realtime_tracking_service.dart';
import '../../widgets/group_tracking_map.dart';
import '../../providers/auth_provider.dart';

class GroupTrackingPage extends StatefulWidget {
  const GroupTrackingPage({super.key});

  @override
  State<GroupTrackingPage> createState() => _GroupTrackingPageState();
}

class _GroupTrackingPageState extends State<GroupTrackingPage> {
  final RealtimeTrackingService _trackingService = RealtimeTrackingService();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupIdController = TextEditingController();
  String? _currentGroupId;
  bool _isCreator = false;
  Map<String, dynamic>? _groupInfo;

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

  Future<void> _createGroup() async {
    if (_groupNameController.text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để sử dụng tính năng này'),
        ),
      );
      return;
    }

    final groupId = await _trackingService.createGroup(
      _groupNameController.text,
      user.id,
      user.fullName,
    );

    setState(() {
      _currentGroupId = groupId;
      _isCreator = true;
    });

    _loadGroupInfo();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nhóm đã được tạo với ID: $groupId')),
      );
    }
  }

  Future<void> _joinGroup() async {
    if (_groupIdController.text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để sử dụng tính năng này'),
        ),
      );
      return;
    }

    try {
      await _trackingService.joinGroup(
        _groupIdController.text,
        user.id,
        user.fullName,
      );

      // Kiểm tra xem người dùng có phải là người tạo nhóm không
      final isCreator = await _trackingService.isGroupCreator(
        _groupIdController.text,
        user.id,
      );

      setState(() {
        _currentGroupId = _groupIdController.text;
        _isCreator = isCreator;
      });

      _loadGroupInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tham gia nhóm thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tham gia nhóm')),
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
    ).showSnackBar(const SnackBar(content: Text('Đã rời khỏi nhóm')));
  }

  Future<void> _deleteGroup() async {
    if (_currentGroupId == null) return;

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Xóa nhóm'),
                content: const Text(
                  'Bạn có chắc chắn muốn xóa nhóm này không? Tất cả thành viên sẽ bị rời khỏi nhóm.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Hủy'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Xóa',
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
      ).showSnackBar(const SnackBar(content: Text('Đã xóa nhóm')));
    }
  }

  void _copyGroupId() {
    if (_currentGroupId == null) return;

    Clipboard.setData(ClipboardData(text: _currentGroupId!));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép mã nhóm vào clipboard')),
    );
  }

  void _showMembersDialog() {
    if (_groupInfo == null || _groupInfo!['members'] == null) return;

    final members = _groupInfo!['members'] as Map<dynamic, dynamic>;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Thành viên trong nhóm'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members.entries.elementAt(index);
                  final memberInfo = member.value as Map<dynamic, dynamic>;
                  final memberName = memberInfo['name'] as String;

                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(memberName),
                    subtitle: Text('ID: ${member.key}'),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Theo dõi nhóm')),
        body: const Center(
          child: Text('Vui lòng đăng nhập để sử dụng tính năng này'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentGroupId != null
              ? 'Nhóm: ${_groupInfo?['name'] ?? 'Đang tải...'}'
              : 'Theo dõi nhóm',
        ),
        actions: [
          if (_currentGroupId != null) ...[
            IconButton(
              icon: const Icon(Icons.people),
              tooltip: 'Danh sách thành viên',
              onPressed: _showMembersDialog,
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'copy') {
                  _copyGroupId();
                } else if (value == 'leave') {
                  _leaveGroup(user.id);
                } else if (value == 'delete' && _isCreator) {
                  _deleteGroup();
                }
              },
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          const Icon(Icons.copy),
                          const SizedBox(width: 8),
                          Text('Sao chép mã: $_currentGroupId'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'leave',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app),
                          SizedBox(width: 8),
                          Text('Rời nhóm'),
                        ],
                      ),
                    ),
                    if (_isCreator)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Xóa nhóm',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                  ],
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
                      labelText: 'Tên nhóm mới',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _createGroup,
                    child: const Text('Tạo nhóm mới'),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _groupIdController,
                    decoration: const InputDecoration(labelText: 'Mã nhóm'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _joinGroup,
                    child: const Text('Tham gia nhóm'),
                  ),
                ],
              ),
            )
          else
            GroupTrackingMap(
              groupId: _currentGroupId!,
              userId: user.id,
              userName: user.fullName,
            ),
          if (_currentGroupId != null)
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                children: [
                  FloatingActionButton(
                    heroTag: 'zoomIn',
                    tooltip: 'Phóng to',
                    onPressed: () {
                      // TODO: Cần cập nhật GroupTrackingMap để hỗ trợ zoom
                      // (_mapController?.zoomIn)
                    },
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'zoomOut',
                    tooltip: 'Thu nhỏ',
                    onPressed: () {
                      // TODO: Cần cập nhật GroupTrackingMap để hỗ trợ zoom
                      // (_mapController?.zoomOut)
                    },
                    child: const Icon(Icons.remove),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'location',
                    tooltip: 'Vị trí hiện tại',
                    onPressed: () {
                      // TODO: Cần cập nhật GroupTrackingMap để hỗ trợ di chuyển đến vị trí hiện tại
                      // (_mapController?.moveToCurrentLocation)
                    },
                    child: const Icon(Icons.my_location),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
