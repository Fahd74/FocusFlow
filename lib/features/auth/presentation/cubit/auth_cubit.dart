import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/domain/services/fcm_service.dart';

part 'auth_state.dart';

bool _isSupabaseInitialized() {
  try {
    Supabase.instance;
    return true;
  } catch (_) {
    return false;
  }
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({SupabaseClient? supabaseClient}) : super(AuthInitial()) {
    _supabaseClient = supabaseClient;
    _initAuthListener();
  }

  late final SupabaseClient? _supabaseClient;

  SupabaseClient get _supabase {
    if (_supabaseClient != null) return _supabaseClient;
    if (_isSupabaseInitialized()) return Supabase.instance.client;
    throw StateError('Supabase has not been initialized.');
  }

  StreamSubscription<AuthState>? _authSubscription;
  bool _isGuestMode = false;

  void _initAuthListener() {
    if (!_isSupabaseInitialized() && _supabaseClient == null) {
      emit(AuthUnauthenticated());
      return;
    }
    _authSubscription =
        _supabase.auth.onAuthStateChange.map<AuthState>((data) {
      final session = data.session;
      if (session != null) {
        _isGuestMode = false;
        return AuthAuthenticated(session.user);
      } else {
        if (_isGuestMode) {
          return const AuthGuest();
        }
        return AuthUnauthenticated();
      }
    }).listen((authState) {
      if (!isClosed) {
        emit(authState);
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    try {
      emit(AuthLoading());
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // The listener will emit AuthAuthenticated
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signUp(String email, String password, String fullName) async {
    try {
      emit(AuthLoading());
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      if (response.session == null) {
        emit(AuthEmailConfirmationRequired());
      }
      // The listener will emit AuthAuthenticated if auto-login occurs
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() async {
    try {
      emit(AuthLoading());
      _isGuestMode = false;
      if (!kIsWeb && Platform.isAndroid) {
        await FcmService.instance.clearFcmToken();
      }
      await _supabase.auth.signOut();
      // The listener will emit AuthUnauthenticated
    } catch (e) {
      emit(AuthError(e.toString()));
      // C2 fix: safely handle null currentUser instead of force-unwrapping
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        emit(AuthAuthenticated(currentUser));
      } else {
        emit(AuthUnauthenticated());
      }
    }
  }

  Future<bool> resetPassword(String email, {String? redirectTo}) async {
    try {
      emit(AuthLoading());
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectTo,
      );
      emit(AuthUnauthenticated());
      return true;
    } catch (e) {
      emit(AuthError(e.toString()));
      return false;
    }
  }

  Future<void> refreshUser() async {
    try {
      final response = await _supabase.auth.getUser();
      final user = response.user;
      if (user != null) {
        emit(AuthAuthenticated(user));
      }
    } catch (e) {
      // Ignore network errors on refresh
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        emit(AuthAuthenticated(currentUser));
      } else {
        emit(AuthUnauthenticated());
      }
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String displayName,
    String? avatarType,
    String? avatarUrl,
    String? avatarAsset,
  }) async {
    try {
      final Map<String, dynamic> metadata = {
        'full_name': displayName,
        'first_name': firstName,
        'last_name': lastName,
      };
      if (avatarType != null) {
        metadata['avatar_type'] = avatarType;
        metadata['avatar_url'] = avatarUrl;
        metadata['avatar_asset'] = avatarAsset;
      }

      await _supabase.auth.updateUser(
        UserAttributes(data: metadata),
      );

      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        final Map<String, dynamic> dbPayload = {
          'id': currentUser.id,
          'full_name': displayName,
          'first_name': firstName,
          'last_name': lastName,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };
        if (avatarType != null) {
          dbPayload['avatar_type'] = avatarType;
          dbPayload['avatar_url'] = avatarUrl;
          dbPayload['avatar_asset'] = avatarAsset;
        }
        await _supabase.from('users').upsert(dbPayload);
        emit(AuthAuthenticated(currentUser));
      } else {
        emit(AuthUnauthenticated());
      }
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateAvatar({
    required String avatarType,
    String? avatarUrl,
    String? avatarAsset,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;
      await _supabase.from('users').upsert({
        'id': currentUser.id,
        'avatar_type': avatarType,
        'avatar_url': avatarUrl,
        'avatar_asset': avatarAsset,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      return true;
    } catch (e) {
      rethrow;
    }
  }

  void updateGuestProfile({
    required String firstName,
    required String lastName,
    required String displayName,
    required String email,
  }) {
    _isGuestMode = true;
    emit(AuthGuest(
      guestName: displayName,
      guestFirstName: firstName,
      guestLastName: lastName,
      guestEmail: email,
    ));
  }

  void continueAsGuest() {
    _isGuestMode = true;
    emit(const AuthGuest());
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
