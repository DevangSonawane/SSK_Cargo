import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GpsDemoVehicle {
  const GpsDemoVehicle({
    required this.id,
    required this.plate,
    required this.model,
    required this.driver,
    required this.status,
    required this.speed,
    required this.location,
    required this.timeAgo,
    required this.color,
    required this.icon,
    required this.position,
  });

  final String id;
  final String plate;
  final String model;
  final String driver;
  final String status;
  final String speed;
  final String location;
  final String timeAgo;
  final Color color;
  final IconData icon;
  final LatLng position;
}

const gpsDemoFleetVehicles = <GpsDemoVehicle>[
  GpsDemoVehicle(
    id: 'mh12-ab-1234',
    plate: 'MH12 AB 1234',
    model: 'Tata 407 • Cargo',
    driver: 'Rohit Sharma',
    status: 'Running',
    speed: '48 km/h',
    location: 'Andheri East, Mumbai',
    timeAgo: '2 mins ago',
    color: Color(0xFF13B36C),
    icon: Icons.local_shipping_rounded,
    position: LatLng(19.1176, 72.8697),
  ),
  GpsDemoVehicle(
    id: 'mh12-cd-5678',
    plate: 'MH12 CD 5678',
    model: 'Eicher Pro 2049 • Cargo',
    driver: 'Suresh Yadav',
    status: 'Stopped',
    speed: '45 mins',
    location: 'Jogeshwari, Mumbai',
    timeAgo: '45 mins ago',
    color: Color(0xFFFF595D),
    icon: Icons.local_shipping_rounded,
    position: LatLng(19.1364, 72.8427),
  ),
  GpsDemoVehicle(
    id: 'mh12-ef-9012',
    plate: 'MH12 EF 9012',
    model: 'BharatBenz 1617 • Cargo',
    driver: 'Imran Shaikh',
    status: 'Offline',
    speed: 'Offline',
    location: 'Borivali West, Mumbai',
    timeAgo: '1 hr ago',
    color: Color(0xFF4B84F6),
    icon: Icons.local_shipping_rounded,
    position: LatLng(19.2315, 72.8462),
  ),
  GpsDemoVehicle(
    id: 'mh12-gh-3456',
    plate: 'MH12 GH 3456',
    model: 'Ashok Leyland • Cargo',
    driver: 'Vikram Patil',
    status: 'No Data',
    speed: 'No Data',
    location: 'Unknown Location',
    timeAgo: '--',
    color: Color(0xFF8F98AA),
    icon: Icons.local_shipping_rounded,
    position: LatLng(19.0760, 72.8777),
  ),
];

GpsDemoVehicle? gpsDemoVehicleById(String? id) {
  if (id == null || id.isEmpty) {
    return null;
  }
  for (final vehicle in gpsDemoFleetVehicles) {
    if (vehicle.id == id) {
      return vehicle;
    }
  }
  return null;
}
