import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wordProvider = Provider.of<WordProvider>(context);
    final total = wordProvider.totalWords;
    final favorites = wordProvider.favoriteCount;
    return Scaffold(
      appBar: AppBar(title: const Text('İstatistikler')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kullanıcı İstatistikleri', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            _buildChart(total, favorites),
            const SizedBox(height: 32),
            Text('Toplam Terim: $total', style: Theme.of(context).textTheme.bodyLarge),
            Text('Favori Terim: $favorites', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(int total, int favorites) {
    final double favRatio = total == 0 ? 0 : favorites / total;
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: double.infinity,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: favRatio * 300,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Favori oranı: %${(favRatio * 100).toStringAsFixed(1)}'),
      ],
    );
  }
}
