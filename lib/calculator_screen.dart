import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'popup_add_stock.dart';
import 'asset_selection_dialog.dart';
import 'stock_list_title.dart';

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
  bool _showOptions = false;

  void _addStock() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddStockPopup(onAdd: (stock) {
          setState(() {
            stock['percentage'] = stock['percentage'] ?? 0.0;
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
        // 'price': asset['initialPrice'] as double,
        'price': 0.0,
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

  void _toggleOptions() {
    setState(() {
      _showOptions = !_showOptions;
    });
  }

  void _showAddStockDialog() {
    if (_showOptions) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            children: [
              SimpleDialogOption(
                onPressed: () {
                  Navigator.of(context).pop();
                  _addStock();
                },
                child: Text('종목 추가'),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AssetSelectionDialog(
                        onAddStockFromAsset: (asset) {
                          _addStockFromAsset(asset);
                        },
                        existingStocks: _stocks,
                      );
                    },
                  );
                },
                child: Text('내 자산에서 추가'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('리밸런싱 계산기'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _toggleOptions();
              _showAddStockDialog();
            },
          ),
        ],
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
                ),
                SizedBox(height: 20),
                ..._stocks.map((stock) => StockListTile(
                  key: ValueKey(stock['name']),
                  stock: stock,
                  onDelete: () {
                    setState(() {
                      _stocks.remove(stock);
                    });
                  }, 
                )).toList(),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _calculateRebalancing,
                    icon: Icon(Icons.calculate),
                    label: Text('리밸런싱'),
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
                    child: ElevatedButton.icon(
                      onPressed: _clearData,
                      icon: Icon(Icons.clear),
                      label: Text('클리어'),
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