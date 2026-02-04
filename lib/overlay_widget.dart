
import 'package:flutter/material.dart';

class OverlayWidget extends StatelessWidget {
  const OverlayWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 50,
      right: 20,
      child: Opacity(
        opacity: 0.7,
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: const Text(
            'Victoria',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto'
            ),
          ),
        ),
      ),
    );
  }
}
