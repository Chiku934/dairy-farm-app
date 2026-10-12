import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_drawer.dart';
import '../domain/licence_models.dart';
import 'licence_provider.dart';
import 'widgets/add_licence_dialog.dart';

class LicencesScreen extends ConsumerWidget {
  const LicencesScreen({super.key});

  Color _getStatusColor(LicenceStatus status) {
    switch (status) {
      case LicenceStatus.active:
        return Colors.green.shade700;
      case LicenceStatus.expiringSoon:
        return Colors.amber.shade800;
      case LicenceStatus.expired:
      case LicenceStatus.suspended:
        return Colors.red.shade700;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final licencesAsync = ref.watch(licencesListProvider);
    final filter = ref.watch(licenceFilterProvider);
    final filterNotifier = ref.read(licenceFilterProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FSSAI & Regulatory Licences'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Process Expiry Reminders',
            onPressed: () async {
              try {
                final result = await ref.read(licenceRepositoryProvider).processReminders();
                ref.invalidate(licencesListProvider);
                if (context.mounted) {
                  final bool configured = result['configured'] as bool? ?? false;
                  final String msg = result['message'] as String? ?? 'Processed reminders';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: configured ? Colors.green.shade800 : Colors.blueGrey.shade800,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to process reminders: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(licencesListProvider),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/licences'),
      body: Column(
        children: [
          // KPI Summary Row
          licencesAsync.when(
            data: (result) {
              final items = result.items;
              final activeCount = items.where((l) => l.status == LicenceStatus.active).length;
              final expiringCount = items.where((l) => l.status == LicenceStatus.expiringSoon).length;
              final expiredCount = items.where((l) => l.status == LicenceStatus.expired).length;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                color: Theme.of(context).cardColor,
                child: Row(
                  children: [
                    _buildKpiCard('Total Licences', items.length.toString(), Colors.blueGrey),
                    const SizedBox(width: 8),
                    _buildKpiCard('Active', activeCount.toString(), Colors.green.shade700),
                    const SizedBox(width: 8),
                    _buildKpiCard('Expiring Soon', expiringCount.toString(), Colors.amber.shade800),
                    const SizedBox(width: 8),
                    _buildKpiCard('Expired', expiredCount.toString(), Colors.red.shade700),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const Divider(height: 1),

          // Search and Filters
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search licence by title, number, authority...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (val) => filterNotifier.setSearch(val),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<LicenceType?>(
                        value: filter.type,
                        decoration: InputDecoration(
                          labelText: 'Compliance Type',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Types')),
                          ...LicenceType.values.map(
                            (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                          ),
                        ],
                        onChanged: (t) => filterNotifier.setType(t),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<LicenceStatus?>(
                        value: filter.status,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Statuses')),
                          ...LicenceStatus.values.map(
                            (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                          ),
                        ],
                        onChanged: (s) => filterNotifier.setStatus(s),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Licences List
          Expanded(
            child: licencesAsync.when(
              data: (result) {
                final items = result.items;
                if (items.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.policy_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No regulatory licences registered',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Register FSSAI, pollution, or municipal trade licences.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final lic = items[index];
                    return Card(
                      elevation: 1.5,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Name & Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lic.licenceName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Reg: ${lic.licenceNumber} • ${lic.licenceType.label}',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(lic.status).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: _getStatusColor(lic.status)),
                                  ),
                                  child: Text(
                                    lic.status.label,
                                    style: TextStyle(
                                      color: _getStatusColor(lic.status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Authority & Holder
                            Row(
                              children: [
                                Icon(Icons.account_balance, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Authority: ${lic.issuingAuthority}',
                                    style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.business, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Holder: ${lic.licenceHolder}',
                                    style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Validity & Reminder bar
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Validity Period',
                                        style: TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                      Text(
                                        '${lic.issueDate}  ➔  ${lic.expiryDate}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: lic.reminderStatus == ReminderStatus.notified
                                              ? Colors.blue.shade50
                                              : (lic.reminderStatus == ReminderStatus.dismissed
                                                  ? Colors.grey.shade100
                                                  : Colors.amber.shade50),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          lic.reminderStatus == ReminderStatus.notified
                                              ? 'Reminder Sent'
                                              : (lic.reminderStatus == ReminderStatus.dismissed
                                                  ? 'Dismissed'
                                                  : 'Lead: ${lic.reminderDaysBefore}d'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: lic.reminderStatus == ReminderStatus.notified
                                                ? Colors.blue.shade800
                                                : Colors.grey.shade800,
                                          ),
                                        ),
                                      ),
                                      if (lic.status == LicenceStatus.expiringSoon &&
                                          lic.reminderStatus != ReminderStatus.dismissed) ...[
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: () async {
                                            await ref.read(licenceRepositoryProvider).dismissReminder(lic.id);
                                            ref.invalidate(licencesListProvider);
                                          },
                                          child: const Icon(Icons.check_circle_outline, size: 20, color: Colors.grey),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Error loading licences: $err', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(licencesListProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (ctx) => const AddLicenceDialog(),
          );
        },
        icon: const Icon(Icons.add_moderator),
        label: const Text('Register Licence'),
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
