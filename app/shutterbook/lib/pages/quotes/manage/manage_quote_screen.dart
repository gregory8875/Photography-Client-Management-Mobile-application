// Shutterbook — Manage Quote screen
// Full screen used to view and edit a single quote's details.
import 'package:flutter/material.dart';

import 'package:shutterbook/data/models/quote.dart';
import 'package:shutterbook/data/tables/quote_table.dart';
import 'package:shutterbook/data/tables/client_table.dart';
import 'package:shutterbook/pages/bookings/create_booking.dart';
import 'package:shutterbook/pages/quotes/package_picker/package_edit/package_picker_edit_screen.dart';
import 'package:shutterbook/utils/formatters.dart';
import 'package:shutterbook/theme/ui_styles.dart';
import 'package:shutterbook/utils/dialogs.dart';
import 'package:shutterbook/utils/pdf_exporter.dart';
import 'package:open_file/open_file.dart';

class ManageQuotePage extends StatefulWidget {
  /// Optional initialQuote can be provided to avoid a DB lookup (useful for tests)
  final Quote? initialQuote;
  /// Optional injected QuoteTable for testing/mocking
  final dynamic quoteTable;

  const ManageQuotePage({super.key, this.initialQuote, this.quoteTable});

  @override
  State<ManageQuotePage> createState() => _ManageQuotePageState();
}

class _ManageQuotePageState extends State<ManageQuotePage> {
  Quote? _quote;
  bool _loading = true;
  bool _editing = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Prefer provided initialQuote (testing) to avoid DB I/O
    if (widget.initialQuote != null) {
      final q = widget.initialQuote!;
      setState(() {
        _quote = q;
        _loading = false;
        _descriptionController.text = _quote?.description ?? '';
        _priceController.text = _quote != null ? _quote!.totalPrice.toStringAsFixed(2) : '';
      });
      return;
    }

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Quote) {
      _load(args);
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _load(Quote q) async {
    // reload from DB to ensure latest
    final table = widget.quoteTable ?? QuoteTable();
    final fresh = await table.getQuoteById(q.id!);
    if (!mounted) return;
    setState(() {
      _quote = fresh ?? q;
      _loading = false;
      _descriptionController.text = _quote?.description ?? '';
      _priceController.text = _quote != null ? _quote!.totalPrice.toStringAsFixed(2) : '';
    });
  }

  Future<void> _delete() async {
    if (_quote?.id == null) return;
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Quote',
      content: 'Are you sure you want to delete this quote?',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
    );
    if (confirmed == true) {
      final table = widget.quoteTable ?? QuoteTable();
      await table.deleteQuotes(_quote!.id!);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _exportPdf() async {
    if (_quote == null) return;
    
    try {
      // Get client info
      final clientTable = ClientTable();
      final client = await clientTable.getClientById(_quote!.clientId);
      
      if (client == null) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          const SnackBar(content: Text('Client not found')),
        );
        return;
      }

      // Show loading indicator
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Generating PDF...')),
      );

      // Generate PDF
      final file = await PdfExporter.generateQuotePdf(_quote!, client);

      // Open the PDF file automatically
      await OpenFile.open(file.path);

      if (!mounted) return;
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('PDF opened: ${file.path}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_quote == null) return;
    final desc = _descriptionController.text.trim();
    final price = double.tryParse(_priceController.text.replaceAll(',', '').replaceAll('R', '').replaceAll(' ', ''));
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid price')));
      return;
    }

    final updated = Quote(
      id: _quote!.id,
      clientId: _quote!.clientId,
      totalPrice: price,
      description: desc,
      createdAt: _quote!.createdAt,
    );

    final table = widget.quoteTable ?? QuoteTable();
    await table.updateQuote(updated);
    if (!mounted) return;
    setState(() {
      _quote = updated;
      _editing = false;
    });
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Quote saved')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_quote == null) return const Scaffold(body: Center(child: Text('Quote not found')));

    return Scaffold(
      appBar: UIStyles.accentAppBar(
        context,
        Text('Quote #${_quote!.id}'),
        3,
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.close : Icons.edit),
            onPressed: () {
              if (_editing) {
                // cancel edits
                setState(() {
                  _editing = false;
                  _descriptionController.text = _quote?.description ?? '';
                  _priceController.text = _quote != null ? _quote!.totalPrice.toStringAsFixed(2) : '';
                });
              } else {
                setState(() => _editing = true);
              }
            },
          ),
          IconButton(onPressed: _exportPdf, 
          icon: const Icon(Icons.picture_as_pdf),
          tooltip: const Text('Export Pdf').data ,)
            
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Client ID: ${_quote!.clientId}'),
              const SizedBox(height: 8),
              if (!_editing) ...[
                Text('Total: ${formatRand(_quote!.totalPrice)}'),
                const SizedBox(height: 8),
                Text('Created: ${formatDateTime(_quote!.createdAt)}'),
                const SizedBox(height: 8),
                Text('Description: ${_quote!.description}'),
              ] else ...[
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Total (R)', border: OutlineInputBorder()),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter a price';
                    if (double.tryParse(v.replaceAll(',', '').replaceAll('R', '').trim()) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter a description' : null,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  ElevatedButton.icon(
                    style: UIStyles.primaryButton(context),
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    style: UIStyles.outlineButton(context),
                    onPressed: () {
                      setState(() {
                        _editing = false;
                        _descriptionController.text = _quote?.description ?? '';
                        _priceController.text = _quote != null ? _quote!.totalPrice.toStringAsFixed(2) : '';
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                ])
              ],
              const SizedBox(height: 16),
              Column(
                children: [
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: UIStyles.primaryButton(context),
                        onPressed: () async {
                          // Book from this quote
                          final nav = Navigator.of(context);
                          final created = await nav.push<bool>(
                            MaterialPageRoute(builder: (_) => CreateBookingPage(quote: _quote)),
                          );
                          if (created == true) {
                            if (mounted) nav.pop(true);
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Book'),
                      ),
                      
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed:() async{
                           final nav = Navigator.of(context);
                          final created = await nav.push<bool>(
                            MaterialPageRoute(builder: (_) => PackagePickerEditScreen(quoteNum: _quote?.id ?? 0)),
                          );
                          if (created == true) {
                            if (mounted) nav.pop(true);
                          }
                  
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 209, 109, 10)),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: UIStyles.destructiveButton(context),
                        onPressed: _delete,
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                      ),
                      
                    ],
                  ),
                      
                ],
              )

            ],

          ),
        ),
     
        ),
      );
    
  }
}
