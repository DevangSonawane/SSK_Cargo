import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class DriverDeliveryDetailsScreen extends StatefulWidget {
  const DriverDeliveryDetailsScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<DriverDeliveryDetailsScreen> createState() =>
      _DriverDeliveryDetailsScreenState();
}

class _DriverDeliveryDetailsScreenState
    extends State<DriverDeliveryDetailsScreen> {
  double _arrivalSlide = 0;
  bool _showArrivalSwipe = false;
  Timer? _arrivalTimer;

  @override
  void initState() {
    super.initState();
    _arrivalTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _showArrivalSwipe = true);
    });
  }

  @override
  void dispose() {
    _arrivalTimer?.cancel();
    super.dispose();
  }

  void _showEmergencyAssistance(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDEEEF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Color(0xFFE35A62),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Emergency Assistance',
                          style: Theme.of(sheetContext).textTheme.titleLarge
                              ?.copyWith(
                                color: const Color(0xFF101828),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: const Color(0xFF98A2B3),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _EmergencyAssistanceTile(
                    backgroundColor: const Color(0xFFFDEEEF),
                    iconColor: const Color(0xFFE35A62),
                    icon: Icons.local_police_rounded,
                    title: 'Call Police',
                    subtitle: 'Emergency: 112',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Calling police support soon.'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _EmergencyAssistanceTile(
                    backgroundColor: const Color(0xFFFDEEEF),
                    iconColor: const Color(0xFFE35A62),
                    icon: Icons.local_hospital_rounded,
                    title: 'Call Ambulance',
                    subtitle: 'Emergency: 108',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Calling ambulance support soon.'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _EmergencyAssistanceTile(
                    backgroundColor: const Color(0xFFEAF2FF),
                    iconColor: const Color(0xFF3F7DE8),
                    icon: Icons.call_rounded,
                    title: 'Call Broker',
                    subtitle: '9000000003',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Calling broker soon.')),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _EmergencyAssistanceTile(
                    backgroundColor: const Color(0xFFFFF7DE),
                    iconColor: const Color(0xFFC98B17),
                    icon: Icons.report_outlined,
                    title: 'Report Incident to Support',
                    subtitle: 'Notify our support team immediately',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _showIncidentReport(context, widget.tripId);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showIncidentReport(BuildContext context, String tripId) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _IncidentReportDialog(parentContext: context, tripId: tripId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F6FB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF101828),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Delivery ID',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(0xFF98A2B3),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'DEL-2048',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF101828),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F6FB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.call_rounded,
                              size: 18,
                              color: Color(0xFF1F88C9),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Call',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFF1F88C9),
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showEmergencyAssistance(context),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F6FB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Icon(
                          Icons.more_vert_rounded,
                          color: Color(0xFF101828),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: _DriverDeliveryMapBackdrop(),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.10),
                                Colors.white.withValues(alpha: 0.36),
                                Colors.white.withValues(alpha: 0.82),
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _showArrivalSwipe
                              ? Container(
                                  key: const ValueKey('arrival-swipe'),
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Current status',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: const Color(
                                                        0xFF98A2B3,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Arrived',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      color: const Color(
                                                        0xFF101828,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEAF7EF),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: const Text(
                                              'Ready',
                                              style: TextStyle(
                                                color: Color(0xFF2FA56E),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      const Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: Color(0xFFE8EDF2),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        'Swipe to continue',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: const Color(0xFF101828),
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'The on-route card is hidden now. Swipe to open photo upload.',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: const Color(0xFF667085),
                                              height: 1.4,
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 92,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SliderTheme(
                                              data: SliderTheme.of(context).copyWith(
                                                trackHeight: 52,
                                                trackShape:
                                                    const RoundedRectSliderTrackShape(),
                                                thumbShape:
                                                    const _ArrivalThumbShape(),
                                                overlayShape:
                                                    const RoundSliderOverlayShape(
                                                      overlayRadius: 0,
                                                    ),
                                                activeTrackColor: const Color(
                                                  0xFFE5E7EB,
                                                ),
                                                inactiveTrackColor: const Color(
                                                  0xFFE5E7EB,
                                                ),
                                                thumbColor: Colors.white,
                                                overlayColor:
                                                    Colors.transparent,
                                                trackGap: 6,
                                              ),
                                              child: Slider(
                                                value: _arrivalSlide,
                                                onChanged: (value) {
                                                  setState(
                                                    () => _arrivalSlide = value,
                                                  );
                                                  if (value >= 0.98) {
                                                    Future.delayed(
                                                      const Duration(
                                                        milliseconds: 350,
                                                      ),
                                                      () {
                                                        if (!context.mounted) {
                                                          return;
                                                        }
                                                        context.push(
                                                          '/driver/delivery-proof/${widget.tripId}?payment=pending',
                                                        );
                                                        setState(
                                                          () =>
                                                              _arrivalSlide = 0,
                                                        );
                                                      },
                                                    );
                                                  }
                                                },
                                                min: 0,
                                                max: 1,
                                                divisions: 100,
                                              ),
                                            ),
                                            IgnorePointer(
                                              child: AnimatedOpacity(
                                                opacity:
                                                    (1 - (_arrivalSlide * 1.7))
                                                        .clamp(0.18, 1.0),
                                                duration: const Duration(
                                                  milliseconds: 90,
                                                ),
                                                child: Text(
                                                  'Swipe to continue',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        color: const Color(
                                                          0xFF6B7280,
                                                        ),
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  key: const ValueKey('on-route-card'),
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Current status',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: const Color(
                                                        0xFF98A2B3,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'On route',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      color: const Color(
                                                        0xFF101828,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEAF7EF),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: const Text(
                                              'Active',
                                              style: TextStyle(
                                                color: Color(0xFF2FA56E),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      const Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: Color(0xFFE8EDF2),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        'Customer details',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: const Color(0xFF101828),
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      const SizedBox(height: 12),
                                      _DetailRow(
                                        label: 'Customer',
                                        value: 'Rahul Sharma',
                                      ),
                                      const SizedBox(height: 10),
                                      _DetailRow(
                                        label: 'Phone',
                                        value: '+91 98765 43210',
                                      ),
                                      const SizedBox(height: 10),
                                      _DetailRow(
                                        label: 'Address',
                                        value:
                                            'Sector 137, Noida, Uttar Pradesh 201305',
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF7FAFD),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFE8EDF2),
                                          ),
                                        ),
                                        child: Text(
                                          'Swipe control will appear automatically after 2 seconds.',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: const Color(0xFF667085),
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF98A2B3),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF101828),
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _ArrivalThumbShape extends SliderComponentShape {
  const _ArrivalThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(56, 56);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..isAntiAlias = true
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final fillPaint = Paint()
      ..color = Colors.white
      ..isAntiAlias = true;
    final borderPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center + const Offset(0, 1.5), 22, shadowPaint);
    canvas.drawCircle(center, 22, fillPaint);
    canvas.drawCircle(center, 22, borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.chevron_right_rounded.codePoint),
        style: TextStyle(
          color: const Color(0xFF2FA56E),
          fontSize: 28,
          fontWeight: FontWeight.w800,
          fontFamily: Icons.chevron_right_rounded.fontFamily,
          package: Icons.chevron_right_rounded.fontPackage,
          height: 1,
        ),
      ),
      textDirection: textDirection,
      textAlign: TextAlign.center,
    )..layout();

    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2 + 1),
    );
  }
}

