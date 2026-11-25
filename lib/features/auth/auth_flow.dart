import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/shark_mascot.dart';
import '../learn/learning_home.dart';
import 'local_profiles.dart';

const _ink = Color(0xFF12334C);
const _muted = Color(0xFF46647A);
const _blue = Color(0xFF075DAB);
const _paper = Color(0xFFF7FBFF);
const _line = Color(0xFF9EB8CD);

ThemeData lingoSharkTheme() {
  final colors = ColorScheme.fromSeed(seedColor: _blue).copyWith(
    primary: _blue,
    onPrimary: Colors.white,
    surface: _paper,
    onSurface: _ink,
  );
  return ThemeData(
    colorScheme: colors,
    scaffoldBackgroundColor: _paper,
    useMaterial3: true,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        side: const BorderSide(color: _line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _line),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    ),
  );
}

enum _AuthMode { signIn, register }

class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key});

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  late final _profiles = LocalProfiles();
  LearnerProfile? _profile;

  Future<void> _openForm(_AuthMode mode) async {
    final profile = await Navigator.of(context).push<LearnerProfile>(
      MaterialPageRoute(
        builder: (context) => _AuthPage(profiles: _profiles, initialMode: mode),
      ),
    );
    if (!mounted || profile == null) return;
    setState(() => _profile = profile);
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (profile != null) {
      return LearningHome(
        key: ValueKey(profile.email),
        profile: profile,
        onSignOut: () => setState(() => _profile = null),
      );
    }
    return _PageLayout(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PageIntro(
            title: 'Belajar Inggris bareng hiu!',
            description:
                'Selami bahasa Inggris lewat latihan singkat setiap hari.',
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => _openForm(_AuthMode.register),
            child: const Text('Mulai belajar'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _openForm(_AuthMode.signIn),
            child: const Text('Aku sudah punya akun'),
          ),
        ],
      ),
    );
  }
}

class _AuthPage extends StatefulWidget {
  const _AuthPage({required this.profiles, required this.initialMode});

  final LocalProfiles profiles;
  final _AuthMode initialMode;

