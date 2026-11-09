import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class MemberQrScannerScreen extends StatefulWidget {
  const MemberQrScannerScreen({super.key});

  @override
  State<MemberQrScannerScreen> createState() => _MemberQrScannerScreenState();
}

class _MemberQrScannerScreenState extends State<MemberQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isSubmitting = false;
  String? _message;

  Future<void> _submitCode(String code) async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      final response = await context.read<ApiService>().post(
        '/operations/check-in/gym-qr',
        data: {'code': code},
      );
      final member = response.data['member'];
      if (!mounted) return;
      setState(() {
        _message = '${member['name']} checked in successfully.';
        _isSubmitting = false;
      });
      await _controller.stop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = 'Check-in failed: $error';
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gym check-in')),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                final value = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
                if (value == 'GYM-CHECKIN') {
                  _submitCode(value!);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _isSubmitting
                ? const CircularProgressIndicator()
                : Text(_message ?? 'Scan the gym check-in QR code'),
          ),
        ],
      ),
    );
  }
}
