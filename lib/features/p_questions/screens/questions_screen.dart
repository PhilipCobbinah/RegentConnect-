import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class PastQuestionsScreen extends StatelessWidget {
  const PastQuestionsScreen({super.key});

  // Mock list of departments at Regent
  final List<Map<String, dynamic>> departments = const [
    {"name": "Computer Science", "icon": Icons.computer},
    {"name": "Information Tech", "icon": Icons.lan},
    {"name": "Business Admin", "icon": Icons.business_center},
    {"name": "Engineering", "icon": Icons.engineering},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Past Questions"),
        backgroundColor: RegentColors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 columns
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemCount: departments.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () {
                // Navigate to specific level/year selection
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, spreadRadius: 2)
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(departments[index]['icon'], size: 50, color: RegentColors.green),
                    const SizedBox(height: 10),
                    Text(
                      departments[index]['name'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
