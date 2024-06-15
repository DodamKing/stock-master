import 'package:flutter/material.dart';

class TradeDialog extends StatefulWidget {
  final String action;
  final Function(int, double) onTrade;

  TradeDialog({required this.action, required this.onTrade});

  @override
  _TradeDialogState createState() => _TradeDialogState();
}

class _TradeDialogState extends State<TradeDialog> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.action} 주식'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextFormField(
            controller: _quantityController,
            decoration: InputDecoration(labelText: '수량'),
            keyboardType: TextInputType.number,
          ),
          TextFormField(
            controller: _priceController,
            decoration: InputDecoration(labelText: '가격 (원)'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: <Widget>[
        ElevatedButton(
          child: Text('취소'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: Text(widget.action),
          onPressed: () {
            int quantity = int.tryParse(_quantityController.text) ?? 0;
            double price = double.tryParse(_priceController.text) ?? 0.0;
            widget.onTrade(quantity, price);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
