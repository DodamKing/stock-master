import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final response = await http.get(Uri.parse('$API_BASE/price/$code'));
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

  String formatCurrency(double value, code) {
    if (RegExp(r'^[0-9]').hasMatch(code[0])) {
      final formatter = NumberFormat('#,###', 'ko_KR');
      return formatter.format(value);
    }
    else {
      final formatter = NumberFormat('#,###.##', 'en_US');
      return formatter.format(value);
    }
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
                        return Row(
                          children: [
                            Text('수량: ${asset['quantity']} | 평가금: '),
                            SizedBox(
                              height: 20.0,
                              width: 20.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                              ),
                            )
                          ],
                        );
                      } else if (snapshot.hasError) {
                        return Text('Error');
                      } else {
                        double currentPrice = snapshot.data ?? 0;
                        double currentValue = asset['quantity'] * currentPrice;
                        double initialValue = asset['quantity'] * asset['initialPrice'];
                        double profitLoss = currentValue - initialValue;
                        double profitLossPercent = (profitLoss / initialValue) * 100;
                        String profitLossText = profitLoss >= 0
                            ? '+${formatCurrency(profitLoss, asset['code'])} (${profitLossPercent.toStringAsFixed(2)}%)'
                            : '-${formatCurrency(profitLoss.abs(), asset['code'])} (${profitLossPercent.abs().toStringAsFixed(2)}%)';
                        Color profitLossColor = profitLoss >= 0 ? Colors.red : Colors.blue;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('수량: ${asset['quantity']} | 평가금: ${formatCurrency(currentValue, asset['code'])}'),
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
                        icon: Icon(Icons.edit),
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

class TradeDialog extends StatefulWidget {
  final int index;
  final Function(String, int, double) onTrade;

  TradeDialog({required this.index, required this.onTrade});

  @override
  _TradeDialogState createState() => _TradeDialogState();
}

class _TradeDialogState extends State<TradeDialog> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  List<bool> isSelected = [true, false];

  @override
  Widget build(BuildContext context) {
    bool isBuy = isSelected[0];

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(isBuy ? '매수' : '매도'),
          ToggleButtons(
            borderRadius: BorderRadius.circular(10.0),
            constraints: BoxConstraints(minHeight: 30.0, minWidth: 60.0),
            isSelected: isSelected,
            onPressed: (int index) {
              setState(() {
                for (int i = 0; i < isSelected.length; i++) {
                  isSelected[i] = i == index;
                }
              });
            },
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Text('매수', style: TextStyle(fontSize: 16)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Text('매도', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _quantityController,
            decoration: InputDecoration(labelText: '수량'),
            keyboardType: TextInputType.number,
          ),
          if (isBuy)
            TextField(
              controller: _priceController,
              decoration: InputDecoration(labelText: '가격'),
              keyboardType: TextInputType.number,
            ),
        ],
      ),
      actions: <Widget>[
        ElevatedButton(
          child: Text(isBuy ? 'Buy' : 'Sell'),
          onPressed: () {
            int quantity = int.tryParse(_quantityController.text) ?? 0;
            double price = isBuy ? (double.tryParse(_priceController.text) ?? 0.0) : 0.0;
            if (quantity > 0 && (isBuy ? price > 0 : true)) {
              widget.onTrade(isBuy ? '매수' : '매도', quantity, price);
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
