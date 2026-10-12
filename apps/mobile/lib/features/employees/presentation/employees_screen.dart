import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_drawer.dart';
import '../domain/employee_models.dart';
import 'employee_provider.dart';
import 'widgets/add_employee_dialog.dart';

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  Color _getStatusColor(EmploymentStatus status) {
    switch (status) {
      case EmploymentStatus.active:
        return Colors.green.shade700;
      case EmploymentStatus.onLeave:
        return Colors.orange.shade700;
      case EmploymentStatus.terminated:
      case EmploymentStatus.resigned:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesListProvider);
    final filter = ref.watch(employeeFilterProvider);
    final filterNotifier = ref.read(employeeFilterProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Roster & Personnel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(employeesListProvider),
            tooltip: 'Refresh roster',
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/employees'),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search staff by name, code, job title...',
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
                      child: DropdownButtonFormField<Department?>(
                        value: filter.department,
                        decoration: InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Departments')),
                          ...Department.values.map(
                            (d) => DropdownMenuItem(value: d, child: Text(d.label)),
                          ),
                        ],
                        onChanged: (d) => filterNotifier.setDepartment(d),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<EmploymentStatus?>(
                        value: filter.status,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Statuses')),
                          ...EmploymentStatus.values.map(
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

          // Employees List
          Expanded(
            child: employeesAsync.when(
              data: (result) {
                final items = result.items;
                if (items.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.badge_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No employee records found',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Register team members using the Add Employee button.',
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
                    final emp = items[index];
                    return Card(
                      elevation: 1.5,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Name, Code & Status Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        emp.fullName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${emp.employeeCode} • ${emp.jobTitle}',
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
                                    color: _getStatusColor(emp.status).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: _getStatusColor(emp.status)),
                                  ),
                                  child: Text(
                                    emp.status.label,
                                    style: TextStyle(
                                      color: _getStatusColor(emp.status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Department Tag
                            Row(
                              children: [
                                Icon(Icons.apartment, size: 15, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  emp.department.label,
                                  style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'Joined: ${emp.joiningDate}',
                                  style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                                ),
                              ],
                            ),

                            // Phone & Email if available
                            if (emp.phone != null || emp.email != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (emp.phone != null) ...[
                                    Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      emp.phone!,
                                      style: TextStyle(color: Colors.grey.shade800, fontSize: 12),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  if (emp.email != null) ...[
                                    Icon(Icons.email, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        emp.email!,
                                        style: TextStyle(color: Colors.grey.shade800, fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],

                            const SizedBox(height: 12),

                            // Salary Clearance Card
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: emp.hasSalaryClearance
                                    ? Colors.blueGrey.shade50
                                    : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: emp.hasSalaryClearance
                                      ? Colors.blueGrey.shade200
                                      : Colors.orange.shade200,
                                ),
                              ),
                              child: emp.hasSalaryClearance
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Monthly Salary',
                                              style: TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                            Text(
                                              '₹${emp.monthlySalary!.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blueGrey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (emp.dailySalaryRate != null)
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              const Text(
                                                'Daily Wage Rate',
                                                style: TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                              Text(
                                                '₹${emp.dailySalaryRate!.toStringAsFixed(2)}/day',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blueGrey,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    )
                                  : const Row(
                                      children: [
                                        Icon(Icons.lock_outline, size: 18, color: Colors.orange),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Salary Confidential [REDACTED]',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange,
                                                ),
                                              ),
                                              Text(
                                                'HR Admin & Finance clearance required for wage rates.',
                                                style: TextStyle(fontSize: 11, color: Colors.black54),
                                              ),
                                            ],
                                          ),
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
                      Text('Error loading employees: $err', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(employeesListProvider),
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
            builder: (ctx) => const AddEmployeeDialog(),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Employee'),
      ),
    );
  }
}
