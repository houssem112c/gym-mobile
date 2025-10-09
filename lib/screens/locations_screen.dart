import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/colors.dart';
import '../widgets/gradient_background.dart';
import '../models/location.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();
  List<GymLocation> _locations = [];
  GymLocation? _selectedLocation;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await _apiService.get(ApiConfig.locationsActive);
      final List<dynamic> data = response.data;
      final locations = data.map((json) => GymLocation.fromJson(json)).toList();
      
      setState(() {
        _locations = locations;
        _isLoading = false;
        if (locations.isNotEmpty) {
          _selectedLocation = locations[0];
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load locations: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const GradientBackground(
              child: Center(child: CircularProgressIndicator()),
            )
          : _error.isNotEmpty
              ? GradientBackground(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.gray600,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _error,
                            style: TextStyle(color: AppColors.gray400),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadLocations,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : _locations.isEmpty
                  ? GradientBackground(
                      child: Center(
                        child: Text(
                          'No locations available',
                          style: TextStyle(color: AppColors.gray400),
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        // Map
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: LatLng(
                              _locations[0].latitude,
                              _locations[0].longitude,
                            ),
                            initialZoom: 13.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.gym',
                            ),
                            MarkerLayer(
                              markers: _locations.map((location) {
                                final isSelected = _selectedLocation?.id == location.id;
                                return Marker(
                                  point: LatLng(location.latitude, location.longitude),
                                  width: 40,
                                  height: 40,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedLocation = location;
                                      });
                                      _mapController.move(
                                        LatLng(location.latitude, location.longitude),
                                        14.0,
                                      );
                                    },
                                    child: Icon(
                                      Icons.location_on,
                                      color: isSelected 
                                          ? AppColors.primary400 
                                          : AppColors.primary600,
                                      size: isSelected ? 40 : 32,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        
                        // Header
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.7),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Our Locations',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Location cards
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: MediaQuery.of(context).size.height * 0.4,
                                minHeight: 200,
                              ),
                              child: PageView.builder(
                                itemCount: _locations.length,
                                onPageChanged: (index) {
                                  final location = _locations[index];
                                  setState(() {
                                    _selectedLocation = location;
                                  });
                                  _mapController.move(
                                    LatLng(location.latitude, location.longitude),
                                    14.0,
                                  );
                                },
                                itemBuilder: (context, index) {
                                  final location = _locations[index];
                                  return _buildLocationCard(location);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildLocationCard(GymLocation location) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gray800.withOpacity(0.95),
            AppColors.gray900.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray700),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      location.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary500.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: AppColors.primary400,
                      size: 20,
                    ),
                  ),
                ],
              ),
              if (location.description != null) ...[
                const SizedBox(height: 6),
                Text(
                  location.description!,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.gray300,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              if (location.address != null)
                _buildInfoRow(Icons.location_city, location.address!),
              if (location.phone != null) ...[
                const SizedBox(height: 6),
                _buildInfoRow(Icons.phone, location.phone!),
              ],
              if (location.email != null) ...[
                const SizedBox(height: 6),
                _buildInfoRow(Icons.email, location.email!),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openInMaps(location),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('Get Directions', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.gray400,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.gray300,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _openInMaps(GymLocation location) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }
}
