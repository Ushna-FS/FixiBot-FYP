


// constants/app_errors.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';

class AppErrors {
  // // Human readable error messages
  // constants/app_errors.dart - Update humanReadableError method:
static String humanReadableError(dynamic error, {int? statusCode}) {
  // Check for specific HTTP error codes FIRST
  if (statusCode != null) {
    if (statusCode == 500) {
      return "Server is currently unavailable. Please try later.";
    }
    if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
      return "Server error. Please try again in a few minutes.";
    }
    if (statusCode == 401 || statusCode == 403) {
      return "Please login again";
    }
    if (statusCode == 404) {
      return "Service not found";
    }
  }
  
  // Then check for network errors
  if (error is SocketException) {
    return "No internet connection. Check your network.";
  }
  
  // Check error message for server indicators
  final msg = error.toString().toLowerCase();
  
  if (msg.contains('500') || 
      msg.contains('server error') || 
      msg.contains('internal error') ||
      msg.contains('502') ||
      msg.contains('503') ||
      msg.contains('504')) {
    return "Server error. Please try later.";
  }
  
  // Timeout could be network OR server
  if (msg.contains('timeout')) {
    return "Request timed out. Server might be busy.";
  }
  
  // Handle other specific cases
  if (msg.contains('failed host lookup')) {
    return "Cannot connect to server. Check internet.";
  }
  
  if (msg.contains('no authentication')) {
    return "Please login again";
  }
  
  // Default
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