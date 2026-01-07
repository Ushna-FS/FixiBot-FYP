// constants/app_errors.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';

class AppErrors {
  // Human readable error messages
  static String humanReadableError(dynamic error, {int? statusCode}) {
    if (error is SocketException) {
      return "No internet connection. Please check your network.";
    }

    if (error is HttpException) {
      return "Unable to communicate with the server.";
    }

    if (error is FormatException) {
      return "Something went wrong while processing data.";
    }

    final msg = error.toString().toLowerCase();

    if (msg.contains('timeout')) {
      return "Request timed out. Please try again.";
    }

    if (msg.contains('unauthorized') || statusCode == 401) {
      return "Your session has expired. Please login again.";
    }

    if (msg.contains('500') || statusCode == 500) {
      return "Server is unavailable. Please try later.";
    }

    if (msg.contains('404')) {
      return "Requested service not found.";
    }

    if (msg.contains('socket')) {
      return "Network issue detected. Check your internet.";
    }

    // Handle specific error patterns
    if (msg.contains('no authentication token found')) {
      return "Your session has expired. Please login again.";
    }

    if (msg.contains('user not logged in')) {
      return "Please login to continue.";
    }

    if (msg.contains('server error')) {
      return "Server is experiencing issues. Please try again later.";
    }

    return "Something went wrong. Please try again.";
  }

  // Show error snackbar
  static void showError(dynamic error, {int? statusCode, String? title}) {
    Get.snackbar(
      title ?? "Error",
      humanReadableError(error, statusCode: statusCode),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: Duration(seconds: 4),
    );
  }

  // Show success snackbar
  static void showSuccess(String message, {String? title}) {
    Get.snackbar(
      title ?? "Success",
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: Duration(seconds: 3),
    );
  }

  // Parse server error message
  static String parseServerError(dynamic responseBody) {
    try {
      if (responseBody is String) {
        final errorData = jsonDecode(responseBody);
        return errorData['detail'] ?? 
               errorData['message'] ?? 
               errorData['error'] ?? 
               "Server error occurred";
      }
      return "Server error occurred";
    } catch (e) {
      if (responseBody is String && responseBody.isNotEmpty) {
        return responseBody;
      }
      return "Server error occurred";
    }
  }
}