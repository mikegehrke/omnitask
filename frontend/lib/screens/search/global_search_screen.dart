import 'package:flutter/material.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all'; // all, tasks, files, messages

  final List<Map<String, dynamic>> _allResults = [
    {
      'type': 'task',
      'id': 123,
      'title': 'Analyze market trends for Q4 2024',
      'subtitle': 'Completed • \$0.45',
      'icon': Icons.task_alt,
      'color': Colors.green,
    },
    {
      'type': 'file',
      'id': 1,
      'title': 'Market Analysis Report.pdf',
      'subtitle': '2.3 MB • 2 hours ago',
      'icon': Icons.picture_as_pdf,
      'color': Colors.red,
    },
    {
      'type': 'message',
      'id': 456,
      'title': 'Market analysis complete',
      'subtitle': 'Task #123 • 2 hours ago',
      'icon': Icons.chat,
      'color': Colors.blue,
    },
    {
      'type': 'task',
      'id': 124,
      'title': 'Create Python script for data processing',
      'subtitle': 'Processing • \$0.89',
      'icon': Icons.autorenew,
      'color': Colors.orange,
    },
  ];

  List<Map<String, dynamic>> get _filteredResults {
    var results = _allResults;
    
    if (_searchQuery.isNotEmpty) {
      results = results.where((item) {
        final title = item['title'].toString().toLowerCase();
        final subtitle = item['subtitle'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || subtitle.contains(query);
      }).toList();
    }
    
    if (_filterType != 'all') {
      results = results.where((item) => item['type'] == _filterType).toList();
    }
    
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search tasks, files, messages...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip(
                  label: 'All',
                  count: _allResults.length,
                  isSelected: _filterType == 'all',
                  onTap: () => setState(() => _filterType = 'all'),
                ),
                _FilterChip(
                  label: 'Tasks',
                  count: _allResults.where((r) => r['type'] == 'task').length,
                  isSelected: _filterType == 'task',
                  color: Colors.green,
                  onTap: () => setState(() => _filterType = 'task'),
                ),
                _FilterChip(
                  label: 'Files',
                  count: _allResults.where((r) => r['type'] == 'file').length,
                  isSelected: _filterType == 'file',
                  color: Colors.red,
                  onTap: () => setState(() => _filterType = 'file'),
                ),
                _FilterChip(
                  label: 'Messages',
                  count: _allResults.where((r) => r['type'] == 'message').length,
                  isSelected: _filterType == 'message',
                  color: Colors.blue,
                  onTap: () => setState(() => _filterType = 'message'),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _searchQuery.isEmpty
                ? _buildEmptyState()
                : _filteredResults.isEmpty
                    ? _buildNoResults()
                    : _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Search for anything',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Tasks, files, messages, and more',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No results found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for something else',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredResults.length,
      itemBuilder: (context, index) {
        final result = _filteredResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: result['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                result['icon'],
                color: result['color'],
                size: 24,
              ),
            ),
            title: Text(
              result['title'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(result['subtitle']),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to result
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).primaryColor;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: chipColor.withOpacity(0.1),
        selectedColor: chipColor.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? chipColor : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
