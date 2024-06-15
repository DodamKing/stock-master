import 'package:flutter/material.dart';

class AddStockPopup extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;

  AddStockPopup({required this.onAdd});

  @override
  _AddStockPopupState createState() => _AddStockPopupState();
}

class _AddStockPopupState extends State<AddStockPopup> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _percentageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('종목 추가'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: '종목 이름'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '종목 이름을 입력하세요';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(labelText: '수량'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '수량을 입력하세요';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(labelText: '평단가 (원)'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '평단가를 입력하세요';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _percentageController,
              decoration: InputDecoration(labelText: '비중 (%)'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '비중을 입력하세요';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          child: Text('취소'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: Text('추가'),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Map<String, dynamic> newStock = {
                'name': _nameController.text,
                'quantity': int.parse(_quantityController.text),
                'price': double.parse(_priceController.text),
                'percentage': double.parse(_percentageController.text),
              };
              widget.onAdd(newStock);
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
