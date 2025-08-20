import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth_cubit.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSignUp = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _isSignUp = _tabController.index == 1;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    print('[AuthScreen] _submitForm called');
    final currentFormKey = _isSignUp ? _signUpFormKey : _signInFormKey;
    if (currentFormKey.currentState!.validate()) {
      print('[AuthScreen] Form validation passed, calling auth method');
      final authCubit = context.read<AuthCubit>();

      if (_isSignUp) {
        print('[AuthScreen] Calling signUp');
        authCubit.signUp(_emailController.text, _passwordController.text);
      } else {
        print('[AuthScreen] Calling signIn');
        authCubit.signIn(_emailController.text, _passwordController.text);
      }
    } else {
      print('[AuthScreen] Form validation failed');
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffix,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: colors.tertiary),
      suffixIcon: suffix,
      filled: true,
      fillColor: colors.surfaceVariant.withOpacity(0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.secondary, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.secondary, width: 2),
      ),
      floatingLabelStyle: TextStyle(
        color: colors.secondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    print('[AuthScreen] build() method called');
    
    // Check if we can access the AuthCubit
    try {
      final authCubit = context.read<AuthCubit>();
      print('[AuthScreen] AuthCubit found: ${authCubit.state}');
    } catch (e) {
      print('[AuthScreen] ERROR: Could not access AuthCubit: $e');
    }

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        print('[AuthScreen] Main build called with state: $state');
        
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.primaryContainer],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Main content
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                      child: Card(
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline, size: 64, color: colors.primary),
                              const SizedBox(height: 16),
                              Text(
                                'Habits & Notes',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colors.primary,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sign in to continue or create a new account',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: colors.onSurface.withOpacity(0.7),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              TabBar(
                                controller: _tabController,
                                tabs: const [
                                  Tab(text: 'Sign In'),
                                  Tab(text: 'Sign Up'),
                                ],
                                labelColor: colors.primary,
                                unselectedLabelColor: colors.onSurface.withOpacity(0.5),
                                indicatorColor: colors.primary,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 380,
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildSignInForm(),
                                    _buildSignUpForm(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Error handler overlay - always listening for auth errors
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _AuthErrorHandler(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignInForm() {
    return Form(
      key: _signInFormKey,
      child: Column(
        children: [
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: _inputDecoration(
              label: 'Email',
              icon: Icons.email,
              hint: 'you@example.com',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Please enter your email' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: !_passwordVisible,
            decoration: _inputDecoration(
              label: 'Password',
              icon: Icons.lock,
              suffix: IconButton(
                icon: Icon(
                  _passwordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
              ),
            ),
            validator: (value) =>
                (value == null || value.length < 6) ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 20),
          _authButton('Sign In'),
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Form(
      key: _signUpFormKey,
      child: Column(
        children: [
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: _inputDecoration(
              label: 'Email',
              icon: Icons.email,
              hint: 'you@example.com',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Please enter your email' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: !_passwordVisible,
            decoration: _inputDecoration(
              label: 'Password',
              icon: Icons.lock,
              suffix: IconButton(
                icon: Icon(
                  _passwordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
              ),
            ),
            validator: (value) =>
                (value == null || value.length < 6) ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_confirmPasswordVisible,
            decoration: _inputDecoration(
              label: 'Confirm Password',
              icon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
              ),
            ),
            validator: (value) =>
                value != _passwordController.text ? 'Passwords don\'t match' : null,
          ),
          const SizedBox(height: 20),
          _authButton('Sign Up'),
        ],
      ),
    );
  }

  Widget _authButton(String text) {
    final colors = Theme.of(context).colorScheme;
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        print('[AuthScreen] Button BlocBuilder called with state: $state');
        final isLoading = state is AuthLoading;
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onSecondary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}

/// Dedicated widget to handle authentication errors with proper UX
class _AuthErrorHandler extends StatefulWidget {
  const _AuthErrorHandler();

  @override
  State<_AuthErrorHandler> createState() => _AuthErrorHandlerState();
}

class _AuthErrorHandlerState extends State<_AuthErrorHandler> {
  String? _currentError;
  bool _isVisible = false;

  _AuthErrorHandlerState() {
    print('[AuthErrorHandler] Constructor called');
  }

  @override
  void initState() {
    super.initState();
    print('[AuthErrorHandler] initState called');
    // Check for existing error state when widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[AuthErrorHandler] PostFrameCallback executing');
      _checkForExistingError();
    });
  }

  void _checkForExistingError() {
    final authCubit = context.read<AuthCubit>();
    final currentState = authCubit.state;
    
    if (currentState is AuthError) {
      print('[AuthErrorHandler] Found existing error state: ${currentState.message}');
      _showError(currentState.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        print('[AuthErrorHandler] BlocListener called with state: $state');
        
        if (state is AuthError) {
          print('[AuthErrorHandler] Showing error: ${state.message}');
          _showError(state.message);
        } else if (state is AuthLoading) {
          print('[AuthErrorHandler] Hiding error due to loading');
          _hideError();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: _isVisible ? 60 : 0,
        margin: const EdgeInsets.all(16),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _isVisible ? 1.0 : 0.0,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onError,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _currentError ?? '',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onError,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onError,
                    size: 20,
                  ),
                  onPressed: _hideError,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    print('[AuthErrorHandler] _showError called with: $message');
    if (_currentError != message) {
      setState(() {
        _currentError = message;
        _isVisible = true;
      });
      
      // Auto-hide after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _currentError == message) {
          _hideError();
        }
      });
    }
  }

  void _hideError() {
    print('[AuthErrorHandler] _hideError called');
    if (mounted) {
      setState(() {
        _isVisible = false;
      });
      
      // Clear error after animation
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _currentError = null;
          });
        }
      });
    }
  }
}
