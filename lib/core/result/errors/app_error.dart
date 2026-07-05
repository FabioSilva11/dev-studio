import 'package:flutter/services.dart';

import 'app_error_code.dart';

class AppError {
  const AppError({
    required this.code,
    required this.message,
    this.cause,
  });

  final AppErrorCode code;
  final String message;
  final Object? cause;

  factory AppError.fromException(Object error) {
    if (error is PlatformException) {
      return AppError(
        code: error.code == 'storage_permission_required'
            ? AppErrorCode.storagePermissionRequired
            : AppErrorCode.platformFailure,
        message: error.message ?? error.code,
        cause: error,
      );
    }

    return AppError(
      code: AppErrorCode.unknown,
      message: error.toString(),
      cause: error,
    );
  }
}
