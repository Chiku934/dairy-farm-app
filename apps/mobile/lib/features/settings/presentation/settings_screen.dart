import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_drawer.dart';
import '../domain/settings_models.dart';
import 'settings_provider.dart';
import 'widgets/edit_settings_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(farmSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Settings & Identity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(farmSettingsProvider),
            tooltip: 'Refresh settings',
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/settings'),
      body: settingsAsync.when(
        data: (settings) => _buildBody(context, settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Error loading farm settings: $err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(farmSettingsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, FarmSettingsModel settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Farm Profile & Identity Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'FARM IDENTITY & PROFILE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => EditSettingsDialog(currentSettings: settings),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit Parameters'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildSettingRow('Enterprise Name', settings.farmName),
                  _buildSettingRow('Registered Address', '${settings.address}, ${settings.district}, ${settings.state} - ${settings.pincode}'),
                  _buildSettingRow('Contact Phone', settings.contactPhone),
                  _buildSettingRow('Official Email', settings.contactEmail),
                  _buildSettingRow('Currency', '${settings.currencyCode} (${settings.currencySymbol})'),
                  _buildSettingRow('Operational Timezone', settings.timezone),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Operating Parameters & Tariffs Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OPERATIONAL PARAMETERS & TARIFFS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Divider(height: 24),
                  _buildSettingRow('BMC Tank Capacity', '${settings.bmcCapacityLitres.toStringAsFixed(0)} Litres'),
                  _buildSettingRow('Base Concentrate Ration', '${settings.feedBaseKg.toStringAsFixed(2)} kg/day'),
                  _buildSettingRow('Additional Ration per Litre', '${settings.feedRatePerLitre.toStringAsFixed(2)} kg per litre of milk'),
                  _buildSettingRow('Maximum Ration Ceiling', '${settings.feedMaxCapKg.toStringAsFixed(2)} kg/day'),
                  _buildSettingRow('Electricity Tariff', '₹${settings.electricityTariff.toStringAsFixed(2)} per unit (kWh)'),
                  _buildSettingRow('Farm Default Consumption', '${settings.farmDefaultKwh.toStringAsFixed(1)} kWh/day · ₹${(settings.farmDefaultKwh * settings.electricityTariff).toStringAsFixed(2)}'),
                  _buildSettingRow('Plant Default Consumption', '${settings.productionDefaultKwh.toStringAsFixed(1)} kWh/day · ₹${(settings.productionDefaultKwh * settings.electricityTariff).toStringAsFixed(2)}'),
                  _buildSettingRow('Management Salary Allocation', '${settings.mgmtSalaryToFarmPct.toStringAsFixed(0)}% Farm · ${(100 - settings.mgmtSalaryToFarmPct).toStringAsFixed(0)}% Processing'),
                  _buildSettingRow('Default Operator Name', settings.operatorName),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Master Data & UOM Units Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MASTER UNITS & TAXONOMIES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Divider(height: 24),
                  _buildSettingRow('Liquid Volume Units', 'L (Litre), mL (Millilitre)'),
                  _buildSettingRow('Mass / Weight Units', 'KG (Kilogram), G (Gram)'),
                  _buildSettingRow('Packaging Units', 'PACKET, BOTTLE, BOX, POUCH, BAG (50kg)'),
                  _buildSettingRow('Herd Units', 'HEAD (Cattle Ear Tag ID)'),
                  _buildSettingRow('Energy Units', 'KWH (Kilowatt-Hour Units)'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMain),
            ),
          ),
        ],
      ),
    );
  }
}
