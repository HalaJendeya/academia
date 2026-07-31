import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class StudentVerificationScreen extends StatefulWidget {
  const StudentVerificationScreen({super.key});

  @override
  State<StudentVerificationScreen> createState() =>
      _StudentVerificationScreenState();
}

class _StudentVerificationScreenState extends State<StudentVerificationScreen> {
  int _cooldownSeconds = 30;
  int _resendCount = 0;
  DateTime? _lockoutEndTime;
  Timer? _timer;
  String _email = 'std@university.edu.sa';

  bool _showMockInbox = false;
  bool _emailOpened = false;
  bool _isVerifyingLink = false;

  @override
  void initState() {
    super.initState();
    _loadStateAndStartTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as String?;
    if (args != null && args.isNotEmpty) {
      setState(() {
        _email = args;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadStateAndStartTimer() async {
    final prefs = await SharedPreferences.getInstance();
    _resendCount = prefs.getInt('verification_resend_count') ?? 0;
    
    final lockoutStr = prefs.getString('verification_lockout_end');
    if (lockoutStr != null) {
      final savedEnd = DateTime.parse(lockoutStr);
      if (savedEnd.isAfter(DateTime.now())) {
        _lockoutEndTime = savedEnd;
      } else {
        await prefs.remove('verification_lockout_end');
        await prefs.setInt('verification_resend_count', 0);
        _resendCount = 0;
      }
    }

    _startTimerLoop();
  }

  void _startTimerLoop() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_lockoutEndTime != null) {
          if (DateTime.now().isAfter(_lockoutEndTime!)) {
            _lockoutEndTime = null;
            _resendCount = 0;
            _cooldownSeconds = 0;
            _clearLockoutPrefs();
          }
        } else if (_cooldownSeconds > 0) {
          _cooldownSeconds--;
        }
      });
    });
  }

  Future<void> _clearLockoutPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('verification_lockout_end');
    await prefs.setInt('verification_resend_count', 0);
  }

  Future<void> _handleResend() async {
    if (_cooldownSeconds > 0 || _lockoutEndTime != null) return;

    final prefs = await SharedPreferences.getInstance();
    _resendCount++;
    await prefs.setInt('verification_resend_count', _resendCount);

    if (_resendCount >= 3) {
      final lockoutEnd = DateTime.now().add(const Duration(hours: 1));
      setState(() {
        _lockoutEndTime = lockoutEnd;
      });
      await prefs.setString(
        'verification_lockout_end',
        lockoutEnd.toIso8601String(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'لقد تجاوزت الحد الأقصى للمحاولات. يرجى الانتظار لمدة ساعة.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      setState(() {
        _cooldownSeconds = 30;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إعادة إرسال رابط التأكيد إلى $_email بنجاح.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _simulateVerifyLink() {
    setState(() {
      _isVerifyingLink = true;
    });

    // Simulate 1.0 second verification loading
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        _isVerifyingLink = false;
        _showMockInbox = false; // close the browser
      });

      // Show success message on the Login Screen after routing
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تفعيل حسابك الجامعي بنجاح. يمكنك الآن تسجيل الدخول.'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 4),
          ),
        );
      });
    });
  }

  String _getTimerOrLockoutText() {
    if (_lockoutEndTime != null) {
      final diff = _lockoutEndTime!.difference(DateTime.now());
      final minutes = diff.inMinutes;
      final seconds = diff.inSeconds % 60;
      return 'تجاوزت الحد. يرجى الانتظار $minutes:${seconds.toString().padLeft(2, '0')} دقيقة';
    }
    if (_cooldownSeconds > 0) {
      return 'لم يصلك الرابط؟ يمكنك إعادة الإرسال بعد $_cooldownSeconds ثانية';
    }
    return 'يمكنك إعادة إرسال رابط التأكيد الآن';
  }

  Widget _buildVerificationScreen() {
    final canResend = _cooldownSeconds == 0 && _lockoutEndTime == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'التحقق من الطالب',
          style: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.arrow_forward,
              color: AppColors.secondary,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.borderLight,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.mail_outline,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryDarker,
                            ),
                            child: const Icon(
                              Icons.school,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'رابط تفعيل الحساب',
                      style: AppTextStyles.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'لقد أرسلنا رابط تأكيد الحساب إلى بريدك الإلكتروني الجامعي التالي. يرجى مراجعة صندوق الوارد والضغط على الرابط لتفعيل حسابك.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _email,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      key: const Key('open_email_btn'),
                      onPressed: () {
                        setState(() {
                          _showMockInbox = true;
                          _emailOpened = false;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.open_in_new, color: Colors.white),
                          SizedBox(width: 8),
                          Text('افتح البريد الإلكتروني'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getTimerOrLockoutText(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: _lockoutEndTime != null
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.info_outline,
                          color: _lockoutEndTime != null
                              ? AppColors.error
                              : AppColors.primary,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: canResend ? _handleResend : null,
                      icon: Icon(
                        Icons.refresh,
                        color: canResend
                            ? AppColors.textSecondary
                            : AppColors.textDisabled,
                      ),
                      label: Text(
                        'إعادة إرسال الرابط',
                        style: TextStyle(
                          color: canResend
                              ? AppColors.textSecondary
                              : AppColors.textDisabled,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'إذا كنت تواجه مشكلة في الوصول إلى بريدك الجامعي، يرجى التواصل مع الدعم الفني بالجامعة.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockInbox() {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        title: Row(
          children: const [
            Icon(Icons.lock, size: 16, color: Colors.white70),
            SizedBox(width: 6),
            Text(
              'mail.university.edu',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            setState(() {
              _showMockInbox = false;
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _emailOpened ? _buildEmailDetails() : _buildEmailList(),
    );
  }

  Widget _buildEmailList() {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: const [
              Icon(Icons.inbox, color: AppColors.secondary),
              SizedBox(width: 12),
              Text(
                'صندوق الوارد (Inbox)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        GestureDetector(
          key: const Key('inbox_email_item'),
          onTap: () {
            setState(() {
              _emailOpened = true;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: const Text(
                    'أ',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'أكاديميا (Academia)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'الآن',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'تأكيد البريد الإلكتروني لحسابك',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'مرحباً بك! اضغط هنا لتأكيد حسابك وتفعيله...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildEmailDetails() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _emailOpened = false;
                  });
                },
              ),
              const Text(
                'العودة إلى صندوق الوارد',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'تأكيد البريد الإلكتروني لحسابك',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Text(
                'من: ',
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                'no-reply@academia.com',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'مرحباً بك في أكاديميا، رفيقك الذكي لتنظيم الدراسة.',
            style: TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 12),
          const Text(
            'لتفعيل حسابك والبدء في استخدام التطبيق، يرجى الضغط على رابط التأكيد أدناه لتفعيل حسابك الجامعي:',
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 32),
          _isVerifyingLink
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : ElevatedButton(
                  key: const Key('verify_link_btn'),
                  onPressed: _simulateVerifyLink,
                  child: const Text('تأكيد الحساب (Verify Account)'),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _showMockInbox ? _buildMockInbox() : _buildVerificationScreen();
  }
}
