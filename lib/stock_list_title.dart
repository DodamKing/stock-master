import 'package:flutter/material.dart';

class StockListTile extends StatelessWidget {
  final Map<String, dynamic> stock;
  final VoidCallback onDelete;

  StockListTile({required Key key, required this.stock, required this.onDelete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameController = TextEditingController(text: stock['name']);
    final TextEditingController quantityController = TextEditingController(text: stock['quantity'].toString());
    final TextEditingController priceController = TextEditingController(text: stock['price'].toString());
    final TextEditingController percentageController = TextEditingController(text: stock['percentage'].toString());

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: '종목 이름'),
                onChanged: (value) {
                  stock['name'] = value;
                },
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: quantityController,
                decoration: InputDecoration(labelText: '수량'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  stock['quantity'] = int.tryParse(value) ?? 0;
                },
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: priceController,
                decoration: InputDecoration(labelText: '현재가'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  stock['price'] = double.tryParse(value) ?? 0.0;
                },
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: percentageController,
                decoration: InputDecoration(labelText: '비중 (%)'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  stock['percentage'] = double.tryParse(value) ?? 0.0;
                },
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }
}
