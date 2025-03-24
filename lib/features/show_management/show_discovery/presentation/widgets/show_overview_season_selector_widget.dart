import 'package:flutter/material.dart';

class SeasonSelectorWidget extends StatelessWidget {
  const SeasonSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'Staffel:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          SizedBox(width: 8),
          DropdownButton<String>(
            dropdownColor: Colors.black,
            value: '1',
            items: <String>['1', '2', '3', '4'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              // Staffelwechsel-Logik hier hinzufügen
            },
          ),
          Spacer(),
          Text(
            'Netflix',
            style: TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}