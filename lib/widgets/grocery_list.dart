import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  var _isLoading = true;
  List<GroceryItem> _groceryList = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    Uri url = Uri.https(
        "flutter-prep-fc518-default-rtdb.firebaseio.com", "shopping-list.json");
    final response = await http.get(url);

    if (response.body == 'null') {
      _isLoading = false;
    }
    final List<GroceryItem> loadItems = [];
    final Map<String, dynamic> listData = json.decode(response.body);
    for (var item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (cateIndex) => cateIndex.value.category == item.value['category'])
          .value;
      loadItems.add(GroceryItem(
        id: item.key,
        name: item.value['name'],
        quantity: item.value['quantity'],
        category: category,
      ));
    }
    setState(() {
      _groceryList = loadItems;
      _isLoading = false;
    });
  }

  void _addNewItem() async {
    final result = await Navigator.push<GroceryItem>(
        context,
        MaterialPageRoute(
          builder: (ctx) => const NewItem(),
        ));

    if (result == null) {
      return;
    }
    setState(() {
      _groceryList.add(result);
    });
  }

  void _remmoveItem(GroceryItem groceryItem) {
    Uri url = Uri.https("flutter-prep-fc518-default-rtdb.firebaseio.com",
        "shopping-list/${groceryItem.id}.json");

    http.delete(url);
    _groceryList.remove(groceryItem);

    setState(() {
      _groceryList.remove(groceryItem);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text("There're no data here"));

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryList.isNotEmpty) {
      content = ListView.builder(
          itemCount: _groceryList.length,
          itemBuilder: (context, index) => Dismissible(
                key: ValueKey(_groceryList[index].id),
                onDismissed: (direction) {
                  _remmoveItem(_groceryList[index]);
                },
                child: ListTile(
                  leading: Container(
                    color: _groceryList[index].category.color,
                    height: 24,
                    width: 24,
                  ),
                  title: Text(_groceryList[index].name),
                  trailing: Text(_groceryList[index].quantity.toString()),
                ),
              ));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Groceries"),
        backgroundColor: Theme.of(context).colorScheme.background,
        actions: [
          IconButton(
            onPressed: _addNewItem,
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: content,
    );
  }
}
