import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AssetSelectionDialog extends StatelessWidget {
  final Function(Map<String, dynamic>) onAddStockFromAsset;
  final List<Map<String, dynamic>> existingStocks;

  AssetSelectionDialog({required this.onAddStockFromAsset, required this.existingStocks});

  void _addStockFromAsset(BuildContext context, Map<String, dynamic> asset) {
    onAddStockFromAsset(asset);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
                bool isAdded = existingStocks.any((stock) => stock['name'] == asset['name']);

                return ListTile(
                  title: Text(asset['name'] as String),
                  trailing: isAdded
                      ? Icon(Icons.check, color: Colors.grey)
                      : null,
                  onTap: isAdded
                      ? null
                      : () {
                          _addStockFromAsset(context, asset.cast<String, dynamic>());
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
  }
}
