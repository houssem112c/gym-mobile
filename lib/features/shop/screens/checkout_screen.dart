import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/shop_service.dart';
import '../services/shop_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../providers/gamification_provider.dart';
import 'package:flutter/foundation.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final ShopService _shopService = ShopService();
  bool _isLoading = false;
  String _paymentMethod = 'MONEY';

  Future<void> _handlePayment() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.totalAmount <= 0) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final gamificationProvider = Provider.of<GamificationProvider>(context, listen: false);
      final token = authService.token;

      if (token == null) {
        throw Exception('auth_required'.tr());
      }

      String? paymentIntentId;

      if (_paymentMethod == 'MONEY') {
        // 1. Create Payment Intent
        final paymentData = await _shopService.createPaymentIntent(
          cart.totalAmount,
          'usd',
          token,
        );

        final clientSecret = paymentData['clientSecret'];
        paymentIntentId = paymentData['paymentIntentId'];

        if (kIsWeb) {
          // Web Payment Flow
          await Stripe.instance.confirmPayment(
            paymentIntentClientSecret: clientSecret,
            data: const PaymentMethodParams.card(
              paymentMethodData: PaymentMethodData(),
            ),
          );
        } else {
          // Mobile Payment Flow
          // 2. Initialize Payment Sheet
          await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: clientSecret,
              merchantDisplayName: 'Gym Shop',
              style: ThemeMode.dark,
            ),
          );

          // 3. Display Payment Sheet
          await Stripe.instance.presentPaymentSheet();
        }
      } else {
        // XP Payment Flow
        final currentPoints = gamificationProvider.userGamification?.totalPoints ?? 0;
        if (currentPoints < cart.totalPoints) {
          throw Exception('insufficient_points'.tr());
        }
      }

      // 4. On Success
      await _shopService.createOrder(
        token,
        cart.items.values
            .map((item) => {
                  'productId': item.product.id,
                  'quantity': item.quantity,
                })
            .toList(),
        cart.totalAmount,
        paymentIntentId: paymentIntentId,
        paymentMethod: _paymentMethod,
      );

      if (_paymentMethod == 'POINTS') {
        gamificationProvider.loadData(); // Refresh points
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('payment_success'.tr())),
      );
      cart.clear();
      Navigator.of(context).pop(); // Go back
    } on StripeException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('payment_error'.tr(args: [e.error.localizedMessage ?? '']))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    
    return Scaffold(
      appBar: AppBar(title: Text('checkout_title'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blueGrey[900],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                   Text(
                    'total_to_pay'.tr(),
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${cart.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Divider(height: 32, color: Colors.white24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('points_total'.tr(), style: const TextStyle(color: Colors.white70)),
                      Text('${cart.totalPoints} XP', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'select_payment_method'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentMethodTile(
              title: 'pay_with_money'.tr(),
              subtitle: 'Visa, Mastercard, etc.',
              icon: Icons.credit_card,
              value: 'MONEY',
            ),
            const SizedBox(height: 12),
            _buildPaymentMethodTile(
              title: 'pay_with_points'.tr(),
              subtitle: 'Use your earned XP points',
              icon: Icons.stars,
              value: 'POINTS',
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handlePayment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _paymentMethod == 'MONEY'
                            ? (kIsWeb ? 'pay_now'.tr() : 'checkout'.tr())
                            : 'pay_with_points'.tr(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _paymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? Colors.blue.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}
