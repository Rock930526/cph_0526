import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  // =========================
  // 取得目前位置
  // =========================
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("定位服務未開啟");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("定位權限被永久拒絕");
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // =========================
  // 跳轉 Google Maps 搜尋
  // =========================
  Future<void> _openNearbyDermatology() async {
    final position = await _getCurrentLocation();

    final query = Uri.encodeComponent("皮膚科 診所");
    final url =
        "https://www.google.com/maps/search/?api=1"
        "&query=$query"
        "&center=${position.latitude},${position.longitude}";

    final uri = Uri.parse(url);

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception("無法開啟 Google Maps");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("就醫地圖"),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.local_hospital),
          label: const Text("搜尋附近皮膚科"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            textStyle: const TextStyle(fontSize: 16),
          ),
          onPressed: () async {
            try {
              await _openNearbyDermatology();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
  