import 'package:flutter/material.dart';

class DeadlinePickerScreen extends StatefulWidget {
  const DeadlinePickerScreen({super.key});

  @override
  State<DeadlinePickerScreen> createState() => _DeadlinePickerScreenState();
}

class _DeadlinePickerScreenState extends State<DeadlinePickerScreen> {
  String _selectedOption = 'flexible'; // asap, hours, custom, flexible
  DateTime? _customDate;
  TimeOfDay? _customTime;
  int _hours = 24;

  final List<Map<String, dynamic>> _quickOptions = [
    {
      'id': 'asap',
      'name': 'As Soon As Possible',
      'icon': Icons.flash_on,
      'color': Colors.red,
      'description': 'Get results in 5-15 minutes',
      'cost': '+50% urgency fee',
    },
    {
      'id': 'hours',
      'name': 'Within Hours',
      'icon': Icons.access_time,
      'color': Colors.orange,
      'description': 'Specify number of hours',
      'cost': '+25% urgency fee',
    },
    {
      'id': 'custom',
      'name': 'Specific Date & Time',
      'icon': Icons.event,
      'color': Colors.blue,
      'description': 'Choose exact deadline',
      'cost': 'Standard pricing',
    },
    {
      'id': 'flexible',
      'name': 'Flexible / No Rush',
      'icon': Icons.schedule,
      'color': Colors.green,
      'description': 'Within 24-48 hours, best price',
      'cost': '-10% discount',
    },
  ];

  Future<void> _pickCustomDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      
      if (time != null) {
        setState(() {
          _customDate = date;
          _customTime = time;
        });
      }
    }
  }

  String _getDeadlineText() {
    switch (_selectedOption) {
      case 'asap':
        return 'ASAP (5-15 min)';
      case 'hours':
        return 'Within $_hours hours';
      case 'custom':
        if (_customDate != null && _customTime != null) {
          return '${_customDate!.day}/${_customDate!.month}/${_customDate!.year} ${_customTime!.format(context)}';
        }
        return 'Select date & time';
      case 'flexible':
        return 'Flexible (24-48h)';
      default:
        return 'Not selected';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Deadline'),
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
                  'When do you need this done?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Urgent tasks cost more, flexible timing saves money',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Options List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._quickOptions.map((option) => _DeadlineOptionCard(
                      option: option,
                      isSelected: _selectedOption == option['id'],
                      onTap: () {
                        setState(() {
                          _selectedOption = option['id'];
                        });
                        if (option['id'] == 'custom') {
                          _pickCustomDate();
                        }
                      },
                    )),

                // Hours Slider (only show when 'hours' selected)
                if (_selectedOption == 'hours') ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Number of hours: $_hours',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Slider(
                            value: _hours.toDouble(),
                            min: 1,
                            max: 72,
                            divisions: 71,
                            label: '$_hours hours',
                            onChanged: (value) {
                              setState(() {
                                _hours = value.toInt();
                              });
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '1 hour',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '72 hours',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Custom Date Display (only show when 'custom' selected)
                if (_selectedOption == 'custom' && _customDate != null && _customTime != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.blue.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Icon(Icons.event, color: Colors.blue, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Selected Deadline',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getDeadlineText(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _pickCustomDate,
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Continue Button
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
                    Navigator.pop(context, {
                      'type': _selectedOption,
                      'hours': _hours,
                      'date': _customDate,
                      'time': _customTime,
                      'text': _getDeadlineText(),
                    });
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

class _DeadlineOptionCard extends StatelessWidget {
  final Map<String, dynamic> option;
  final bool isSelected;
  final VoidCallback onTap;

  const _DeadlineOptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? option['color'].withOpacity(0.05) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? option['color'] : Colors.transparent,
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
                  color: option['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  option['icon'],
                  color: option['color'],
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
                      option['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option['description'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: option['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        option['cost'],
                        style: TextStyle(
                          fontSize: 12,
                          color: option['color'],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Selected Indicator
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: option['color'],
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
