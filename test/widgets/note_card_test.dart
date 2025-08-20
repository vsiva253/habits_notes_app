import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits_notes_app/ui/widgets/note_card.dart';
import 'package:habits_notes_app/data/models/note.dart';

void main() {
  group('NoteCard Widget Tests', () {
    late Note testNote;
    bool onTapCalled = false;
    bool onDeleteCalled = false;

    setUp(() {
      onTapCalled = false;
      onDeleteCalled = false;
      
      testNote = Note(
        id: 'test-note-id',
        habitId: 'test-habit-id',
        text: 'This is a test note with some content',
        createdAt: DateTime(2024, 1, 15, 10, 30),
      );
    });

    Widget createTestWidget(Note note) {
      return MaterialApp(
        home: Scaffold(
          body: NoteCard(
            note: note,
            onTap: () => onTapCalled = true,
            onDelete: () => onDeleteCalled = true,
          ),
        ),
      );
    }

    testWidgets('displays note text correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testNote));

      expect(find.text('This is a test note with some content'), findsOneWidget);
    });

    testWidgets('displays note badge', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testNote));

      expect(find.text('Note'), findsOneWidget);
    });

    testWidgets('displays time icon', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testNote));

      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('displays more menu icon', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testNote));

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('calls onTap when card is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testNote));

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(onTapCalled, isTrue);
    });

    testWidgets('shows delete option in popup menu', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testNote));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('calls onDelete when delete is selected', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testNote));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pump();

      expect(onDeleteCalled, isTrue);
    });

    group('date formatting', () {
      testWidgets('shows "just now" for very recent notes', (WidgetTester tester) async {
        final recentNote = testNote.copyWith(createdAt: DateTime.now());
        await tester.pumpWidget(createTestWidget(recentNote));

        expect(find.text('just now'), findsOneWidget);
      });

      testWidgets('shows minutes ago for recent notes', (WidgetTester tester) async {
        final minutesAgoNote = testNote.copyWith(
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        );
        await tester.pumpWidget(createTestWidget(minutesAgoNote));

        expect(find.text('30 minutes ago'), findsOneWidget);
      });

      testWidgets('shows hours ago for notes from today', (WidgetTester tester) async {
        final hoursAgoNote = testNote.copyWith(
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        );
        await tester.pumpWidget(createTestWidget(hoursAgoNote));

        expect(find.text('2 hours ago'), findsOneWidget);
      });

      testWidgets('shows "yesterday" for notes from yesterday', (WidgetTester tester) async {
        final yesterdayNote = testNote.copyWith(
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        );
        await tester.pumpWidget(createTestWidget(yesterdayNote));

        expect(find.text('yesterday'), findsOneWidget);
      });

      testWidgets('shows days ago for recent notes', (WidgetTester tester) async {
        final daysAgoNote = testNote.copyWith(
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        );
        await tester.pumpWidget(createTestWidget(daysAgoNote));

        expect(find.text('3 days ago'), findsOneWidget);
      });

      testWidgets('shows weeks ago for older notes', (WidgetTester tester) async {
        final weeksAgoNote = testNote.copyWith(
          createdAt: DateTime.now().subtract(const Duration(days: 14)),
        );
        await tester.pumpWidget(createTestWidget(weeksAgoNote));

        expect(find.text('2 weeks ago'), findsOneWidget);
      });

      testWidgets('shows months ago for much older notes', (WidgetTester tester) async {
        final monthsAgoNote = testNote.copyWith(
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
        );
        await tester.pumpWidget(createTestWidget(monthsAgoNote));

        expect(find.text('2 months ago'), findsOneWidget);
      });

      testWidgets('shows years ago for very old notes', (WidgetTester tester) async {
        final yearsAgoNote = testNote.copyWith(
          createdAt: DateTime.now().subtract(const Duration(days: 400)),
        );
        await tester.pumpWidget(createTestWidget(yearsAgoNote));

        expect(find.text('1 years ago'), findsOneWidget);
      });
    });

    group('layout and styling', () {
      testWidgets('has proper card structure', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(testNote));

        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(InkWell), findsOneWidget);
      });

      testWidgets('has rounded corners', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(testNote));

        final card = tester.widget<Card>(find.byType(Card));
        final shape = card.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, equals(BorderRadius.circular(12)));
      });

      testWidgets('has proper padding', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(testNote));

        final padding = tester.widget<Padding>(find.byType(Padding).first);
        expect(padding.padding, equals(const EdgeInsets.all(16)));
      });

      testWidgets('has column layout for content', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(testNote));

        expect(find.byType(Column), findsOneWidget);
      });

      testWidgets('has rows for header and footer', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(testNote));

        expect(find.byType(Row), findsNWidgets(2));
      });
    });

    group('popup menu', () {
      testWidgets('popup menu button exists', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(testNote));

        expect(find.byType(PopupMenuButton<String>), findsOneWidget);
      });

      testWidgets('delete menu item has error styling', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(testNote));

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        final deleteIcon = tester.widget<Icon>(find.byIcon(Icons.delete));
        expect(deleteIcon.color, isA<Color>());
      });
    });

    group('text handling', () {
      testWidgets('handles long text properly', (WidgetTester tester) async {
        final longTextNote = testNote.copyWith(
          text: 'This is a very long note text that should be displayed properly without causing any overflow issues in the widget layout',
        );
        await tester.pumpWidget(createTestWidget(longTextNote));

        expect(find.textContaining('This is a very long note'), findsOneWidget);
      });

      testWidgets('handles empty text', (WidgetTester tester) async {
        final emptyTextNote = testNote.copyWith(text: '');
        await tester.pumpWidget(createTestWidget(emptyTextNote));

        expect(find.text(''), findsOneWidget);
      });

      testWidgets('handles special characters', (WidgetTester tester) async {
        final specialCharNote = testNote.copyWith(
          text: 'Note with special chars: @#\$%^&*()_+{}[]|\\:";\'<>?,./`~',
        );
        await tester.pumpWidget(createTestWidget(specialCharNote));

        expect(find.textContaining('Note with special chars'), findsOneWidget);
      });
    });

    group('theme integration', () {
      testWidgets('uses theme colors correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: NoteCard(
                note: testNote,
                onTap: () => onTapCalled = true,
                onDelete: () => onDeleteCalled = true,
              ),
            ),
          ),
        );

        // Widget should render without errors using theme colors
        expect(find.byType(NoteCard), findsOneWidget);
      });

      testWidgets('works with dark theme', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: NoteCard(
                note: testNote,
                onTap: () => onTapCalled = true,
                onDelete: () => onDeleteCalled = true,
              ),
            ),
          ),
        );

        // Widget should render without errors in dark theme
        expect(find.byType(NoteCard), findsOneWidget);
      });
    });
  });
}
