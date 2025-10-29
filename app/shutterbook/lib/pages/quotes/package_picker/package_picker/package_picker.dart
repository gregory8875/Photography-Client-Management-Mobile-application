import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/client.dart';
import 'package:shutterbook/data/tables/package_table.dart';
import 'package:shutterbook/data/models/package.dart';





// Simple Package model

class PackagePicker extends StatefulWidget {
  
  final Client client;
  final Function(Map<Package, int>) onSelectionChanged;

  const PackagePicker({super.key, required this.onSelectionChanged, required this.client});

  @override
  PackagePickerState createState() => PackagePickerState();
}

class PackagePickerState extends State<PackagePicker> {
    
  List<Package> allpackages =[];  

   @override
  void initState() {
    super.initState();
    _loadPackages();
  }

 Future<void> _loadPackages() async{

final packages = await PackageTable().getAllPackages();

setState(() {
  allpackages=packages;
});

for(Package p in packages)
{
  debugPrint('Id:${p.id} Name:${p.name} Price:${p.price} Description${p.details}');
}
 }

 // Public method to reload packages from outside
 Future<void> reload() async {
   await _loadPackages();
 }

 void onSelectionChanged(){}




  // Map to track selected packages and their quantities
  final Map<Package, int> _selectedPackages = {};

  void _toggleSelection(Package package) {
    setState(() {
      if (_selectedPackages.containsKey(package)) {
        _selectedPackages.remove(package);
      } else {
        _selectedPackages[package] = 1;
      }
    });
    widget.onSelectionChanged(_selectedPackages);
  }

  void _updateQuantity(Package package, int quantity) {
    setState(() {
      if (quantity > 0) {
        _selectedPackages[package] = quantity;
      } else {
        _selectedPackages.remove(package);
      }
    });
    widget.onSelectionChanged(_selectedPackages);
  }

  int get totalItems => _selectedPackages.values.fold(0, (sum, qty) => sum + qty);
  double get totalPrice => _selectedPackages.entries
      .fold(0, (sum, entry) => sum + entry.key.price * entry.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Text(
            '${widget.client.firstName} ${widget.client.lastName}',
              style: TextStyle(fontSize: 20),
              ),
        ),
          
        const Text('Pick Packages'),
         Expanded(
           child:allpackages.isEmpty? 
           const Center(child:Text('No packages found'))
            :ListView.builder(
             itemCount:allpackages.length,
             itemBuilder: (context, index) {
               final package = allpackages[index];
               final isSelected = _selectedPackages.containsKey(package);
               final quantity = _selectedPackages[package] ?? 1;
               return Card(
                 child: ListTile(
                   title: Text('${package.name} (R${package.price})'),
                   trailing: isSelected
                       ? Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             IconButton(
                               icon: const Icon(Icons.remove),
                               onPressed: () {
                                 if (quantity > 1) {
                                   _updateQuantity(package, quantity - 1);
                                 } else {
                                   _toggleSelection(package);
                                 }
                               },
                             ),
                             Text('$quantity'),
                             IconButton(
                               icon: const Icon(Icons.add),
                               onPressed: () {
                                 _updateQuantity(package, quantity + 1);
                               },
                             ),
                             IconButton(
                               icon: const Icon(Icons.check_box, color: Colors.green),
                               onPressed: () => _toggleSelection(package),
                             ),
                           ],
                         )
                       : IconButton(
                           icon: const Icon(Icons.check_box_outline_blank),
                           onPressed: () => _toggleSelection(package),
                         ),
                 ),
               );
             },
           ),
         ),
         const SizedBox(height: 10),
         Text('Selected: $totalItems items, Total: R${totalPrice.toStringAsFixed(2)}'),
         const SizedBox(height: 10),

        
       ],
     );
   }
 }


         