import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double deviceHeight = MediaQuery.of(context).size.height;
    final double deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          // HEADER
          Container(
            width: deviceWidth,
            height: deviceHeight * 0.2,
            color: const Color.fromRGBO(11, 15, 26, 1.0),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Welcome to Integenius",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Integral Calculator",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),

          // MAIN CONTENT
          Expanded(
            child: Stack(
              children: [
                // WALLPAPER
                Container(
                  width: deviceWidth,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("lib/assets/images/image.jpeg"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // BUTTONS
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _customButton(
                          deviceWidth,
                          "Start to Calculate",
                          Icons.calculate,
                          () {
                            Navigator.pushNamed(context, '/calculate');
                          },
                        ),
                        const SizedBox(height: 20),
                        _customButton(
                          deviceWidth,
                          "How to Use the App",
                          Icons.help_center_outlined,
                          () {
                            Navigator.pushNamed(context, '/howToUse');
                          },
                        ),
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

  Widget _customButton(
    double width,
    String title,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      width: width * 0.8,
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 10, 40, 53),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.grey, offset: Offset(5, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton(onPressed: onPressed, child: const Text("Click")),
        ],
      ),
    );
  }
}





