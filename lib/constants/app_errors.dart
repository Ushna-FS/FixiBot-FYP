


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
// static String humanReadableError(dynamic error, {int? statusCode}) {
//   // Check for specific HTTP error codes FIRST
//   if (statusCode != null) {
//     if (statusCode == 500) {
//       return "Server is currently unavailable. Please try later.";
//     }
//     if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
//       return "Server error. Please try again in a few minutes.";
//     }
//     if (statusCode == 401 || statusCode == 403) {
//       return "Please login again";
//     }
//     if (statusCode == 404) {
//       return "Service not found";
//     }
//   }
  
//   // Then check for network errors
//   if (error is SocketException) {
//     return "No internet connection. Check your network.";
//   }
  
//   // Check error message for server indicators
//   final msg = error.toString().toLowerCase();
  
//   if (msg.contains('500') || 
//       msg.contains('server error') || 
//       msg.contains('internal error') ||
//       msg.contains('502') ||
//       msg.contains('503') ||
//       msg.contains('504')) {
//     return "Server error. Please try later.";
//   }
  
//   // Timeout could be network OR server
//   if (msg.contains('timeout')) {
//     return "Request timed out. Server might be busy.";
//   }
  
//   // Handle other specific cases
//   if (msg.contains('failed host lookup')) {
//     return "Cannot connect to server. Check internet.";
//   }
  
//   if (msg.contains('no authentication')) {
//     return "Please login again";
//   }
  
//   // Default
//   return "Something went wrong. Please try again.";
// }



// constants/app_errors.dart - Update humanReadableError method:
static String humanReadableError(dynamic error, {int? statusCode}) {
  // First handle null errors
  if (error == null) return "An unknown error occurred";
  
  // Check error message for specific patterns FIRST
  final errorStr = error.toString().toLowerCase();
  
  // Handle authentication errors more specifically
  if (errorStr.contains('authentication') || 
      errorStr.contains('unauthorized') || 
      errorStr.contains('no authentication') ||
      errorStr.contains('token') && errorStr.contains('invalid') ||
      errorStr.contains('token') && errorStr.contains('expired')) {
    return "Please login again to continue";
  }
  
  // Check for network connection issues
  if (error is SocketException || 
      errorStr.contains('socket') || 
      errorStr.contains('network is unreachable') ||
      errorStr.contains('failed host lookup')) {
    return "No internet connection. Please check your network.";
  }
  
  // Check for timeout errors (could be network OR server)
  if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
    return "Request timed out. Please try again.";
  }
  
  // Handle specific HTTP status codes
  if (statusCode != null) {
    switch (statusCode) {
      case 400:
        return "Bad request. Please try again.";
      case 401:
        return "Session expired. Please login again.";
      case 403:
        return "Access denied. You don't have permission.";
      case 404:
        return "Service not found.";
      case 408:
        return "Request timeout. Server took too long to respond.";
      case 429:
        return "Too many requests. Please wait a moment.";
      case 500:
        return "Server is currently unavailable. Please try later.";
      case 502:
      case 503:
      case 504:
        return "Server error. Please try again in a few minutes.";
    }
  }
  
  // Check error message for server indicators
  if (errorStr.contains('500') || 
      errorStr.contains('server error') || 
      errorStr.contains('internal error') ||
      errorStr.contains('502') ||
      errorStr.contains('503') ||
      errorStr.contains('504')) {
    return "Server error. Please try later.";
  }
  
  // Handle connection refused
  if (errorStr.contains('connection refused') || 
      errorStr.contains('connection reset')) {
    return "Cannot connect to server. Please try again.";
  }
  
  // Handle handshake errors
  if (errorStr.contains('handshake')) {
    return "Secure connection failed. Please check your time settings.";
  }
  
  // Default fallback
  if (error is String) {
    if (error.isNotEmpty) return error;
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