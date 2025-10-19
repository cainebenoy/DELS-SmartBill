import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';

/// A minimal AuthGate that, when wired, can control access based on Supabase session.
/// Not enabled by default to avoid impacting current app flow and tests.
class AuthGate extends StatefulWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Session? _session;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await SupabaseInit.ensureInitialized();
    if (Supabase.instance.client.auth.currentSession != null) {
      _session = Supabase.instance.client.auth.currentSession;
    }
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_session != null) {
      return widget.child;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You are not signed in.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await SupabaseInit.ensureInitialized();
                if (!context.mounted) return;
                // Placeholder: implement Google sign-in later.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Auth not yet wired.')),
                );
              },
              child: const Text('Sign in with Google'),
            ),
          ],
        ),
      ),
    );
  }
}