class _IncidentReportDialog extends ConsumerStatefulWidget {
  const _IncidentReportDialog({
    required this.parentContext,
    required this.tripId,
  });

  final BuildContext parentContext;
  final String tripId;

  @override
  ConsumerState<_IncidentReportDialog> createState() =>
      _IncidentReportDialogState();
}

class _IncidentReportDialogState extends ConsumerState<_IncidentReportDialog> {
  static const _incidentTypes = <_IncidentTypeOption>[
    _IncidentTypeOption(
      label: 'Accident',
      icon: Icons.warning_amber_rounded,
      accent: Color(0xFFE08A1E),
      background: Color(0xFFFFF7EA),
    ),
    _IncidentTypeOption(
      label: 'Breakdown',
      icon: Icons.build_rounded,
      accent: Color(0xFF7B8DA6),
      background: Color(0xFFF5F7FA),
    ),
    _IncidentTypeOption(
      label: 'Traffic Block',
      icon: Icons.traffic_rounded,
      accent: Color(0xFF7A5AF8),
      background: Color(0xFFF3EEFF),
    ),
    _IncidentTypeOption(
      label: 'Medical',
      icon: Icons.favorite_border_rounded,
      accent: Color(0xFFE35A62),
      background: Color(0xFFFFF1F2),
    ),
    _IncidentTypeOption(
      label: 'Other',
      icon: Icons.chat_bubble_outline_rounded,
      accent: Color(0xFF7B8DA6),
      background: Color(0xFFF5F7FA),
    ),
  ];

