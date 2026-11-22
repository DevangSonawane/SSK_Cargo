import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../l10n/app_localizations.dart';
import 'help_support_screen.dart';

/// Web parity: `pages/legal/LegalIndex.jsx` + `LegalPage.jsx` (both web apps).
/// Every page is admin-managed HTML from
/// `GET /api/legal-pages/:audience/:pageKey` — nothing is hardcoded here.
class LegalPageKey {
  const LegalPageKey._(this.key, this.icon);

  final String key;
  final IconData icon;

  static const privacyPolicy = LegalPageKey._(
    'privacy_policy',
    AppIcons.shield_rounded,
  );
  static const termsConditions = LegalPageKey._(
    'terms_conditions',
    AppIcons.description_outlined,
  );
  static const accountDeletion = LegalPageKey._(
    'account_deletion',
    AppIcons.person_remove_rounded,
  );
  static const contactSupport = LegalPageKey._(
    'contact_support',
    AppIcons.support_agent_rounded,
  );
  static const refundPolicy = LegalPageKey._(
    'refund_policy',
    AppIcons.rotate_ccw_rounded,
  );
  static const safetyPolicy = LegalPageKey._(
    'safety_policy',
    AppIcons.gpp_maybe_rounded,
  );

  /// Same order as the web `PAGES` list.
  static const all = [
    privacyPolicy,
    termsConditions,
    accountDeletion,
    contactSupport,
    refundPolicy,
    safetyPolicy,
  ];

  String label(AppLocalizations l10n) => switch (key) {
    'privacy_policy' => l10n.legalPrivacyPolicy,
    'terms_conditions' => l10n.legalTermsConditions,
    'account_deletion' => l10n.legalAccountDeletion,
    'contact_support' => l10n.legalContactSupport,
    'refund_policy' => l10n.legalRefundPolicy,
    'safety_policy' => l10n.legalSafetyPolicy,
    _ => key,
  };
}

typedef _LegalPageArgs = ({String audience, String pageKey});

final legalPageProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, _LegalPageArgs>((ref, args) async {
      final response = await ref
          .watch(apiClientProvider)
          .getLegalPage(audience: args.audience, pageKey: args.pageKey);
      final data = response['data'];
      final page = data is Map ? data['page'] : null;
      if (response['success'] != true || page is! Map) {
        throw const ApiException('Could not load this page');
      }
      return Map<String, dynamic>.from(page);
    });

String legalRoute(SupportAudience audience, [String? pageKey]) =>
    pageKey == null
    ? '/${audience.name}/legal'
    : '/${audience.name}/legal/$pageKey';

/// "Legal & Support" index — links to every policy page.
class LegalIndexScreen extends StatelessWidget {
  const LegalIndexScreen({super.key, required this.audience});

