import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shutterbook/data/models/package.dart';
import 'package:shutterbook/data/tables/package_table.dart';
import 'package:shutterbook/theme/ui_styles.dart';
import 'package:shutterbook/theme/app_colors.dart';

// ignore_for_file: use_build_context_synchronously

class PackageAdd extends StatefulWidget {
  const PackageAdd({super.key});

  @override
  PackageAddState createState() => PackageAddState();
}

class PackageAddState extends State<PackageAdd> {
  List<Package> allPackages = [];

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    final packages = await PackageTable().getAllPackages();
    if (!mounted) return;
    setState(() {
      allPackages = packages;
    });
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();


  // NOTE: to avoid using BuildContext across async gaps we capture NavigatorState
  // before awaiting on nested dialogs.
  Future<void> _addOrEditPackages({Package? package}) async {
    final packageNameController = TextEditingController(text: package?.name ?? '');
    final packagePriceController = TextEditingController(text: package != null ? package.price.toString() : '');
    final packageDescriptionController = TextEditingController(text: package?.details ?? '');
    final formKey = GlobalKey<FormState>();

    final nav = Navigator.of(context);
    final result = await showDialog<Package?>(
      context: nav.context,
      builder: (ctx) => AlertDialog(
        title: Text(package == null ? 'Add Package' : 'Edit Package'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: packageNameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Package Name required' : null,
                  textCapitalization: TextCapitalization.words,
                ),
                TextFormField(
                  controller: packagePriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: <TextInputFormatter>[
                    // Allow digits and optional decimal point. The previous pattern included
                    // a stray escaped dollar sign which prevented entering numbers.
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  ],
                  decoration: const InputDecoration(labelText: 'Price'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Package Price required' : null,
                  textCapitalization: TextCapitalization.words,
                ),
                TextFormField(
                  controller: packageDescriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Package Description required' : null,
                  textCapitalization: TextCapitalization.words,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                // Use the builder context [ctx] for subsequent dialogs to avoid using
                // the State's [context] across awaits.
                final dialogNavigator = Navigator.of(ctx);
                final confirmed = await showDialog<bool>(
                  context: dialogNavigator.context,
                  builder: (dCtx) => AlertDialog(
                    title: Text(package == null ? 'Add Package' : 'Save Changes'),
                    content: Text(package == null
                        ? 'Are you sure you want to add this package?'
                        : 'Are you sure you want to save changes to this package?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: const Text('Cancel')),
                      ElevatedButton(onPressed: () => Navigator.of(dCtx).pop(true), child: const Text('Confirm')),
                    ],
                  ),
                );
                if (confirmed != true) return;
                final newPackage = Package(
                  id: package?.id,
                  name: _capitalize(packageNameController.text.trim()),
                  price: double.tryParse(packagePriceController.text) ?? 0.0,
                  details: _capitalize(packageDescriptionController.text.trim()),
                );
                dialogNavigator.pop(newPackage);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      if (package == null) {
        await PackageTable().insertPackage(result);
      } else {
        await PackageTable().updatePackage(result);
      }
      await _loadPackages();
    }
  }

  Future<void> _deletePackage(Package package) async {
    final nav = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: nav.context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Delete Package'),
        content: Text('Are you sure you want to delete the package "${package.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(dCtx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (package.id == null) return;
    await PackageTable().deletePackages(package.id!);
    await _loadPackages();
  }

  @override
  Widget build(BuildContext context) {
    final tabColor = AppColors.colorForIndex(context, 3);
    final onColor = tabColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return Scaffold(
      appBar: UIStyles.accentAppBar(context, const Text('Packages'), 3),
      body: allPackages.isEmpty
          ? const Center(child: Text('No Packages found'))
          : ListView.builder(
              itemCount: allPackages.length,
              itemBuilder: (context, index) {
                final package = allPackages[index];
                return ListTile(
                  title: Text('${package.name} R${package.price}'),
                  subtitle: Text(package.details),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _addOrEditPackages(package: package),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deletePackage(package),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditPackages(),
        tooltip: 'Add Package',
        backgroundColor: tabColor,
        foregroundColor: onColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}