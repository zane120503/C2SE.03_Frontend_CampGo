import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/realtime_tracking_service.dart';
import 'widgets/group_tracking_map.dart';
import '../../providers/auth_provider.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

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
  final GlobalKey _menuKey = GlobalKey();
  OverlayEntry? _menuOverlayEntry;
  final GlobalKey<State<GroupTrackingMap>> _mapKey = GlobalKey<State<GroupTrackingMap>>();

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

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Members in group'),
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
                child: const Text('Close'),
              ),
            ],
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
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
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
                ],
              ),
            ),
        ],
      ),
    );
  }
}
