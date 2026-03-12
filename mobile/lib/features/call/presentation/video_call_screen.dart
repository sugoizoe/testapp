import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart'; // adjust path if needed
import 'call_controller.dart';
import 'widgets/report_bottom_sheet.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  const VideoCallScreen({super.key});

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Offset _pipOffset = const Offset(16, 120);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(callControllerProvider);
    final controller = ref.read(callControllerProvider.notifier);
    final size = MediaQuery.of(context).size;

    final totalSeconds = state.remaining.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    final isLastMinute = totalSeconds <= 60 && !state.ended;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Karşı tarafın videosu (şimdilik placeholder)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.darkBackground, AppColors.deepCharcoal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  color: Colors.white24,
                  size: 120,
                ),
              ),
            ),
          ),
          // Kalan süre sayacı
          Positioned(
            top: 32,
            left: 0,
            right: 0,
            child: Center(
              child: ScaleTransition(
                scale: isLastMinute
                    ? Tween<double>(begin: 1.0, end: 1.1).animate(
                        CurvedAnimation(
                          parent: _pulseController,
                          curve: Curves.easeInOut,
                        ),
                      )
                    : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha:0.4),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isLastMinute
                          ? AppColors.danger
                          : AppColors.accentPurpleSoft,
                    ),
                  ),
                  child: Text(
                    '$minutes:$seconds',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color:
                              isLastMinute ? AppColors.danger : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ),
          ),
          // Güvenlik / Şikayet ikonu
          Positioned(
            top: 32,
            left: 16,
            child: IconButton(
              icon: const Icon(
                Icons.shield_outlined,
                color: Colors.white70,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const ReportBottomSheet(),
                );
              },
            ),
          ),
          // PIP - kendi videosu (draggable)
          Positioned(
            right: _pipOffset.dx,
            bottom: _pipOffset.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  final newDx =
                      (_pipOffset.dx - details.delta.dx).clamp(16.0, 16.0);
                  final newDy = (_pipOffset.dy - details.delta.dy)
                      .clamp(80.0, size.height - 200);
                  _pipOffset = Offset(newDx, newDy);
                });
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: size.width * 0.32,
                  height: size.height * 0.22,
                  color: Colors.black87,
                  child: const Center(
                    child: Icon(
                      Icons.person_outline,
                      color: Colors.white54,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Alt kontrol barı (Glassmorphism)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ControlBar(
              isMuted: state.isMuted,
              isCameraOff: state.isCameraOff,
              onToggleMute: controller.toggleMute,
              onToggleCamera: controller.toggleCamera,
              onEndCall: controller.endCall,
            ),
          ),
          if (state.ended)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha:0.8),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.hourglass_disabled_rounded,
                        color: AppColors.accentPurpleSoft,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Süre Doldu!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Premium plana geçerek 10 dakikalık görüşmeler yapabilirsin.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.softGrey,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.isMuted,
    required this.isCameraOff,
    required this.onToggleMute,
    required this.onToggleCamera,
    required this.onEndCall,
  });

  final bool isMuted;
  final bool isCameraOff;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleCamera;
  final VoidCallback onEndCall;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 90,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha:0.5),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha:0.08),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CircleIconButton(
                icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                background: Colors.black87,
                iconColor: isMuted ? AppColors.danger : Colors.white,
                onPressed: onToggleMute,
              ),
              _CircleIconButton(
                icon:
                    isCameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                background: Colors.black87,
                iconColor: isCameraOff ? AppColors.danger : Colors.white,
                onPressed: onToggleCamera,
              ),
              _CircleIconButton(
                icon: Icons.call_end_rounded,
                background: AppColors.danger,
                iconColor: Colors.white,
                onPressed: onEndCall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.onPressed,
  });

  final IconData icon;
  final Color background;
  final Color iconColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor,
        ),
      ),
    );
  }
}

