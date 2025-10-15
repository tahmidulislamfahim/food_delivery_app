import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_delivery_app/providers/categories_provider.dart';
import 'storage_helper.dart';

class ProductForm extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initial;
  const ProductForm({super.key, this.initial});

  @override
  ConsumerState<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<ProductForm> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _price = TextEditingController();
  final _category = TextEditingController();
  final _calories = TextEditingController();
  final _cookTime = TextEditingController();
  String? _imagePath; // storage path
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      _title.text = init['title'] ?? '';
      _subtitle.text = init['subtitle'] ?? '';
      _price.text = (init['price'] ?? '').toString();
      _imagePath = init['image_url'] as String?;
      _category.text = init['category'] ?? '';
      _calories.text = (init['calories'] ?? '').toString();
      _cookTime.text = (init['cook_time_minutes'] ?? init['cook_time'] ?? '')
          .toString();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _price.dispose();
    _category.dispose();
    _calories.dispose();
    _cookTime.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    final f = await StorageHelper.pickImage();
    if (f == null) return;
    setState(() {
      _loading = true;
    });
    try {
      final path = await StorageHelper.uploadFile(f);
      setState(() {
        _imagePath = path;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final title = _title.text.trim();
    final subtitle = _subtitle.text.trim();
    final price = double.tryParse(_price.text.trim()) ?? 0.0;
    final imagePath = _imagePath;
    final category = _category.text.trim();
    final calories = int.tryParse(_calories.text.trim());
    final cookTime = int.tryParse(_cookTime.text.trim());

    // Get public URL if path present
    final imageUrl = (imagePath != null)
        ? StorageHelper.publicUrlForPath(imagePath)
        : null;

    try {
      final client = Supabase.instance.client;
      if (widget.initial == null) {
        // create
        await client.rpc(
          'create_product',
          params: {
            'p_title': title,
            'p_subtitle': subtitle,
            'p_price': price,
            'p_image_url': imageUrl,
            'p_category': category.isEmpty ? null : category,
            'p_calories': calories,
            'p_cook_time_minutes': cookTime,
          },
        );
      } else {
        await client.rpc(
          'update_product',
          params: {
            'p_id': widget.initial!['id'],
            'p_title': title,
            'p_subtitle': subtitle,
            'p_price': price,
            'p_image_url': imageUrl,
            'p_category': category.isEmpty ? null : category,
            'p_calories': calories,
            'p_cook_time_minutes': cookTime,
          },
        );
      }
      // invalidate categories provider so UI updates to include any new category
      ref.invalidate(categoriesProvider);
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final publicUrl = (_imagePath != null)
        ? StorageHelper.publicUrlForPath(_imagePath!)
        : null;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.initial == null ? 'Add Product' : 'Edit Product',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Card
                if (publicUrl != null)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Image.network(
                      publicUrl,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _pickAndUpload,
                  icon: const Icon(Icons.upload_file, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  label: Text(
                    _imagePath == null
                        ? 'Pick & Upload Image'
                        : 'Replace Image',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),

                // Product Info Section
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _title,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              (v?.trim().isEmpty ?? true) ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _subtitle,
                          decoration: const InputDecoration(
                            labelText: 'Subtitle',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _price,
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) => (double.tryParse(v ?? '') == null)
                              ? 'Invalid price'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category Section
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Consumer(
                      builder: (context, ref, _) {
                        final catsAsync = ref.watch(categoriesProvider);
                        return catsAsync.when(
                          data: (cats) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<String>(
                                  initialValue:
                                      cats.contains(_category.text) &&
                                          _category.text.isNotEmpty
                                      ? _category.text
                                      : null,
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('Select category'),
                                    ),
                                    ...cats.map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _category.text = v);
                                    }
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Select category',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _category,
                                  decoration: const InputDecoration(
                                    labelText: 'Or enter new category',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, __) => TextFormField(
                            controller: _category,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nutrition Section
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _calories,
                          decoration: const InputDecoration(
                            labelText: 'Calories',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              (v != null &&
                                  v.isNotEmpty &&
                                  int.tryParse(v) == null)
                              ? 'Invalid number'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cookTime,
                          decoration: const InputDecoration(
                            labelText: 'Cook time (minutes)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              (v != null &&
                                  v.isNotEmpty &&
                                  int.tryParse(v) == null)
                              ? 'Invalid number'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save Product',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
