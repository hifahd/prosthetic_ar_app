import 'package:flutter/material.dart';

class CustomizeProstheticScreen extends StatefulWidget {
  const CustomizeProstheticScreen({Key? key}) : super(key: key);

  @override
  _CustomizeProstheticScreenState createState() => _CustomizeProstheticScreenState();
}

class _CustomizeProstheticScreenState extends State<CustomizeProstheticScreen> {
  double _length = 50;
  double _width = 10;
  Color _color = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Prosthetic'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Length: ${_length.toStringAsFixed(1)} cm'),
            Slider(
              value: _length,
              min: 30,
              max: 70,
              divisions: 40,
              label: _length.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _length = value;
                });
              },
            ),
            const SizedBox(height: 20),
            Text('Width: ${_width.toStringAsFixed(1)} cm'),
            Slider(
              value: _width,
              min: 5,
              max: 15,
              divisions: 20,
              label: _width.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _width = value;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text('Color:'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ColorButton(Colors.grey, _color == Colors.grey, () => _setColor(Colors.grey)),
                ColorButton(Colors.brown, _color == Colors.brown, () => _setColor(Colors.brown)),
                ColorButton(Colors.pink, _color == Colors.pink, () => _setColor(Colors.pink)),
              ],
            ),
            const SizedBox(height: 40),
            Center(
              child: Container(
                width: _width * 10,
                height: _length * 2,
                color: _color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setColor(Color color) {
    setState(() {
      _color = color;
    });
  }
}

class ColorButton extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const ColorButton(this.color, this.isSelected, this.onTap, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }
}