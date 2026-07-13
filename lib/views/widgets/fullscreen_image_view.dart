import 'package:flutter/material.dart';

/// Bir görseli (fiş/fatura vb.) tam ekranda, yakınlaştırılabilir şekilde
/// gösteren basit görüntüleyici. `Navigator.push` ile açılır.
class FullscreenImageView extends StatelessWidget {
  final String imageUrl;
  final String? heroTag;

  const FullscreenImageView({super.key, required this.imageUrl, this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Hero(
            tag: heroTag ?? imageUrl,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) => const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('Görsel yüklenemedi', style: TextStyle(color: Colors.white70)),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              },
            ),
          ),
        ),
      ),
    );
  }
}
