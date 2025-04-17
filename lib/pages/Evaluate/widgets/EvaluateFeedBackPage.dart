import 'dart:io';
import 'package:CampGo/api/api.service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:CampGo/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final TextEditingController _commentController = TextEditingController();
  double _rating = 0;
  final List<String> _selectedImages = [];

  @override
  Widget build(BuildContext context) {
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
                    leading: widget.productImage != null
                        ? Image.network(
                            widget.productImage!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported),
                              );
                            },
                          )
                        : const Icon(Icons.image_not_supported),
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
                        return Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_selectedImages[index]),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
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
                    onPressed: _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
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
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((file) => file.path));
      });
    }
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn số sao đánh giá',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng viết nhận xét của bạn',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Lấy thông tin người dùng hiện tại
      final userProfile = await APIService.getUserProfile();
      if (userProfile['success'] != true) {
        throw Exception('Không thể lấy thông tin người dùng');
      }

      final userData = userProfile['userData'];
      final firstName = userData['first_name'] ?? '';
      final lastName = userData['last_name'] ?? '';

      // Giữ nguyên rating là double
      final double rating = _rating;

      final success = await APIService.createProductReview(
        widget.productId,
        rating, // Sử dụng rating là double
        _commentController.text,
        _selectedImages,
        firstName: firstName,
        lastName: lastName,
      );

      // Hide loading indicator
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (success) {
        if (context.mounted) {
          // Pop trang review và trả về true để báo hiệu đánh giá thành công
          Navigator.pop(context, true);
          
          // Hiển thị thông báo thành công
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã gửi đánh giá thành công',
              textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading indicator if still showing
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