  @override
  State<_AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<_AuthPage> {
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late _AuthMode _mode = widget.initialMode;
  int _step = 0;
  String? _level;
  int? _goal;
  bool _obscured = true;
  bool _busy = false;
  String? _error;

  bool get _registering => _mode == _AuthMode.register;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _switchMode() {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    final email = _email.text;
    _form.currentState?.reset();
    _name.clear();
    _password.clear();
    _email.text = email;
    setState(() {
      _mode = _registering ? _AuthMode.signIn : _AuthMode.register;
      _step = 0;
      _obscured = true;
      _error = null;
    });
  }

  void _goBack() {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (_registering && _step > 0) {
      setState(() {
        _step--;
        _password.clear();
        _obscured = true;
        _error = null;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final profile = _registering
          ? await widget.profiles.register(
              name: _name.text,
              email: _email.text,
              password: _password.text,
              level: _level!,
              dailyGoal: _goal!,
            )
          : await widget.profiles.signIn(
              email: _email.text,
              password: _password.text,
            );
      if (!mounted) return;
      if (profile != null) {
        TextInput.finishAutofillContext(shouldSave: false);
        Navigator.of(context).pop(profile);
        return;
      }
      setState(() {
        _error = _registering
            ? 'Email ini sudah dipakai di perangkat ini.'
            : 'Email atau kata sandi salah.';
        _busy = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _error = 'Penyimpanan lokal tidak tersedia. Coba lagi.';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = _registering ? 'Buat akun' : 'Masuk';
    return PopScope(
      canPop: !_busy && (!_registering || _step == 0),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _registering && _step > 0) _goBack();
      },
      child: _PageLayout(
        onBack: _busy ? null : _goBack,
        showBack: true,
        compact: true,
        viewKey: ValueKey((_mode, _step)),
        message: !_registering
            ? 'Selamat datang kembali!'
            : switch (_step) {
                0 => 'Hai! Aku teman belajarmu.',
                1 => 'Sedikit setiap hari, yuk!',
                _ => 'Siap menyelam?',
              },
        content: _registering && _step < 2
            ? _setupStep()
            : AutofillGroup(
                onDisposeAction: AutofillContextAction.cancel,
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_registering) _SetupProgress(step: _step),
                      _PageIntro(
                        title: _registering ? 'Simpan profilmu' : 'Masuk lagi',
                        description: _registering
                            ? 'Buat profil demo di perangkat ini.'
                            : 'Gunakan profil demo yang kamu buat di perangkat ini.',
                      ),
                      const SizedBox(height: 24),
                      if (_registering) ...[
                        TextFormField(
                          key: const ValueKey('auth-name'),
                          controller: _name,
                          enabled: !_busy,
                          autofillHints: const [AutofillHints.name],
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(60),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Nama panggilan',
                          ),
                          validator: (value) => value!.trim().isEmpty
                              ? 'Masukkan nama panggilan.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        key: const ValueKey('auth-email'),
                        controller: _email,
                        enabled: !_busy,
                        autofillHints: const [AutofillHints.email],
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(254),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Email demo',
                          hintText: 'nama@example.com',
                        ),
                        validator: (value) =>
                            _emailPattern.hasMatch(value!.trim())
                            ? null
                            : 'Masukkan email yang valid.',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const ValueKey('auth-password'),
                        controller: _password,
                        enabled: !_busy,
                        obscureText: _obscured,
                        autofillHints: [
                          _registering
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        autocorrect: false,
                        enableSuggestions: false,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(128),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Kata sandi demo',
                          helperText: _registering
                              ? 'Minimal 8 karakter.'
                              : null,
                          suffixIcon: IconButton(
                            tooltip: _obscured
                                ? 'Tampilkan kata sandi'
                                : 'Sembunyikan kata sandi',
                            onPressed: _busy
                                ? null
                                : () => setState(() => _obscured = !_obscured),
                            icon: Icon(
                              _obscured
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value!.trim().isEmpty) {
                            return 'Masukkan kata sandi.';
                          }
                          if (_registering && value.length < 8) {
                            return 'Gunakan minimal 8 karakter.';
                          }
                          return null;
                        },
                      ),
                      if (_error case final error?) ...[
                        const SizedBox(height: 12),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            error,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: Text(_busy ? 'Memproses…' : action),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _busy ? null : _switchMode,
                        child: Text(
                          _registering
                              ? 'Sudah punya akun? Masuk'
                              : 'Belum punya akun? Mulai belajar',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _setupStep() {
    final levelStep = _step == 0;
    final ready = levelStep ? _level != null : _goal != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SetupProgress(step: _step),
        _PageIntro(
          title: levelStep
              ? 'Seberapa kenal bahasa Inggris?'
              : 'Pilih target harianmu',
          description: levelStep
              ? 'Kursus Bahasa Inggris · Unit 1'
              : 'Target ini dipakai untuk quest harian dan bisa diubah dari Profil.',
        ),
        const SizedBox(height: 18),
        if (levelStep)
          for (final option in ['Pemula', 'Sudah tahu sedikit'])
            _SetupChoice(
              label: option,
              icon: option == 'Pemula'
                  ? Icons.waving_hand_outlined
                  : Icons.chat_bubble_outline_rounded,
              selected: _level == option,
              onTap: () => setState(() => _level = option),
            )
        else
          for (final count in [1, 2, 3])
            _SetupChoice(
              label: '$count lesson per hari',
              icon: Icons.flag_outlined,
              selected: _goal == count,
              onTap: () => setState(() => _goal = count),
            ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: ready ? () => setState(() => _step++) : null,
          child: const Text('Lanjut'),
        ),
        if (levelStep)
          TextButton(
            onPressed: _switchMode,
            child: const Text('Sudah punya akun? Masuk'),
          ),
      ],
    );
  }
}

class _SetupProgress extends StatelessWidget {
  const _SetupProgress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: LinearProgressIndicator(
      value: (step + 1) / 3,
      minHeight: 8,
      borderRadius: BorderRadius.circular(8),
      semanticsLabel: 'Langkah ${step + 1} dari 3',
    ),
  );
}

class _SetupChoice extends StatelessWidget {
  const _SetupChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      selected: selected,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(selected ? Icons.check_circle_rounded : icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          backgroundColor: selected ? const Color(0xFFDDEFFE) : Colors.white,
          side: BorderSide(color: selected ? _blue : _line),
        ),
      ),
    ),
  );
}

class _PageLayout extends StatelessWidget {
  const _PageLayout({
    required this.content,
    this.onBack,
    this.showBack = false,
    this.compact = false,
    this.message,
    this.viewKey,
  });

  final Widget content;
  final VoidCallback? onBack;
  final bool showBack;
  final bool compact;
  final String? message;
  final Key? viewKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 840;
            final inset = wide ? 40.0 : 20.0;
            return SingleChildScrollView(
              key: viewKey,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(inset, 12, inset, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 1000 : 470),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (showBack) ...[
                            IconButton(
                              tooltip: 'Kembali',
                              onPressed: onBack,
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            const SizedBox(width: 4),
                          ],
                          const Icon(
                            Icons.waves_rounded,
                            color: _blue,
                            size: 27,
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'LingoShark',
                              style: TextStyle(
                                color: _ink,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: wide ? 36 : 20),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _OceanPanel(height: 440, message: message),
                            ),
                            const SizedBox(width: 58),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 380,
                                  ),
                                  child: content,
                                ),
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _OceanPanel(
                          height: compact ? 144 : 262,
                          message: message,
                        ),
                        SizedBox(height: compact ? 22 : 28),
                        content,
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PageIntro extends StatelessWidget {
  const _PageIntro({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 36,
              height: 1.08,
              color: _ink,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.4,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: const TextStyle(fontSize: 15, height: 1.45, color: _muted),
        ),
      ],
    );
  }
}

class _OceanPanel extends StatelessWidget {
  const _OceanPanel({required this.height, this.message});

  final double height;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFFE3F7FF), Color(0xFF9FDDF6)],
                ),
              ),
            ),
            Positioned(
              top: -height * .24,
              right: -height * .10,
              child: _Bubble(size: height * .70),
            ),
            Positioned(
              bottom: -height * .35,
              left: -height * .10,
              child: _Bubble(size: height * .76),
            ),
            Positioned(
              top: height * .22,
              left: height * .20,
              child: _Bubble(size: height * .075),
            ),
            Positioned(
              bottom: height * .17,
              right: height * .14,
              child: _Bubble(size: height * .12),
            ),
            if (message case final speech?)
              Center(
                child: Flex(
                  direction: height < 200 ? Axis.horizontal : Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SharkMascot(
                      size: height < 200 ? height * .75 : height * .69,
                    ),
                    const SizedBox(width: 6, height: 6),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            child: Text(
                              speech,
                              style: const TextStyle(
                                color: _ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Center(child: SharkMascot(size: height * .85)),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0x24FFFFFF),
        border: Border.all(color: const Color(0x80FFFFFF), width: 2),
      ),
    );
  }
}
