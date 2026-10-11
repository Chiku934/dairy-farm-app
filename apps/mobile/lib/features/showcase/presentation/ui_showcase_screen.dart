import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/cards/app_kpi_card.dart';
import '../../../../core/widgets/chips/app_filter_bar.dart';
import '../../../../core/widgets/chips/app_status_chip.dart';
import '../../../../core/widgets/feedback/app_feedback.dart';
import '../../../../core/widgets/inputs/app_date_picker.dart';
import '../../../../core/widgets/inputs/app_dropdown.dart';
import '../../../../core/widgets/inputs/app_number_input.dart';
import '../../../../core/widgets/inputs/app_search_bar.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/layout/app_responsive.dart';
import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../core/widgets/states/app_state_views.dart';
import '../../../../core/widgets/tables/app_data_table.dart';

class UIShowcaseScreen extends StatefulWidget {
  const UIShowcaseScreen({super.key});

  @override
  State<UIShowcaseScreen> createState() => _UIShowcaseScreenState();
}

class _UIShowcaseScreenState extends State<UIShowcaseScreen> {
  // Filter state
  String _activeCategoryFilter = 'All';
  String _activeHerdFilter = 'All';

  // Input states
  final TextEditingController _tagController =
      TextEditingController(text: 'TAG-4029');
  final TextEditingController _notesController = TextEditingController(
    text: 'Administered 5ml antibiotic; withholding milk until 14 Oct.',
  );
  String? _selectedCareType = 'VACCINATION';
  DateTime _selectedDate = DateTime.now();
  double _milkingYield = 16.5;
  double _feedAmount = 3.2;
  String _searchQuery = '';
  int _tablePage = 1;

