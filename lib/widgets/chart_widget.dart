import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  final String stepNumber;
  final String label;
  final bool isActive;

  const StepIndicator({
    Key? key,
    required this.stepNumber,
    required this.label,
    required this.isActive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color activeColor = const Color(0xFFF06500);
    final Color inactiveColor = const Color(0xFF3F3F46);
    final Color activeTextColor = Colors.white;
    final Color inactiveTextColor = const Color(0xFFA1A1AA);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: isActive ? activeColor : inactiveColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  stepNumber,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: activeTextColor,
                    fontFamily: 'TT Commons',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? activeTextColor : inactiveTextColor,
                fontFamily: 'TT Commons',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: 164,
          height: 4,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
