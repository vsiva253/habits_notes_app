import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'logic/auth_cubit.dart';
import 'logic/habits_cubit.dart';
import 'logic/notes_cubit.dart';
import 'logic/sync_cubit.dart';
import 'ui/screens/auth_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/splash_screen.dart';

class HabitsNotesApp extends StatelessWidget {
  const HabitsNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(),
        ),
        BlocProvider<HabitsCubit>(
          create: (context) => HabitsCubit(),
        ),
        BlocProvider<NotesCubit>(
          create: (context) => NotesCubit(),
        ),
        BlocProvider<SyncCubit>(
          create: (context) => SyncCubit(),
        ),
      ],
      child: MaterialApp(
        title: 'Habits & Notes',
        themeMode: ThemeMode.light,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF7A1B2E), // wine/burgundy
            brightness: Brightness.light,
          ).copyWith(
            secondary: const Color(0xFFD9A441), // gold accent
            tertiary: const Color(0xFF5A8F7B), // sage
          ),
          textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          tabBarTheme: const TabBarTheme(
            labelStyle: TextStyle(fontWeight: FontWeight.w600),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
            indicatorSize: TabBarIndicatorSize.tab,
          ),
          appBarTheme: const AppBarTheme(centerTitle: false),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF7A1B2E),
            brightness: Brightness.dark,
          ).copyWith(
            secondary: const Color(0xFFD9A441),
            tertiary: const Color(0xFF5A8F7B),
          ),
          scaffoldBackgroundColor: const Color(0xFF16131A),
          textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          tabBarTheme: const TabBarTheme(
            labelStyle: TextStyle(fontWeight: FontWeight.w600),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
            indicatorSize: TabBarIndicatorSize.tab,
          ),
          appBarTheme: const AppBarTheme(centerTitle: false),
        ),
        home: const AppRouter(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        // Debug which screen is being chosen based on state
        // ignore: avoid_print
        print('[AppRouter] State=$state -> screen=' + (
          (state is AuthInitial || state is AuthLoading)
              ? 'SplashScreen'
              : (state is Authenticated)
                  ? 'HomeScreen'
                  : 'AuthScreen'
        ));
        
        // Show SplashScreen during initial loading
        if (state is AuthInitial || state is AuthLoading) {
          return const SplashScreen();
        } 
        // Show HomeScreen when authenticated
        else if (state is Authenticated) {
          return const HomeScreen();
        } 
        // Show AuthScreen for all other states (Unauthenticated, AuthError)
        // This ensures AuthError states can properly display SnackBars
        else {
          return const AuthScreen();
        }
      },
    );
  }
}
