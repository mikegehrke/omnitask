import 'package:flutter/material.dart';

class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pricing'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'AI Provider Pricing',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pay only for what you use. No subscriptions required.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // OpenAI Card
          _PricingCard(
            provider: 'OpenAI',
            model: 'gpt-4o-mini',
            icon: Icons.psychology,
            color: Colors.green,
            inputPrice: '\$0.00015',
            outputPrice: '\$0.0006',
            perTokens: '1K tokens',
            features: [
              'Fast response time (~9 seconds)',
              'High quality results',
              'Best for complex tasks',
              'Reliable and accurate',
            ],
          ),
          const SizedBox(height: 16),

          // Claude Card
          _PricingCard(
            provider: 'Claude',
            model: 'claude-3-haiku',
            icon: Icons.smart_toy,
            color: Colors.purple,
            inputPrice: '\$0.00025',
            outputPrice: '\$0.00125',
            perTokens: '1K tokens',
            features: [
              'Excellent for analysis',
              'Strong reasoning',
              'Good value',
              'Fast processing',
            ],
          ),
          const SizedBox(height: 16),

          // Gemini Card  
          _PricingCard(
            provider: 'Gemini',
            model: 'gemini-1.5-flash',
            icon: Icons.auto_awesome,
            color: Colors.blue,
            inputPrice: '\$0.00010',
            outputPrice: '\$0.0004',
            perTokens: '1K tokens',
            features: [
              'Lowest cost option',
              'Fast performance',
              'Good for simple tasks',
              'High throughput',
            ],
          ),
          const SizedBox(height: 16),

          // Ollama Card
          _PricingCard(
            provider: 'Ollama',
            model: 'llama3.2',
            icon: Icons.computer,
            color: Colors.orange,
            inputPrice: '\$0.00',
            outputPrice: '\$0.00',
            perTokens: 'Free',
            features: [
              'Completely free',
              'Self-hosted',
              'Slower processing (~5 min)',
              'Privacy-focused',
            ],
          ),
          const SizedBox(height: 32),

          const Divider(),
          const SizedBox(height: 16),

          // Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'How it works',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('• Tasks are analyzed and estimated before execution'),
                  const Text('• You see the estimated cost upfront'),
                  const Text('• Only pay when task completes successfully'),
                  const Text('• Failed tasks are not charged'),
                  const Text('• Detailed usage tracking in your profile'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String provider;
  final String model;
  final IconData icon;
  final Color color;
  final String inputPrice;
  final String outputPrice;
  final String perTokens;
  final List<String> features;

  const _PricingCard({
    required this.provider,
    required this.model,
    required this.icon,
    required this.color,
    required this.inputPrice,
    required this.outputPrice,
    required this.perTokens,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      model,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Input', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      Text(inputPrice, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Output', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      Text(outputPrice, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'per $perTokens',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const Divider(height: 24),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.check, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
