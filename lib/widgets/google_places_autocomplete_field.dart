import 'dart:async';

import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/constants/decoration_constant.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/services/google_places_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GooglePlacesAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<GooglePlaceDetails>? onSelected;
  final ValueChanged<String>? onTextChanged;
  final bool showKeySourceInfo;

  const GooglePlacesAutocompleteField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.validator,
    this.onSelected,
    this.onTextChanged,
    this.showKeySourceInfo = true,
  });

  @override
  State<GooglePlacesAutocompleteField> createState() =>
      _GooglePlacesAutocompleteFieldState();
}

class _GooglePlacesAutocompleteFieldState
    extends State<GooglePlacesAutocompleteField> {
  static const Duration _debounceDuration = Duration(milliseconds: 350);

  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  List<GooglePlacePrediction> _predictions = const [];
  bool _isLoading = false;
  String? _queryErrorMessage;
  String _activeKeySourceLabel = 'checking...';
  int _requestCounter = 0;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    if (kDebugMode) {
      unawaited(_refreshActiveKeySource());
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _focusNode.hasFocus) return;

      setState(() {
        _predictions = const [];
        _isLoading = false;
        _queryErrorMessage = null;
      });
    });
  }

  void _queueSearch(String input) {
    widget.onTextChanged?.call(input);

    _debounceTimer?.cancel();

    final query = input.trim();
    if (query.length < 2) {
      if (mounted) {
        setState(() {
          _predictions = const [];
          _isLoading = false;
          _queryErrorMessage = null;
        });
      }
      return;
    }

    _debounceTimer = Timer(_debounceDuration, () async {
      final requestId = ++_requestCounter;

      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _queryErrorMessage = null;
      });

      try {
        final results = await GooglePlacesService.autocomplete(query);

        if (!mounted || requestId != _requestCounter) return;

        setState(() {
          _predictions = results;
          _isLoading = false;
          _queryErrorMessage = null;
        });
      } on GooglePlacesException catch (e) {
        if (!mounted || requestId != _requestCounter) return;

        setState(() {
          _predictions = const [];
          _isLoading = false;
          _queryErrorMessage = e.userMessage;
        });
      } catch (_) {
        if (!mounted || requestId != _requestCounter) return;

        setState(() {
          _predictions = const [];
          _isLoading = false;
          _queryErrorMessage =
              'Autocomplete gagal. Cek koneksi internet lalu coba lagi.';
        });
      }
    });
  }

  Future<void> _refreshActiveKeySource() async {
    final label = await GooglePlacesService.getActiveKeySourceLabel();
    if (!mounted) return;
    setState(() {
      _activeKeySourceLabel = label;
    });
  }

  void _selectPrediction(GooglePlacePrediction prediction) {
    _applySelection(prediction);
  }

  Future<void> _applySelection(GooglePlacePrediction prediction) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _queryErrorMessage = null;
    });

    GooglePlaceDetails canonicalDetails;
    try {
      final details = await GooglePlacesService.placeDetails(
        prediction.placeId,
      );
      canonicalDetails =
          details ??
          GooglePlaceDetails(
            placeId: prediction.placeId,
            description: prediction.description,
            formattedAddress: prediction.description,
            name: prediction.mainText,
          );
    } on GooglePlacesException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _queryErrorMessage = e.userMessage;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _queryErrorMessage = 'Gagal mengambil detail lokasi. Coba pilih lagi.';
      });
      return;
    }

    if (!mounted) return;

    final selectedPlaceName = canonicalDetails.name?.trim().isNotEmpty ?? false
        ? canonicalDetails.name!.trim()
        : canonicalDetails.description.trim();

    widget.controller.text = selectedPlaceName;
    widget.controller.selection = TextSelection.collapsed(
      offset: selectedPlaceName.length,
    );
    widget.onSelected?.call(canonicalDetails);

    setState(() {
      _predictions = const [];
      _isLoading = false;
      _queryErrorMessage = null;
    });

    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final hasSuggestions = _predictions.isNotEmpty;
    final suggestions = _predictions.take(5).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.labelText, style: styleText()),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          style: TextStyle(color: AppTheme.secondary, fontSize: 12),
          validator: widget.validator,
          onChanged: _queueSearch,
          decoration: decorationConstant(hintText: widget.hintText).copyWith(
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : widget.controller.text.trim().isEmpty
                ? const Icon(Icons.place_outlined)
                : IconButton(
                    onPressed: () {
                      widget.controller.clear();
                      widget.onTextChanged?.call('');
                      if (mounted) {
                        setState(() {
                          _predictions = const [];
                          _isLoading = false;
                          _queryErrorMessage = null;
                        });
                      }
                    },
                    icon: const Icon(Icons.clear),
                  ),
          ),
        ),
        if (_queryErrorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _queryErrorMessage!,
              style: const TextStyle(color: AppTheme.fourth, fontSize: 11.5),
            ),
          ),
        if (kDebugMode && widget.showKeySourceInfo)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'source key aktif: $_activeKeySourceLabel',
              style: TextStyle(
                color: AppTheme.secondary.withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (hasSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF171A33),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.third.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.third.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < suggestions.length; i++) ...[
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(
                      suggestions[i].mainText ?? suggestions[i].description,
                      style: styleText().copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: suggestions[i].secondaryText == null
                        ? null
                        : Text(
                            suggestions[i].secondaryText!,
                            style: styleText().copyWith(fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                    onTap: () => _selectPrediction(suggestions[i]),
                  ),
                  if (i < suggestions.length - 1)
                    Divider(
                      height: 1,
                      color: AppTheme.secondary.withOpacity(0.08),
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
