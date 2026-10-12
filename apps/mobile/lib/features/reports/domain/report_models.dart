import 'package:flutter/material.dart';

enum ReportType {
  milkProduction(
    'milk-production',
    'Milk Production & Yield',
    Icons.water_drop_outlined,
    'Shift yields, milk withholding, and individual cow output logs.',
  ),
  sales(
    'sales',
    'Sales & Customer Revenue',
    Icons.point_of_sale_outlined,
    'Customer invoices, payments collected, and outstanding receivables.',
  ),
  expenses(
    'expenses',
    'Operating Expenses & Costs',
    Icons.receipt_long_outlined,
    'Cost centre allocations (Farm, Plant, Biogas) and expense breakdown.',
  ),
  herd(
    'herd',
    'Herd Inventory & Health Status',
    Icons.pets_outlined,
    'Cattle headcounts, breeding stages, and medical withdrawal tags.',
  ),
  inventory(
    'inventory',
    'Feed & Stock Valuation',
    Icons.warehouse_outlined,
    'Stock on hand, reorder warnings, and weighted inventory valuation.',
  ),
  staffPayroll(
    'staff-payroll',
    'Staff Directory & Wage Rates',
    Icons.badge_outlined,
    'Confidential employee roster and wage liability (HR & Finance clearance required).',
    isSensitive: true,
  ),
  licences(
    'licences',
    'FSSAI & Regulatory Compliance',
    Icons.policy_outlined,
    'Permits, food safety registrations, and expiration timelines.',
  );

  final String apiEndpoint;
  final String title;
  final IconData icon;
  final String description;
  final bool isSensitive;

  const ReportType(
    this.apiEndpoint,
    this.title,
    this.icon,
    this.description, {
    this.isSensitive = false,
  });
}

class ReportResultModel {
  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> items;
  final int total;
  final int page;
  final int limit;

  const ReportResultModel({
    required this.summary,
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory ReportResultModel.fromJson(Map<String, dynamic> json) {
    final rawSummary = json['summary'] as Map<String, dynamic>? ?? {};
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    return ReportResultModel(
      summary: rawSummary,
      items: itemsList,
      total: json['total'] as int? ?? itemsList.length,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 50,
    );
  }
}
