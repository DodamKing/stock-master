import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:rebalancing_calculator/env.dart';

class AssetSearchScreen extends StatefulWidget {
  final Function(String, String) onAssetSelected;

  AssetSearchScreen({required this.onAssetSelected});

  @override
  _AssetSearchScreenState createState() => _AssetSearchScreenState();
}

class _AssetSearchScreenState extends State<AssetSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  Future<void> _searchAssets() async {
    String query = _searchController.text;
    if (query.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('경고'),
            content: Text('종목 이름을 입력하세요.'),
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

    final response = await http.get(Uri.parse('$API_BASE/search/name/$query'));

    if (response.statusCode == 200) {
      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(json.decode(response.body));
      });
    } else {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('종목 찾기'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '종목 이름',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _searchAssets,
              child: Text('검색'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                textStyle: TextStyle(fontSize: 16),
                backgroundColor: Colors.blue,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  var asset = _searchResults[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: Text(asset['Name']),
                      subtitle: Text('종목 코드: ${asset['Symbol']}'),
                      onTap: () {
                        widget.onAssetSelected(asset['Name'], asset['Symbol']);
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
