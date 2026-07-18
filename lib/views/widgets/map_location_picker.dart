import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

import 'package:hane/theme/app_theme.dart';

/// Haritadan konum seçme ekranı. Kullanıcı haritayı sürükleyip ortadaki
/// pin'i istediği noktaya getirir; onayladığında adres metnine
/// (varsa) reverse-geocoding ile çözülmüş bir konum ismi döner.
class MapLocationPicker extends StatefulWidget {
  const MapLocationPicker({super.key});

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  final _mapController = MapController();
  // Türkiye'nin coğrafi merkezine yakın varsayılan başlangıç noktası (Ankara).
  LatLng _center = const LatLng(39.9208, 32.8541);
  bool _resolving = false;

  Future<void> _confirm() async {
    setState(() => _resolving = true);
    String result = '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}';
    try {
      final placemarks = await placemarkFromCoordinates(_center.latitude, _center.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final addressParts = <String>[];
        
        if (p.street != null && p.street!.isNotEmpty) {
          addressParts.add(p.street!);
        }
        if (p.subLocality != null && p.subLocality!.isNotEmpty) {
          addressParts.add(p.subLocality!);
        }
        if (p.subAdministrativeArea != null && p.subAdministrativeArea!.isNotEmpty) {
          addressParts.add(p.subAdministrativeArea!);
        } else if (p.locality != null && p.locality!.isNotEmpty) {
          addressParts.add(p.locality!);
        }
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) {
          addressParts.add(p.administrativeArea!);
        }
        
        if (addressParts.isNotEmpty) {
          result = addressParts.join(', ');
        }
      }
    } catch (_) {
      // Reverse geocoding başarısız olursa koordinatları kullan.
    }
    if (mounted) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Haritadan Konum Seç',
            style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: context.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.brand),
        centerTitle: true,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 6,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) setState(() => _center = position.center);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.safakciftci.hane2026',
              ),
            ],
          ),
          // Harita merkezinde sabit duran pin (harita kaydırılır, pin yerinde kalır).
          IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Icon(Icons.location_pin, size: 44, color: context.colors.brand),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _resolving ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.brand,
                  foregroundColor: context.colors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _resolving
                    ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.surface))
                    : const Text('Bu Konumu Seç', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
