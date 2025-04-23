import 'dart:io';
import 'package:CampGo/api/api.service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:CampGo/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:CampGo/services/share_service.dart';

class EvaluateFeedBackPage extends StatefulWidget {
  final String productId;
  final String productName;
  final String? productImage;

  const EvaluateFeedBackPage({
    super.key,
    required this.productId,
    required this.productName,
    this.productImage,
  });

  @override
  State<EvaluateFeedBackPage> createState() => _EvaluateFeedBackPageState();
}

class _EvaluateFeedBackPageState extends State<EvaluateFeedBackPage> {
  late TextEditingController _commentController;
  double _rating = 0;
  final List<File> _selectedImages = [];
  bool _isSubmitting = false;
  bool _hasReviewed = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _checkIfReviewed();
  }

  Future<void> _checkIfReviewed() async {
    try {
      final response = await APIService.getProductReviews(widget.productId);
      if (response != null && 
          response['success'] == true && 
          response['data'] != null) {
        final reviews = List<Map<String, dynamic>>.from(response['data']['reviews'] ?? []);
        final userInfo = await ShareService.getUserInfo();
        if (userInfo != null) {
          final userName = userInfo['userName'] as String?;
          if (userName != null) {
            setState(() {
              _hasReviewed = reviews.any((review) => 
                '${review['first_name'] ?? ''} ${review['last_name'] ?? ''}' == userName
              );
            });
          }
        }
      }
    } catch (e) {
      print('Error checking review status: $e');
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasReviewed) {
      return Scaffold(
        backgroundColor: const Color(0xFFEDECF2),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(82.0),
          child: AppBar(
            backgroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  size: 30,
                  color: Colors.black,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            title: Container(
              margin: const EdgeInsets.only(top: 0),
              child: const Text(
                'Write A Review',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            centerTitle: true,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bạn đã đánh giá sản phẩm này',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mỗi sản phẩm chỉ có thể đánh giá một lần',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text(
                    'Quay lại',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // Tắt bàn phím khi nhấn ra ngoài
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEDECF2),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(82.0),
          child: AppBar(
            backgroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  size: 30,
                  color: Colors.black,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            title: Container(
              margin: const EdgeInsets.only(top: 0),
              child: const Text(
                'Write A Review',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            centerTitle: true,
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product information
                Card(
                  child: ListTile(
                    leading: widget.productImage != null && widget.productImage!.startsWith('http')
                        ? Image.network(
                            widget.productImage!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading product image: $error');
                              return Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported),
                              );
                            },
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported),
                          ),
                    title: Text(
                      widget.productName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Rating stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 40,
                      ),
                      onPressed: () {
                        setState(() {
                          _rating = index + 1;
                        });
                      },
                    );
                  }),
                ),

                const SizedBox(height: 16),
                // Comment field
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Write your review here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  textInputAction: TextInputAction.done,
                  onEditingComplete: () {
                    FocusScope.of(context).unfocus();
                  },
                ),

                // Image picker
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Add Photos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                // Selected images preview
                if (_selectedImages.isNotEmpty)
                  Container(
                    height: 100,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        final imagePath = _selectedImages[index].path;
                        return Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImages[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Error loading image: $error');
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image_not_supported),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              right: 7.5,
                              top: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImages.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                // Submit button
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Submit Review',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.clear(); // Xóa ảnh cũ
          for (var file in pickedFiles) {
            try {
              // Kiểm tra xem file có tồn tại không
              if (file.path.isNotEmpty) {
                // Tạo một bản sao tạm thời của file
                final tempFile = File(file.path);
                if (tempFile.existsSync()) {
                  // Đọc file và kiểm tra xem có thể đọc được không
                  final bytes = tempFile.readAsBytesSync();
                  if (bytes.isNotEmpty) {
                    _selectedImages.add(tempFile);
                  }
                }
              }
            } catch (e) {
              print('Error processing image: $e');
            }
          }
        });
      }
    } catch (e) {
      print('Error picking images: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn số sao đánh giá')),
      );
      return;
    }

    if (_commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung đánh giá')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Kiểm tra đăng nhập
      final isLoggedIn = await ShareService.isLoggedIn();
      if (!isLoggedIn) {
        throw Exception('Vui lòng đăng nhập để đánh giá sản phẩm');
      }

      // Lấy token
      final token = await ShareService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Không tìm thấy token đăng nhập');
      }

      // Lấy thông tin người dùng
      final userInfo = await ShareService.getUserInfo();
      if (userInfo == null) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      // Chuẩn bị danh sách đường dẫn ảnh
      final List<String> imagePaths = [];
      for (var file in _selectedImages) {
        if (file.existsSync()) {
          imagePaths.add(file.path);
        }
      }

      // Gọi API
      final success = await APIService.createProductReview(
        widget.productId,
        _rating,
        _commentController.text,
        imagePaths,
        firstName: userInfo['userName']?.split(' ').first,
        lastName: userInfo['userName']?.split(' ').last,
      );

      if (success) {
        // Tạo đối tượng review mới
        final newReview = {
          'first_name': userInfo['userName']?.split(' ').first,
          'last_name': userInfo['userName']?.split(' ').last,
          'rating': _rating,
          'comment': _commentController.text,
          'images': imagePaths,
          'created_at': DateTime.now().toIso8601String(),
        };

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đánh giá thành công')),
        );
        Navigator.pop(context, newReview); // Trả về review mới
      } else {
        throw Exception('Có lỗi xảy ra khi đánh giá');
      }
    } catch (e) {
      print('Error submitting review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}
