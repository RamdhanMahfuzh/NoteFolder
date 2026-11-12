import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:notefolder/core/themes/app_colors.dart';
import 'package:notefolder/presentation/bloc/note_bloc.dart';
import 'package:notefolder/presentation/bloc/note_event.dart';
import 'package:notefolder/presentation/widgets/pin_input.dart';

class PinPage extends StatefulWidget {
  const PinPage({super.key, required this.noteId});

  final String noteId;

  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  final _localAuth = LocalAuthentication();
  String _pin = '';
  bool _authenticating = false;

  Future<void> _unlockWithFingerprint() async {
    setState(() => _authenticating = true);
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint to unlock this note',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (authenticated && mounted) context.pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fingerprint authentication failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _authenticating = false);
    }
  }

  void _submit() {
    if (_pin.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PIN must be 6 digits')));
      return;
    }
    context.pop(_pin);
  }

  Future<void> _forgotPin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forgot PIN?'),
        content: const Text(
          'This will permanently delete the locked note. This cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete note'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<NoteBloc>().add(DeleteNoteEvent(widget.noteId));
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter PIN')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64),
              const SizedBox(height: 16),
              const Text('This note is locked'),
              const SizedBox(height: 24),
              PinInput(onChanged: (pin) => setState(() => _pin = pin)),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _forgotPin,
                child: const Text('Forgot PIN? Delete this note'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.primary, AppColors.secondary],
                          ),
                        ),
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _submit,
                          child: const Text(
                            'Unlock',
                            style: TextStyle(color: AppColors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: IconButton(
                      onPressed: _authenticating
                          ? null
                          : _unlockWithFingerprint,
                      tooltip: 'Unlock with fingerprint',
                      style: IconButton.styleFrom(
                        shape: const CircleBorder(),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      icon: _authenticating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.fingerprint, size: 28),
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
