import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_provider.dart';
import '../models/request_model.dart';
import '../services/customer_service.dart';

/// AddReviewScreen
/// Interactive form for submitting a review and rating for a vendor request with amber star animations.
class AddReviewScreen extends StatefulWidget {
  final RequestModel request;

  const AddReviewScreen({super.key, required this.request});

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final CustomerService _customerService = CustomerService();
  final _commentController = TextEditingController();
  int _selectedRating = 5;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isSubmitting = true);

    try {
      await _customerService.addReview(
        token,
        requestId: widget.request.id,
        rating: _selectedRating,
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff12141C),
      appBar: AppBar(
        backgroundColor: const Color(0xff1A1D27),
        elevation: 0,
        title: const Text('Leave Shop Review', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vendor Summary Card
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: const Color(0xff1A1D27),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xff2A2E3D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.request.shopName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Component: ${widget.request.modelName}',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Rating Selector Container
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: const Color(0xff1A1D27),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xff2A2E3D)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Rate Your Experience',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        iconSize: 40,
                        icon: Icon(
                          starValue <= _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedRating = starValue;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_selectedRating / 5 Stars',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Comment Field
            TextFormField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Comment / Review (Optional)',
                hintText: 'Share details about part condition, vendor response time, etc.',
                labelStyle: const TextStyle(color: Colors.grey),
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: const Color(0xff1A1D27),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xff2A2E3D)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.amber),
                ),
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Submit Review', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
