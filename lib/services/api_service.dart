import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl = "http://test0.gpstrack.in:9010";

  static Future<Map<String, dynamic>?> sendImageForPrediction(File image) async {
    try {
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(image.path, filename: 'canvas.png'),
      });

      Response response = await Dio().post('$baseUrl/predict', data: formData);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        return null;
      }
    } catch (e) {
      print("Prediction error: $e");
      return null;
    }
  }
}
