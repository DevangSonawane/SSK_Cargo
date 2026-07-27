import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/google_places_provider.dart';
import '../../../../core/services/google_places_service.dart';

class GooglePlacesAutocompleteField extends ConsumerStatefulWidget {
  const GooglePlacesAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.onSelected,
    this.initialValue,
    this.embedded = false,
    this.showLabel = true,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final ValueChanged<GooglePlaceSelection> onSelected;
  final String? initialValue;
  final bool embedded;
  final bool showLabel;

  @override
  ConsumerState<GooglePlacesAutocompleteField> createState() =>
      _GooglePlacesAutocompleteFieldState();
}

class _GooglePlacesAutocompleteFieldState
    extends ConsumerState<GooglePlacesAutocompleteField> {
  final FocusNode _focusNode = FocusNode();
  final Random _random = Random();
  Timer? _debounce;
  String _sessionToken = '';
  bool _loading = false;
  bool _selectingSuggestion = false;
  String? _errorMessage;
  List<GooglePlaceSuggestion> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    _sessionToken = _newSessionToken();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    if (widget.initialValue != null && widget.controller.text.isEmpty) {
      widget.controller.text = widget.initialValue!;
    }
  }

  @override
  void didUpdateWidget(covariant GooglePlacesAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
    if (oldWidget.initialValue != widget.initialValue &&
        widget.initialValue != null &&
        widget.controller.text.isEmpty) {
      widget.controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_selectingSuggestion) {
      return;
    }
    if (_focusNode.hasFocus && widget.controller.text.trim().isNotEmpty) {
      _scheduleSearch();
      return;
    }
    if (!_focusNode.hasFocus) {
      setState(() {
        _suggestions = const [];
      });
    }
  }

  void _onTextChanged() {
    if (_selectingSuggestion) {
      return;
    }
    if (!_focusNode.hasFocus) {
      return;
    }
    final text = widget.controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _suggestions = const [];
        _errorMessage = null;
      });
      _sessionToken = _newSessionToken();
      return;
    }
    _scheduleSearch();
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _search);
  }

  Future<void> _search() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(googlePlacesServiceProvider);
      final suggestions = await service.autocomplete(
        input: text,
        sessionToken: _sessionToken,
      );
      if (!mounted) return;
      setState(() {
        _suggestions = suggestions;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _suggestions = const [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _selectSuggestion(GooglePlaceSuggestion suggestion) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _selectingSuggestion = true;
      _suggestions = const [];
    });

    try {
      FocusManager.instance.primaryFocus?.unfocus();
      final service = ref.read(googlePlacesServiceProvider);
      final selection = await service.fetchPlaceSelection(
        placeId: suggestion.placeId,
      );
      if (!mounted) return;
      widget.controller
        ..text = selection.formattedAddress.isNotEmpty
            ? selection.formattedAddress
            : suggestion.description
        ..selection = TextSelection.collapsed(
          offset: widget.controller.text.length,
        );
      widget.onSelected(
        GooglePlaceSelection(
          placeId: selection.placeId,
          formattedAddress: widget.controller.text,
          latitude: selection.latitude,
          longitude: selection.longitude,
        ),
      );
      setState(() {
        _sessionToken = _newSessionToken();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _selectingSuggestion = false;
        });
      }
    }
  }

  String _newSessionToken() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final randomPart = _random.nextInt(1 << 32).toRadixString(36);
    return '$timestamp$randomPart'.substring(0, min(36, timestamp.length + randomPart.length));
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          if (widget.showLabel) ...[
            Text(
              widget.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF667085),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: InputBorder.none,
              isDense: true,
              suffixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.place_outlined, size: 18),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              'Could not load suggestions',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFFB42318),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            ..._suggestions.asMap().entries.map(
              (entry) => Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == _suggestions.length - 1 ? 0 : 8,
                ),
                child: _SuggestionTile(
                  suggestion: entry.value,
                  onTap: () => _selectSuggestion(entry.value),
                ),
              ),
            ),
          ],
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: content,
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.suggestion,
    required this.onTap,
  });

  final GooglePlaceSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => onTap(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF2FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: Color(0xFF1F88C9),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.mainText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF101828),
                      ),
                    ),
                    if (suggestion.secondaryText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        suggestion.secondaryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF667085),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (suggestion.distanceMeters != null) ...[
                const SizedBox(width: 10),
                Text(
                  '${(suggestion.distanceMeters! / 1000).toStringAsFixed(suggestion.distanceMeters! >= 1000 ? 1 : 0)} km',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF667085),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
