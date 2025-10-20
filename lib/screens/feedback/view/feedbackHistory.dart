import 'package:fixibot_app/constants/app_colors.dart';
import 'package:fixibot_app/model/feedbackModel.dart';
import 'package:fixibot_app/screens/feedback/controller/feedbackController.dart';
import 'package:fixibot_app/screens/feedback/view/feedback_popup.dart';
import 'package:fixibot_app/widgets/customAppBar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FeedbackHistoryScreen extends StatelessWidget {
  final FeedbackController controller = Get.find<FeedbackController>();

  FeedbackHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title:  "Feedback Histroy",
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: AppColors.textColor,
            onPressed: () {
              controller.loadFeedbackHistory();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingHistory.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                color: AppColors.mainColor,
                child: TabBar(
                  labelColor: AppColors.textColor2,
                  unselectedLabelColor: AppColors.secondaryColor,
                  indicatorColor: AppColors.textColor2,
                  tabs: const [
                    Tab(
                      text: 'Pending Feedback',
                      icon: Icon(Icons.pending_actions),
                    ),
                    Tab(
                      text: 'Feedback History',
                      icon: Icon(Icons.history),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // PENDING TAB
                    _buildPendingTab(),
                    // HISTORY TAB
                    _buildHistoryTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPendingTab() {
    if (controller.pendingFeedback.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feedback_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Pending Feedback',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Complete services will appear here for feedback',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.pendingFeedback.length,
      itemBuilder: (context, index) {
        final feedback = controller.pendingFeedback[index];
        return _buildPendingFeedbackCard(feedback);
      },
    );
  }

  Widget _buildPendingFeedbackCard(FeedbackModel feedback) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    feedback.mechanicName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              feedback.serviceType,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Service ID: ${feedback.serviceId}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () {
                    _showSkipConfirmationDialog(feedback.serviceId);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: const Text('Skip'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _showFeedbackDialog(feedback);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Give Feedback'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (controller.feedbackHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Feedback History',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Your submitted feedback will appear here',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.feedbackHistory.length,
      itemBuilder: (context, index) {
        final feedback = controller.feedbackHistory[index];
        return _buildHistoryFeedbackCard(feedback);
      },
    );
  }

  Widget _buildHistoryFeedbackCard(FeedbackModel feedback) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    feedback.mechanicName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Submitted',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              feedback.serviceType,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Service ID: ${feedback.serviceId}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            // Rating stars
            Row(
              children: List.generate(5, (starIndex) {
                return Icon(
                  starIndex < feedback.rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                );
              }),
            ),
            const SizedBox(height: 8),
            // Comment
            if (feedback.comment.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Comment:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feedback.comment,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submitted: ${_formatDate(feedback.createdAt)}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    if (feedback.updatedAt != null)
                      Text(
                        'Updated: ${_formatDate(feedback.updatedAt!)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    _showUpdateFeedbackDialog(feedback);
                  },
                  child: const Text(
                    'Edit Feedback',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog(FeedbackModel feedback) {
    // Create a temporary service map for the feedback popup
    final serviceData = {
      '_id': feedback.serviceId,
      'mechanic_id': feedback.mechanicId,
      'mechanic_name': feedback.mechanicName,
      'service_type': feedback.serviceType,
      'created_at': feedback.createdAt.toIso8601String(),
    };

    Get.dialog(
      Dialog(
        child: FeedbackPopup(
          service: serviceData,
          controller: controller,
        ),
      ),
    );
  }

 // In FeedbackHistoryScreen, update the _showUpdateFeedbackDialog method:
void _showUpdateFeedbackDialog(FeedbackModel feedback) {
  final updatedRating = feedback.rating.obs;
  final updatedComment = TextEditingController(text: feedback.comment);

  Get.dialog(
    Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Feedback',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Rate your experience:'),
            const SizedBox(height: 8),
            Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    updatedRating.value = index + 1;
                  },
                  icon: Icon(
                    index < updatedRating.value ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 30,
                  ),
                );
              }),
            )),
            const SizedBox(height: 16),
            const Text('Comments:'),
            const SizedBox(height: 8),
            TextField(
              controller: updatedComment,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Update your comments...',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    // Use serviceId instead of feedbackId
                    final success = await controller.updateFeedback(
                      serviceId: feedback.serviceId, // Pass serviceId
                      newRating: updatedRating.value,
                      newComment: updatedComment.text,
                    );
                    
                    if (success) {
                      Get.back();
                      Get.snackbar(
                        'Success',
                        'Feedback updated successfully',
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                      );
                    } else {
                      Get.snackbar(
                        'Error',
                        'Failed to update feedback',
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
  void _showSkipConfirmationDialog(String serviceId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Skip Feedback?'),
        content: const Text('Are you sure you want to skip giving feedback for this service?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.removePendingFeedback(serviceId);
              Get.back();
              Get.snackbar(
                'Skipped',
                'Feedback skipped for this service',
                backgroundColor: Colors.orange,
                colorText: Colors.white,
              );
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}