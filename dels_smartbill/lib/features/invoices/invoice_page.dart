import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/db/app_database.dart';
import '../../data/db/entities/customer_entity.dart';
import '../../data/db/entities/product_entity.dart';
import '../../data/db/entities/invoice_entity.dart';
import '../../services/auto_sync_service.dart';
import '../../services/auth_service.dart';
import '../products/providers/products_provider.dart';

class CartItem {
  final ProductEntity product;
  int quantity;
  CartItem({required this.product, required this.quantity});

  CartItem copyWith({ProductEntity? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class AddCustomerDialog extends StatefulWidget {
  const AddCustomerDialog({Key? key}) : super(key: key);

  @override
  State<AddCustomerDialog> createState() => AddCustomerDialogState();
}

class AddCustomerDialogState extends State<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Customer'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
              ),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Phone required' : null,
              ),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              const uuid = Uuid();
              Navigator.of(context).pop(CustomerEntity(
                id: uuid.v4(),
                name: _nameCtrl.text.trim(),
                phone: _phoneCtrl.text.trim(),
                email: _emailCtrl.text.trim(),
                address: _addressCtrl.text.trim(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                isDirty: true,
                isDeleted: false,
              ));
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class InvoicePage extends ConsumerStatefulWidget {
  const InvoicePage({super.key});

  @override
  ConsumerState<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends ConsumerState<InvoicePage> {
  CustomerEntity? selectedCustomer;
  List<CustomerEntity> customers = [];
  List<CartItem> cart = [];
  bool loading = true;
  final TextEditingController _customerCtrl = TextEditingController();
  final TextEditingController _productSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final db = await openAppDatabase();
    final custList = await db.customerDao.search('');
    setState(() {
      customers = custList;
      loading = false;
    });
  }

  double get total => cart.fold(0, (sum, item) => sum + item.product.price * item.quantity);

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    List<ProductEntity> products = [];
    if (productsState is AsyncData<ProductsState>) {
      products = productsState.value.products;
    }
    final productSearch = _productSearchCtrl.text;
    final filteredProducts = products.where((p) => productSearch.isEmpty || p.name.toLowerCase().contains(productSearch.toLowerCase()) || p.category.toLowerCase().contains(productSearch.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('New Invoice')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Autocomplete<CustomerEntity>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return customers;
                      }
                      return customers.where((c) =>
                        c.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                        c.phone.contains(textEditingValue.text)
                      );
                    },
                    displayStringForOption: (c) => c.name,
                    fieldViewBuilder: (context, ctrl, focus, onFieldSubmitted) {
                      _customerCtrl.value = ctrl.value;
                      return TextField(
                        controller: ctrl,
                        focusNode: focus,
                        decoration: InputDecoration(
                          hintText: 'Search or add customer',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.person_add),
                            onPressed: () async {
                              final newCustomer = await showDialog<CustomerEntity>(
                                context: context,
                                builder: (ctx) => AddCustomerDialog(),
                              );
                              if (newCustomer != null) {
                                final db = await openAppDatabase();
                                await db.customerDao.insertOne(newCustomer);
                                AutoSyncService().syncAfterMutation();
                                setState(() {
                                  customers.add(newCustomer);
                                  selectedCustomer = newCustomer;
                                  _customerCtrl.text = newCustomer.name;
                                });
                              }
                            },
                          ),
                        ),
                      );
                    },
                    onSelected: (c) {
                      setState(() {
                        selectedCustomer = c;
                        _customerCtrl.text = c.name;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Text('Products', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _productSearchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Search products',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  ...filteredProducts.map((p) => ListTile(
                        title: Text(p.name),
                        subtitle: Text(p.category),
                        trailing: ElevatedButton(
                          child: const Text('Add'),
                          onPressed: () {
                            setState(() {
                              final idx = cart.indexWhere((item) => item.product.id == p.id);
                              if (idx >= 0) {
                                cart[idx] = cart[idx].copyWith(quantity: cart[idx].quantity + 1);
                              } else {
                                cart.add(CartItem(product: p, quantity: 1));
                              }
                            });
                          },
                        ),
                      )),
                  const SizedBox(height: 24),
                  Text('Cart', style: Theme.of(context).textTheme.titleMedium),
                  ...cart.map((item) => ListTile(
                        title: Text(item.product.name),
                        subtitle: Text('Qty: ${item.quantity}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                setState(() {
                                  if (item.quantity > 1) {
                                    item.quantity--;
                                  } else {
                                    cart.remove(item);
                                  }
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  item.quantity++;
                                });
                              },
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 24),
                  Text('Total: ₹${total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    child: const Text('Save Invoice'),
                    onPressed: () async {
                      if (selectedCustomer == null || cart.isEmpty) {
                        if (!mounted || context.mounted == false) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Select customer and add products to cart')),
                        );
                        return;
                      }
                      final db = await openAppDatabase();
                      const uuid = Uuid();
                      final invoiceId = uuid.v4();
                      final now = DateTime.now();
                      final invoice = InvoiceEntity(
                        id: invoiceId,
                        invoiceNumber: 'LOCAL-$invoiceId',
                        customerId: selectedCustomer!.id,
                        totalAmount: total,
                        createdByUserId: AuthService().userId ?? 'local',
                        createdAt: now,
                        updatedAt: now,
                        isDirty: true,
                        isDeleted: false,
                      );
                      await db.invoiceDao.insertOne(invoice);
                      final items = cart.map((item) => InvoiceItemEntity(
                        id: uuid.v4(),
                        invoiceId: invoiceId,
                        productId: item.product.id,
                        quantity: item.quantity,
                        unitPrice: item.product.price,
                        createdAt: now,
                        updatedAt: now,
                        isDirty: true,
                        isDeleted: false,
                      )).toList();
                      await db.invoiceItemDao.insertAll(items);
                      AutoSyncService().syncAfterMutation();
                      if (!mounted || context.mounted == false) return;
                      setState(() {
                        cart.clear();
                        selectedCustomer = null;
                        _customerCtrl.clear();
                        _productSearchCtrl.clear();
                      });
                      if (!mounted || context.mounted == false) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invoice saved!')),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
