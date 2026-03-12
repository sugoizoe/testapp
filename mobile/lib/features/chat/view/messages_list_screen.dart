import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

class MessagesListScreen extends StatelessWidget {
  const MessagesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const threads = _mockThreads;
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mesajlar',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search_rounded),
                      color: AppColors.softGrey,
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Eşleştiğin kişilerle hızlıca görüntülü randevulaş.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.softGrey,
                      ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: threads.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final thread = threads[index];
                      return _MessageThreadTile(thread: thread);
                    },
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

class _MessageThread {
  final String name;
  final String lastMessage;
  final String avatarUrl;
  final String time;
  final bool isOnline;
  final bool hasUnread;

  const _MessageThread({
    required this.name,
    required this.lastMessage,
    required this.avatarUrl,
    required this.time,
    this.isOnline = false,
    this.hasUnread = false,
  });
}

const _mockThreads = [
  _MessageThread(
    name: 'Deniz Yılmaz',
    lastMessage: 'Müsait olunca görüntülü arayalım mı?',
    avatarUrl:
        'https://images.pexels.com/photos/415829/pexels-photo-415829.jpeg?auto=compress',
    time: 'Şimdi',
    isOnline: true,
    hasUnread: true,
  ),
  _MessageThread(
    name: 'Ece',
    lastMessage: 'Yarın akşam 21:30 olur mu?',
    avatarUrl:
        'https://images.pexels.com/photos/1130626/pexels-photo-1130626.jpeg?auto=compress',
    time: '3 dk',
    isOnline: true,
  ),
  _MessageThread(
    name: 'Mert',
    lastMessage: 'Toplantıdan sonra haber vereyim.',
    avatarUrl:
        'https://images.pexels.com/photos/614810/pexels-photo-614810.jpeg?auto=compress',
    time: '1 sa',
  ),
  _MessageThread(
    name: 'Selin',
    lastMessage: 'Hafta sonu için uygun musun?',
    avatarUrl:
        'https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress',
    time: 'Dün',
  ),
];

class _MessageThreadTile extends StatelessWidget {
  const _MessageThreadTile({required this.thread});

  final _MessageThread thread;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          'chat',
          extra: {'name': thread.name, 'avatarUrl': thread.avatarUrl},
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withValues(alpha:0.05),
              border: Border.all(
                color: Colors.white.withValues(alpha:0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.5),
                  blurRadius: 26,
                  offset: const Offset(0, 18),
                  spreadRadius: -14,
                ),
              ],
            ),
            child: Row(
              children: [
                _AvatarWithStatus(
                  url: thread.avatarUrl,
                  isOnline: thread.isOnline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              thread.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            thread.time,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.softGrey,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        thread.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.softGrey,
                                ),
                      ),
                    ],
                  ),
                ),
                if (thread.hasUnread) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentPurpleSoft,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarWithStatus extends StatelessWidget {
  const _AvatarWithStatus({
    required this.url,
    required this.isOnline,
  });

  final String url;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                AppColors.accentPurple,
                AppColors.accentPurpleSoft,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPurpleSoft.withValues(alpha:0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: ClipOval(
              child: Image.network(
                url,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        if (isOnline)
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.greenAccent.shade400,
                border: Border.all(
                  color: AppColors.darkBackground,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

