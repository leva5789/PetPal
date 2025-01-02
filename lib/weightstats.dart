import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class WeightStatsPage extends StatefulWidget {
  final String petId;
  final String petName;

  WeightStatsPage({required this.petId, required this.petName});

  @override
  _WeightStatsPageState createState() => _WeightStatsPageState();
}

class _WeightStatsPageState extends State<WeightStatsPage> {
  final TextEditingController _weightController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<FlSpot> _weightData = [];
  List<String> _dates = [];

  @override
  void initState() {
    super.initState();
    _fetchWeightData();
  }

  Future<void> _fetchWeightData() async {
    try {
      DateTime thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));

      QuerySnapshot weightSnapshot = await _firestore
          .collection('pets')
          .doc(widget.petId)
          .collection('weightHistory')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .orderBy('date', descending: false)
          .get();

      setState(() {
        _weightData = [];
        _dates = [];
        weightSnapshot.docs.forEach((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final date = (data['date'] as Timestamp).toDate();
          final weight = double.tryParse(data['weight'].toString()) ?? 0.0;

          _dates.add(DateFormat('MM-dd').format(date)); // Only display MM-dd format
          _weightData.add(FlSpot(_dates.length.toDouble(), weight));
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching weight data: $e')),
      );
    }
  }

  Future<void> _updateWeight() async {
    final newWeight = _weightController.text;
    if (newWeight.isEmpty || double.tryParse(newWeight) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid weight.')),
      );
      return;
    }

    try {
      final timestamp = Timestamp.now();
      final parsedWeight = double.parse(newWeight);

      await _firestore
          .collection('pets')
          .doc(widget.petId)
          .collection('weightHistory')
          .add({
        'date': timestamp,
        'weight': parsedWeight,
      });

      await _firestore
          .collection('pets')
          .doc(widget.petId)
          .update({'weight': parsedWeight}); // Update the current weight

      _weightController.clear();
      _fetchWeightData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Weight updated successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating weight: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.petName),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: 'Enter new weight',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateWeight,
              child: Text('Update Weight'),
            ),
            SizedBox(height: 24),
            Expanded(
              child: _weightData.isNotEmpty
                  ? LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: SideTitles(showTitles: true),
                    bottomTitles: SideTitles(
                      showTitles: true,
                      getTitles: (value) {
                        int index = value.toInt() - 1;
                        if (index >= 0 && index < _dates.length) {
                          return _dates[index];
                        }
                        return '';
                      },
                      rotateAngle: 0, // Make labels horizontal
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 1,
                  maxX: _weightData.length.toDouble(),
                  minY: _weightData.map((e) => e.y).reduce((a, b) => a < b ? a : b),
                  maxY: _weightData.map((e) => e.y).reduce((a, b) => a > b ? a : b),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _weightData,
                      isCurved: true,
                      colors: [Colors.blue],
                      barWidth: 4,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              )
                  : Center(child: Text('No weight data available.')),
            ),
          ],
        ),
      ),
    );
  }
}