  final SupportAudience audience;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        elevation: 0,
        title: Text(l10n.legalAndSupport),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              l10n.legalIndexSubtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            // Material (not a decorated Container) so ListTile ink shows.
            Material(
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                side: BorderSide(color: colors.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (i, page) in LegalPageKey.all.indexed) ...[
                    if (i > 0) Divider(height: 1, color: colors.divider),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colors.brandFill,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          page.icon,
                          size: 18,
                          color: AppColors.brand,
                        ),
                      ),
                      title: Text(
                        page.label(l10n),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Icon(
                        AppIcons.chevron_right_rounded,
                        color: colors.textTertiary,
                      ),
                      onTap: () => context.push(legalRoute(audience, page.key)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One admin-managed legal page (HTML), plus the deletion request form on
/// `account_deletion` — same as the web `LegalPage.jsx`.
class LegalPageScreen extends ConsumerWidget {
  const LegalPageScreen({
    super.key,
    required this.audience,
    required this.pageKey,
  });

  final SupportAudience audience;
  final String pageKey;

  Future<bool> _openLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null &&
        const {'https', 'http', 'tel', 'mailto'}.contains(uri.scheme)) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return true;
        }
      } catch (_) {}
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
    final colors = context.colors;
    final args = (audience: audience.name, pageKey: pageKey);
    final page = ref.watch(legalPageProvider(args));
    final fallbackTitle = LegalPageKey.all
        .where((p) => p.key == pageKey)
        .map((p) => p.label(l10n))
        .firstOrNull;

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        elevation: 0,
        title: Text(fallbackTitle ?? l10n.legalAndSupport),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(legalPageProvider(args).future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              page.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _LegalCard(
                  child: Column(
                    children: [
                      Icon(
                        AppIcons.description_outlined,
                        size: 40,
                        color: colors.textTertiary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.legalPageLoadError,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () =>
                            ref.invalidate(legalPageProvider(args)),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
                data: (page) {
                  final title = page['title']?.toString().trim() ?? '';
                  final content = page['content']?.toString().trim() ?? '';
                  return _LegalCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title.isNotEmpty) ...[
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (content.isEmpty)
                          Text(
                            l10n.legalContentComingSoon,
                            style: TextStyle(
                              color: colors.textTertiary,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          HtmlWidget(
                            content,
                            textStyle: TextStyle(
                              color: colors.textPrimary,
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
              if (pageKey == LegalPageKey.accountDeletion.key &&
                  page.hasValue) ...[
                const SizedBox(height: 16),
                _AccountDeletionForm(audience: audience),
              ],
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final other in LegalPageKey.all)
                    if (other.key != pageKey)
                      ActionChip(
                        label: Text(other.label(l10n)),
                        onPressed: () => context.pushReplacement(
                          legalRoute(audience, other.key),
                        ),
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalCard extends StatelessWidget {
  const _LegalCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.line),
      ),
      child: child,
    );
  }
}

class _AccountDeletionForm extends ConsumerStatefulWidget {
  const _AccountDeletionForm({required this.audience});

  final SupportAudience audience;

  @override
  ConsumerState<_AccountDeletionForm> createState() =>
      _AccountDeletionFormState();
}

class _AccountDeletionFormState extends ConsumerState<_AccountDeletionForm> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _reason = TextEditingController();
  bool _submitting = false;
  ({bool ok, String message})? _result;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_email.text.trim().isEmpty && _phone.text.trim().isEmpty) {
      setState(
        () => _result = (ok: false, message: l10n.legalDeletionNeedContact),
      );
      return;
    }
    setState(() {
      _submitting = true;
      _result = null;
    });
    try {
      final res = await ref
          .read(apiClientProvider)
          .submitLegalAccountDeletionRequest(
            audience: widget.audience.name,
            name: _name.text,
            email: _email.text,
            phone: _phone.text,
            reason: _reason.text,
          );
      if (res['success'] != true) {
        throw ApiException(
          res['message']?.toString() ?? l10n.legalDeletionFailed,
        );
      }
      if (!mounted) return;
      final message = res['message']?.toString().trim();
      setState(() {
        _result = (
          ok: true,
          message: (message == null || message.isEmpty)
              ? l10n.legalDeletionReceived
              : message,
        );
        _name.clear();
        _email.clear();
        _phone.clear();
        _reason.clear();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _result = (ok: false, message: userFacingError(error)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _decoration(String label, {String? hint}) =>
      InputDecoration(labelText: label, hintText: hint);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final result = _result;
    return _LegalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.legalDeletionFormTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.legalDeletionFormSubtitle,
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textInputAction: TextInputAction.next,
            decoration: _decoration(l10n.legalDeletionName),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: _decoration(
              l10n.legalDeletionPhone,
              hint: l10n.legalDeletionPhoneHint,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _decoration(l10n.email),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            maxLines: 3,
            inputFormatters: [LengthLimitingTextInputFormatter(2000)],
            decoration: _decoration(l10n.legalDeletionReason),
          ),
          if (result != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: result.ok
                    ? colors.brandFill
                    : AppColors.dangerIcon.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                result.message,
                style: TextStyle(
                  color: result.ok ? AppColors.brand : AppColors.dangerIcon,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: const Icon(AppIcons.send_rounded, size: 18),
            label: Text(
              _submitting
                  ? l10n.legalDeletionSubmitting
                  : l10n.legalDeletionSubmit,
            ),
          ),
        ],
      ),
    );
  }
}
