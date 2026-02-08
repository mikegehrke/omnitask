import 'package:flutter/material.dart';

class OutputTypeScreen extends StatefulWidget {
  const OutputTypeScreen({super.key});

  @override
  State<OutputTypeScreen> createState() => _OutputTypeScreenState();
}

class _OutputTypeScreenState extends State<OutputTypeScreen> {
  String? _selectedType;

  final List<Map<String, dynamic>> _outputTypes = [
    {
      'id': 'text',
      'name': 'Text Response',
      'icon': Icons.text_fields,
      'color': Colors.blue,
      'description': 'Plain text answer or content',
      'examples': ['Answers', 'Summaries', 'Explanations'],
      'formats': ['Plain text', 'Markdown', 'HTML'],
    },
    {
      'id': 'pdf',
      'name': 'PDF Document',
      'icon': Icons.picture_as_pdf,
      'color': Colors.red,
      'description': 'Professional formatted PDF document',
      'examples': ['Reports', 'Presentations', 'Documents'],
      'formats': ['PDF with formatting', 'Page numbers', 'Headers/footers'],
    },
    {
      'id': 'code',
      'name': 'Source Code',
      'icon': Icons.code,
      'color': Colors.green,
      'description': 'Programming code and scripts',
      'examples': ['Python scripts', 'JavaScript', 'SQL queries'],
      'formats': ['Syntax highlighted', 'Commented', 'Ready to run'],
    },
    {
      'id': 'spreadsheet',
      'name': 'Spreadsheet',
      'icon': Icons.table_chart,
      'color': Colors.teal,
      'description': 'Excel or CSV data file',
      'examples': ['Data tables', 'Calculations', 'Charts'],
      'formats': ['XLSX', 'CSV', 'Google Sheets'],
    },
    {
      'id': 'image',
      'name': 'Image/Diagram',
      'icon': Icons.image,
      'color': Colors.purple,
      'description': 'Visual diagrams and charts',
      'examples': ['Flowcharts', 'Graphs', 'Illustrations'],
      'formats': ['PNG', 'SVG', 'JPEG'],
    },
    {
      'id': 'zip',
      'name': 'ZIP Archive',
      'icon': Icons.folder_zip,
      'color': Colors.orange,
      'description': 'Multiple files packaged together',
      'examples': ['Project files', 'Code packages', 'Document sets'],
      'formats': ['ZIP file', 'Multiple formats', 'Organized structure'],
    },
    {
      'id': 'json',
      'name': 'Structured Data',
      'icon': Icons.data_object,
      'color': Colors.indigo,
      'description': 'JSON or XML data format',
      'examples': ['API responses', 'Configuration', 'Data export'],
      'formats': ['JSON', 'XML', 'YAML'],
    },
    {
      'id': 'chat',
      'name': 'Interactive Chat',
      'icon': Icons.chat,
      'color': Colors.pink,
      'description': 'Back-and-forth conversation',
      'examples': ['Interviews', 'Q&A sessions', 'Consultations'],
      'formats': ['Real-time chat', 'Follow-up questions', 'Clarifications'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Output Type'),
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
                  'How would you like to receive your result?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose the format that best suits your needs',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Output Types List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _outputTypes.length,
              itemBuilder: (context, index) {
                final type = _outputTypes[index];
                final isSelected = _selectedType == type['id'];
                
                return _OutputTypeCard(
                  type: type,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedType = type['id'];
                    });
                  },
                );
              },
            ),
          ),

          // Continue Button
          if (_selectedType != null)
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
                      Navigator.pop(context, _selectedType);
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

class _OutputTypeCard extends StatelessWidget {
  final Map<String, dynamic> type;
  final bool isSelected;
  final VoidCallback onTap;

  const _OutputTypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? type['color'].withOpacity(0.05) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? type['color'] : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: type['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  type['icon'],
                  color: type['color'],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type['description'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: (type['examples'] as List<String>)
                          .take(2)
                          .map((example) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: type['color'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  example,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: type['color'],
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

              // Selected Indicator
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: type['color'],
                  size: 28,
                )
              else
                Icon(
                  Icons.radio_button_unchecked,
                  color: Colors.grey[400],
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
