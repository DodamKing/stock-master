import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'asset_search_dialog.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'env.dart';

class ManagementScreen extends StatefulWidget {
  @override
  _ManagementScreenState createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> {
  late Box _assetsBox;

  @override
  void initState() {
    super.initState();
    _assetsBox = Hive.box('assetsBox');
  }

  Future<double> _getCurrentPrice(String code) async {
    final response = await http.get(Uri.parse('$API_BASE/search/symbol/$code'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['price']?.toDouble(); // 현재가를 반환합니다.
    } else {
      throw Exception('Failed to load current price');
    }
  }

  void _searchAsset() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AssetSearchDialog(
          onAssetSaved: (newAsset) async {
            await _assetsBox.add(newAsset);
            setState(() {});
          },
        );
      },
    );
  }

  void _deleteAsset(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('삭제'),
          content: Text('정말 삭제하시겠습니까?'),
          actions: <Widget>[
            ElevatedButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('삭제'),
              onPressed: () async {
                await _assetsBox.deleteAt(index);
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  void _tradeAsset(String action, int index, int quantity, double price) {
    setState(() {
      var asset = _assetsBox.getAt(index) as Map;
      int currentQuantity = asset['quantity'];
      double currentInitialPrice = asset['initialPrice'];
      int newQuantity;
      double newInitialPrice;

      if (action == '매수') {
        newQuantity = currentQuantity + quantity;
        newInitialPrice = ((currentQuantity * currentInitialPrice) + (quantity * price)) / newQuantity;
      } else {
        newQuantity = currentQuantity - quantity;
        newInitialPrice = currentInitialPrice; // 매도의 경우 평단가는 변하지 않음
      }

      asset['quantity'] = newQuantity;
      asset['initialPrice'] = newInitialPrice;

      _assetsBox.putAt(index, asset);
    });
  }

  String formatCurrency(double value) {
    final formatter = NumberFormat('#,###', 'ko_KR');
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('주식'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _searchAsset,
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _assetsBox.listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return Center(
              child: Text('보유 주식이 없습니다. 추가하세요.'),
            );
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              var asset = box.getAt(index) as Map;

              return Card(
                child: ListTile(
                  title: Text('${asset['name']}'),
                  subtitle: FutureBuilder<double>(
                    future: _getCurrentPrice(asset['code']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text('수량: ${asset['quantity']} | 평가금: 로딩 중...');
                      } else if (snapshot.hasError) {
                        return Text('Error');
                      } else {
                        double currentPrice = snapshot.data ?? 0;
                        double currentValue = asset['quantity'] * currentPrice;
                        double initialValue = asset['quantity'] * asset['initialPrice'];
                        double profitLoss = currentValue - initialValue;
                        double profitLossPercent = (profitLoss / initialValue) * 100;
                        String profitLossText = profitLoss >= 0
                            ? '+${formatCurrency(profitLoss)} (${profitLossPercent.toStringAsFixed(2)}%)'
                            : '${formatCurrency(profitLoss)} (${profitLossPercent.toStringAsFixed(2)}%)';
                        Color profitLossColor = profitLoss >= 0 ? Colors.red : Colors.blue;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('수량: ${asset['quantity']} | 평가금: ${formatCurrency(currentValue)}원'),
                            Text(
                              '수익: $profitLossText',
                              style: TextStyle(color: profitLossColor),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  trailing: Wrap(
                    spacing: 12, // space between two icons
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.swap_vert),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return TradeDialog(
                                index: index,
                                onTrade: (action, quantity, price) {
                                  _tradeAsset(action, index, quantity, price);
                                },
                              );
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteAsset(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class TradeDialog extends StatelessWidget {
  final int index;
  final Function(String, int, double) onTrade;

  TradeDialog({required this.index, required this.onTrade});

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('매수/매도'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _quantityController,
            decoration: InputDecoration(labelText: '수량'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _priceController,
            decoration: InputDecoration(labelText: '가격 (원)'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Expanded(
              child: ElevatedButton(
                child: Icon(Icons.add_shopping_cart),
                onPressed: () {
                  int quantity = int.tryParse(_quantityController.text) ?? 0;
                  double price = double.tryParse(_priceController.text) ?? 0.0;
                  if (quantity > 0 && price > 0) {
                    onTrade('매수', quantity, price);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
            Expanded(
              child: ElevatedButton(
                child:  Icon(Icons.remove_shopping_cart),
                onPressed: () {
                  int quantity = int.tryParse(_quantityController.text) ?? 0;
                  double price = double.tryParse(_priceController.text) ?? 0.0;
                  if (quantity > 0 && price > 0) {
                    onTrade('매도', quantity, price);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
            Expanded(
              child: ElevatedButton(
                child: Icon(Icons.cancel),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
