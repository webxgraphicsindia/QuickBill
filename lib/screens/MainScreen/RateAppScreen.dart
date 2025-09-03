import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:quickbill/api/API.dart';
import 'package:quickbill/constants/Colors.dart';

class RateAppScreen extends StatefulWidget {
  const RateAppScreen({Key? key}) : super(key: key);

  @override
  _RateAppScreenState createState() => _RateAppScreenState();
}

class _RateAppScreenState extends State<RateAppScreen> {
  final _formKey = GlobalKey<FormState>();
  double _rating = 3.0;
  final TextEditingController _feedbackController = TextEditingController();
  String _feedbackType = 'UI Feedback';
  bool _isSubmitting = false;

  final List<String> _feedbackTypes = [
    'UI Feedback',
    'Bug Report',
    'Feature Request',
    'Performance Issue',
    'Other'
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await apiServices.submitFeedback(
        rating: _rating,
        feedbackType: _feedbackType,
        message: _feedbackController.text,
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Failed to submit feedback')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // Add this to load existing feedback when screen opens
  Future<void> _loadExistingFeedback() async {
    try {
      final response = await apiServices.getUserFeedback();

      if (response.success && response.data != null) {
        setState(() {
          _rating = response.data!.rating ?? 3.0;
          _feedbackType = response.data!.feedbackType ?? 'UI Feedback';
          _feedbackController.text = response.data!.message ?? '';
        });
      }
    } catch (e) {
      print("Error loading feedback: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load previous feedback')),
      );
    }
  }



  @override
  void initState() {
    super.initState();
    _loadExistingFeedback();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'We value your feedback!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Please let us know how we can improve QuickBill',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Rating Section
              const Text(
                'How would you rate your experience?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Center(
                child: RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) {
                    setState(() => _rating = rating);
                  },
                ),
              ),
              const SizedBox(height: 30),

              // Feedback Type Dropdown
              const Text(
                'Feedback Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _feedbackType,
                items: _feedbackTypes.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() => _feedbackType = newValue!);
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Feedback Text Field
              const Text(
                'Your Feedback',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _feedbackController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Please describe your feedback in detail...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your feedback';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Submit Feedback',
                    style: TextStyle(fontSize: 16,color: Colors.white),
                  ),
                ),
              ),

              // Optional: Add some prompt questions
              const SizedBox(height: 30),
              const Text(
                'Consider including:',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 10),
              const Text('• What do you like about the app?'),
              const Text('• What could be improved?'),
              const Text('• Any specific issues you encountered?'),
            ],
          ),
        ),
      ),
    );
  }
}