  @override
  void dispose() {
    _tagController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'UI & Design System Showcase',
      currentRoute: '/ui-showcase',
      actions: [
        IconButton(
          tooltip: 'Toggle Theme Info',
          icon: const Icon(Icons.info_outline, color: AppColors.primary700),
          onPressed: () => AppFeedback.showInfoSnackbar(
            context,
            'Dairy Farm App UI System: Light Theme · Forest Green Palette',
          ),
        ),
      ],
      body: SingleChildScrollView(
        child: AppResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Banner
              _buildHeaderBanner(),
              const SizedBox(height: AppSpacing.xl),

              // Category Filter Bar
              AppFilterBar<String>(
                padding: EdgeInsets.zero,
                options: const [
                  FilterOption(value: 'All', label: 'All Components'),
                  FilterOption(value: 'Colors', label: 'Color Tokens'),
                  FilterOption(value: 'Typography', label: 'Typography'),
                  FilterOption(value: 'Buttons', label: 'Buttons'),
                  FilterOption(value: 'Inputs', label: 'Form Inputs'),
                  FilterOption(value: 'Cards', label: 'Cards & Metrics'),
                  FilterOption(value: 'Tables', label: 'Data Tables'),
                  FilterOption(value: 'Feedback', label: 'Dialogs & Feedback'),
                  FilterOption(value: 'States', label: 'State Views'),
                ],
                selectedValue: _activeCategoryFilter,
                onSelected: (val) => setState(() => _activeCategoryFilter = val),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // 2. Color System
              if (_shouldShow('Colors')) ...[
                _buildSectionTitle('1. Color Palette & Surface Tokens',
                    'Commercial farm-management light theme with forest green anchors and warm neutral surfaces.'),
                const SizedBox(height: AppSpacing.md),
                _buildColorPaletteSection(),
                const SizedBox(height: AppSpacing.xxl),
              ],

              // 3. Typography Scale
              if (_shouldShow('Typography')) ...[
                _buildSectionTitle('2. Typography Scale (Inter / Roboto)',
                    'Strict contrast, high daylight visibility, and clear numerical hierarchy.'),
                const SizedBox(height: AppSpacing.md),
                _buildTypographySection(),
                const SizedBox(height: AppSpacing.xxl),
              ],

              // 4. Action Buttons
              if (_shouldShow('Buttons')) ...[
                _buildSectionTitle('3. Action Buttons & Controls',
                    'Primary, secondary, outline, destructive, and text buttons with sizing, icons and loading states.'),
                const SizedBox(height: AppSpacing.md),
                _buildButtonsSection(),
                const SizedBox(height: AppSpacing.xxl),
              ],

              // 5. Form Inputs & Steppers
              if (_shouldShow('Inputs')) ...[
                _buildSectionTitle('4. Form Inputs & Field Steppers',
                    'Keyboard-aware text fields, styled dropdowns, date pickers, and measurement steppers.'),
                const SizedBox(height: AppSpacing.md),
                _buildInputsSection(),
                const SizedBox(height: AppSpacing.xxl),
              ],

              // 6. Status Chips & Filter Bar
              if (_shouldShow('Cards') || _shouldShow('Inputs')) ...[
                _buildSectionTitle('5. Status Chips & Badges',
                    'Clear semantic signals for cattle state, milk intake decisions, and inventory.'),
                const SizedBox(height: AppSpacing.md),
                _buildStatusChipsSection(),
                const SizedBox(height: AppSpacing.xxl),
              ],

              // 7. Cards & KPI Metrics
              if (_shouldShow('Cards')) ...[
                _buildSectionTitle('6. Responsive Metric & KPI Cards',
                    'Single-column on small phones, 2-column on standard devices, and 4-column on tablets.'),
                const SizedBox(height: AppSpacing.md),
                _buildCardsSection(),
                const SizedBox(height: AppSpacing.xxl),
              ],

              // 8. Data Tables & Lists
              if (_shouldShow('Tables')) ...[
                _buildSectionTitle('7. Farm Data Table with Pagination',
                    'Clean horizontal scrollable table with alternating rows, badges, and pagination.'),
                const SizedBox(height: AppSpacing.md),
                _buildTableSection(),
                const SizedBox(height: AppSpacing.xxl),
              ],

              // 9. Feedback & Modals
              if (_shouldShow('Feedback')) ...[
                _buildSectionTitle('8. Confirmation Dialogs & Bottom Sheets',
                    'Contextual alerts, destructive action confirmations, and responsive bottom sheets.'),
                const SizedBox(height: AppSpacing.md),
                _buildFeedbackSection(),
                const SizedBox(height: AppSpacing.xxl),
              ],

              // 10. State Views
              if (_shouldShow('States')) ...[
                _buildSectionTitle('9. Empty, Loading, Error & Skeleton States',
                    'Respectful feedback when data is absent, fetching, or failing.'),
                const SizedBox(height: AppSpacing.md),
                _buildStatesSection(),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShow(String category) {
    return _activeCategoryFilter == 'All' || _activeCategoryFilter == category;
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  // --- 1. Header Banner ---
  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: AppColors.primary200),
        boxShadow: AppElevation.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary200),
                ),
                child: const Icon(Icons.eco, color: AppColors.primary700, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kaivalya Dairy UI/UX Design System',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    Text(
                      'Phase 2 Implementation · Verified Light Aesthetic',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const AppStatusChip.success(label: 'Verified v2.0'),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Designed for commercial agricultural operations with high daylight readability, warm white backgrounds, deep forest green anchors (#0F3923 - #1B6E42), charcoal typography, and responsive tablet adaptability.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Color Palette Section ---
  Widget _buildColorPaletteSection() {
    return AppCard(
      title: 'Theme Color Swatches & Tokens',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BRAND ANCHORS (FOREST GREEN)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildColorSwatch('Primary 900', '#0F3923', AppColors.primary900, Colors.white),
              _buildColorSwatch('Primary 800', '#165A36', AppColors.primary800, Colors.white),
              _buildColorSwatch('Primary 700', '#1B6E42', AppColors.primary700, Colors.white),
              _buildColorSwatch('Primary 600', '#238652', AppColors.primary600, Colors.white),
              _buildColorSwatch('Primary 200', '#BBF7D0', AppColors.primary200, AppColors.textMain),
              _buildColorSwatch('Primary 50', '#F0FDF4', AppColors.primary50, AppColors.primary800),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'SURFACES & NEUTRALS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildColorSwatch('Canvas Bg', '#F7F8F5', AppColors.background, AppColors.textMain, hasBorder: true),
              _buildColorSwatch('Card Surface', '#FFFFFF', AppColors.cardSurface, AppColors.textMain, hasBorder: true),
              _buildColorSwatch('Neutral Surface', '#F2F4ED', AppColors.surfaceNeutral, AppColors.textMain),
              _buildColorSwatch('Border Subtle', '#E2E6DC', AppColors.borderSubtle, AppColors.textMain),
              _buildColorSwatch('Text Main', '#19241E', AppColors.textMain, Colors.white),
              _buildColorSwatch('Text Muted', '#637066', AppColors.textMuted, Colors.white),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'SEMANTIC STATUSES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildColorSwatch('Success', '#15803D', AppColors.statusSuccess, Colors.white),
              _buildColorSwatch('Warning', '#B45309', AppColors.statusWarning, Colors.white),
              _buildColorSwatch('Danger', '#B91C1C', AppColors.statusDanger, Colors.white),
              _buildColorSwatch('Info', '#0369A1', AppColors.statusInfo, Colors.white),
              _buildColorSwatch('Mint Accent', '#10B981', AppColors.mint, Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorSwatch(
    String label,
    String hex,
    Color color,
    Color textCol, {
    bool hasBorder = false,
  }) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: hasBorder
            ? Border.all(color: AppColors.borderStrong, width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textCol,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hex,
            style: TextStyle(
              color: textCol.withAlpha(200),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Typography Section ---
  Widget _buildTypographySection() {
    return AppCard(
      title: 'Typography Hierarchy',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTypeRow('Headline Large (24sp / Bold)', 'BMC Intake & Processing',
              const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          _buildTypeRow('Headline Medium (20sp / Bold)', 'Herd Health & Vaccination',
              const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          _buildTypeRow('Title Medium (15sp / Semi-bold)', 'Maize Feed Silo · Level A',
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          _buildTypeRow('Body Large (15sp / Regular)', 'Standard batch recorded by Kaivalya team.',
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w400)),
          _buildTypeRow('Body Medium (13sp / Regular)', 'Saved records automatically update stock ledger.',
              const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          _buildTypeRow('Caption (11sp / Bold Uppercase)', 'INDIA TIME · IST (UTC+5:30)',
              AppTypography.sectionHeader()),
          const Divider(height: 24, color: AppColors.borderSubtle),
          const Text('HERO METRIC COUNTERS (FINANCE & PRODUCTION)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('₹1,616.67', style: AppTypography.metricHero()),
                  const Text('Daily Cost', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('2,000 L', style: AppTypography.metricHero(color: AppColors.primary700)),
                  const Text('BMC Capacity', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('48 Cows', style: AppTypography.metricHero()),
                  const Text('Lactating Herd', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeRow(String label, String sample, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(sample, style: style.copyWith(color: AppColors.textMain)),
        ],
      ),
    );
  }

  // --- 4. Buttons Section ---
  Widget _buildButtonsSection() {
    return AppCard(
      title: 'Action Buttons & Sizes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BUTTON VARIANTS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppButton.primary(
                label: 'Save Record',
                icon: Icons.check,
                onPressed: () => AppFeedback.showSuccessSnackbar(context, 'Record saved successfully!'),
              ),
              AppButton.secondary(
                label: 'Export CSV',
                icon: Icons.download_outlined,
                onPressed: () => AppFeedback.showInfoSnackbar(context, 'Exporting ledger to CSV...'),
              ),
              AppButton.outline(
                label: 'Print Tag',
                icon: Icons.print_outlined,
                onPressed: () {},
              ),
              AppButton.destructive(
                label: 'Delete',
                icon: Icons.delete_outline,
                onPressed: () => AppFeedback.showErrorSnackbar(context, 'Action denied: active livestock.'),
              ),
              AppButton.text(
                label: 'View details',
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('BUTTON SIZES & STATES',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppButton.primary(
                label: 'Small Button',
                size: AppButtonSize.small,
                onPressed: () {},
              ),
              AppButton.primary(
                label: 'Medium Button',
                size: AppButtonSize.medium,
                onPressed: () {},
              ),
              AppButton.primary(
                label: 'Large Button',
                size: AppButtonSize.large,
                onPressed: () {},
              ),
              const AppButton.primary(
                label: 'Loading State',
                isLoading: true,
                onPressed: null,
              ),
              const AppButton.primary(
                label: 'Disabled',
                onPressed: null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 5. Inputs Section ---
  Widget _buildInputsSection() {
    return AppCard(
      title: 'Form Inputs & Numeric Steppers',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        if (AppResponsive.isCompact(context)) ...[
          AppTextField(
            label: 'Ear Tag ID',
            hint: 'e.g. COW-104',
            isRequired: true,
            controller: _tagController,
            prefixIcon: Icons.tag,
          ),
          const SizedBox(height: 12),
          AppDropdownField<String>(
            label: 'Care Type',
            isRequired: true,
            value: _selectedCareType,
            prefixIcon: Icons.medical_services_outlined,
            items: const [
              AppDropdownItem(value: 'TREATMENT', label: 'Treatment'),
              AppDropdownItem(value: 'VACCINATION', label: 'Vaccination'),
              AppDropdownItem(value: 'DEWORMING', label: 'Deworming'),
              AppDropdownItem(value: 'EXAMINATION', label: 'Examination'),
            ],
            onChanged: (val) => setState(() => _selectedCareType = val),
          ),
          const SizedBox(height: 12),
          AppDatePickerField(
            label: 'Record Date',
            isRequired: true,
            selectedDate: _selectedDate,
            onDateSelected: (d) => setState(() => _selectedDate = d),
          ),
          const SizedBox(height: 12),
          AppNumberInputField(
            label: 'Milk Yield (Litres)',
            isRequired: true,
            value: _milkingYield,
            step: 0.5,
            min: 0.0,
            max: 50.0,
            unitSuffix: 'L',
            onChanged: (val) => setState(() => _milkingYield = val),
          ),
          const SizedBox(height: 12),
          AppNumberInputField(
            label: 'Feed Ration Allocation',
            value: _feedAmount,
            step: 0.2,
            min: 0.0,
            max: 15.0,
            unitSuffix: 'kg',
            onChanged: (val) => setState(() => _feedAmount = val),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Search Input', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              AppSearchBar(
                hint: 'Filter herd items...',
                onChanged: (q) => setState(() => _searchQuery = q),
              ),
            ],
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Ear Tag ID',
                  hint: 'e.g. COW-104',
                  isRequired: true,
                  controller: _tagController,
                  prefixIcon: Icons.tag,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AppDropdownField<String>(
                  label: 'Care Type',
                  isRequired: true,
                  value: _selectedCareType,
                  prefixIcon: Icons.medical_services_outlined,
                  items: const [
                    AppDropdownItem(value: 'TREATMENT', label: 'Treatment'),
                    AppDropdownItem(value: 'VACCINATION', label: 'Vaccination'),
                    AppDropdownItem(value: 'DEWORMING', label: 'Deworming'),
                    AppDropdownItem(value: 'EXAMINATION', label: 'Examination'),
                  ],
                  onChanged: (val) => setState(() => _selectedCareType = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AppDatePickerField(
                  label: 'Record Date',
                  isRequired: true,
                  selectedDate: _selectedDate,
                  onDateSelected: (d) => setState(() => _selectedDate = d),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AppNumberInputField(
                  label: 'Milk Yield (Litres)',
                  isRequired: true,
                  value: _milkingYield,
                  step: 0.5,
                  min: 0.0,
                  max: 50.0,
                  unitSuffix: 'L',
                  onChanged: (val) => setState(() => _milkingYield = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AppNumberInputField(
                  label: 'Feed Ration Allocation',
                  value: _feedAmount,
                  step: 0.2,
                  min: 0.0,
                  max: 15.0,
                  unitSuffix: 'kg',
                  onChanged: (val) => setState(() => _feedAmount = val),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Search Input', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    AppSearchBar(
                      hint: 'Filter herd items...',
                      onChanged: (q) => setState(() => _searchQuery = q),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
          const SizedBox(height: 14),
          AppTextField(
            label: 'Veterinary Notes & Withdrawal Rules',
            hint: 'Describe medication, symptoms, or withholding period...',
            maxLines: 2,
            controller: _notesController,
          ),
        ],
      ),
    );
  }

  // --- 6. Status Chips Section ---
  Widget _buildStatusChipsSection() {
    return AppCard(
      title: 'Status Chips & Filter Bar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LIVESTOCK & BATCH STATUSES',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppStatusChip.success(label: 'Lactating'),
              AppStatusChip.success(label: 'Accepted'),
              AppStatusChip.success(label: 'Eligible'),
              AppStatusChip.warning(label: 'Pregnant'),
              AppStatusChip.warning(label: 'Hold Quality'),
              AppStatusChip.warning(label: 'Low Feed Stock'),
              AppStatusChip.danger(label: 'Rejected'),
              AppStatusChip.danger(label: 'Milk Withheld'),
              AppStatusChip.danger(label: 'Expired'),
              AppStatusChip.info(label: 'External BMC Intake'),
              AppStatusChip.neutral(label: 'Dry Cow'),
              AppStatusChip.neutral(label: 'Archived'),
            ],
          ),
          const SizedBox(height: 16),
          const Text('INTERACTIVE HERD FILTER BAR',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          AppFilterBar<String>(
            padding: EdgeInsets.zero,
            options: const [
              FilterOption(value: 'All', label: 'All Herd', count: 48),
              FilterOption(value: 'Lactating', label: 'Lactating', count: 28),
              FilterOption(value: 'Dry', label: 'Dry Cows', count: 9),
              FilterOption(value: 'Pregnant', label: 'Pregnant', count: 7),
              FilterOption(value: 'Calf', label: 'Calves', count: 4),
            ],
            selectedValue: _activeHerdFilter,
            onSelected: (val) => setState(() => _activeHerdFilter = val),
          ),
        ],
      ),
    );
  }

  // --- 7. Cards Section ---
  Widget _buildCardsSection() {
    return Column(
      children: [
        // Responsive KPI Grid
        AppResponsiveGrid(
          compactColumns: 2,
          mediumColumns: 2,
          expandedColumns: 4,
          childAspectRatio: 1.1,
          children: const [
            AppKpiCard(
              title: 'Milk Recorded',
              value: '25.0 L',
              subtitle: 'Daily yield',
              icon: Icons.water_drop,
              trendPercent: 4.2,
            ),
            AppKpiCard(
              title: 'Sales Revenue',
              value: '₹1,500.00',
              subtitle: 'Direct sales',
              icon: Icons.currency_rupee,
              trendPercent: 0.0,
            ),
            AppKpiCard(
              title: 'Operating Cost',
              value: '₹1,616.67',
              subtitle: 'Elapsed daily',
              icon: Icons.trending_up,
              trendPercent: -1.8,
            ),
            AppKpiCard(
              title: 'Biogas Stock',
              value: '120 kg',
              subtitle: 'Dry fertiliser',
              icon: Icons.eco,
              trendPercent: 8.5,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Executive Dark Mode Card
        const AppKpiCard(
          title: 'Manager / Director Overview',
          value: '₹1,336.67 Farm · ₹280.00 Production',
          subtitle: 'Active 50% Management Salary Allocation · Odisha Facility',
          icon: Icons.shield,
          isExecutive: true,
        ),
      ],
    );
  }

  // --- 8. Table Section ---
  Widget _buildTableSection() {
    final previewAnimals = [
      {
        'tag': 'COW-101',
        'breed': 'Holstein Friesian',
        'status': const AppStatusChip.success(label: 'Lactating'),
        'yield': '18.5 L',
      },
      {
        'tag': 'COW-104',
        'breed': 'Jersey Cross',
        'status': const AppStatusChip.warning(label: 'Pregnant'),
        'yield': '12.0 L',
      },
      {
        'tag': 'COW-109',
        'breed': 'Gir Indigenous',
        'status': const AppStatusChip.neutral(label: 'Dry'),
        'yield': '0.0 L',
      },
      {
        'tag': 'COW-112',
        'breed': 'Sahiwal',
        'status': const AppStatusChip.danger(label: 'Withheld'),
        'yield': '14.2 L',
      },
    ];

    // Filter rows based on search
    final filtered = previewAnimals.where((row) {
      if (_searchQuery.isEmpty) return true;
      return row['tag'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          row['breed'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return AppDataTable(
      currentPage: _tablePage,
      totalPages: 6,
      totalItems: 24,
      pageSize: 4,
      onPageChanged: (p) => setState(() => _tablePage = p),
      columns: const [
        AppTableColumn(title: 'Ear Tag', width: 110),
        AppTableColumn(title: 'Breed', width: 140),
        AppTableColumn(title: 'Status', width: 130),
        AppTableColumn(title: 'Yield (L)', width: 90, textAlign: TextAlign.right),
        AppTableColumn(title: 'Action', width: 90, textAlign: TextAlign.center),
      ],
      rows: filtered.map((item) {
        return [
          Text(
            item['tag'] as String,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(item['breed'] as String, style: const TextStyle(fontSize: 13)),
          item['status'] as Widget,
          Text(
            item['yield'] as String,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 18),
            color: AppColors.textMuted,
            onPressed: () {},
          ),
        ];
      }).toList(),
    );
  }

  // --- 9. Feedback Section ---
  Widget _buildFeedbackSection() {
    return AppCard(
      title: 'Feedback, Dialogs & Modals',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MODAL ACTIONS & CONFIRMATIONS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AppButton.primary(
                label: 'Open Confirmation Dialog',
                icon: Icons.help_outline,
                onPressed: () async {
                  final confirmed = await AppFeedback.showConfirmationDialog(
                    context: context,
                    title: 'Release Production Batch?',
                    message:
                        'Batch #PB-2026-10-11 meets fat (4.2%) and SNF (8.5%) specs. Authorizing release will mark 200 packets for distribution.',
                    confirmLabel: 'Authorize Release',
                    icon: Icons.verified_outlined,
                  );
                  if (confirmed == true && mounted) {
                    AppFeedback.showSuccessSnackbar(context, 'Batch successfully authorized for dispatch!');
                  }
                },
              ),
              AppButton.destructive(
                label: 'Confirm Destructive Action',
                icon: Icons.warning_amber_rounded,
                onPressed: () async {
                  final confirmed = await AppFeedback.showConfirmationDialog(
                    context: context,
                    title: 'Withhold Milk Batch?',
                    message:
                        'Cow COW-112 is on active antibiotic withdrawal. Yield cannot be routed to BMC until 14 Oct.',
                    confirmLabel: 'Withhold Yield',
                    isDestructive: true,
                    icon: Icons.medical_services_outlined,
                  );
                  if (confirmed == true && mounted) {
                    AppFeedback.showErrorSnackbar(context, 'Milk yield marked WITHHELD and barred from BMC.');
                  }
                },
              ),
              AppButton.secondary(
                label: 'Open Bottom Sheet Form',
                icon: Icons.vertical_align_top,
                onPressed: () {
                  AppFeedback.showCustomBottomSheet(
                    context: context,
                    title: 'Quick Milking Entry',
                    subtitle: 'Morning shift entry for current active herd',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppTextField(
                          label: 'Animal Ear Tag',
                          hint: 'Enter tag...',
                          isRequired: true,
                        ),
                        const SizedBox(height: 12),
                        const AppNumberInputField(
                          label: 'Yield Litres',
                          value: 14.5,
                          unitSuffix: 'L',
                          onChanged: _dummyNum,
                        ),
                        const SizedBox(height: 18),
                        AppButton.primary(
                          label: 'Save Quick Entry',
                          isFullWidth: true,
                          onPressed: () {
                            Navigator.of(context).pop();
                            AppFeedback.showSuccessSnackbar(context, 'Quick milking record added!');
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('SNACKBAR PREVIEWS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AppButton.outline(
                label: 'Success SnackBar',
                icon: Icons.check_circle_outline,
                onPressed: () => AppFeedback.showSuccessSnackbar(context, 'Veterinary health log saved!'),
              ),
              AppButton.outline(
                label: 'Warning SnackBar',
                icon: Icons.warning_amber_rounded,
                onPressed: () => AppFeedback.showInfoSnackbar(context, 'Attention: Mineral mixture stock is low (50 kg left).'),
              ),
              AppButton.outline(
                label: 'Danger SnackBar',
                icon: Icons.error_outline,
                onPressed: () => AppFeedback.showErrorSnackbar(context, 'BMC Intake batch #B-04 rejected: Acidity 0.18%.'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 10. States Section ---
  Widget _buildStatesSection() {
    return Column(
      children: [
        const AppCard(
          title: 'Empty State Pattern',
          child: AppEmptyState(
            title: 'No Milking Records Found Today',
            description:
                'Morning shift recording has not started yet. Use "+ Record Milking" to register animal yields.',
            actionLabel: 'Record Morning Milking',
            icon: Icons.water_drop_outlined,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (AppResponsive.isCompact(context)) ...[
          AppCard(
            title: 'Loading State',
            child: const AppLoadingState(message: 'Syncing ledger data with MariaDB...'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            title: 'Error State with Retry',
            child: AppErrorState(
              title: 'Connection Interrupted',
              message: 'Local server at 127.0.0.1:3000 did not respond.',
              onRetry: () => AppFeedback.showSuccessSnackbar(context, 'Reconnecting...'),
            ),
          ),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppCard(
                  title: 'Loading State',
                  child: const AppLoadingState(message: 'Syncing ledger data with MariaDB...'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppCard(
                  title: 'Error State with Retry',
                  child: AppErrorState(
                    title: 'Connection Interrupted',
                    message: 'Local server at 127.0.0.1:3000 did not respond.',
                    onRetry: () => AppFeedback.showSuccessSnackbar(context, 'Reconnecting...'),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        AppCard(
          title: 'Skeleton Placeholder Pattern',
          child: Column(
            children: const [
              AppSkeletonCard(),
              SizedBox(height: 8),
              AppSkeletonCard(),
            ],
          ),
        ),
      ],
    );
  }
}

void _dummyNum(double v) {}
