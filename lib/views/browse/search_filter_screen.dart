import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/item_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/custom_button.dart';

/// View: filter sheet for category, district, and proximity (district-based)
/// search. Writes selections into ItemController, which Home reads from.
class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  String? _category;
  String? _district;

  @override
  void initState() {
    super.initState();
    final controller = context.read<ItemController>();
    _category = controller.categoryFilter;
    _district = controller.districtFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search & Filter')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.itemCategories.map((category) {
                return ChoiceChip(
                  label: Text(category),
                  selected: _category == category,
                  onSelected: (selected) {
                    setState(() => _category = selected ? category : null);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: _district,
              decoration: const InputDecoration(labelText: 'District'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All districts')),
                ...AppConstants.sriLankanDistricts
                    .map((d) => DropdownMenuItem(value: d, child: Text(d))),
              ],
              onChanged: (value) => setState(() => _district = value),
            ),
            const Spacer(),
            CustomButton(
              label: 'Apply Filters',
              onPressed: () {
                final controller = context.read<ItemController>();
                controller.setCategoryFilter(_category);
                controller.setDistrictFilter(_district);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                context.read<ItemController>().clearFilters();
                Navigator.of(context).pop();
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
