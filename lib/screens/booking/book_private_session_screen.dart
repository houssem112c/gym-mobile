
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/private_session.dart';
import '../../services/private_session_service.dart';
import 'package:intl/intl.dart';

class BookPrivateSessionScreen extends StatefulWidget {
  final DateTime initialDate;

  const BookPrivateSessionScreen({Key? key, required this.initialDate}) : super(key: key);

  @override
  _BookPrivateSessionScreenState createState() => _BookPrivateSessionScreenState();
}

class _BookPrivateSessionScreenState extends State<BookPrivateSessionScreen> {
  final PrivateSessionService _privateSessionService = PrivateSessionService();
  
  List<User> _coaches = [];
  User? _selectedCoach;
  bool _isLoadingCoaches = true;
  
  List<SessionAvailability> _availability = [];
  String? _selectedTime;
  bool _isLoadingAvailability = false;
  
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCoaches();
  }

  Future<void> _fetchCoaches() async {
    try {
      final coaches = await _privateSessionService.getCoaches();
      setState(() {
        _coaches = coaches;
        _isLoadingCoaches = false;
      });
    } catch (e) {
      setState(() => _isLoadingCoaches = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load coaches: $e')));
    }
  }

  Future<void> _fetchAvailability() async {
    if (_selectedCoach == null) return;
    
    setState(() {
      _isLoadingAvailability = true;
      _availability = [];
      _selectedTime = null;
    });

    try {
      final availability = await _privateSessionService.getAvailability(
        _selectedCoach!.id, 
        widget.initialDate
      );
      setState(() {
        _availability = availability;
        _isLoadingAvailability = false;
      });
    } catch (e) {
      setState(() => _isLoadingAvailability = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load availability: $e')));
    }
  }

  Future<void> _bookSession() async {
    if (_selectedCoach == null || _selectedTime == null) return;

    try {
      // Calculate endTime (assume 1 hr)
      final startHour = int.parse(_selectedTime!.split(':')[0]);
      final endHour = startHour + 1;
      final endTime = '${endHour.toString().padLeft(2, '0')}:00';

      await _privateSessionService.requestSession(
        coachId: _selectedCoach!.id,
        date: widget.initialDate,
        startTime: _selectedTime!,
        endTime: endTime,
        note: _noteController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent successfully!')));
      Navigator.pop(context, true); // Return true to refresh calendar
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to book session: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Dark theme background
      appBar: AppBar(
        title: const Text('Book Private Session'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: ${DateFormat('yyyy-MM-dd').format(widget.initialDate)}',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            const Text('Select Coach', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            _isLoadingCoaches
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<User>(
                    dropdownColor: const Color(0xFF2A2A2A),
                    value: _selectedCoach,
                    items: _coaches.map((coach) {
                      return DropdownMenuItem(
                        value: coach,
                        child: Text(coach.name, style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (User? value) {
                      setState(() {
                        _selectedCoach = value;
                      });
                      _fetchAvailability();
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

            const SizedBox(height: 20),
            
            if (_selectedCoach != null) ...[
              const Text('Available Slots', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 10),
              _isLoadingAvailability
                  ? const Center(child: CircularProgressIndicator())
                  : _availability.isEmpty
                      ? const Text('No slots available', style: TextStyle(color: Colors.white))
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _availability.map((slot) {
                            final isSelected = _selectedTime == slot.time;
                            return ChoiceChip(
                              label: Text(slot.time),
                              selected: isSelected,
                              onSelected: slot.isAvailable ? (selected) {
                                setState(() {
                                  _selectedTime = selected ? slot.time : null;
                                });
                              } : null,
                              selectedColor: Colors.blue,
                              backgroundColor: slot.isAvailable ? const Color(0xFF333333) : const Color(0xFF222222),
                              labelStyle: TextStyle(
                                color: slot.isAvailable ? Colors.white : Colors.grey,
                              ),
                            );
                          }).toList(),
                        ),
              
              const SizedBox(height: 20),
              const Text('Note (Optional)', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 10),
              TextField(
                controller: _noteController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  hintText: 'Any special requests?',
                  hintStyle: const TextStyle(color: Colors.grey),
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedTime != null ? _bookSession : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Request Session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
