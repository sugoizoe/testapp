import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/validators.dart';
import '../controllers/auth_controller.dart';
import '../widgets/aurora_background.dart';
import '../widgets/custom_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _pageController = PageController();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _hobbiesController = TextEditingController();

  int _currentStep = 0;
  DateTime? _birthDate;
  String? _gender;
  String? _targetPreference;

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _hobbiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(
      authControllerProvider,
      (previous, next) {
        next.whenOrNull(
          error: (err, _) {
            String message = err.toString();
            if (err is DioException) {
              final data = err.response?.data;
              if (data is Map) {
                message = data['error']?.toString() ??
                    data['details']?.toString() ??
                    message;
              } else if (data != null) {
                message = data.toString();
              }
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.danger.withValues(alpha:0.95),
              ),
            );
          },
        );
      },
    );

    final state = ref.watch(authControllerProvider);
    final isLoading = state.isLoading;

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Kayıt Ol'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.03),
                        border: Border.all(color: Colors.white.withValues(alpha:0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildStepIndicator(),
                          const SizedBox(height: 16),
                          Expanded(
                            child: PageView(
                              controller: _pageController,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _buildStep1(),
                                _buildStep2(),
                                _buildStep3(),
                                _buildStep4(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              if (_currentStep > 0)
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: isLoading ? null : _prevStep,
                                    child: const Text('Geri'),
                                  ),
                                ),
                              if (_currentStep > 0) const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    backgroundColor: const Color(0xFF7C3AED),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: isLoading
                                      ? null
                                      : () async {
                                          if (_currentStep < 3) {
                                            if (_validateCurrentStep(context)) {
                                              _nextStep();
                                            }
                                          } else {
                                            await _submit(context);
                                          }
                                        },
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation(Colors.white),
                                          ),
                                        )
                                      : Text(_currentStep == 3 ? 'Kayıt Ol' : 'İleri'),
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildStepIndicator() {
    const totalSteps = 4;
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;
        Color color;
        if (isCompleted) {
          color = AppColors.accentPurpleSoft;
        } else if (isActive) {
          color = AppColors.accentPurple;
        } else {
          color = AppColors.softGrey.withValues(alpha:0.4);
        }
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adım 1: Giriş Bilgileri',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Güçlü bir şifre ile hesabını güvene al.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.softGrey,
                ),
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: 'E-posta',
            hint: 'ornek@mail.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Şifre',
            hint: 'En az 8 karakter',
            controller: _passwordController,
            obscureText: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adım 2: Kişisel Bilgiler',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Seni daha iyi tanımamız için birkaç bilgi.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.softGrey,
                ),
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: 'Ad Soyad',
            hint: 'Adını ve soyadını yaz',
            controller: _fullNameController,
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Doğum Tarihi'),
            subtitle: Text(
              _birthDate == null
                  ? 'Seçmek için dokun'
                  : '${_birthDate!.day}.${_birthDate!.month}.${_birthDate!.year}',
            ),
            onTap: _pickBirthDate,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _genderChip('male', 'Erkek'),
              _genderChip('female', 'Kadın'),
              _genderChip('other', 'Diğer'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _genderChip(String value, String label) {
    final selected = _gender == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _gender = value;
        });
      },
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adım 3: Tercihler ve İlgi Alanları',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Kimleri görmek istediğini ve nelerden hoşlandığını seç.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.softGrey,
                ),
          ),
          const SizedBox(height: 24),
          Text(
            'Karşı Cinsiyet Tercihi',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _preferenceChip('male', 'Erkek'),
              _preferenceChip('female', 'Kadın'),
              _preferenceChip('both', 'Her ikisi'),
              _preferenceChip('any', 'Farketmez'),
            ],
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: 'Hobiler & İlgi Alanları',
            hint: 'Örn: Satranç, performans araçları, felsefe...',
            controller: _hobbiesController,
          ),
        ],
      ),
    );
  }

  Widget _preferenceChip(String value, String label) {
    final selected = _targetPreference == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _targetPreference = value;
        });
      },
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adım 4: Fotoğraf',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Seni en iyi yansıtan bir fotoğraf ekle.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.softGrey,
              ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              const CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.deepCharcoal,
                child: Icon(
                  Icons.person,
                  size: 48,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _requestPhotoPermissions,
                icon: const Icon(Icons.photo_camera_back_outlined),
                label: const Text('Fotoğraf Ekle'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _prevStep() {
    setState(() {
      _currentStep--;
    });
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  bool _validateCurrentStep(BuildContext context) {
    switch (_currentStep) {
      case 0:
        if (!isValidEmail(_emailController.text) ||
            !isValidPassword(_passwordController.text)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Lütfen geçerli bir e-posta ve en az 8 karakterli şifre girin.'),
            ),
          );
          return false;
        }
        return true;
      case 1:
        if (_fullNameController.text.trim().isEmpty ||
            _birthDate == null ||
            _gender == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lütfen ad, doğum tarihi ve cinsiyet bilgilerini doldurun.'),
            ),
          );
          return false;
        }
        if (!isAtLeast18YearsOld(_birthDate!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Datenow sadece 18 yaş ve üzeri kullanıcılar içindir.'),
            ),
          );
          return false;
        }
        return true;
      case 2:
        if (_targetPreference == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lütfen en az bir tercih seçin.'),
            ),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = DateTime(now.year - 20, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _requestPhotoPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final photosStatus = await Permission.photos.request();

    if (!mounted) return;

    final granted = cameraStatus.isGranted && photosStatus.isGranted;
    final permanentlyDenied =
        cameraStatus.isPermanentlyDenied || photosStatus.isPermanentlyDenied;

    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fotoğraf izinleri verildi. Yakında yükleme akışını tamamlayacağız.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (permanentlyDenied) {
      // Kullanıcıyı ayarlara yönlendiren şık bir uyarı
      showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('İzin Gerekli'),
            content: const Text(
              'Fotoğraf ekleyebilmek için kamera ve galeri izinlerine ihtiyaç var. '
              'İzinleri daha önce kalıcı olarak reddettin. Cihaz ayarlarından izinleri açabilirsin.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Daha Sonra'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await openAppSettings();
                },
                child: const Text('Ayarları Aç'),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fotoğraf yüklemek için kamera/galeri izinlerini vermelisin.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submit(BuildContext context) async {
    if (!_validateCurrentStep(context)) return;
    final router = GoRouter.of(context);
    final controller = ref.read(authControllerProvider.notifier);

    try {
      await controller.register(
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _fullNameController.text,
        birthDate: _birthDate!,
        gender: _gender!,
        targetGenderPreference: _targetPreference!,
        router: router,
      );
    } catch (_) {
      // Hatalar Snackbar ile dinleyici üzerinden gösteriliyor.
    }
  }
}
