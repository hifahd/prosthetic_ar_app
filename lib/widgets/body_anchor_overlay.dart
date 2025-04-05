import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BodyAnchorOverlay extends StatefulWidget {
  final String limbType; // Type of limb: "arm", "leg"
  final Function(Offset)
      onAnchorSelected; // Callback when user selects anchor point

  const BodyAnchorOverlay({
    Key? key,
    required this.limbType,
    required this.onAnchorSelected,
  }) : super(key: key);

  @override
  _BodyAnchorOverlayState createState() => _BodyAnchorOverlayState();
}

class _BodyAnchorOverlayState extends State<BodyAnchorOverlay>
    with SingleTickerProviderStateMixin {
  Offset? _selectedPosition;
  bool _showGuide = true;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Transparent GestureDetector to capture taps
        Positioned.fill(
          child: GestureDetector(
            onTapUp: (details) {
              setState(() {
                _selectedPosition = details.localPosition;
                _showGuide = false;
              });
              widget.onAnchorSelected(details.localPosition);
            },
          ),
        ),

        // Guide overlay when no position selected
        if (_showGuide)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: Colors.white,
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text(
                      widget.limbType.contains("arm")
                          ? "Tap where you want to attach the prosthetic arm"
                          : "Tap where you want to attach the prosthetic leg",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        "The prosthetic will be positioned at this point",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Selected position indicator
        if (_selectedPosition != null && !_showGuide)
          Positioned(
            left: _selectedPosition!.dx - 25,
            top: _selectedPosition!.dy - 25,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          AppTheme.primaryColor.withOpacity(_animation.value),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
