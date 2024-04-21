import "package:flutter/material.dart";

import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:flutter_rps/widgets/svg_icons.dart' as svg_icons;

enum DisplayPages { pictureImage, donwloadImage }

class DisplayPage extends StatefulWidget {
  const DisplayPage({
    super.key,
  });

  @override
  State<DisplayPage> createState() => _DisplayPageState();
}

class _DisplayPageState extends State<DisplayPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          children: [
            Iconify(
              svg_icons.chevronBack,
              color: Colors.white,
            ),
            Padding(padding: EdgeInsets.symmetric(horizontal: 4.0)),
            Text(
              'Back',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        const Spacer(flex: 10),
        Container(
          clipBehavior: Clip.hardEdge,
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 2 / 5,
          alignment: Alignment.topCenter,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 3 / 11,
                decoration: BoxDecoration(boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 6,
                    blurRadius: 5,
                  )
                ]),
              ),
              const Spacer(),
              const Column(
                children: [
                  Text(
                    'Data',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Pred Time:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w100,
                    ),
                  )
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
        const Spacer(flex: 4),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
              ),
              onPressed: () {},
              child: const Row(
                children: [
                  Iconify(
                    svg_icons.predictions,
                    color: Colors.white,
                  ),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 4.0)),
                  Text(
                    'Re-Predict',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
              ),
              onPressed: () {},
              child: const Row(
                children: [
                  Icon(
                    Icons.preview_outlined,
                    color: Colors.white,
                  ),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 4.0)),
                  Text(
                    'Preprocess Image',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
              ),
              onPressed: () {},
              child: const Row(
                children: [
                  Iconify(
                    svg_icons.imageFile,
                    color: Colors.white,
                  ),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 4.0)),
                  Text(
                    'Choose another Image',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
        const Spacer(flex: 10),
      ],
    );
  }
}
