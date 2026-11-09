import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../services/shop_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late Future<List<Map<String, dynamic>>> _orders;
  final ShopService _shopService = ShopService();

  @override
  void initState() {
    super.initState();
    _orders = _loadOrders();
  }

  Future<List<Map<String, dynamic>>> _loadOrders() async {
    final auth = context.read<AuthService>();
    await auth.initialization;
    if (!auth.isAuthenticated) {
      throw const UnauthorizedException();
    }
    try {
      return await _shopService.getMyOrders(auth);
    } on UnauthorizedException {
      try {
        await auth.refreshSession();
      } catch (_) {
        await auth.logout();
        throw const UnauthorizedException();
      }
      return _shopService.getMyOrders(auth);
    }
  }

  Color _statusColor(String status) {
    if (status == 'DELIVERED') return Colors.green;
    if (status == 'SHIPPED') return Colors.blue;
    if (status == 'PROCESSING') return Colors.orange;
    if (status == 'CANCELLED') return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My deliveries')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _orders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            if (snapshot.error is UnauthorizedException) {
              return const Center(
                  child: Text('Your session expired. Please log in again.'));
            }
            return Center(
                child: Text('Unable to load deliveries: ${snapshot.error}'));
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) return const Center(child: Text('No orders yet'));
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _orders = _loadOrders();
              });
              await _orders;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (_, index) {
                final order = orders[index];
                final status = order['status'] as String? ?? 'PENDING';
                final paid = order['paymentStatus'] == 'PAID';
                final items = (order['items'] as List<dynamic>? ?? const [])
                    .whereType<Map<String, dynamic>>()
                    .toList();
                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Order #${(order['id'] as String).substring(0, 8)}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        if (items.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          const Text('Products',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...items.map(_buildOrderItem),
                        ],
                        const SizedBox(height: 10),
                        Row(children: [
                          const Text('Payment: '),
                          Text(
                              paid
                                  ? 'Accepted'
                                  : 'Waiting for in-person payment',
                              style: TextStyle(
                                  color: paid ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Text('Delivery: '),
                          Text(status,
                              style: TextStyle(
                                  color: _statusColor(status),
                                  fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: status == 'DELIVERED'
                              ? 1
                              : status == 'SHIPPED'
                                  ? .75
                                  : status == 'PROCESSING'
                                      ? .5
                                      : .2,
                          color: _statusColor(status),
                        ),
                        const SizedBox(height: 8),
                        Text(
                            '\$${(order['totalAmount'] as num).toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final product = item['product'] as Map<String, dynamic>? ?? const {};
    final name = product['name'] as String? ?? 'Product';
    final quantity = item['quantity'] as num? ?? 1;
    final price =
        (item['price'] as num? ?? product['price'] as num? ?? 0).toDouble();
    final imageUrl = product['imageUrl'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _productPlaceholder()),
            )
          else
            _productPlaceholder(),
          const SizedBox(width: 10),
          Expanded(
            child: Text('$name x${quantity.toInt()}',
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          Text('\$${price.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _productPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.shopping_bag_outlined, color: Colors.white70),
    );
  }
}
