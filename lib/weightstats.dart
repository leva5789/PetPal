import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app_theme.dart';
import 'app_toast.dart';
import 'widgets/premium_widgets.dart';

class WeightStatsPage extends StatefulWidget {
  final String petId;
  final String petName;

  const WeightStatsPage({
    super.key,
    required this.petId,
    required this.petName,
  });

  @override
  _WeightStatsPageState createState() => _WeightStatsPageState();
}

class _WeightStatsPageState extends State<WeightStatsPage> {
  final TextEditingController _weightController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<FlSpot> _weightData = [];
  List<String> _dates = [];
  bool _isLoading = true;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _fetchWeightData();
  }

  Future<void> _fetchWeightData() async {
    try {
      DateTime thirtyDaysAgo =
          DateTime.now().subtract(const Duration(days: 30));

      QuerySnapshot weightSnapshot = await _firestore
          .collection('pets')
          .doc(widget.petId)
          .collection('weightHistory')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .orderBy('date', descending: false)
          .get();

      setState(() {
        _weightData = [];
        _dates = [];
        for (var doc in weightSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final date = (data['date'] as Timestamp).toDate();
          final weight = double.tryParse(data['weight'].toString()) ?? 0.0;

          _dates.add(DateFormat('MM-dd').format(date));
          _weightData.add(FlSpot(_dates.length.toDouble(), weight));
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(context, 'Failed to load weight data');
      }
    }
  }

  Future<void> _updateWeight() async {
    if (_isAdding) return;

    final newWeight = _weightController.text;
    if (newWeight.isEmpty || double.tryParse(newWeight) == null) {
      AppToast.warning(context, 'Please enter a valid weight');
      return;
    }

    setState(() => _isAdding = true);

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
          .update({'weight': parsedWeight});

      _weightController.clear();
      await _fetchWeightData();

      if (mounted) {
        AppToast.success(context, 'Weight recorded!');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to save weight');
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.mint.withOpacity(isDark ? 0.1 : 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputCard(isDark),
                        const SizedBox(height: 32),
                        Text(
                          'Weight History (Last 30 Days)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.darkText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildChart(isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: isDark ? Colors.white : AppTheme.darkText,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.petName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.darkText,
                ),
              ),
              Text(
                'Weight Tracker',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildInputCard(bool isDark) {
    return AnimatedCard(
      child: Row(
        children: [
          Expanded(
            child: PremiumTextField(
              controller: _weightController,
              label: 'New Weight (kg)',
              prefixIcon: Icons.monitor_weight_rounded,
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.mintGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.mint.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _updateWeight,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _isAdding
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.add_rounded,
                          color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildChart(bool isDark) {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator(color: AppTheme.mint)),
      );
    }

    if (_weightData.isEmpty) {
      return Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isDark ? AppTheme.darkBorder : Colors.grey.shade200),
        ),
        child: Center(
          child: EmptyState(
            icon: Icons.bar_chart_rounded,
            title: 'No Data',
            subtitle: 'Add a weight entry to visualize progress!',
          ),
        ),
      );
    }

    return Container(
      height: 350,
      padding: const EdgeInsets.fromLTRB(16, 32, 24, 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
            color: isDark ? AppTheme.darkBorder : Colors.grey.shade200),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: isDark ? Colors.white10 : Colors.grey[200],
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: SideTitles(showTitles: false),
            topTitles: SideTitles(showTitles: false),
            leftTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTextStyles: (value) => TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              margin: 10,
            ),
            bottomTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTextStyles: (value) => TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 11,
              ),
              getTitles: (value) {
                int index = value.toInt() - 1;
                if (index >= 0 && index < _dates.length && index % 2 == 0) {
                  return _dates[index];
                }
                return '';
              },
              margin: 10,
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 1,
          maxX: _weightData.length.toDouble(),
          minY: _weightData.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 1,
          maxY: _weightData.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 1,
          lineBarsData: [
            LineChartBarData(
              spots: _weightData,
              isCurved: true,
              colors: [AppTheme.mint, AppTheme.mintLight],
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: AppTheme.mint,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                colors: [
                  AppTheme.mint.withOpacity(0.2),
                  AppTheme.mint.withOpacity(0.0),
                ],
                gradientFrom: const Offset(0, 0),
                gradientTo: const Offset(0, 1),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 600.ms)
        .slideY(begin: 0.1, end: 0);
  }
}
