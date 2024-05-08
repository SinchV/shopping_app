import 'package:flutter/material.dart';
import 'package:shopping_app/data/categories.dart';
import 'package:shopping_app/widgets/new_item.dart';
import 'package:shopping_app/models/grocery_item.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItem = [];
  var _isLoading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  void _loadItem() async {
    final url = Uri.https(
        'shoppingapp-9ab9d-default-rtdb.firebaseio.com', 'shopping_list.json');
    final response = await http.get(url);

    if (response.statusCode >= 400) {
      setState(() {
        _error = 'Failed to fetch data .Please try again later';
      });
    }
    print(response.body);
    final Map<String, dynamic> listItem = json.decode(response.body);
    final List<GroceryItem> loadedItem = [];
    for (final list in listItem.entries) {
      final category = categories.entries
          .firstWhere(
              (cartItem) => cartItem.value.title == list.value['category'])
          .value;
      loadedItem.add(
        GroceryItem(
            id: list.key,
            name: list.value['name'],
            quantity: list.value['quantity'],
            category: category),
      );
    }
    setState(() {
      _groceryItem = loadedItem;
      _isLoading = false;
    });
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItem.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItem.indexOf(item);
    setState(() {
      _groceryItem.remove(item);
    });
    final url = Uri.https('shoppingapp-9ab9d-default-rtdb.firebaseio.com',
        'shopping_list/${item.id}.json');
    final respose = await http.delete(url);
    if (respose.statusCode >= 400) {
      setState(() {
        _groceryItem.insert(index, item);
      });
    }
    if (respose.body == 'null') {
      setState(() {
        _isLoading = false;
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text("No items added yet!:)"));
    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_groceryItem.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItem.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_groceryItem[index]);
          },
          key: ValueKey(_groceryItem[index].id),
          child: ListTile(
            title: Text(_groceryItem[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItem[index].category.color,
            ),
            trailing: Text(
              _groceryItem[index].quantity.toString(),
            ),
          ),
        ),
      );
    }
    if (_error != null) {
      content = Center(
        child: Text(_error!),
      );
    }
    return Scaffold(
        appBar: AppBar(
          title: const Text('Your Grocerices'),
          actions: [
            IconButton(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: content);
  }
}
