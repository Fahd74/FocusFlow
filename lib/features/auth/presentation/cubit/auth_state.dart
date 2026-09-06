part of 'auth_cubit.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final User user;

  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  final String? guestName;
  final String? guestFirstName;
  final String? guestLastName;
  final String? guestEmail;

  const AuthUnauthenticated({
    this.guestName,
    this.guestFirstName,
    this.guestLastName,
    this.guestEmail,
  });

  @override
  List<Object> get props => [
        guestName ?? '',
        guestFirstName ?? '',
        guestLastName ?? '',
        guestEmail ?? '',
      ];
}

class AuthGuest extends AuthState {
  final String? guestName;
  final String? guestFirstName;
  final String? guestLastName;
  final String? guestEmail;

  const AuthGuest({
    this.guestName,
    this.guestFirstName,
    this.guestLastName,
    this.guestEmail,
  });

  @override
  List<Object> get props => [
        guestName ?? '',
        guestFirstName ?? '',
        guestLastName ?? '',
        guestEmail ?? '',
      ];
}

class AuthEmailConfirmationRequired extends AuthState {}

class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
