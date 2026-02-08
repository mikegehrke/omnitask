import 'package:flutter/material.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _agreedToTerms = false;
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;

  void _deleteAccount() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please confirm you understand the consequences')),
      );
      return;
    }

    if (_confirmController.text != 'DELETE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please type DELETE to confirm')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Account deleted - navigate to login
      Navigator.of(context).pushNamedAndRemoveUntil('/auth/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Account'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Warning Icon
          const Center(
            child: Icon(
              Icons.warning,
              size: 80,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Delete Account',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This action cannot be undone',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),

          // Consequences
          Card(
            color: Colors.red.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What will be deleted:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ConsequenceItem(
                    icon: Icons.person,
                    text: 'Your account and profile',
                  ),
                  _ConsequenceItem(
                    icon: Icons.task,
                    text: 'All your tasks and their results',
                  ),
                  _ConsequenceItem(
                    icon: Icons.folder,
                    text: 'All uploaded files and documents',
                  ),
                  _ConsequenceItem(
                    icon: Icons.chat,
                    text: 'All chat messages and conversations',
                  ),
                  _ConsequenceItem(
                    icon: Icons.payment,
                    text: 'Payment history and invoices',
                  ),
                  _ConsequenceItem(
                    icon: Icons.key,
                    text: 'API keys and integrations',
                  ),
                  _ConsequenceItem(
                    icon: Icons.settings,
                    text: 'All settings and preferences',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // What happens next
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 12),
                      Text(
                        'What happens next',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoItem(text: '1. Your account will be permanently deleted'),
                  _InfoItem(text: '2. All data will be removed within 30 days'),
                  _InfoItem(text: '3. Active subscriptions will be cancelled'),
                  _InfoItem(text: '4. You will be logged out immediately'),
                  _InfoItem(text: '5. You can create a new account with the same email later'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Confirmation Checkbox
          CheckboxListTile(
            value: _agreedToTerms,
            onChanged: (value) {
              setState(() {
                _agreedToTerms = value ?? false;
              });
            },
            title: const Text(
              'I understand that this action cannot be undone and all my data will be permanently deleted',
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),

          // Confirmation Input
          TextField(
            controller: _confirmController,
            decoration: InputDecoration(
              labelText: 'Type DELETE to confirm',
              hintText: 'DELETE',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabled: _agreedToTerms,
            ),
          ),
          const SizedBox(height: 24),

          // Delete Button
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _isLoading || !_agreedToTerms || _confirmController.text != 'DELETE'
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Final Confirmation'),
                          content: const Text(
                            'Are you absolutely sure you want to delete your account? This action cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteAccount();
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Delete My Account'),
                            ),
                          ],
                        ),
                      );
                    },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Delete My Account Permanently'),
            ),
          ),
          const SizedBox(height: 16),

          // Cancel Button
          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel, Keep My Account'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }
}

class _ConsequenceItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ConsequenceItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String text;

  const _InfoItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
