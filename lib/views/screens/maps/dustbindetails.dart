import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';


class DustbinDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> dustbin;

  DustbinDetailsScreen({required this.dustbin});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      padding: EdgeInsets.all(16),
      color: Colors.white, // Adjust as needed
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dustbin Details',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Name: ${dustbin['name']}',
            style: TextStyle(fontSize: 18),
          ),
          Text(
            'Percentage: ${dustbin['percentage']}%',
            style: TextStyle(fontSize: 18),
          ),
          Text(
            'State: ${dustbin['state'] ?? 'Unknown'}',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Generate route to this dustbin
              // Call the function to generate the route here
            },
            child: Text('Generate Route'),
          ),
        ],
      ),
    );
  }
}
