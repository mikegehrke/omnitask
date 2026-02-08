import 'package:flutter/material.dart';

class TaskCategoryScreen extends StatefulWidget {
  const TaskCategoryScreen({super.key});

  @override
  State<TaskCategoryScreen> createState() => _TaskCategoryScreenState();
}

class _TaskCategoryScreenState extends State<TaskCategoryScreen> {
  String? _selectedCategory;

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'analysis',
      'name': 'Data Analysis',
      'icon': Icons.analytics,
      'color': Colors.blue,
      'description': 'Analyze data, create visualizations, find insights',
      'examples': ['Market research', 'Survey analysis', 'Trend detection'],
    },
    {
      'id': 'content',
      'name': 'Content Creation',
      'icon': Icons.create,
      'color': Colors.purple,
      'description': 'Write articles, create summaries, generate text',
      'examples': ['Blog posts', 'Product descriptions', 'Email drafts'],
    },
    {
      'id': 'code',
      'name': 'Code & Development',
      'icon': Icons.code,
      'color': Colors.green,
      'description': 'Write code, debug, create scripts',
      'examples': ['Python scripts', 'API integration', 'Bug fixes'],
    },
    {
      'id': 'research',
      'name': 'Research',
      'icon': Icons.search,
      'color': Colors.orange,
      'description': 'Find information, summarize papers, compare options',
      'examples': ['Literature review', 'Competitive analysis', 'Fact checking'],
    },
    {
      'id': 'translation',
      'name': 'Translation',
      'icon': Icons.translate,
      'color': Colors.teal,
      'description': 'Translate text between languages',
      'examples': ['Documents', 'Websites', 'Emails'],
    },
    {
      'id': 'planning',
      'name': 'Planning & Strategy',
      'icon': Icons.assignment,
      'color': Colors.indigo,
      'description': 'Create plans, strategies, roadmaps',
      'examples': ['Project plans', 'Marketing strategies', 'Roadmaps'],
    },
    {
      'id': 'automation',
      'name': 'Automation',
      'icon': Icons.autorenew,
      'color': Colors.red,
      'description': 'Automate repetitive tasks',
      'examples': ['Data entry', 'Report generation', 'File processing'],
    },
    {
      'id': 'other',
      'name': 'Other',
      'icon': Icons.more_horiz,
      'color': Colors.grey,
      'description': 'Everything else',
      'examples': ['Custom requests'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Category'),
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What type of task do you need help with?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a category to get personalized suggestions',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Categories Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['id'];
                
                return _CategoryCard(
                  category: category,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedCategory = category['id'];
                    });
                  },
                );
              },
            ),
          ),

          // Continue Button
          if (_selectedCategory != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context, _selectedCategory);
                    },
                    child: const Text('Continue'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? category['color'].withOpacity(0.1)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? category['color'] : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: category['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  category['icon'],
                  color: category['color'],
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),

              // Name
              Text(
                category['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Description
              Text(
                category['description'],
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Selected Indicator
              if (isSelected) ...[
                const SizedBox(height: 8),
                Icon(
                  Icons.check_circle,
                  color: category['color'],
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
