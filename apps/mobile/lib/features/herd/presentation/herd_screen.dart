import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/status_badge.dart';

class HerdScreen extends StatelessWidget {
  const HerdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Herd & Calves')),
      drawer: const AppDrawer(currentRoute: '/herd'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primary700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add animal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusChip('Lactating (1)', true),
                  _buildStatusChip('Dry (0)', false),
                  _buildStatusChip('Pregnant (0)', false),
                  _buildStatusChip('Heifer (0)', false),
                  _buildStatusChip('Calf (1)', false),
                  _buildStatusChip('Bull (0)', false),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cattle List Card
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary50,
                  child: Icon(Icons.pets, color: AppColors.primary700),
                ),
                title: const Text('210385 - Ganga', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Breed: HF · Age: 4 yrs · Yield: 25 L/day'),
                trailing: const StatusBadge(
                  label: 'Lactating',
                  backgroundColor: Color(0xFFDCFCE7),
                  textColor: AppColors.statusSuccess,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary50,
                  child: Icon(Icons.pets, color: AppColors.primary700),
                ),
                title: const Text('12345 - Calf A', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Breed: HF · Age: 3 months · Dam: Ganga'),
                trailing: const StatusBadge(
                  label: 'Calf',
                  backgroundColor: Color(0xFFFEF9C3),
                  textColor: AppColors.statusWarning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        selectedColor: AppColors.primary50,
        checkmarkColor: AppColors.primary700,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary800 : AppColors.textMain,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (_) {},
      ),
    );
  }
}
