import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EmptyNotesIllustration extends StatelessWidget {
  const EmptyNotesIllustration({super.key, this.size = 200});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SvgPicture.asset(
        'assets/empty_notes.svg',
        width: size,
        height: size,
      ),
    );
  }
}
