import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_drawer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Farm Settings')),
      drawer: const AppDrawer(currentRoute: '/settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'OPERATING SETTINGS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit settings'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildSettingRow('BMC Capacity', '2,000 L'),
                    _buildSettingRow('Base Concentrate', '1 kg/day'),
                    _buildSettingRow('Additional Concentrate', '0.4 kg per litre of daily milk'),
                    _buildSettingRow('Maximum Concentrate', '8 kg/day'),
                    _buildSettingRow('Recorded Operator', 'Kaivalya team'),
                    _buildSettingRow('Electricity Tariff', '₹1.40 per unit'),
                    _buildSettingRow('Farm Default Consumption', '50 units/day · ₹70.00'),
                    _buildSettingRow('Production Default Consumption', '200 units/day · ₹280.00'),
                    _buildSettingRow('Management Salary Allocation', '50% farm · 50% production'),
                    _buildSettingRow('Operating Timezone', 'India · Asia/Kolkata'),
                  ],
                ),
              ),
            ),
          ],
        ),
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
