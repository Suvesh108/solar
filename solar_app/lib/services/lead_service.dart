import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/lead.dart';

class LeadService {
  static const String _storageKey = 'sunward_leads_v1';
  static final LeadService instance = LeadService._internal();

  LeadService._internal();

  final ValueNotifier<List<Lead>> leadsNotifier = ValueNotifier<List<Lead>>([]);
  final _uuid = const Uuid();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        leadsNotifier.value = decoded.map((e) => Lead.fromJson(e as Map<String, dynamic>)).toList();
        return;
      } catch (e) {
        debugPrint('Error parsing stored leads: $e');
      }
    }

    // Seed default sample leads for instant demonstration
    final initialSample = [
      Lead(
        id: _uuid.v4(),
        name: 'Ramesh Kulkarni',
        phone: '9822012345',
        location: 'Kothrud, Pune',
        monthlyBill: '4500',
        propertyType: 'Independent House',
        status: LeadStatus.siteVisit,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      Lead(
        id: _uuid.v4(),
        name: 'Sneha Patil',
        phone: '9890123456',
        location: 'Gangapur Road, Nashik',
        monthlyBill: '8200',
        propertyType: 'Row House',
        status: LeadStatus.newLead,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      Lead(
        id: _uuid.v4(),
        name: 'Pravin Deshmukh',
        phone: '9765432109',
        location: 'MIDC, Satara',
        monthlyBill: '18500',
        propertyType: 'Commercial Dukaan',
        status: LeadStatus.quotation,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    leadsNotifier.value = initialSample;
    await _persist(initialSample);
  }

  Future<Lead> addLead({
    required String name,
    required String phone,
    required String location,
    required String monthlyBill,
    required String propertyType,
  }) async {
    final lead = Lead(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      location: location,
      monthlyBill: monthlyBill,
      propertyType: propertyType,
      status: LeadStatus.newLead,
      createdAt: DateTime.now(),
    );

    final updated = [lead, ...leadsNotifier.value];
    leadsNotifier.value = updated;
    await _persist(updated);
    return lead;
  }

  Future<void> updateStatus(String leadId, LeadStatus newStatus) async {
    final updated = leadsNotifier.value.map((l) {
      if (l.id == leadId) {
        return l.copyWith(status: newStatus);
      }
      return l;
    }).toList();

    leadsNotifier.value = updated;
    await _persist(updated);
  }

  Future<void> deleteLead(String leadId) async {
    final updated = leadsNotifier.value.where((l) => l.id != leadId).toList();
    leadsNotifier.value = updated;
    await _persist(updated);
  }

  Future<void> _persist(List<Lead> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Error saving leads: $e');
    }
  }
}
