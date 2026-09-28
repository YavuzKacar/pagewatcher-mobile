import 'package:flutter/material.dart';

import '../l10n.dart';
import '../network/api_error.dart';
import '../theme/colors.dart';

/// User-facing text for any error thrown by a repository call.
String describeError(BuildContext context, Object error) {
  final l10n = context.l10n;
  if (error is ApiException) {
    if (error.isNetworkError) return l10n.mobileErrorsNetwork;
    if (error.detail != null && error.detail!.isNotEmpty) return error.detail!;
  }
  return l10n.authModalErrorsGeneric;
}

void showErrorSnackBar(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(describeError(context, error)), backgroundColor: AppColors.danger),
    );
}

void showInfoSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
