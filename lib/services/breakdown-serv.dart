import 'dart:convert';
import 'package:fixibot_app/model/breakdownsModel.dart';
import 'package:flutter/services.dart';


class BreakdownService {
  static Future<List<BreakdownModel>> loadBreakdowns() async {
    final String response =
        await rootBundle.loadString('assets/breakdowns.json');
    final data = json.decode(response);

    final List breakdowns = data["Breakdowns"];
    return breakdowns.map((b) => BreakdownModel.fromJson(b)).toList();
  }
}