import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:storybird_flutter/core/theme/app_colors.dart';
import 'package:storybird_flutter/core/theme/app_theme.dart';
import 'package:storybird_flutter/providers/create_provider.dart';

/// 生成朗读绘本进度页面
/// 显示生成进度，提示用户可稍后在绘本架查看
class GenerateProgressScreen extends ConsumerStatefulWidget {
  const GenerateProgressScreen({super.key});

  @override
  ConsumerState<GenerateProgressScreen> createState() =>
      _GenerateProgressScreenState();
}

class _GenerateProgressScreenState
    extends ConsumerState<GenerateProgressScreen> {
  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createProvider);
    final progress = createState.generateProgress;
    final isGenerating = createState.isGenerating;
    final error = createState.error;
    final bookId = createState.generatedBookId;

    // 生成完成且无错误
    final isCompleted = !isGenerating && bookId != null && error == null;

    // 生成失败
    final isFailed = !isGenerating && error != null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // 进度指示器
              _buildProgressIndicator(progress, isGenerating, isCompleted),

              const SizedBox(height: 32),

              // 进度消息
              _buildProgressMessage(progress, isCompleted, isFailed, error),

              const Spacer(),

              // 提示卡片
              _buildTipCard(isCompleted),

              const SizedBox(height: 24),

              // 按钮区域
              _buildButtons(isCompleted, isFailed, bookId),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(
    GenerateProgress progress,
    bool isGenerating,
    bool isCompleted,
  ) {
    final displayProgress = isCompleted ? 100 : progress.progress;

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        children: [
          CircularProgressIndicator(
            value: displayProgress / 100,
            strokeWidth: 12,
            backgroundColor: AppColors.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(
              isCompleted ? AppColors.tertiaryContainer : AppColors.secondaryContainer,
            ),
          ),
          Center(
            child: isCompleted
                ? Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      LucideIcons.check,
                      size: 24,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    '$displayProgress%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onPrimaryFixed,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressMessage(
    GenerateProgress progress,
    bool isCompleted,
    bool isFailed,
    String? error,
  ) {
    String message;
    String subtitle;

    if (isCompleted) {
      message = '绘本生成完成！';
      subtitle = '快去朗读吧！';
    } else if (isFailed) {
      message = '生成失败';
      subtitle = error ?? '请稍后重试';
    } else {
      message = progress.message.isNotEmpty ? progress.message : '正在生成...';
      subtitle = '请稍候，这可能需要几分钟';
    }

    return Column(
      children: [
        Text(
          message,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.onPrimaryFixed,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isFailed ? AppColors.error : AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTipCard(bool isCompleted) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: AppColors.primaryContainer.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.lightbulb,
              size: 24,
              color: AppColors.onPrimaryFixed,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              isCompleted
                  ? '绘本已添加到绘本架，您可以随时阅读'
                  : '生成完成后，您可以在首页绘本架查看并朗读这本绘本',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.onPrimaryFixed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(bool isCompleted, bool isFailed, String? bookId) {
    // 返回首页按钮（始终显示）
    // 生成中不重置状态，完成/失败才重置
    final homeButton = ElevatedButton(
      onPressed: () {
        // 只有完成或失败时才重置状态
        if (isCompleted || isFailed) {
          ref.read(createProvider.notifier).reset();
        }
        context.go('/home');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.onSurface,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        elevation: 0,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.home, size: 20),
          SizedBox(width: 8),
          Text(
            '返回首页',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );

    // 完成后显示"立即阅读"按钮
    if (isCompleted && bookId != null) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                ref.read(createProvider.notifier).reset();
                context.go('/reading/$bookId');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryContainer,
                foregroundColor: AppColors.onSecondaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.bookOpen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '立即阅读',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: homeButton),
        ],
      );
    }

    // 失败时显示"重新尝试"按钮
    if (isFailed) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(createProvider.notifier).clearError();
                context.go('/create');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryContainer,
                foregroundColor: AppColors.onSecondaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.refreshCw, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '重新尝试',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: homeButton,
          ),
        ],
      );
    }

    // 生成中：只显示"返回首页"按钮
    return SizedBox(
      width: double.infinity,
      child: homeButton,
    );
  }
}