  late String _selectedType;
  late final TextEditingController _detailsController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedType = _incidentTypes.first.label;
    _detailsController = TextEditingController();
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        const SnackBar(
          content: Text('Please log in again to report the issue.'),
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(widget.parentContext);
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(apiClientProvider)
          .reportTripIssue(
            accessToken: session.tokens.accessToken,
            tripId: widget.tripId,
            reason: _incidentReasonFor(_selectedType),
            notes: _detailsController.text.trim(),
          );

      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('$_selectedType report submitted to support.'),
          backgroundColor: const Color(0xFF2FA56E),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4D9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.report_gmailerrorred_outlined,
                        color: Color(0xFFE2A22F),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Report Incident',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF101828),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xFF98A2B3),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'What\'s going on? Your broker and the client will be notified right away.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667085),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: _incidentTypes.map((option) {
                    return _IncidentTypeChip(
                      option: option,
                      selected: _selectedType == option.label,
                      onTap: () => setState(() => _selectedType = option.label),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _detailsController,
                  maxLines: 4,
                  minLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Add any details (optional)',
                    hintStyle: const TextStyle(
                      color: Color(0xFFB0B7C3),
                      fontWeight: FontWeight.w600,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFE6EBF2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFE6EBF2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2A22F),
                        width: 1.4,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5C86E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _isSubmitting
                          ? const SizedBox(
                              key: ValueKey('submit-loading'),
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Submit Report',
                              key: ValueKey('submit-label'),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
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

class _IncidentTypeOption {
  const _IncidentTypeOption({
    required this.label,
    required this.icon,
    required this.accent,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final Color background;
}

String _incidentReasonFor(String label) {
  return switch (label) {
    'Accident' => 'accident',
    'Breakdown' => 'breakdown',
    'Traffic Block' => 'traffic_block',
    'Medical' => 'medical',
    _ => 'other',
  };
}

class _IncidentTypeChip extends StatelessWidget {
  const _IncidentTypeChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _IncidentTypeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? option.background : const Color(0xFFF8FAFD),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 125,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? option.accent : const Color(0xFFF0F2F6),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(option.icon, color: option.accent, size: 22),
              const SizedBox(height: 6),
              Text(
                option.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF667085),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyAssistanceTile extends StatelessWidget {
  const _EmergencyAssistanceTile({
    required this.backgroundColor,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF101828),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF667085),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriverDeliveryMapBackdrop extends StatelessWidget {
  const _DriverDeliveryMapBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DriverDeliveryMapPainter(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4F7FC), Color(0xFFE7EEF7)],
          ),
        ),
      ),
    );
  }
}

class _DriverDeliveryMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFFD6DDE8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final accentPaint = Paint()
      ..color = const Color(0xFFC9D4E3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final nodePaint = Paint()..color = const Color(0xFFF9FBFD);
    final nodeBorderPaint = Paint()
      ..color = const Color(0xFFD8E2EF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFF4F7FC),
    );

    final paths = [
      Path()
        ..moveTo(size.width * 0.08, size.height * 0.18)
        ..quadraticBezierTo(
          size.width * 0.38,
          size.height * 0.10,
          size.width * 0.63,
          size.height * 0.24,
        )
        ..quadraticBezierTo(
          size.width * 0.82,
          size.height * 0.34,
          size.width * 0.95,
          size.height * 0.21,
        ),
      Path()
        ..moveTo(size.width * 0.06, size.height * 0.44)
        ..quadraticBezierTo(
          size.width * 0.30,
          size.height * 0.38,
          size.width * 0.50,
          size.height * 0.50,
        )
        ..quadraticBezierTo(
          size.width * 0.74,
          size.height * 0.62,
          size.width * 0.98,
          size.height * 0.56,
        ),
      Path()
        ..moveTo(size.width * 0.14, size.height * 0.75)
        ..quadraticBezierTo(
          size.width * 0.38,
          size.height * 0.65,
          size.width * 0.59,
          size.height * 0.77,
        )
        ..quadraticBezierTo(
          size.width * 0.78,
          size.height * 0.86,
          size.width * 0.94,
          size.height * 0.79,
        ),
    ];

    for (final path in paths) {
      canvas.drawPath(path, roadPaint);
      canvas.drawPath(path, accentPaint);
    }

    final nodes = [
      Offset(size.width * 0.18, size.height * 0.24),
      Offset(size.width * 0.46, size.height * 0.33),
      Offset(size.width * 0.72, size.height * 0.27),
      Offset(size.width * 0.28, size.height * 0.58),
      Offset(size.width * 0.63, size.height * 0.66),
      Offset(size.width * 0.84, size.height * 0.82),
    ];

    for (final node in nodes) {
      canvas.drawCircle(node, 11, nodePaint);
      canvas.drawCircle(node, 11, nodeBorderPaint);
      canvas.drawCircle(node, 3.5, Paint()..color = const Color(0xFF2FA56E));
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFE6ECF4)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.12 + i * 0.18);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
