import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

/// Belső helper stat osztály 1 (pet, type) kombinációra
class _ActivityStats {
  DateTime lastDate;
  int countLast7Days;
  int countYesterday;

  _ActivityStats({
    required this.lastDate,
    required this.countLast7Days,
    required this.countYesterday,
  });
}

class _InfoPageState extends State<InfoPage> {
  bool _isLoading = true;
  String? _errorMessage;

  /// Itt tároljuk a felhasználó kutyafajtáihoz tartozó leírásokat
  List<Map<String, String>> _breedInfos = [];

  /// Napi 1 mondatos tipp
  String? _dailyTip;

  @override
  void initState() {
    super.initState();
    _loadBreedInfos();
    _loadDailyTip();
  }

  Future<void> _loadBreedInfos() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'You must be logged in to see the information.';
        });
        return;
      }

      final firestore = FirebaseFirestore.instance;

      final petsSnapshot = await firestore
          .collection('pets')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (petsSnapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _breedInfos = [];
        });
        return;
      }

      final Set<String> breedNames = {};
      for (final doc in petsSnapshot.docs) {
        final data = doc.data();
        final breed = data['breed'];
        if (breed is String && breed.trim().isNotEmpty) {
          breedNames.add(breed.trim());
        }
      }

      if (breedNames.isEmpty) {
        setState(() {
          _isLoading = false;
          _breedInfos = [];
        });
        return;
      }

      final List<Map<String, String>> infos = [];

      for (final breed in breedNames) {
        final querySnapshot = await firestore
            .collection('dog_breed')
            .where('name', isEqualTo: breed)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final dogData =
          querySnapshot.docs.first.data() as Map<String, dynamic>;

          final description =
              (dogData['description'] as String?) ?? 'No description available.';

          infos.add({
            'breedName': breed,
            'description': description,
          });
        }
      }

      setState(() {
        _isLoading = false;
        _breedInfos = infos;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading information: $e';
      });
    }
  }

  /// Napi 1 mondatos tipp generálása a tasks kollekció alapján
  Future<void> _loadDailyTip() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _dailyTip =
          'You\'re doing great taking care of your pets – even a small walk or play session today makes a big difference. 🐾';
        });
        return;
      }

      final firestore = FirebaseFirestore.instance;

      final tasksSnapshot = await firestore
          .collection('tasks')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (tasksSnapshot.docs.isEmpty) {
        setState(() {
          _dailyTip =
          'You don\'t have any tasks yet – try adding reminders for walks, vet visits or grooming to support your pet\'s routine. 🐾';
        });
        return;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final weekAgo = today.subtract(const Duration(days: 7));

      final Map<String, Map<String, _ActivityStats>> statsCompleted = {};
      final Map<String, Map<String, _ActivityStats>> statsAll = {};

      void updateStatsMap(
          Map<String, Map<String, _ActivityStats>> base,
          String petName,
          String type,
          DateTime date,
          ) {
        final normalized =
        DateTime(date.year, date.month, date.day); // csak nap pontosság

        base.putIfAbsent(petName, () => {});
        final petMap = base[petName]!;

        petMap.putIfAbsent(
          type,
              () => _ActivityStats(
            lastDate: normalized,
            countLast7Days: 0,
            countYesterday: 0,
          ),
        );

        final stats = petMap[type]!;

        if (normalized.isAfter(stats.lastDate)) {
          stats.lastDate = normalized;
        }

        if (!normalized.isBefore(weekAgo) && !normalized.isAfter(today)) {
          stats.countLast7Days += 1;
        }

        if (normalized.isAtSameMomentAs(yesterday)) {
          stats.countYesterday += 1;
        }
      }

      for (final doc in tasksSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final type = (data['type'] as String?) ?? 'not_understood';
        if (type == 'not_understood') continue;

        final petName = (data['petName'] as String?) ?? 'your dog';

        final ts = data['date'];
        if (ts is! Timestamp) continue;
        final date = ts.toDate();
        if (date.isAfter(now)) continue;

        updateStatsMap(statsAll, petName, type, date);

        final completed = data['completed'] as bool? ?? false;
        if (completed) {
          updateStatsMap(statsCompleted, petName, type, date);
        }
      }

      final baseStats =
      statsCompleted.isNotEmpty ? statsCompleted : statsAll;

      if (baseStats.isEmpty) {
        setState(() {
          _dailyTip =
          'You\'re doing great taking care of your pets – even a small walk or play session today makes a big difference. 🐾';
        });
        return;
      }

      const Map<String, int> recommendedGapDays = {
        'walk': 1,
        'feeding': 1,
        'watering': 1,
        'play': 1,
        'training': 2,
        'multi_pet': 2,
        'cleaning': 7,
        'grooming': 30,
        'shopping': 30,
        'medication': 1,
        'vet': 180,
        'other_pet_related': 14,
      };

      const Map<String, String> typeToPhrase = {
        'walk': 'gone for a proper walk with',
        'feeding': 'given a proper meal to',
        'watering': 'refilled the water bowl for',
        'play': 'had a dedicated play session with',
        'training': 'done some training with',
        'multi_pet': 'spent one-on-one time with',
        'cleaning': 'cleaned the bed and bowls of',
        'grooming': 'done grooming for',
        'shopping': 'checked the supplies for',
        'medication': 'given medication to',
        'vet': 'visited the vet with',
        'other_pet_related': 'done this kind of care for',
      };

      String? overduePet;
      String? overdueType;
      double bestOverdueScore = 0;
      int bestOverdueDaysSince = 0;

      baseStats.forEach((petName, typeMap) {
        typeMap.forEach((type, stats) {
          final daysSince = now.difference(stats.lastDate).inDays;
          final gap = recommendedGapDays[type] ?? 14;
          final score = daysSince / gap;

          if (score > bestOverdueScore && daysSince >= gap) {
            bestOverdueScore = score;
            overduePet = petName;
            overdueType = type;
            bestOverdueDaysSince = daysSince;
          }
        });
      });

      String tip;

      if (overduePet != null && overdueType != null) {
        final phrase = typeToPhrase[overdueType] ?? 'done this activity with';

        if (overdueType == 'vet' && bestOverdueDaysSince >= 60) {
          final months = (bestOverdueDaysSince / 30).round();
          tip =
          'It\'s been around $months months since you last $phrase $overduePet – it might be a good idea to plan a vet check-up soon. 🐾';
        } else {
          tip =
          'It looks like you haven\'t $phrase $overduePet for about $bestOverdueDaysSince days – today could be a great day to do it. 🐾';
        }
      } else {

        String? bestPet;
        String? bestType;
        _ActivityStats? bestStats;
        int bestCount7 = -1;
        DateTime bestLastDate = DateTime.fromMillisecondsSinceEpoch(0);

        baseStats.forEach((petName, typeMap) {
          typeMap.forEach((type, stats) {
            if (stats.countLast7Days > bestCount7 ||
                (stats.countLast7Days == bestCount7 &&
                    stats.lastDate.isAfter(bestLastDate))) {
              bestCount7 = stats.countLast7Days;
              bestLastDate = stats.lastDate;
              bestPet = petName;
              bestType = type;
              bestStats = stats;
            }
          });
        });

        if (bestPet != null && bestType != null && bestStats != null) {
          final phrase = typeToPhrase[bestType] ?? 'spent time with';
          final stats = bestStats!; // <-- ITT TESSZÜK NEM NULL-LÁ

          if (stats.countYesterday > 0) {
            tip =
            'Yesterday you $phrase $bestPet ${stats.countYesterday} time(s) – that\'s fantastic, keep it up! 🐾';
          } else if (stats.countLast7Days > 0) {
            tip =
            'In the last week you $phrase $bestPet ${stats.countLast7Days} time(s) – you\'re doing a great job caring for your dog! 🐾';
          } else {
            final daysSince = now.difference(stats.lastDate).inDays;
            tip =
            'You\'re taking good care of $bestPet – your last time you $phrase was about $daysSince days ago, maybe repeat it again soon. 🐾';
          }
        } else {
          tip =
          'You\'re doing great taking care of your pets – even a small walk or play session today makes a big difference. 🐾';
        }
      }

      setState(() {
        _dailyTip = tip;
      });
    } catch (e) {
      print('Error while generating daily tip: $e');
      setState(() {
        _dailyTip =
        'You\'re doing great taking care of your pets – even a small walk or play session today makes a big difference. 🐾';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Information'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
          ),
        ),
      )
          : _breedInfos.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_dailyTip != null) ...[
                Card(
                  margin:
                  const EdgeInsets.only(bottom: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _dailyTip!,
                      style:
                      const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
              const Text(
                'You don\'t have any breeds with information yet.\n\n'
                    'Add a pet to see related information here. 🐾',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount:
        _breedInfos.length + (_dailyTip != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (_dailyTip != null && index == 0) {
            return Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _dailyTip!,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          final infoIndex =
              index - (_dailyTip != null ? 1 : 0);
          final info = _breedInfos[infoIndex];
          final breedName =
              info['breedName'] ?? 'Unknown';
          final description =
              info['description'] ??
                  'No description available.';

          return Card(
            margin:
            const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding:
              const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    breedName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                        fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
