import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  bool onLastPage = false;

  List<String> images = [
    "assets/onboard1.png",
    "assets/onboard2.png",
    "assets/onboard3.png",
    "assets/onboard4.png",
  ];

  List<String> titles = [
    "Pantau progress latihan Anda",
    "Jadwal operasi gym dan instruktur",
    "Akses video latihan dan panduan",
    "Kelola profil kesehatan Anda",
  ];

  List<String> subtitles = [
    "Aplikasi ini membantu Anda mengawasi perkembangan latihan setiap hari agar tujuan kebugaran lebih mudah tercapai.",
    "Temukan jadwal instruktur, kelas workout, dan jam operasional gym dengan cepat dalam satu aplikasi.",
    "Tingkatkan teknik latihan Anda melalui video dan panduan terpercaya yang mudah diikuti.",
    "Atur data kesehatan dan kebiasaan olahraga Anda dalam satu tempat untuk hasil yang lebih optimal.",
  ];

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

          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (index) {
                    setState(() {
                      onLastPage = (index == images.length - 1);
                    });
                  },
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * 0.48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF78A7FF),
                                Color(0xFF91D5FF),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(45),
                              bottomRight: Radius.circular(45),
                            ),
                          ),
                          child: Center(
                            child: Image.asset(
                              images[index],
                              width:
                                  MediaQuery.of(context).size.width * 0.65,
                              height:
                                  MediaQuery.of(context).size.width * 0.65,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 35),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 25),
                          child: Text(
                            titles[index],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 28),
                          child: Text(
                            subtitles[index],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 15.5,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              /// Bottom Indicator + Buttons
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Text(
                        "Skip",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SmoothPageIndicator(
                      controller: _controller,
                      count: images.length,
                      effect: const WormEffect(
                        dotHeight: 10,
                        dotWidth: 10,
                        activeDotColor: Colors.blue,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (onLastPage) {
                          Navigator.pushReplacementNamed(context, '/login');
                        } else {
                          _controller.nextPage(
                            duration:
                                const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: CircleAvatar(
                        radius: 27,
                        backgroundColor: Colors.blue.shade500,
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}