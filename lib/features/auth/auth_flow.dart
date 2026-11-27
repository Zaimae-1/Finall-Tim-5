import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/motion.dart';
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
          _WelcomeButton(
            label: 'Mulai belajar',
            icon: Icons.explore_rounded,
            primary: true,
            onPressed: () => _openForm(_AuthMode.register),
          ),
          const SizedBox(height: 12),
          _WelcomeButton(
            label: 'Aku sudah punya akun',
            icon: Icons.login_rounded,
            primary: false,
            onPressed: () => _openForm(_AuthMode.signIn),
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
              : 'Target ini dipakai untuk misi harianmu.',
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

class _WelcomeButton extends StatefulWidget {
  const _WelcomeButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onPressed;

  @override
  State<_WelcomeButton> createState() => _WelcomeButtonState();
}

class _WelcomeButtonState extends State<_WelcomeButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => setState(() => _pressed = true),
    onPointerUp: (_) => setState(() => _pressed = false),
    onPointerCancel: (_) => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? .97 : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: widget.primary
              ? const LinearGradient(
                  colors: [Color(0xFF0564A4), Color(0xFF0AA5CA)],
                )
              : null,
          color: widget.primary ? null : Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: widget.primary
                ? const Color(0xFF66D8EF)
                : const Color(0xFF8FC6DD),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26083D68),
              blurRadius: 16,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: widget.primary
            ? FilledButton.icon(
                onPressed: widget.onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(19),
                  ),
                ),
                icon: Icon(widget.icon),
                label: Text(widget.label),
              )
            : OutlinedButton.icon(
                onPressed: widget.onPressed,
                style: OutlinedButton.styleFrom(
                  side: BorderSide.none,
                  foregroundColor: _ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(19),
                  ),
                ),
                icon: Icon(widget.icon),
                label: Text(widget.label),
              ),
      ),
    ),
  );
}

class _SetupProgress extends StatelessWidget {
  const _SetupProgress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.route_rounded, size: 16, color: _blue),
            const SizedBox(width: 6),
            Text(
              'LANGKAH ${step + 1} DARI 3',
              style: const TextStyle(
                color: _ink,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Semantics(
          label: 'Langkah ${step + 1} dari 3',
          child: Container(
            height: 11,
            decoration: BoxDecoration(
              color: const Color(0xFFD1E8F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: (step + 1) / 3),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF075DAB), Color(0xFF2CC6D8)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
    padding: const EdgeInsets.only(bottom: 10),
    child: Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: selected
                ? const [Color(0xFFDDF5FF), Color(0xFFF3FBFF)]
                : const [Colors.white, Color(0xFFF1F9FD)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF087DB6) : const Color(0xFFA9C9DA),
            width: selected ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? const Color(0x2B0689BD)
                  : const Color(0x14084368),
              blurRadius: selected ? 16 : 9,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFB8E9F8)
                          : const Color(0xFFE1F2F8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: _blue),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_ios_rounded,
                    color: selected ? _blue : const Color(0xFF83A8BB),
                    size: selected ? 25 : 17,
                  ),
                ],
              ),
            ),
          ),
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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAF9FF), Color(0xFFCBECF7), Color(0xFFF5FCFF)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 840;
              final inset = wide ? 40.0 : 20.0;
              return SingleChildScrollView(
                key: viewKey,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                                child: _OceanPanel(
                                  height: 440,
                                  message: message,
                                ),
                              ),
                              const SizedBox(width: 58),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 380,
                                    ),
                                    child: MotionReveal(child: content),
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
                          MotionReveal(child: content),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
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

class _OceanPanel extends StatefulWidget {
  const _OceanPanel({required this.height, this.message});

  final double height;
  final String? message;

  @override
  State<_OceanPanel> createState() => _OceanPanelState();
}

class _OceanPanelState extends State<_OceanPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _tide.stop();
      _tide.value = 0;
    } else if (!_tide.isAnimating) {
      _tide.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _tide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _tide,
          builder: (context, _) => Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF074266),
                      Color(0xFF098CB7),
                      Color(0xFF8ADCF0),
                    ],
                  ),
                ),
              ),
              CustomPaint(painter: _OceanWaves(_tide.value)),
              Positioned(
                top: -widget.height * .24,
                right: -widget.height * .10,
                child: Transform.translate(
                  offset: Offset(0, -_tide.value * 6),
                  child: _Bubble(size: widget.height * .70),
                ),
              ),
              Positioned(
                bottom: -widget.height * .35,
                left: -widget.height * .10,
                child: _Bubble(size: widget.height * .76),
              ),
              Positioned(
                top: widget.height * .22,
                left: widget.height * .20,
                child: Transform.translate(
                  offset: Offset(0, -_tide.value * 10),
                  child: _Bubble(size: widget.height * .075),
                ),
              ),
              Positioned(
                bottom: widget.height * .17,
                right: widget.height * .14,
                child: Transform.translate(
                  offset: Offset(0, -_tide.value * 15),
                  child: _Bubble(size: widget.height * .12),
                ),
              ),
              if (widget.message case final speech?)
                Center(
                  child: Flex(
                    direction: widget.height < 200
                        ? Axis.horizontal
                        : Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SharkMascot(
                        size: widget.height < 200
                            ? widget.height * .75
                            : widget.height * .69,
                        mood: SharkMood.greet,
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
                Center(
                  child: SharkMascot(
                    size: widget.height * .85,
                    mood: SharkMood.greet,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OceanWaves extends CustomPainter {
  const _OceanWaves(this.phase);
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    for (var layer = 0; layer < 3; layer++) {
      final base = size.height * (.62 + layer * .10);
      final path = Path()..moveTo(0, base);
      for (var x = 0.0; x <= size.width + 8; x += 8) {
        final wave =
            math.sin(x / (36 + layer * 13) + phase * math.pi * 2 + layer) *
            (8 + layer * 3);
        path.lineTo(x, base + wave);
      }
      path
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = [
            const Color(0x236BDBEE),
            const Color(0x3297EEFB),
            const Color(0x4AB9F3F7),
          ][layer],
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OceanWaves oldDelegate) =>
      oldDelegate.phase != phase;
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
