import 'dart:io';
import 'package:flutter/material.dart';

class GalleryScreen extends StatelessWidget {
  final List<String> imagePaths;

  const GalleryScreen({super.key, required this.imagePaths});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Captured Photos'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[900],
      body: imagePaths.isEmpty
          ? const Center(
              child: Text(
                'No photos taken yet.',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(4.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, 
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemCount: imagePaths.length,
              itemBuilder: (context, index) {
                final imagePath = imagePaths[imagePaths.length - 1 - index];
                return Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                     return const Icon(Icons.error, color: Colors.red);
                  },
                );
              },
            ),
    );
  }
}