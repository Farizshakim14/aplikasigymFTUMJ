import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'reservasi_page.dart';
import 'panduan_page.dart';
import 'profil_page.dart';
import 'package:aplikasigym/pages/rekomendasi_page.dart';
import 'statistik_page.dart';
import 'tentang_page.dart';
import 'absensi_page.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  final ScrollController _scrollController = ScrollController();
  double _parallaxOffset = 0;

  String _selectedPage = 'Dashboard';

  String userName = "User";
  String userEmail = "user@email.com";

  final _auth = FirebaseAuth.instance;

  bool loadingChart = true;
  List<FlSpot> yearSpots = [];
  double maxChartY = 7;

  @override
  void initState() {
    super.initState();
    _loadFromFirebase();
    _loadYearStatistic();

    _scrollController.addListener(() {
      setState(() {
        _parallaxOffset = _scrollController.offset * 0.3;
      });
    });
  }

  Future<void> _loadFromFirebase() async {
    final user = _auth.currentUser;
    if (user == null) return;

    userEmail = user.email ?? "user@email.com";

    final snap = await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(user.uid)
        .get();

    if (!snap.exists) return;

    final data = Map<String, dynamic>.from(snap.value as Map);

    setState(() {
      userName = data["nama"] ?? "User";
    });
  }

  Future<void> _loadYearStatistic() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap =
        await FirebaseDatabase.instance.ref("absensi/${user.uid}").get();

    yearSpots.clear();

    if (!snap.exists) {
      setState(() => loadingChart = false);
      return;
    }

    List<DateTime> dates = [];
    for (var e in snap.children) {
      final data = Map<String, dynamic>.from(e.value as Map);
      if (data.containsKey("tanggal")) {
        dates.add(DateTime.parse(data["tanggal"]));
      }
    }

    int year = DateTime.now().year;
    double tempMax = 0;

    for (int m = 1; m <= 12; m++) {
      int count =
          dates.where((d) => d.year == year && d.month == m).length;

      if (count > tempMax) tempMax = count.toDouble();

      yearSpots.add(FlSpot(m.toDouble(), count.toDouble()));
    }

    maxChartY = tempMax < 7 ? 7 : tempMax;

    setState(() => loadingChart = false);
  }

  void _selectPage(String page) {
    Navigator.of(context).maybePop();
    if (!mounted) return;
    setState(() => _selectedPage = page);
  }

  Widget _getPage() {
    switch (_selectedPage) {
      case 'Profil':
        return const ProfilPage();
      case 'Jadwal':
        return const ReservasiPage();
      case 'Panduan':
        return const PanduanPage();
      case 'Rekomendasi':
        return const RekomendasiAIPage();
      case 'Statistik':
        return const StatistikPage();
      case 'Tentang':
        return const TentangPage();
      default:
        return _dashboardContent();
    }
  }

  Widget _dashboardContent() {
    return Stack(
      children: [

        /// ================= PARALLAX BACKGROUND =================
        Positioned.fill(
          child: Transform.translate(
            offset: Offset(0, -_parallaxOffset),
            child: Image.asset(
              "assets/fotobackground.jpg",
              fit: BoxFit.cover,
            ),
          ),
        ),

        /// ================= BLUR + GRADIENT =================
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xCC0A0F1C),
                    Color(0xDD111B2E),
                    Color(0xEE000000),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),

        /// ================= CONTENT =================
        SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [

              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [

                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person,
                              color: Colors.black, size: 30),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Row(
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  GestureDetector(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const ProfilPage()),
                                      );
                                      _loadFromFirebase();
                                    },
                                    child: const Text(
                                      "Edit",
                                      style: TextStyle(
                                        color: Colors.blueAccent,
                                        fontWeight: FontWeight.bold,
                                        decoration:
                                            TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              Text(
                                userEmail,
                                style: const TextStyle(
                                    color: Colors.white70),
                              ),
                            ],
                          ),
                        ),

                        InkWell(
                          onTap: () => _selectPage("Jadwal"),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.calendar_month,
                                    color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  "Booking",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// ================= STATISTICS =================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xAA0C1424),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          const Text(
                            "Statistics",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          SizedBox(
                            height: 180,
                            child: loadingChart
                                ? const Center(
                                    child:
                                        CircularProgressIndicator(
                                            color:
                                                Colors.white))
                                : LineChart(
                                    LineChartData(
                                      minX: 1,
                                      maxX: 12,
                                      minY: 0,
                                      maxY: maxChartY,
                                      gridData:
                                          FlGridData(show: true),
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                            sideTitles:
                                                SideTitles(
                                                    showTitles:
                                                        false)),
                                        topTitles: AxisTitles(
                                            sideTitles:
                                                SideTitles(
                                                    showTitles:
                                                        false)),
                                        rightTitles: AxisTitles(
                                            sideTitles:
                                                SideTitles(
                                                    showTitles:
                                                        false)),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            interval: 1,
                                            getTitlesWidget:
                                                (value, _) {
                                              const months = [
                                                "",
                                                "Jan",
                                                "Feb",
                                                "Mar",
                                                "Apr",
                                                "Mei",
                                                "Jun",
                                                "Jul",
                                                "Agu",
                                                "Sep",
                                                "Okt",
                                                "Nov",
                                                "Des"
                                              ];

                                              if (value % 1 == 0 &&
                                                  value >= 1 &&
                                                  value <=
                                                      12) {
                                                return Text(
                                                  months[value
                                                      .toInt()],
                                                  style:
                                                      const TextStyle(
                                                    color: Colors
                                                        .white70,
                                                    fontSize: 10,
                                                  ),
                                                );
                                              }
                                              return const SizedBox
                                                  .shrink();
                                            },
                                          ),
                                        ),
                                      ),
                                      borderData: FlBorderData(
                                          show: false),
                                      lineBarsData: [
                                        LineChartBarData(
                                          isCurved: true,
                                          barWidth: 4,
                                          color:
                                              Colors.blueAccent,
                                          dotData: FlDotData(
                                              show: true),
                                          spots: yearSpots,
                                        )
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Quick Actions",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),

                    const SizedBox(height: 10),

                    _actionButton(
                      Icons.qr_code,
                      "Absensi",
                      "Masuk ke halaman absensi",
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const AbsensiPage()),
                        );
                      },
                    ),

                    _actionButton(Icons.menu_book, "Panduan",
                        "Panduan Penggunaan",
                        () => _selectPage("Panduan")),

                    _actionButton(Icons.thumb_up,
                        "Rekomendasi", "Saran Latihan",
                        () => _selectPage("Rekomendasi")),

                    _actionButton(Icons.bar_chart,
                        "Statistik", "Lihat grafik",
                        () => _selectPage("Statistik")),

                    _actionButton(Icons.info, "Tentang",
                        "Tentang aplikasi",
                        () => _selectPage("Tentang")),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionButton(
      IconData icon, String title, String subtitle,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xE0EFF3FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 35),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.black54)),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(userName),
              accountEmail: Text(userEmail),
              currentAccountPicture:
                  const CircleAvatar(
                      child: Icon(Icons.person)),
            ),
            _drawerItem(Icons.person, 'Profil'),
            _drawerItem(Icons.calendar_month, 'Jadwal'),
            _drawerItem(Icons.menu_book, 'Panduan'),
            _drawerItem(Icons.thumb_up, 'Rekomendasi'),
            _drawerItem(Icons.bar_chart, 'Statistik'),
            _drawerItem(Icons.info, 'Tentang'),
          ],
        ),
      ),
      body: _getPage(),
    );
  }

  Widget _drawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () => _selectPage(title),
    );
  }
}