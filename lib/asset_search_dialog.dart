import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'env.dart';

class AssetSearchDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAssetSaved;

  AssetSearchDialog({required this.onAssetSaved});

  @override
  _AssetSearchDialogState createState() => _AssetSearchDialogState();
}

class _AssetSearchDialogState extends State<AssetSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  Map<String, dynamic>? _selectedAsset;

  Future<void> _searchAssets() async {
    if (_searchController.text.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response = await http.get(Uri.parse('$API_BASE/search/name/${_searchController.text}'));
    if (response.statusCode == 200) {
      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(json.decode(response.body));
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to load assets');
    }
  }

  void _saveAsset() {
    if (_selectedAsset != null && _quantityController.text.isNotEmpty && _priceController.text.isNotEmpty) {
      Map<String, dynamic> newAsset = {
        'name': _selectedAsset!['Name'],
        'code': _selectedAsset!['Symbol'],
        'quantity': int.parse(_quantityController.text),
        'price': double.parse(_priceController.text),
        'initialPrice': double.parse(_priceController.text),
      };
      widget.onAssetSaved(newAsset);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('종목 찾기'),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '종목 이름',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchAssets,
                ),
              ),
            ),
            SizedBox(height: 16),
            _isLoading
                ? CircularProgressIndicator()
                : _searchResults.isNotEmpty
                    ? Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            var asset = _searchResults[index];
                            bool isSelected = _selectedAsset == asset;
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                side: BorderSide(color: isSelected ? Colors.blue : Colors.grey),
                              ),
                              color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                              child: ListTile(
                                title: Text(asset['Name']),
                                subtitle: Text('코드: ${asset['Symbol']}'),
                                onTap: () {
                                  setState(() {
                                    _selectedAsset = asset;
                                    _priceController.text = asset['Price'].toString();
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      )
                    : Container(),
            if (_selectedAsset != null)
              Column(
                children: <Widget>[
                  TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(labelText: '수량'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(labelText: '평단가 (원)'),
                    keyboardType: TextInputType.number,
                  ),
                ],
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
          child: Text('저장'),
          onPressed: _saveAsset,
        ),
      ],
    );
  }
}
