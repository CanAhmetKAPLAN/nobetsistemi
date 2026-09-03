import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final token = context.read<AuthProvider>().token!;
      await context.read<GroupProvider>().createGroup(
            token,
            _nameCtrl.text.trim(),
            _codeCtrl.text.trim(),
          );
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false);
      }
    } catch (e) {
      if (mounted) {
        final message = e is ApiException ? e.message : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Grup Oluştur')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(Icons.groups, size: 56, color: AppTheme.primary),
                        const SizedBox(height: 12),
                        Text(
                          'Yeni Nöbet Grubu',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Grup Adı',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Grup adı girin' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _codeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Katılım Kodu',
                            prefixIcon: Icon(Icons.vpn_key_outlined),
                            helperText: 'Diğer kişiler bu kodla gruba katılabilir',
                          ),
                          validator: (v) => v == null || v.trim().length < 4
                              ? 'En az 4 karakter girin'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        _loading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: _submit,
                                child: const Text('Grubu Oluştur', style: TextStyle(fontSize: 16)),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
