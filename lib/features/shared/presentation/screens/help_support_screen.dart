import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_icons.dart';

enum SupportAudience { broker, driver }

final _supportPageProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, SupportAudience>((ref, audience) async {
      final api = ref.watch(apiClientProvider);
      final response = await switch (audience) {
        SupportAudience.broker => api.getBrokerSupportPage(),
        SupportAudience.driver => api.getDriverSupportPage(),
      };
      final data = response['data'];
      final page = data is Map ? data['page'] : null;
      if (response['success'] != true || page is! Map) {
        throw const ApiException('Could not load support content');
      }
      return Map<String, dynamic>.from(page);
    });

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key, required this.audience});

  final SupportAudience audience;

  Future<bool> _openLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null &&
        const {'https', 'http', 'tel', 'mailto'}.contains(uri.scheme)) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return true;
        }
      } catch (_) {
        // Keep the support page open and offer feedback if no app can handle it.
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.brokerSupportLinkError),
        ),
      );
    }
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final page = ref.watch(_supportPageProvider(audience));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          children: [
            IconButton(
              tooltip: l10n.back,
              icon: const Icon(AppIcons.arrow_back_rounded),
              alignment: Alignment.centerLeft,
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/${audience.name}/profile');
                }
              },
            ),
            const SizedBox(height: 16),
            Text(
              l10n.helpSupport,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            page.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => Column(
                children: [
                  Text(l10n.brokerSupportLoadError),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () =>
                        ref.invalidate(_supportPageProvider(audience)),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
              data: (page) {
                final title = page['title']?.toString().trim() ?? '';
                final content = page['content']?.toString().trim() ?? '';
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title.isNotEmpty) ...[
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (content.isEmpty)
                        Text(l10n.comingSoon)
                      else
                        HtmlWidget(
                          content,
                          textStyle: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            height: 1.6,
                          ),
                          onTapUrl: (url) => _openLink(context, url),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
