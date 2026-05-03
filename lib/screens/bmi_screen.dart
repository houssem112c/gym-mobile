import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/bmi.dart';
import '../services/bmi_service.dart';
import '../services/auth_service.dart';
import 'bmi_history_screen.dart';

class BmiScreen extends StatefulWidget {
  final AuthService authService;
  final BmiService bmiService;

  const BmiScreen({
    Key? key,
    required this.authService,
    required this.bmiService,
  }) : super(key: key);

  @override
  State<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends State<BmiScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _age;
  Gender? _gender;
  double? _height;
  double? _weight;
  bool _loading = false;
  BmiCalculationResult? _result;
  String? _error;

  void _calculateAndSave() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final req = CreateBmiRequest(
        age: _age!,
        gender: _gender!,
        height: _height!,
        weight: _weight!,
      );
      // Save to backend and get result
      final record = await widget.bmiService.createBmiRecord(req);
      setState(() {
        _result = BmiCalculationResult(
          bmiValue: record.bmiValue,
          category: record.category,
          status: record.status,
          recommendations: record.notes,
          input: req,
        );
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('bmi_title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BmiHistoryScreen(bmiService: widget.bmiService),
                ),
              );
            },
            tooltip: 'BMI History',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'bmi_age'.tr()),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final val = int.tryParse(v ?? '');
                  if (val == null || val < 2 || val > 120) {
                    return 'bmi_error_age'.tr();
                  }
                  return null;
                },
                onSaved: (v) => _age = int.parse(v!),
              ),
              DropdownButtonFormField<Gender>(
                decoration: InputDecoration(labelText: 'bmi_gender'.tr()),
                items: [
                  DropdownMenuItem(value: Gender.male, child: Text('bmi_male'.tr())),
                  DropdownMenuItem(value: Gender.female, child: Text('bmi_female'.tr())),
                ],
                validator: (v) => v == null ? 'bmi_error_gender'.tr() : null,
                onChanged: (v) => setState(() => _gender = v),
                onSaved: (v) => _gender = v,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'bmi_height'.tr()),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final val = double.tryParse(v ?? '');
                  if (val == null || val < 0.5 || val > 2.5) {
                    return 'bmi_error_height'.tr();
                  }
                  return null;
                },
                onSaved: (v) => _height = double.parse(v!),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'bmi_weight'.tr()),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final val = double.tryParse(v ?? '');
                  if (val == null || val < 10 || val > 300) {
                    return 'bmi_error_weight'.tr();
                  }
                  return null;
                },
                onSaved: (v) => _weight = double.parse(v!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _calculateAndSave,
                child: _loading ? const CircularProgressIndicator() : Text('bmi_calculate'.tr()),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              if (_result != null) ...[
                const SizedBox(height: 24),
                Card(
                  color: _result!.status == BmiStatus.ok
                      ? Colors.green[100]
                      : _result!.status == BmiStatus.caution
                          ? Colors.yellow[100]
                          : Colors.red[100],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BMI: ${_result!.bmiValue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20)),
                        Text('Category: ${_result!.category}', style: const TextStyle(fontSize: 18)),
                        Text('Status: ${_result!.status.name.toUpperCase()}', style: const TextStyle(fontSize: 16)),
                        if (_result!.recommendations != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('Advice: ${_result!.recommendations!}', style: const TextStyle(fontSize: 15)),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
