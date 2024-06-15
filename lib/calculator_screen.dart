import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'popup_add_stock.dart';

class CalculatorScreen extends StatefulWidget {
  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cashController = TextEditingController(text: '0');
  final List<Map<String, dynamic>> _stocks = [];
  double _totalInvestment = 0.0;
  List<double> _investmentPerStock = [];

  void _addStock() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddStockPopup(onAdd: (stock) {
          setState(() {
            _stocks.add(stock);
          });
        });
      },
    );
  }

  void _addStockFromAsset(Map<String, dynamic> asset) {
    setState(() {
      _stocks.add({
        'name': asset['name'] as String,
        'quantity': asset['quantity'] as int,
        'price': asset['price'] as double,
        'percentage': 0.0,
      });
    });
  }

  bool _validateWeights() {
    double totalWeight = _stocks.fold(0.0, (sum, stock) => sum + stock['percentage']);
    return totalWeight == 100.0;
  }

  void _calculateRebalancing() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_validateWeights()) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("경고"),
              content: Text("모든 종목의 비중 합은 100%이어야 합니다."),
              actions: <Widget>[
                ElevatedButton(
                  child: Text("확인"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        return;
      }

      double cash = double.tryParse(_cashController.text) ?? 0.0;
      double totalInvestment = cash;

      _stocks.forEach((stock) {
        totalInvestment += stock['quantity'] * stock['price'];
      });

      _totalInvestment = totalInvestment;

      setState(() {
        _investmentPerStock = _stocks.map((stock) {
          double percentage = stock['percentage'] / 100;
          return totalInvestment * percentage;
        }).toList();
      });
    }
  }

  void _clearData() {
    setState(() {
      _cashController.text = '0';
      _stocks.clear();
      _investmentPerStock.clear();
    });
  }

  String formatCurrency(double value) {
    final formatter = NumberFormat('#,###', 'ko_KR');
    return formatter.format(value);
  }

  void _showAssetSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Box assetBox = Hive.box('assetsBox');
        return AlertDialog(
          title: Text('자산 선택'),
          content: Container(
            width: double.maxFinite,
            child: ValueListenableBuilder(
              valueListenable: assetBox.listenable(),
              builder: (context, Box box, _) {
                if (box.isEmpty) {
                  return Center(child: Text('저장된 자산이 없습니다.'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    var asset = box.getAt(index) as Map;
                    return ListTile(
                      title: Text(asset['name'] as String),
                      onTap: () {
                        _addStockFromAsset(asset.cast<String, dynamic>());
                        Navigator.of(context).pop();
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('리밸런싱 계산기'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  controller: _cashController,
                  decoration: InputDecoration(labelText: '현금 (원)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '현금을 입력하세요';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ..._stocks.map((stock) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              decoration: InputDecoration(labelText: '종목 이름'),
                              initialValue: stock['name'],
                              onChanged: (value) {
                                stock['name'] = value;
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              decoration: InputDecoration(labelText: '수량'),
                              keyboardType: TextInputType.number,
                              initialValue: stock['quantity'].toString(),
                              onChanged: (value) {
                                stock['quantity'] = int.tryParse(value) ?? 0;
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              decoration: InputDecoration(labelText: '평단가 (원)'),
                              keyboardType: TextInputType.number,
                              initialValue: stock['price'].toString(),
                              onChanged: (value) {
                                stock['price'] = double.tryParse(value) ?? 0.0;
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                             child: TextFormField(
                              decoration: InputDecoration(labelText: '비중 (%)'),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                stock['percentage'] = double.tryParse(value) ?? 0.0;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                    ],
                  );
                }).toList(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _addStock,
                        child: Text('종목 추가'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                          textStyle: TextStyle(fontSize: 16),
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _showAssetSelectionDialog,
                        child: Text('내 자산에서 추가'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                          textStyle: TextStyle(fontSize: 16),
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _calculateRebalancing,
                    child: Text('리밸런싱'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      textStyle: TextStyle(fontSize: 16),
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                if (_investmentPerStock.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _stocks.asMap().entries.map((entry) {
                      int idx = entry.key;
                      var stock = entry.value;
                      return Text(
                        '${stock['name']}에 투자할 금액: ${formatCurrency(_investmentPerStock[idx])}원',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      );
                    }).toList(),
                  ),
                SizedBox(height: 20),
                if (_investmentPerStock.isNotEmpty)
                  Center(
                    child: ElevatedButton(
                      onPressed: _clearData,
                      child: Text('클리어'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        textStyle: TextStyle(fontSize: 16),
                        backgroundColor: Colors.red,
                      ),
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
