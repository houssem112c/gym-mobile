import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShopService {
  static const String _productsCacheKey = 'shop_products_cache_v1';
  static const String _productsCacheTimeKey = 'shop_products_cache_time_v1';
  static const Duration _productsCacheTtl = Duration(hours: 6);
  static const Duration _requestTimeout = Duration(seconds: 20);

  String get baseUrl {
    if (kIsWeb) return 'http://https://gym-backend-1-qchc.onrender.com/api';
    return 'https://gym-backend-1-qchc.onrender.com/api';
  }

  Future<List<Product>> getProducts({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _readCachedProducts();
      if (cached != null) {
        return cached;
      }
    }

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/products'))
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        await _writeProductsCache(response.body);
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      }

      // Non-200 response: fall back to cache if present
      final cached = await _readCachedProducts(ignoreTtl: true);
      if (cached != null) {
        return cached;
      }

      throw Exception('Failed to load products (${response.statusCode})');
    } catch (e) {
      // Network/timeouts/etc: fall back to cache if present
      final cached = await _readCachedProducts(ignoreTtl: true);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  Future<List<Product>?> _readCachedProducts({bool ignoreTtl = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(_productsCacheKey);
    if (cachedJson == null || cachedJson.isEmpty) return null;

    if (!ignoreTtl) {
      final cachedAtMs = prefs.getInt(_productsCacheTimeKey);
      if (cachedAtMs != null) {
        final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMs);
        final isFresh = DateTime.now().difference(cachedAt) <= _productsCacheTtl;
        if (!isFresh) return null;
      }
    }

    try {
      final List<dynamic> data = json.decode(cachedJson);
      return data.map((json) => Product.fromJson(json)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeProductsCache(String rawBody) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_productsCacheKey, rawBody);
    await prefs.setInt(_productsCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<Map<String, dynamic>> createPaymentIntent(
    double amount,
    String currency,
    String token,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/payments/create-intent'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'amount': amount,
            'currency': currency,
            // 'orderId': orderId // Optionally link to order
          }),
        )
        .timeout(_requestTimeout);

    if (response.statusCode == 201) {
      return json.decode(response.body);
    }

    throw Exception('Failed to create payment intent (${response.statusCode})');
  }

  Future<Map<String, dynamic>> createOrder(
    String token,
    List<Map<String, dynamic>> items,
    double totalAmount, {
    String? paymentIntentId,
    String paymentMethod = 'MONEY',
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/orders'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'items': items,
            'totalAmount': totalAmount,
            'paymentIntentId': paymentIntentId,
            'paymentMethod': paymentMethod,
          }),
        )
        .timeout(_requestTimeout);

    if (response.statusCode == 201) {
      return json.decode(response.body);
    }

    throw Exception('Failed to create order (${response.statusCode})');
  }
}
