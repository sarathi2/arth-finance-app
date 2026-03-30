  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    bool success;

    if (_isLogin) {
      success = await auth.signInWithEmail(email, password);
    } else {
      success = await auth.registerWithEmail(email, password);
    }

    if (success && mounted) {
      // 🔥 NEW: Check where they should go!
      if (auth.needsProfileSetup) {
        Navigator.pushReplacementNamed(context, '/profile-setup');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }