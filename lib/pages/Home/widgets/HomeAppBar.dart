import 'package:flutter/material.dart';
import 'package:CampGo/pages/TaskBar/TaskBarPage.dart';
import 'package:CampGo/pages/ChatBot/ChatBotPage.dart';

class HomeAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Function(String?, double?, double?) onFiltersApplied;

  const HomeAppBar({
    super.key,
    required this.onFiltersApplied,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  _HomeAppBarState createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar> with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showTaskbarOverlay(BuildContext context) {
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight +
                 (_animation.value * 300),
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _hideTaskbarOverlay,
                    child: Container(
                      height: MediaQuery.of(context).size.height,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                  TaskBar(
                    onClose: _hideTaskbarOverlay,
                    onFiltersApplied: widget.onFiltersApplied,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }

  void _hideTaskbarOverlay() {
    if (_animationController.isAnimating) {
      _animationController.reverse();
    }
    
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(
          Icons.sort,
          size: 30,
          color: Color(0xFF2B2321),
        ),
        onPressed: () => _showTaskbarOverlay(context),
      ),
      title: const Text(
        "CampGo",
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2B2321),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.smart_toy,
            size: 30,
            color: Color(0xFF2B2321),
          ),
          onPressed: () {
            if (_overlayEntry != null) {
              _hideTaskbarOverlay();
            }
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatBotPage()),
            );
          },
        ),
      ],
    );
  }
}