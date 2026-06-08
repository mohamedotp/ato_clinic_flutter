import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapLocationPicker extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapLocationPicker({super.key, this.initialLat, this.initialLng});

  /// Shows a full-screen map dialog and returns the picked [LatLng] or null.
  static Future<LatLng?> show(BuildContext context, {double? initialLat, double? initialLng}) {
    return Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MapLocationPicker(initialLat: initialLat, initialLng: initialLng),
      ),
    );
  }

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  static const _primaryColor = Color(0xFF006D63);
  late final MapController _mapController;
  LatLng _pickedLocation = const LatLng(30.0444, 31.2357); // Default: Cairo
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialLat != null && widget.initialLng != null) {
      _pickedLocation = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  Future<void> _goToMyLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خدمة الموقع غير مفعّلة. فعّلها من الإعدادات.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم رفض إذن الموقع. افتح إعدادات التطبيق لتفعيله.')),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() => _pickedLocation = loc);
      _mapController.move(loc, 16);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: const Text('تحديد موقع العيادة', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _pickedLocation),
            child: const Text('تأكيد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pickedLocation,
              initialZoom: 15,
              onTap: (tapPos, latLng) => setState(() => _pickedLocation = latLng),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.atoclinic.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pickedLocation,
                    width: 50,
                    height: 60,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('العيادة', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const Icon(Icons.location_pin, color: _primaryColor, size: 36),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Coordinates display
          Positioned(
            bottom: 90,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, color: _primaryColor, size: 16),
                      SizedBox(width: 6),
                      Text('الموقع المحدد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'خط العرض: ${_pickedLocation.latitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    'خط الطول: ${_pickedLocation.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'اضغط على الخريطة لتحديد الموقع بدقة',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // GPS button
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: _isLocating ? null : _goToMyLocation,
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              icon: _isLocating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.my_location),
              label: const Text('موقعي الحالي', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
