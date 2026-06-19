/// Representación de fallos de dominio/UI.
sealed class Failure {
  const Failure(this.message);
  final String message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Error de conexión. Verifique su red.']);
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Sesión expirada o no autorizada.']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Ocurrió un error inesperado.']);
}
