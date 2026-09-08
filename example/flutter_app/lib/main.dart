import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shevchenko/shevchenko.dart' as s;

import 'declension_demo.dart';
import 'smoke.dart';
import 'smoke_platform.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const platformSmoke = bool.fromEnvironment('SMOKE_TEST');
  final browserSmoke = Uri.base.queryParameters['smoke'] == 'true';
  if (platformSmoke || browserSmoke) {
    final smokeResult = await runExample();
    if (platformSmoke) finishSmoke(smokeResult);
  }
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Українське відмінювання',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1659A7),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
      ),
    ),
    home: const DeclensionPage(),
  );
}

class DeclensionPage extends StatefulWidget {
  const DeclensionPage({super.key});

  @override
  State<DeclensionPage> createState() => _DeclensionPageState();
}

class _DeclensionPageState extends State<DeclensionPage> {
  final _rankController = TextEditingController(text: 'солдат');
  final _nameController = TextEditingController(
    text: 'Тарас Григорович Шевченко',
  );
  final _appointmentController = TextEditingController(
    text: 'помічник гранатометника',
  );
  Map<String, String>? _results;
  String? _error;
  bool _isLoading = false;
  s.GrammaticalGender _gender = s.GrammaticalGender.masculine;

  @override
  void dispose() {
    _rankController.dispose();
    _nameController.dispose();
    _appointmentController.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _error = null;
    });
    Map<String, String>? results;
    String? message;
    try {
      results = await declineAllCases(
        rank: _rankController.text,
        fullName: _nameController.text,
        appointment: _appointmentController.text,
        gender: _gender,
      );
    } on FormatException catch (error) {
      message = error.message.toString();
    } catch (_) {
      message = 'Не вдалося виконати відмінювання.';
    }
    if (!mounted) return;
    setState(() {
      _results = results;
      _error = message;
      _isLoading = false;
    });
  }

  Future<void> _copyResults() async {
    final results = _results;
    if (results == null) return;
    final text = results.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Результати скопійовано')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(colors: colors),
                  const SizedBox(height: 28),
                  Card(
                    elevation: 0,
                    color: colors.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Стать',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<s.GrammaticalGender>(
                            key: const Key('genderSelector'),
                            segments: const [
                              ButtonSegment(
                                value: s.GrammaticalGender.masculine,
                                label: Text('М'),
                                tooltip: 'Чоловіча стать',
                              ),
                              ButtonSegment(
                                value: s.GrammaticalGender.feminine,
                                label: Text('Ж'),
                                tooltip: 'Жіноча стать',
                              ),
                            ],
                            selected: {_gender},
                            showSelectedIcon: false,
                            expandedInsets: EdgeInsets.zero,
                            onSelectionChanged: _isLoading
                                ? null
                                : (selection) {
                                    setState(() {
                                      _gender = selection.single;
                                      _results = null;
                                      _error = null;
                                    });
                                  },
                          ),
                          const SizedBox(height: 20),
                          _InputField(
                            key: const Key('rankText'),
                            controller: _rankController,
                            label: 'Звання',
                            hint: 'солдат',
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 16),
                          _InputField(
                            key: const Key('fullNameText'),
                            controller: _nameController,
                            label: 'ПІБ',
                            hint: 'Тарас Григорович Шевченко',
                            enabled: !_isLoading,
                            autofillHints: const [AutofillHints.name],
                          ),
                          const SizedBox(height: 16),
                          _InputField(
                            key: const Key('appointmentText'),
                            controller: _appointmentController,
                            label: 'Посада',
                            hint: 'помічник гранатометника',
                            enabled: !_isLoading,
                            onSubmitted: (_) => _isLoading ? null : _run(),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              _error!,
                              key: const Key('errorMessage'),
                              style: TextStyle(color: colors.error),
                            ),
                          ],
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            key: const Key('testButton'),
                            onPressed: _isLoading ? null : _run,
                            icon: _isLoading
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.play_arrow_rounded),
                            label: Text(_isLoading ? 'Відмінювання…' : 'Тест'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_results != null) ...[
                    const SizedBox(height: 24),
                    _ResultsCard(results: _results!, onCopy: _copyResults),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.enabled,
    this.autofillHints,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    enabled: enabled,
    textCapitalization: TextCapitalization.words,
    textInputAction: onSubmitted == null
        ? TextInputAction.next
        : TextInputAction.done,
    autofillHints: autofillHints,
    decoration: InputDecoration(labelText: label, hintText: hint),
    onSubmitted: onSubmitted,
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(Icons.translate_rounded, color: colors.primary, size: 30),
        ),
      ),
      const SizedBox(width: 16),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Українське відмінювання',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              'Заповніть потрібні поля й отримайте всі відмінки.',
              style: TextStyle(fontSize: 16, height: 1.4),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({required this.results, required this.onCopy});

  final Map<String, String> results;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('Результат', style: theme.textTheme.titleLarge),
                ),
                IconButton(
                  key: const Key('copyResults'),
                  tooltip: 'Копіювати всі результати',
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_all_outlined),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SelectionArea(
            child: Column(
              children: [
                for (final entry in results.entries)
                  _ResultRow(
                    label: entry.key,
                    value: entry.value,
                    showDivider: entry.key != results.keys.last,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    required this.showDivider,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 112,
              child: Text(
                label,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                key: ValueKey('result:$label'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      if (showDivider) const Divider(height: 1, indent: 20, endIndent: 20),
    ],
  );
}
