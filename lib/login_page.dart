import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginPage extends StatefulWidget {
  final String? banMessage;
  const LoginPage({super.key, this.banMessage});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Offset _mousePosition = Offset.zero;
  
  final List<String> _tags = [
    'flutter', 'data', 'gamedev', 'art', 'music', 'kazakhstan',
    'barbecue', 'warhammer', 'python', 'Syncory', 'design', 'cinema'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.banMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.banMessage!),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      });
    }
  }
  
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> signUp() async {
    setState(() { _isLoading = true; });
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (userCredential.user != null) {
        await userCredential.user!.sendEmailVerification();
        _showSuccess("Письмо для подтверждения отправлено на ${userCredential.user!.email}.");
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Ошибка регистрации");
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> signIn() async {
    setState(() { _isLoading = true; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Error");
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError("Сначала введите Email в поле выше");
      return;
    }
    setState(() { _isLoading = true; });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        _showSuccess("Ссылка для сброса пароля отправлена на $email");
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Ошибка сброса пароля");
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _isLoading = true; });
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'openid'],
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() { _isLoading = false; });
        return; 
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Error");
    } catch (e) {
      _showError("Произошла ошибка: $e");
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: MouseRegion(
        onHover: (event) {
          setState(() {
            _mousePosition = event.position;
          });
        },
        child: Stack(
          children: [
            // --- Интерактивный Фон ---
            Positioned.fill(
              child: Container(
                color: theme.colorScheme.surfaceContainerLowest,
                child: Stack(
                  children: _tags.map((tag) {
                    return _AnimatedChip(
                      key: ValueKey(tag),
                      text: tag,
                      mousePosition: _mousePosition,
                      screenSize: size,
                    );
                  }).toList(),
                ),
              ),
            ),

            // --- Форма Входа (Парит по центру) ---
            Center(
              child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Card(
                color: theme.colorScheme.surface.withOpacity(0.85),
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: _isLoading
                  ? Padding(
                      padding: EdgeInsets.all(100),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : SingleChildScrollView(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Syncory',
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 24),
                        
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                          ),
                          obscureText: true,
                        ),
                        SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _resetPassword,
                            child: Text('Forgot?'),
                          ),
                        ),
                        SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: signIn, 
                            child: Text('Sign-In'),
                            style: FilledButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
                          ),
                        ),
                        SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: signUp,
                            child: Text('Registration'),
                            style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text('OR')
                              ),
                              Expanded(child: Divider())
                            ]
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _signInWithGoogle,
                            icon: Image.asset('assets/images/google_logo.png', height: 20, width: 20),
                            label: Text('Google'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ),
            ),
          ),
        ],
      ),
    ));
  }
}


// --- "АНИМИРОВАННЫЙ ЧИП" ---
class _AnimatedChip extends StatefulWidget {
  final String text;
  final Offset mousePosition;
  final Size screenSize;

  const _AnimatedChip({
    super.key,
    required this.text,
    required this.mousePosition,
    required this.screenSize,
  });

  @override
  State<_AnimatedChip> createState() => _AnimatedChipState();
}

class _AnimatedChipState extends State<_AnimatedChip> {
  late double _top;
  late double _left;
  late double _endTop;
  late double _endLeft;
  late Duration _animationDuration;
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    final random = Random();
    _top = random.nextDouble() * (widget.screenSize.height - 100);
    _left = random.nextDouble() * (widget.screenSize.width - 100);
    _endTop = random.nextDouble() * (widget.screenSize.height - 100);
    _endLeft = random.nextDouble() * (widget.screenSize.width - 100);
    _animationDuration = Duration(seconds: random.nextInt(10) + 15);
  }

  Offset _getRepelOffset() {
    if (_key.currentContext == null) return Offset.zero;
    final RenderBox? renderBox = _key.currentContext!.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return Offset.zero;
    
    final chipSize = renderBox.size;
    final chipPosition = renderBox.localToGlobal(Offset.zero);
    final chipCenter = Offset(
      chipPosition.dx + chipSize.width / 2,
      chipPosition.dy + chipSize.height / 2
    );

    final distance = (chipCenter - widget.mousePosition).distance;
    
    if (distance > 150) return Offset.zero;

    final repelStrength = (150 - distance) / 150;
    final direction = chipCenter - widget.mousePosition;
    final repelVector = Offset(
      direction.dx * 0.3 * repelStrength,
      direction.dy * 0.3 * repelStrength,
    );
    
    return repelVector;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repelOffset = _getRepelOffset();
    
    return Animate(
      key: _key,
      effects: [
        MoveEffect(
          delay: 1.seconds,
          duration: _animationDuration,
          begin: Offset(_left, _top),
          end: Offset(_endLeft, _endTop),
          curve: Curves.easeInOut,
        ),
        FadeEffect(delay: 1.seconds, duration: 2.seconds),
      ],
      onPlay: (controller) => controller.repeat(reverse: true),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 100),
        transform: Matrix4.translationValues(repelOffset.dx, repelOffset.dy, 0),
        child: Chip(
          label: Text(
            widget.text,
            style: GoogleFonts.roboto(color: theme.colorScheme.onSurfaceVariant)
          ),
          backgroundColor: theme.colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5)
            ),
          ),
        ),
      ),
    );
  }
}