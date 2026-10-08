import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/lead.dart';
import '../services/lead_service.dart';
import '../theme/app_theme.dart';

class AdminInboxScreen extends StatefulWidget {
  const AdminInboxScreen({super.key});

  @override
  State<AdminInboxScreen> createState() => _AdminInboxScreenState();
}

class _AdminInboxScreenState extends State<AdminInboxScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final _dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return AppColors.coral;
      case LeadStatus.contacted:
        return Colors.blueGrey;
      case LeadStatus.qualified:
        return Colors.indigo;
      case LeadStatus.siteVisit:
        return AppColors.sun;
      case LeadStatus.quotation:
        return Colors.deepPurple;
      case LeadStatus.won:
        return AppColors.teal;
      case LeadStatus.lost:
        return Colors.grey;
    }
  }

  Future<void> _makeCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch dialer for $phone')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phone, String name) async {
    var clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 10) {
      clean = '91$clean';
    }
    final message = "Namaste $name ji, I'm reaching out from Sunward Solar regarding your rooftop inquiry.";
    final uri = Uri.parse('https://wa.me/$clean?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  void _showAddLeadModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final billCtrl = TextEditingController();
    String propType = 'House';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Manual Lead',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Customer Name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationCtrl,
                decoration: const InputDecoration(labelText: 'Location / City *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: billCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Monthly Bill (₹)'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;

                    await LeadService.instance.addLead(
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      location: locationCtrl.text.trim(),
                      monthlyBill: billCtrl.text.trim().isEmpty ? '0' : billCtrl.text.trim(),
                      propertyType: propType,
                    );

                    if (mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Add Lead', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lead Inbox Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Add Lead',
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () => _showAddLeadModal(context),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<Lead>>(
        valueListenable: LeadService.instance.leadsNotifier,
        builder: (context, leads, _) {
          final filtered = leads.where((l) {
            final matchesStatus = _selectedFilter == 'All' || l.status.label == _selectedFilter;
            final matchesSearch = _searchQuery.isEmpty ||
                l.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                l.phone.contains(_searchQuery) ||
                l.location.toLowerCase().contains(_searchQuery.toLowerCase());
            return matchesStatus && matchesSearch;
          }).toList();

          final totalCount = leads.length;
          final newCount = leads.where((l) => l.status == LeadStatus.newLead).length;
          final wonCount = leads.where((l) => l.status == LeadStatus.won).length;

          return Column(
            children: [
              // Summary Stats Strip
              Container(
                color: AppColors.ink,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTopMetric('Total Inquiries', '$totalCount', AppColors.white),
                    Container(width: 1, height: 24, color: Colors.white24),
                    _buildTopMetric('New Pending', '$newCount', AppColors.sun),
                    Container(width: 1, height: 24, color: Colors.white24),
                    _buildTopMetric('Won Deals', '$wonCount', AppColors.teal),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone or location...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),

              // Status Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    _buildFilterChip('All'),
                    for (final status in LeadStatus.values) _buildFilterChip(status.label),
                  ],
                ),
              ),

              // Lead List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 48, color: AppColors.muted.withOpacity(0.5)),
                            const SizedBox(height: 8),
                            const Text('No leads found matching criteria', style: TextStyle(color: AppColors.muted)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final lead = filtered[index];
                          final badgeColor = _getStatusColor(lead.status);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              lead.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${lead.location} • ${lead.propertyType}',
                                              style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Status Selector Chip
                                      PopupMenuButton<LeadStatus>(
                                        tooltip: 'Update status',
                                        initialValue: lead.status,
                                        onSelected: (newStatus) {
                                          LeadService.instance.updateStatus(lead.id, newStatus);
                                        },
                                        itemBuilder: (context) => LeadStatus.values
                                            .map(
                                              (s) => PopupMenuItem(
                                                value: s,
                                                child: Text(s.label),
                                              ),
                                            )
                                            .toList(),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: badgeColor.withOpacity(0.18),
                                            border: Border.all(color: badgeColor, width: 1.2),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                lead.status.label,
                                                style: TextStyle(
                                                  color: badgeColor == AppColors.sun ? AppColors.ink : badgeColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.arrow_drop_down,
                                                size: 16,
                                                color: badgeColor == AppColors.sun ? AppColors.ink : badgeColor,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.cream.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.receipt_long, size: 16, color: AppColors.muted),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Monthly Bill: ₹${lead.monthlyBill}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink),
                                        ),
                                        const Spacer(),
                                        Text(
                                          _dateFormatter.format(lead.createdAt),
                                          style: const TextStyle(fontSize: 10, color: AppColors.muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Quick Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.ink,
                                            side: const BorderSide(color: AppColors.ink),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          icon: const Icon(Icons.call, size: 16),
                                          label: Text(lead.phone, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          onPressed: () => _makeCall(lead.phone),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF25D366),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          icon: const Icon(Icons.chat, size: 16),
                                          label: const Text('WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          onPressed: () => _openWhatsApp(lead.phone, lead.name),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                        onPressed: () {
                                          LeadService.instance.deleteLead(lead.id);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.sun,
        foregroundColor: AppColors.ink,
        icon: const Icon(Icons.add),
        label: const Text('Add Lead', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddLeadModal(context),
      ),
    );
  }

  Widget _buildTopMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.ink : AppColors.muted,
        ),
        selected: isSelected,
        selectedColor: AppColors.sun,
        backgroundColor: AppColors.white,
        showCheckmark: false,
        onSelected: (_) {
          setState(() {
            _selectedFilter = label;
          });
        },
      ),
    );
  }
}
