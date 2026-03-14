import 'package:flutter/material.dart';

class ItemDetailPage extends StatelessWidget {
  final String itemId;

  const ItemDetailPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('事项详情'),
      ),
      body: Center(
        child: Text('事项详情 - ID: $itemId - 待实现'),
      ),
    );
  }
}
