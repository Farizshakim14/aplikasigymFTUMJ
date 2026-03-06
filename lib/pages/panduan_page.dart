import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class PanduanPage extends StatefulWidget {
  const PanduanPage({super.key});

  @override
  State<PanduanPage> createState() => _PanduanPageState();
}

class _PanduanPageState extends State<PanduanPage> {
  final List<Map<String, dynamic>> tutorialData = [
{
  "title": "Bicep Workout",
  "img": "assets/bicep.jpg",
  "videos": [
    {
      "name": "Dumbbell Curl",
      "desc": "Latihan dasar untuk membentuk otot bicep.",
      "id": "ykJmrZ5v0Oo"
    },
    {
      "name": "Hammer Curl",
      "desc": "Menambah ketebalan lengan dan brachialis.",
      "id": "5nIXL6UuGZ8"
    },
    {
      "name": "Barbell Curl",
      "desc": "Meningkatkan massa dan kekuatan bicep.",
      "id": "kwG2ipFRgfo"
    },
    {
      "name": "Preacher Curl",
      "desc": "Isolasi maksimal otot bicep.",
      "id": "DoCWeUBA0Gs"
    },
    {
      "name": "Concentration Curl",
      "desc": "Membentuk puncak otot bicep.",
      "id": "0AUGkch3tzc"
    },
    {
      "name": "Cable Bicep Curl",
      "desc": "Menjaga ketegangan otot sepanjang gerakan.",
      "id": "NFzTWp2qpiE"
    },
    {
      "name": "Incline Dumbbell Curl",
      "desc": "Memberikan stretch maksimal pada bicep.",
      "id": "soxrZlIl35U"
    }
  ]
},

{
  "title": "Shoulder Workout",
  "img": "assets/shoulder.jpg",
  "videos": [
    {
      "name": "Dumbbell Shoulder Press",
      "desc": "Latihan utama untuk kekuatan dan massa bahu.",
      "id": "qEwKCR5JCog"
    },
    {
      "name": "Arnold Press",
      "desc": "Melatih bahu depan dan samping secara maksimal.",
      "id": "vKz6V5B9z8Q"
    },
    {
      "name": "Lateral Raise",
      "desc": "Membentuk bahu samping agar terlihat lebar.",
      "id": "Oi2IvqrE-m4"
    },
    {
      "name": "Front Raise",
      "desc": "Fokus melatih bahu bagian depan.",
      "id": "sOcYlBI85hc"
    },
    {
      "name": "Rear Delt Fly",
      "desc": "Melatih bahu belakang dan memperbaiki postur.",
      "id": "eaR9dO1gYcE"
    },
    {
      "name": "Face Pull",
      "desc": "Menjaga kesehatan bahu dan melatih rear delt.",
      "id": "rep-qVOkqgk"
    },
    {
      "name": "Upright Row",
      "desc": "Melatih bahu dan trapezius.",
      "id": "amCU-ziHITM"
    }
  ]
},

{
  "title": "Chest Workout",
  "img": "assets/chest.jpg",
  "videos": [
    {
      "name": "Push Up",
      "desc": "Latihan dasar untuk kekuatan dan daya tahan otot dada.",
      "id": "IODxDxX7oi4"
    },
    {
      "name": "Bench Press",
      "desc": "Latihan utama untuk menambah massa otot dada.",
      "id": "rT7DgCr-3pg"
    },
    {
      "name": "Incline Bench Press",
      "desc": "Fokus melatih dada bagian atas.",
      "id": "SrqOu55lrYU"
    },
    {
      "name": "Decline Bench Press",
      "desc": "Menargetkan dada bagian bawah.",
      "id": "LfyQBUKR8SE"
    },
    {
      "name": "Dumbbell Fly",
      "desc": "Membentuk dan meregangkan otot dada.",
      "id": "eozdVDA78K0"
    },
    {
      "name": "Cable Fly",
      "desc": "Menjaga kontraksi dada sepanjang gerakan.",
      "id": "taI4XduLpTk"
    },
    {
      "name": "Chest Press Machine",
      "desc": "Latihan aman dan terarah untuk pemula.",
      "id": "xUm0BiZCWlQ"
    }
  ]
},

{
  "title": "Back Workout",
  "img": "assets/back.jpg",
  "videos": [
    {
      "name": "Pull Up",
      "desc": "Latihan utama untuk kekuatan punggung atas.",
      "id": "CAwf7n6Luuc"
    },
    {
      "name": "Lat Pulldown",
      "desc": "Membentuk lebar punggung (V-shape).",
      "id": "eE7dzM0IEPM"
    },
    {
      "name": "Seated Cable Row",
      "desc": "Melatih ketebalan punggung tengah.",
      "id": "GZbfZ033f74"
    },
    {
      "name": "Barbell Row",
      "desc": "Meningkatkan massa dan kekuatan punggung.",
      "id": "vT2GjY_Umpw"
    },
    {
      "name": "Dumbbell Row",
      "desc": "Melatih punggung kiri dan kanan secara seimbang.",
      "id": "roCP6wCXPqo"
    },
    {
      "name": "Face Pull",
      "desc": "Melatih upper back dan menjaga kesehatan bahu.",
      "id": "rep-qVOkqgk"
    },
    {
      "name": "Deadlift",
      "desc": "Latihan compound untuk punggung bawah dan tubuh belakang.",
      "id": "op9kVnSso6Q"
    }
  ]
},

{
  "title": "Leg Workout",
  "img": "assets/leg.png",
  "videos": [
    {
      "name": "Squat",
      "desc": "Latihan utama untuk paha depan, glutes, dan kekuatan kaki.",
      "id": "IZxyjW7MPJQ"
    },
    {
      "name": "Leg Press",
      "desc": "Melatih paha dan glutes dengan beban terkontrol.",
      "id": "IZxyjW7MPJQ"
    },
    {
      "name": "Lunges",
      "desc": "Melatih keseimbangan, paha, dan glutes.",
      "id": "QOVaHwm-Q6U"
    },
    {
      "name": "Leg Extension",
      "desc": "Isolasi paha depan (quadriceps).",
      "id": "YyvSfVjQeL0"
    },
    {
      "name": "Leg Curl",
      "desc": "Melatih paha belakang (hamstrings).",
      "id": "1Tq3QdYUuHs"
    },
    {
      "name": "Romanian Deadlift",
      "desc": "Fokus pada hamstrings dan glutes.",
      "id": "2SHsk9AzdjA"
    },
    {
      "name": "Standing Calf Raise",
      "desc": "Melatih otot betis agar lebih kuat dan berisi.",
      "id": "YMmgqO8Jo-k"
    }
  ]
},

{
  "title": "Abs Workout",
  "img": "assets/abs.jpg",
  "videos": [
    {
      "name": "Crunch",
      "desc": "Melatih otot perut bagian atas.",
      "id": "MLx3m0QZpZE"
    },
    {
      "name": "Sit Up",
      "desc": "Melatih kekuatan dasar otot perut.",
      "id": "1fbU_MkV7NE"
    },
    {
      "name": "Leg Raise",
      "desc": "Fokus pada otot perut bagian bawah.",
      "id": "JB2oyawG9KI"
    },
    {
      "name": "Hanging Leg Raise",
      "desc": "Latihan lanjutan untuk perut bawah.",
      "id": "hdng3Nm1x_E"
    },
    {
      "name": "Plank",
      "desc": "Melatih core stability dan daya tahan perut.",
      "id": "ASdvN_XEl_c"
    },
    {
      "name": "Russian Twist",
      "desc": "Melatih otot perut samping (oblique).",
      "id": "wkD8rjkodUI"
    },
    {
      "name": "Cable Crunch",
      "desc": "Memberikan beban tambahan pada otot perut.",
      "id": "AV5PmZJIrrw"
    }
  ]
},

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: const Text("Panduan", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacementNamed(context, "/dashboard");
          },
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12),
        itemCount: tutorialData.length,
        itemBuilder: (context, index) {
          final item = tutorialData[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 500),
                  pageBuilder: (_, __, ___) =>
                      ExerciseListPage(title: item["title"], list: item["videos"], img: item["img"]),
                  transitionsBuilder: (_, a, __, child) =>
                      FadeTransition(opacity: a, child: child),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Colors.blueAccent, Colors.lightBlueAccent],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: item["title"],
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.asset(
                          item["img"],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(item["title"],
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18))
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ================= LIST PAGE =================
class ExerciseListPage extends StatelessWidget {
  final String title;
  final List list;
  final String img;

