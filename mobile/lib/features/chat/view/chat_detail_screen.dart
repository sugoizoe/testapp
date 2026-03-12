import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.name,
    required this.avatarUrl,
  });

  final String name;
  final String avatarUrl;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text: 'Selam, nasılsın? 😊',
      isMe: false,
    ),
    const _ChatMessage(
      text: 'Günün nasıl geçti, akşam için planın var mı?',
      isMe: false,
    ),
  ];

  bool _hasPendingProposal = false;

  List<String> get _quickReplies => const [
        'Konuşalım mı? 📹',
        'Zaman seçelim 🗓️',
        'Müsaitim 👍',
        'Daha sonra 🔄',
      ];

  Future<void> _onQuickReplyTap(String text) async {
    if (text == 'Zaman seçelim 🗓️') {
      await _openSchedulingFlow();
      return;
    }

    String longMessage;
    switch (text) {
      case 'Konuşalım mı? 📹':
        longMessage =
            'Şu anda kısa bir görüntülü konuşma için müsait misin? 📹';
        break;
      case 'Müsaitim 👍':
        longMessage = 'Evet, şu an için uygunum. İstersen hemen başlayalım. 👍';
        break;
      case 'Daha sonra 🔄':
        longMessage =
            'Şu an çok uygun değilim, biraz daha sonra konuşsak olur mu? 🔄';
        break;
      default:
        longMessage = text;
    }

    setState(() {
      _messages.add(
        _ChatMessage(
          text: longMessage,
          isMe: true,
        ),
      );
    });
  }

  Future<void> _openSchedulingFlow() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentPurple,
              secondary: AppColors.accentPurpleSoft,
              surface: AppColors.deepCharcoal,
              error: AppColors.danger,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 21, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentPurple,
              secondary: AppColors.accentPurpleSoft,
              surface: AppColors.deepCharcoal,
              error: AppColors.danger,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (time == null || !mounted) return;

    final scheduled = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      _hasPendingProposal = true;
      _messages.add(
        _ChatMessage.schedule(
          scheduledAt: scheduled,
        ),
      );
    });
  }

  void _onAcceptSchedule() {
    setState(() {
      _hasPendingProposal = false;
      final index = _messages.lastIndexWhere(
        (m) => m.type == _MessageType.scheduleProposal,
      );
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          scheduleStatus: _ScheduleStatus.accepted,
        );
      }
      _messages.add(
        const _ChatMessage(
          text: 'Bu zaman bana uyar! 👍',
          isMe: true,
        ),
      );
    });
  }

  void _onRejectSchedule() {
    setState(() {
      _hasPendingProposal = false;
      final index = _messages.lastIndexWhere(
        (m) => m.type == _MessageType.scheduleProposal,
      );
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          scheduleStatus: _ScheduleStatus.rejected,
        );
      }
      _messages.add(
        const _ChatMessage(
          text:
              'Bu zaman bana pek uygun değil, başka bir zamana ayarlayalım. 🔄',
          isMe: true,
        ),
      );
      _messages.add(const _ChatMessage._schedulePrompt());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF070716),
              Color(0xFF050510),
              Color(0xFF050513),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: Colors.white,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    _TopBarAvatar(
                      name: widget.name,
                      avatarUrl: widget.avatarUrl,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.more_horiz_rounded),
                      color: AppColors.softGrey,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _BigVideoCallButton(
                onPressed: () {},
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Deneyimi metinden çok, anlık görüntülü buluşmalar ve randevulaşma üzerine kur.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.softGrey,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    switch (msg.type) {
                      case _MessageType.scheduleProposal:
                        return _ScheduleBubble(
                          message: msg,
                          onAccept: _onAcceptSchedule,
                          onReject: _onRejectSchedule,
                        );
                      case _MessageType.schedulePrompt:
                        return _SchedulePromptBubble(
                          onTap: _openSchedulingFlow,
                        );
                      case _MessageType.text:
                        return _MessageBubble(message: msg);
                    }
                  },
                ),
              ),
              _QuickRepliesBar(
                quickReplies: _quickReplies,
                onTap: _onQuickReplyTap,
                disabled: _hasPendingProposal,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MessageType {
  text,
  scheduleProposal,
  schedulePrompt,
}

class _ChatMessage {
  final String? text;
  final bool isMe;
  final _MessageType type;
  final DateTime? scheduledAt;
  final _ScheduleStatus? scheduleStatus;

  const _ChatMessage({
    required this.text,
    required this.isMe,
    this.type = _MessageType.text,
    this.scheduledAt,
    this.scheduleStatus,
  });

  const _ChatMessage.schedule({
    required this.scheduledAt,
  })  : text = null,
        isMe = true,
        type = _MessageType.scheduleProposal,
        scheduleStatus = _ScheduleStatus.pending;

  const _ChatMessage._schedulePrompt()
      : text = null,
        isMe = true,
        type = _MessageType.schedulePrompt,
        scheduledAt = null,
        scheduleStatus = null;

  _ChatMessage copyWith({
    String? text,
    bool? isMe,
    _MessageType? type,
    DateTime? scheduledAt,
    _ScheduleStatus? scheduleStatus,
  }) {
    return _ChatMessage(
      text: text ?? this.text,
      isMe: isMe ?? this.isMe,
      type: type ?? this.type,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      scheduleStatus: scheduleStatus ?? this.scheduleStatus,
    );
  }
}

enum _ScheduleStatus { pending, accepted, rejected }

class _TopBarAvatar extends StatelessWidget {
  const _TopBarAvatar({
    required this.name,
    required this.avatarUrl,
  });

  final String name;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.accentPurple,
                AppColors.accentPurpleSoft,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: ClipOval(
              child: Image.network(
                avatarUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              'Şu an çevrimiçi',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.softGrey,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BigVideoCallButton extends StatelessWidget {
  const _BigVideoCallButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentPurpleSoft.withValues(alpha:0.6),
              blurRadius: 40,
              spreadRadius: -4,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ).merge(
            ButtonStyle(
              backgroundColor: WidgetStateProperty.all<Color>(Colors
                  .transparent), // keeping for clarity, gradient is in Ink
            ),
          ),
          child: Ink(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(999)),
              gradient: LinearGradient(
                colors: [
                  AppColors.accentPurple,
                  AppColors.accentPurpleSoft,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.videocam_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Görüntülü Ara',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final alignment =
        isMe ? Alignment.centerRight : Alignment.centerLeft;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(22),
      topRight: const Radius.circular(22),
      bottomLeft: Radius.circular(isMe ? 22 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 22),
    );

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: isMe
              ? const LinearGradient(
                  colors: [
                    AppColors.accentPurple,
                    AppColors.accentPurpleSoft,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isMe
              ? null
              : Colors.white.withValues(alpha:0.04),
          border: isMe
              ? null
              : Border.all(
                  color: Colors.white.withValues(alpha:0.08),
                ),
        ),
        child: Text(
          message.text ?? '',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
        ),
      ),
    );
  }
}

class _ScheduleBubble extends StatelessWidget {
  const _ScheduleBubble({
    required this.message,
    required this.onAccept,
    required this.onReject,
  });

  final _ChatMessage message;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  String _formatDate(BuildContext context) {
    final dt = message.scheduledAt;
    if (dt == null) return '';
    final timeOfDay = TimeOfDay.fromDateTime(dt);
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '${dt.day}.${dt.month}.${dt.year} • $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final status = message.scheduleStatus ?? _ScheduleStatus.pending;
    final isAccepted = status == _ScheduleStatus.accepted;
    final isRejected = status == _ScheduleStatus.rejected;

    final Color borderColor;
    final Color bgColor;
    if (isAccepted) {
      borderColor = Colors.greenAccent.withValues(alpha:0.7);
      bgColor = const Color(0xFF072818).withValues(alpha:0.9);
    } else if (isRejected) {
      borderColor = Colors.white.withValues(alpha:0.12);
      bgColor = Colors.white.withValues(alpha:0.03);
    } else {
      borderColor = Colors.white.withValues(alpha:0.16);
      bgColor = Colors.white.withValues(alpha:0.06);
    }

    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: bgColor,
          border: Border.all(
            color: borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:isRejected ? 0.2 : 0.4),
              blurRadius: 30,
              offset: const Offset(0, 16),
              spreadRadius: -12,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isAccepted)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.greenAccent,
                    size: 18,
                  )
                else if (isRejected)
                  Icon(
                    Icons.block,
                    color: AppColors.softGrey.withValues(alpha:0.8),
                    size: 18,
                  )
                else
                  const Icon(
                    Icons.schedule_rounded,
                    color: AppColors.accentPurpleSoft,
                    size: 18,
                  ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isAccepted
                        ? 'Randevu onaylandı'
                        : isRejected
                            ? 'Randevu iptal edildi'
                            : 'Önerilen görüntülü buluşma zamanı',
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(context),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.softGrey,
                    decoration:
                        isRejected ? TextDecoration.lineThrough : null,
                  ),
            ),
            const SizedBox(height: 12),
            if (!isAccepted && !isRejected)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      child: const Text('Kabul Et'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha:0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text('Reddet / Yeni Zaman Öner'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SchedulePromptBubble extends StatelessWidget {
  const _SchedulePromptBubble({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha:0.06),
            border: Border.all(
              color: Colors.white.withValues(alpha:0.18),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: AppColors.accentPurpleSoft,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Yeni bir tarih/saat öner',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickRepliesBar extends StatelessWidget {
  const _QuickRepliesBar({
    required this.quickReplies,
    required this.onTap,
    required this.disabled,
  });

  final List<String> quickReplies;
  final ValueChanged<String> onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final chips = quickReplies
        .map(
          (text) => _QuickReplyChip(
            text: text,
            onTap: disabled ? null : () => onTap(text),
          ),
        )
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withValues(alpha:0.06),
              border: Border.all(
                color: Colors.white.withValues(alpha:0.16),
              ),
            ),
            child: Stack(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      ...chips.expand(
                        (chip) => [
                          chip,
                          const SizedBox(width: 8),
                        ],
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IgnorePointer(
                    child: Container(
                      width: 28,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha:0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  const _QuickReplyChip({
    required this.text,
    this.onTap,
  });

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: disabled
              ? Colors.white.withValues(alpha:0.03)
              : Colors.white.withValues(alpha:0.08),
          border: Border.all(
            color: Colors.white.withValues(alpha:disabled ? 0.14 : 0.22),
          ),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
    );
  }
}

