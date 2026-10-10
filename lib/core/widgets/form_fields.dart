import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';

/// A labelled text field with the label above it, like the website's forms.
class LabeledField extends StatefulWidget {
  const LabeledField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.optional = false,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.errorText,
    this.readOnly = false,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final bool optional;
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final String? errorText;
  final bool readOnly;
  final ValueChanged<String>? onSubmitted;

  @override
  State<LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<LabeledField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: widget.label,
            style: context.text.labelLarge,
            children: [
              if (widget.optional)
                TextSpan(text: ' (optional)', style: TextStyle(color: p.mutedForeground, fontWeight: FontWeight.w400))
              else if (!widget.readOnly)
                TextSpan(text: ' *', style: TextStyle(color: p.destructive)),
            ],
          ),
        ),
        if (widget.helper != null) ...[
          const SizedBox(height: 2),
          Text(widget.helper!, style: context.text.bodySmall),
        ],
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.obscure && _hidden,
          keyboardType: widget.keyboardType,
          autofillHints: widget.autofillHints,
          textInputAction: widget.textInputAction,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          readOnly: widget.readOnly,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator ??
              (widget.optional || widget.readOnly
                  ? null
                  : (v) => (v == null || v.trim().isEmpty) ? 'Enter ${widget.label.toLowerCase()}.' : null),
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            errorMaxLines: 3,
            counterText: '',
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _hidden ? 'Show password' : 'Hide password',
                    icon: Icon(_hidden ? LucideIcons.eye : LucideIcons.eyeOff, size: 18),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.optional = false,
    this.hint,
  });

  final String label;
  final T? value;
  final List<(T, String)> items;
  final ValueChanged<T?> onChanged;
  final bool optional;
  final String? hint;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(
            text: label,
            style: context.text.labelLarge,
            children: [
              if (optional)
                TextSpan(
                  text: ' (optional)',
                  style: TextStyle(color: context.palette.mutedForeground, fontWeight: FontWeight.w400),
                )
              else
                TextSpan(text: ' *', style: TextStyle(color: context.palette.destructive)),
            ],
          )),
          const SizedBox(height: 8),
          DropdownButtonFormField<T>(
            initialValue: value,
            isExpanded: true,
            hint: hint == null ? null : Text(hint!),
            items: [
              for (final (v, text) in items)
                DropdownMenuItem(value: v, child: Text(text, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: onChanged,
            validator: optional ? null : (v) => v == null ? 'Choose ${label.toLowerCase()}.' : null,
          ),
        ],
      );
}

/// The consent checkbox the backend requires on public forms.
class ConsentField extends FormField<bool> {
  ConsentField({super.key, required String text})
      : super(
          initialValue: false,
          validator: (v) => v == true ? null : 'Please confirm to continue.',
          builder: (state) {
            final context = state.context;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => state.didChange(!(state.value ?? false)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(value: state.value, onChanged: state.didChange),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(text, style: context.text.bodySmall?.copyWith(height: 1.4)),
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      state.errorText!,
                      style: context.text.bodySmall?.copyWith(color: context.palette.destructive),
                    ),
                  ),
              ],
            );
          },
        );
}

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(String? v) {
  if (v == null || v.trim().isEmpty) return 'Enter your email.';
  return _emailPattern.hasMatch(v.trim()) ? null : 'Enter a valid email, like name@example.com.';
}

String? validateNewPassword(String? v) {
  if (v == null || v.isEmpty) return 'Enter a password.';
  if (v.length < 8) return 'Use at least 8 characters.';
  if (RegExp(r'^\d+$').hasMatch(v)) return "A password can't be only numbers.";
  return null;
}