  const ExerciseListPage({super.key, required this.title, required this.list, required this.img});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: .6),
      body: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: .4)),
          ),
          Column(
            children: [
              const SizedBox(height: 40),
              Hero(
                tag: title,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    img,
                    height: 180,
                    width: MediaQuery.of(context).size.width * .9,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return Card(
                        color: Colors.white.withValues(alpha: .15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                            contentPadding: const EdgeInsets.all(10),
                            leading: const Icon(Icons.fitness_center,
                                color: Colors.white, size: 35),
                            title: Text(item["name"],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            subtitle: Text(item["desc"],
                                style: const TextStyle(color: Colors.white70)),
                            trailing: const Icon(Icons.play_circle_fill,
                                size: 35, color: Colors.blueAccent),
                            onTap: () {
                              showDialog(
                                  context: context,
                                  builder: (_) =>
                                      VideoPopup(videoId: item["id"]));
                            }));
                  },
                ),
              ),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Kembali"))
            ],
          )
        ],
      ),
    );
  }
}

// ================= VIDEO POPUP =================
class VideoPopup extends StatefulWidget {
  final String videoId;
  const VideoPopup({super.key, required this.videoId});

  @override
  State<VideoPopup> createState() => _VideoPopupState();
}

class _VideoPopupState extends State<VideoPopup> {
  late YoutubePlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
      ),
    );
  }

  @override
  void dispose() {
    controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width * .85;

    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: width,
        height: 320,
        child: Column(
          children: [
            Expanded(
              child: YoutubePlayer(
                controller: controller,
                aspectRatio: 16 / 9,
              ),
            ),
            ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Kembali"))
          ],
        ),
      ),
    );
  }
}
