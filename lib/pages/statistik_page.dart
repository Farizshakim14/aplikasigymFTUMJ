import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class StatistikPage extends StatefulWidget {
  const StatistikPage({super.key});

  @override
  State<StatistikPage> createState() => _StatistikPageState();
}

class _StatistikPageState extends State<StatistikPage> {
  String selectedRange = "Harian";
  List<FlSpot> chartData = [];
  bool loading = true;
  int totalCount = 0;

  List<String> dayLabels = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"];
  List<String> weekLabels = ["Minggu 1", "Minggu 2", "Minggu 3", "Minggu 4"];
  List<String> monthLabels = [
    "Jan","Feb","Mar","Apr","Mei","Jun",
    "Jul","Agu","Sep","Okt","Nov","Des"
  ];

  double minX = 0;
  double maxX = 6;
  double interval = 1;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    loadStatistic();
  }

  Future<void> loadStatistic() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap =
        await FirebaseDatabase.instance.ref("absensi/${user.uid}").get();

    chartData.clear();
    totalCount = 0;

    if (!snap.exists) {
      setState(() => loading = false);
      return;
    }

    List<DateTime> dates = [];
    for (var e in snap.children) {
      final data = Map<String, dynamic>.from(e.value as Map);
      if (data.containsKey("tanggal")) {
        dates.add(DateTime.parse(data["tanggal"]));
      }
    }

    DateTime now = DateTime.now();

    if (selectedRange == "Harian") {
      totalCount = 0;

      DateTime start = now.subtract(Duration(days: now.weekday - 1));

      minX = 0;
      maxX = 6;
      interval = 1;

      for (int i = 0; i < 7; i++) {
        DateTime d = start.add(Duration(days: i));

        bool hadir = dates.any((x) =>
            x.year == d.year && x.month == d.month && x.day == d.day);

        if (hadir) totalCount++;
        chartData.add(FlSpot(i.toDouble(), hadir ? 1.0 : 0.0));
      }
    }

    else if (selectedRange == "Mingguan") {
      totalCount = 0;

      minX = 0;
      maxX = 3;
      interval = 1;

      for (int i = 0; i < 4; i++) {
        DateTime start = now.subtract(Duration(days: (3 - i) * 7));
        DateTime end = start.add(const Duration(days: 7));

        int count =
            dates.where((d) => d.isAfter(start) && d.isBefore(end)).length;

        totalCount += count;
        chartData.add(FlSpot(i.toDouble(), count.toDouble()));
      }
    }

    else if (selectedRange == "Bulanan") {
      totalCount = 0;

      int daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;

      minX = 1;
      maxX = daysInMonth.toDouble();
      interval = 1;

      for (int d = 1; d <= daysInMonth; d++) {
        int count = dates.where((x) =>
            x.year == selectedYear &&
            x.month == selectedMonth &&
            x.day == d).length;

        totalCount += count;
        chartData.add(FlSpot(d.toDouble(), count.toDouble()));
      }
    }

    else {
      totalCount = 0;

      minX = 1;
      maxX = 12;
      interval = 1;

      for (int m = 1; m <= 12; m++) {
        int count =
            dates.where((d) => d.year == selectedYear && d.month == m).length;

        totalCount += count;
        chartData.add(FlSpot(m.toDouble(), count.toDouble()));
      }
    }

    setState(() => loading = false);
  }

  Widget bottomTitle(double value, TitleMeta meta) {
    switch (selectedRange) {
      case "Harian":
        if (value >= 0 && value < 7) {
          return Text(dayLabels[value.toInt()],
              style: const TextStyle(color: Colors.white70, fontSize: 10));
        }
        break;

      case "Mingguan":
        if (value >= 0 && value < 4) {
          return Text(weekLabels[value.toInt()],
              style: const TextStyle(color: Colors.white70, fontSize: 10));
        }
        break;

      case "Bulanan":
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            value.toInt().toString(),
            style: const TextStyle(color: Colors.white70, fontSize: 9),
          ),
        );

      case "Tahunan":
        if (value >= 1 && value <= 12) {
          return Text(monthLabels[value.toInt() - 1],
              style: const TextStyle(color: Colors.white70, fontSize: 10));
        }
        break;
    }
    return const Text("");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [

          Positioned.fill(
            child: Image.asset(
              "assets/fotobackground.jpg",
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: .4),
            ),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.transparent),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 35),

                GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/dashboard'),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C1424),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 20),
                  ),
                ),

                const SizedBox(height: 20),

                const Text("Statistik Absensi",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Lihat berdasarkan:",
                        style: TextStyle(color: Colors.white70)),

                    Row(
                      children: [
                        DropdownButton<String>(
                          dropdownColor: Colors.black,
                          value: selectedRange,
                          underline: Container(),
                          style: const TextStyle(color: Colors.white),
                          items: const [
                            DropdownMenuItem(
                                value: "Harian", child: Text("Harian")),
                            DropdownMenuItem(
                                value: "Mingguan", child: Text("Mingguan")),
                            DropdownMenuItem(
                                value: "Bulanan", child: Text("Bulanan")),
                            DropdownMenuItem(
                                value: "Tahunan", child: Text("Tahunan")),
                          ],
                          onChanged: (v) {
                            selectedRange = v!;
                            loading = true;
                            setState(() {});
                            loadStatistic();
                          },
                        ),

                        if (selectedRange == "Bulanan")
                          DropdownButton<int>(
                            dropdownColor: Colors.black,
                            value: selectedMonth,
                            style: const TextStyle(color: Colors.white),
                            underline: Container(),
                            items: List.generate(
                              12,
                              (i) => DropdownMenuItem(
                                value: i + 1,
                                child: Text(monthLabels[i]),
                              ),
                            ),
                            onChanged: (v) {
                              selectedMonth = v!;
                              loading = true;
                              setState(() {});
                              loadStatistic();
                            },
                          ),

                        if (selectedRange == "Tahunan")
                          DropdownButton<int>(
                            dropdownColor: Colors.black,
                            value: selectedYear,
                            style: const TextStyle(color: Colors.white),
                            underline: Container(),
                            items: List.generate(
                              6,
                              (i) {
                                int year = DateTime.now().year - i;
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text(year.toString()),
                                );
                              },
                            ),
                            onChanged: (v) {
                              selectedYear = v!;
                              loading = true;
                              setState(() {});
                              loadStatistic();
                            },
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  "Total Absensi $selectedRange : $totalCount",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xFF0C1424),
                        borderRadius: BorderRadius.circular(18)),
                    child: loading
                        ? const Center(
                            child:
                                CircularProgressIndicator(color: Colors.white))
                        : chartData.isEmpty
                            ? const Center(
                                child: Text("Belum ada data absensi",
                                    style:
                                        TextStyle(color: Colors.white70)))
                            : LineChart(
                                LineChartData(
                                  minX: minX,
                                  maxX: maxX,
                                  minY: 0,
                                  maxY: chartData.isEmpty
                                      ? 7.0
                                      : (() {
                                          double max = chartData
                                              .map((e) => e.y)
                                              .reduce((a, b) =>
                                                  a > b ? a : b);
                                          return max < 7 ? 7.0 : max;
                                        }()),
                                  gridData: FlGridData(show: true),
                                  borderData: FlBorderData(show: false),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: 1,
                                        reservedSize: 30,
                                        getTitlesWidget: (value, meta) => Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10),
                                        ),
                                      ),
                                    ),
                                    rightTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    topTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: interval,
                                        getTitlesWidget: bottomTitle,
                                        reservedSize: 34,
                                      ),
                                    ),
                                  ),
                                  lineBarsData: [
                                    LineChartBarData(
                                      isCurved: true,
                                      barWidth: 4,
                                      color: Colors.blueAccent,
                                      dotData: FlDotData(show: true),
                                      spots: chartData,
                                    ),
                                  ],
                                ),
                              ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}