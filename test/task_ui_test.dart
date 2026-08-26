import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:academia/core/constants/app_strings.dart';
import 'package:academia/features/assignments/models/course_assignment_model.dart';
import 'package:academia/features/assignments/providers/assignment_progress_provider.dart';
import 'package:academia/features/assignments/providers/course_assignment_provider.dart';
import 'package:academia/features/auth/models/app_user_model.dart';
import 'package:academia/features/auth/providers/auth_provider.dart';
import 'package:academia/features/courses/models/course_model.dart';
import 'package:academia/features/courses/models/student_course_view.dart';
import 'package:academia/features/courses/providers/student_courses_provider.dart';
import 'package:academia/features/enrollments/models/enrollment_model.dart';
import 'package:academia/features/tasks/models/task_model.dart';
import 'package:academia/features/tasks/providers/task_provider.dart';
import 'package:academia/features/tasks/widgets/task_filter_bar.dart';
import 'package:academia/features/tasks/screens/tasks_screen.dart';
import 'package:academia/features/tasks/screens/task_detail_screen.dart';
import 'package:academia/features/tasks/screens/create_edit_task_screen.dart';

/// No completion marks. These suites predate the feature and assert the
/// behaviour of a student who has not marked anything done, so the empty
/// provider keeps their expectations exactly as they were.
class FakeProgressProvider extends ChangeNotifier
    implements AssignmentProgressProvider {
  @override
  Set<String> get completedAssignmentIds => const <String>{};

  @override
  Map<String, DateTime?> get completionTimes => const <String, DateTime?>{};

  @override
  bool isCompleted(String assignmentId) => false;

  @override
  DateTime? completedAt(String assignmentId) => null;

  @override
  bool isSaving(String assignmentId) => false;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  bool get isLoggedIn => true;

  @override
  AppUserModel? get currentUserProfile => const AppUserModel(
        uid: 'student1',
        fullName: 'طالبة تجريبية',
        email: 'student1@academia.edu',
        role: UserRole.student,
        status: 'active',
        emailVerified: true,
        onboardingCompleted: true,
        onboardingStatus: 'completed',
        majorId: 'major1',
        academicLevel: 4,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStudentCoursesProvider extends ChangeNotifier implements StudentCoursesProvider {
  FakeStudentCoursesProvider({
    this.currentCoursesValue = const [],
  });

  final List<StudentCourseView> currentCoursesValue;

  @override
  List<StudentCourseView> get currentCourses => currentCoursesValue;

  @override
  CourseModel? courseById(String? courseId) {
    if (courseId == 'c1') {
      return const CourseModel(
        id: 'c1',
        courseCode: 'BMIS2344',
        title: 'تحليل وتصميم النظم',
        description: '',
        creditHours: 3,
        departmentId: 'dep1',
        status: 'active',
      );
    }
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTaskProvider extends ChangeNotifier implements TaskProvider {
  FakeTaskProvider({
    List<TaskModel>? tasks,
    this.isLoadingValue = false,
    this.errorMessageValue,
  }) : tasksValue = tasks ?? [];

  final List<TaskModel> tasksValue;
  final bool isLoadingValue;
  final String? errorMessageValue;

  @override
  List<TaskModel> get tasks => tasksValue;

  @override
  bool get isLoading => isLoadingValue;

  @override
  String? get errorMessage => errorMessageValue;

  @override
  String? get userId => 'student1';

  int createTaskCount = 0;
  String? lastCreatedTitle;
  String? lastCreatedEnrollmentId;

  int updateTaskCount = 0;
  String? lastUpdatedTitle;
  String? lastUpdatedEnrollmentId;

  int completeTaskCount = 0;
  String? lastCompletedId;

  int reopenTaskCount = 0;
  String? lastReopenedId;

  int deleteTaskCount = 0;
  String? lastDeletedId;

  @override
  Future<void> createTask({
    required String title,
    required String description,
    required DateTime? dueAt,
    required TaskPriority priority,
    required TaskType type,
    String? enrollmentId,
    required List<StudentCourseView> currentCourses,
  }) async {
    createTaskCount++;
    lastCreatedTitle = title;
    lastCreatedEnrollmentId = enrollmentId;
  }

  @override
  Future<void> updateTask({
    required String taskId,
    required String title,
    required String description,
    required DateTime? dueAt,
    required TaskPriority priority,
    required TaskType type,
    String? enrollmentId,
    required List<StudentCourseView> currentCourses,
    required TaskStatus status,
  }) async {
    updateTaskCount++;
    lastUpdatedTitle = title;
    lastUpdatedEnrollmentId = enrollmentId;
  }

  @override
  Future<void> completeTask(String taskId) async {
    completeTaskCount++;
    lastCompletedId = taskId;
  }

  @override
  Future<void> reopenTask(String taskId) async {
    reopenTaskCount++;
    lastReopenedId = taskId;
  }

  @override
  Future<void> deleteTask(String taskId) async {
    deleteTaskCount++;
    lastDeletedId = taskId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/*
 * Phase 8.4: TasksScreen became the unified «المهام والواجبات» screen and
 * now also reads academic assignments. Loaded and empty by default keeps
 * these tests about personal-task behaviour, which is what they cover;
 * the merged view is tested in tasks_screen_unified_test.
 */
class FakeAssignmentProvider extends ChangeNotifier
    implements CourseAssignmentProvider {
  FakeAssignmentProvider({this.assignmentsValue = const <CourseAssignmentModel>[]});

  final List<CourseAssignmentModel> assignmentsValue;

  @override
  List<CourseAssignmentModel> get assignments => assignmentsValue;

  @override
  List<CourseAssignmentModel> get activeAssignments =>
      assignmentsValue.where((a) => a.isActive).toList();

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap({
  required Widget child,
  required FakeTaskProvider taskProvider,
  required FakeStudentCoursesProvider coursesProvider,
  FakeAssignmentProvider? assignmentProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuthProvider()),
      ChangeNotifierProvider<StudentCoursesProvider>.value(value: coursesProvider),
      ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
      ChangeNotifierProvider<CourseAssignmentProvider>.value(
        value: assignmentProvider ?? FakeAssignmentProvider(),
      ),
      ChangeNotifierProvider<AssignmentProgressProvider>(
        create: (_) => FakeProgressProvider(),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar')],
      routes: {
        '/tasks': (context) => const TasksScreen(),
        '/tasks/detail': (context) => const TaskDetailScreen(),
        '/tasks/create-edit': (context) => const CreateEditTaskScreen(),
      },
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: child,
      ),
    ),
  );
}

void _useNarrowScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  final now = DateTime.now();

  final courseEnrollment = StudentCourseView(
    enrollment: EnrollmentModel(
      id: 'enrollment_1',
      userId: 'student1',
      offeringId: 'offering_1',
      courseId: 'c1',
      semesterId: 'semester_1',
      status: EnrollmentModel.statusActive,
      assignedBy: 'admin',
    ),
    course: const CourseModel(
      id: 'c1',
      courseCode: 'BMIS2344',
      title: 'تحليل وتصميم النظم',
      description: '',
      creditHours: 3,
      departmentId: 'dep1',
      status: 'active',
    ),
  );

  group('TasksScreen UI Tests', () {
    testWidgets('zero-task empty state shows appropriate message and add button', (tester) async {
      _useNarrowScreen(tester);
      final taskProvider = FakeTaskProvider(tasks: []);
      final coursesProvider = FakeStudentCoursesProvider();

      await tester.pumpWidget(
        _wrap(
          child: const TasksScreen(),
          taskProvider: taskProvider,
          coursesProvider: coursesProvider,
        ),
      );
      await tester.pumpAndSettle();

      /*
       * Phase 8.4: the landing tab is الكل, which covers personal tasks AND
       * academic assignments, so its empty state speaks for both. The
       * personal-task-specific empty state with its add action now lives in
       * the مهامي tab.
       */
      expect(find.text(AppStrings.workEmptyAllTitle), findsOneWidget);

      await tester.tap(find.text(AppStrings.workTabMyTasks));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.workEmptyMyTasksTitle), findsOneWidget);
      expect(find.text(AppStrings.addNewTaskAction), findsOneWidget);
    });

    testWidgets('one pending task renders correctly', (tester) async {
      _useNarrowScreen(tester);
      final task = TaskModel(
        id: 't1',
        userId: 'student1',
        title: 'واجب البرمجة',
        description: 'حل السؤال الأول والثاني',
        status: TaskStatus.pending,
        priority: TaskPriority.high,
        type: TaskType.assignment,
        createdAt: now,
        updatedAt: now,
      );

      final taskProvider = FakeTaskProvider(tasks: [task]);
      final coursesProvider = FakeStudentCoursesProvider();

      await tester.pumpWidget(
        _wrap(
          child: const TasksScreen(),
          taskProvider: taskProvider,
          coursesProvider: coursesProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('واجب البرمجة'), findsOneWidget);
      expect(find.text('حل السؤال الأول والثاني'), findsOneWidget);
      expect(find.text('عالية'), findsOneWidget);
      expect(find.text('واجب'), findsOneWidget);
    });

    testWidgets('filtering by today, overdue, completed shows correct tasks', (tester) async {
      _useNarrowScreen(tester);
      final taskToday = TaskModel(
        id: 't1',
        userId: 'student1',
        title: 'مهمة اليوم',
        dueAt: DateTime(now.year, now.month, now.day, 15, 0), // today
        status: TaskStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
      final taskOverdue = TaskModel(
        id: 't2',
        userId: 'student1',
        title: 'مهمة متأخرة',
        dueAt: now.subtract(const Duration(days: 2)), // yesterday
        status: TaskStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
      final taskCompleted = TaskModel(
        id: 't3',
        userId: 'student1',
        title: 'مهمة مكتملة',
        status: TaskStatus.completed,
        createdAt: now,
        updatedAt: now,
      );

      final taskProvider = FakeTaskProvider(tasks: [taskToday, taskOverdue, taskCompleted]);
      final coursesProvider = FakeStudentCoursesProvider();

      await tester.pumpWidget(
        _wrap(
          child: const TasksScreen(),
          taskProvider: taskProvider,
          coursesProvider: coursesProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Phase 8.4: the temporal quick filters now live inside مهامي.
      Future<void> openMyTasks() async {
        await tester.tap(find.text(AppStrings.workTabMyTasks));
        await tester.pumpAndSettle();
      }

      Future<void> tapFilter(String label) async {
        final finder = find.text(label);
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      await openMyTasks();

      /*
       * مهامي holds PENDING personal tasks only — completed ones moved to
       * their own tab in Phase 8.4, so the pill that used to select them
       * would now duplicate a tab label.
       */
      expect(find.text('مهمة اليوم'), findsOneWidget);
      expect(find.text('مهمة متأخرة'), findsOneWidget);
      expect(find.text('مهمة مكتملة'), findsNothing);

      await tapFilter('اليوم');
      expect(find.text('مهمة اليوم'), findsOneWidget);
      expect(find.text('مهمة متأخرة'), findsNothing);

      await tapFilter('متأخرة');
      expect(find.text('مهمة اليوم'), findsNothing);
      expect(find.text('مهمة متأخرة'), findsOneWidget);

      // Back to all pending. 'الكل' appears twice (tab + pill), so target
      // the pill explicitly rather than by bare text.
      await tester.tap(find.descendant(
        of: find.byType(TaskFilterBar),
        matching: find.text(AppStrings.workTabAll),
      ));
      await tester.pumpAndSettle();
      expect(find.text('مهمة اليوم'), findsOneWidget);
      expect(find.text('مهمة متأخرة'), findsOneWidget);

      // The completed task lives in the مكتملة tab.
      await tester.tap(find.text(AppStrings.workTabCompleted));
      await tester.pumpAndSettle();
      expect(find.text('مهمة مكتملة'), findsOneWidget);
      expect(find.text('مهمة اليوم'), findsNothing);
      expect(find.text('مهمة متأخرة'), findsNothing);
    });

    testWidgets('clearing filters returns to showing all tasks', (tester) async {
      _useNarrowScreen(tester);
      /*
       * A PENDING task with no due date: مهامي lists it by default, and the
       * اليوم filter excludes it, which is exactly the state the clear-filters
       * action has to recover from. A completed task would not appear in
       * مهامي at all after Phase 8.4.
       */
      final task = TaskModel(
        id: 't1',
        userId: 'student1',
        title: 'مهمة بلا موعد',
        status: TaskStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
      final taskProvider = FakeTaskProvider(tasks: [task]);
      final coursesProvider = FakeStudentCoursesProvider();

      await tester.pumpWidget(
        _wrap(
          child: const TasksScreen(),
          taskProvider: taskProvider,
          coursesProvider: coursesProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Phase 8.4: the temporal quick filters now live inside مهامي.
      Future<void> openMyTasks() async {
        await tester.tap(find.text(AppStrings.workTabMyTasks));
        await tester.pumpAndSettle();
      }

      Future<void> tapFilter(String label) async {
        final finder = find.text(label);
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      await openMyTasks();

      // Tap 'اليوم' (which this task does not match)
      await tapFilter('اليوم');

      expect(find.text(AppStrings.noSearchResultsTitle), findsOneWidget);

      await tester.tap(find.text(AppStrings.clearFiltersAction));
      await tester.pumpAndSettle();

      expect(find.text('مهمة بلا موعد'), findsOneWidget);
    });

    testWidgets('no-course task vs linked-course task display details', (tester) async {
      _useNarrowScreen(tester);
      final taskNoCourse = TaskModel(
        id: 't1',
        userId: 'student1',
        title: 'مهمة حرة',
        createdAt: now,
        updatedAt: now,
      );
      final taskLinkedCourse = TaskModel(
        id: 't2',
        userId: 'student1',
        title: 'مهمة مساق',
        enrollmentId: 'enrollment_1',
        courseId: 'c1',
        offeringId: 'offering_1',
        createdAt: now,
        updatedAt: now,
      );

      final taskProvider = FakeTaskProvider(tasks: [taskNoCourse, taskLinkedCourse]);
      final coursesProvider = FakeStudentCoursesProvider(currentCoursesValue: [courseEnrollment]);

      await tester.pumpWidget(
        _wrap(
          child: const TasksScreen(),
          taskProvider: taskProvider,
          coursesProvider: coursesProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('مهمة حرة'), findsOneWidget);
      expect(find.text('مهمة مساق'), findsOneWidget);
      // Renders course badge
      expect(find.textContaining('BMIS2344 - تحليل وتصميم النظم'), findsOneWidget);
    });
  });

  group('CreateEditTaskScreen Form Tests', () {
    testWidgets('form functions with zero current courses', (tester) async {
      _useNarrowScreen(tester);
      final taskProvider = FakeTaskProvider(tasks: []);
      final coursesProvider = FakeStudentCoursesProvider(currentCoursesValue: []);

      await tester.pumpWidget(
        _wrap(
          child: const CreateEditTaskScreen(),
          taskProvider: taskProvider,
          coursesProvider: coursesProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Submit empty title to test validation
      await tester.tap(find.text('إضافة المهمة'));
      await tester.pumpAndSettle();
      expect(find.text('يرجى إدخال عنوان المهمة.'), findsOneWidget);

      // Enter valid title
      await tester.enterText(find.byType(TextFormField).first, 'مهمة جديدة حرة');
      await tester.tap(find.text('إضافة المهمة'));
      await tester.pumpAndSettle();

      expect(taskProvider.createTaskCount, 1);
      expect(taskProvider.lastCreatedTitle, 'مهمة جديدة حرة');
      expect(taskProvider.lastCreatedEnrollmentId, isNull);
    });

    testWidgets('form links current course correctly', (tester) async {
      _useNarrowScreen(tester);
      final taskProvider = FakeTaskProvider(tasks: []);
      final coursesProvider = FakeStudentCoursesProvider(currentCoursesValue: [courseEnrollment]);

      await tester.pumpWidget(
        _wrap(
          child: const CreateEditTaskScreen(),
          taskProvider: taskProvider,
          coursesProvider: coursesProvider,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'مهمة للمساق');

      // Select course from dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('BMIS2344 - تحليل وتصميم النظم').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('إضافة المهمة'));
      await tester.pumpAndSettle();

      expect(taskProvider.createTaskCount, 1);
      expect(taskProvider.lastCreatedTitle, 'مهمة للمساق');
      expect(taskProvider.lastCreatedEnrollmentId, 'enrollment_1');
    });

    testWidgets('edit mode pre-populates existing values', (tester) async {
      _useNarrowScreen(tester);
      final task = TaskModel(
        id: 't1',
        userId: 'student1',
        title: 'مهمة للتعديل',
        description: 'وصف المهمة للتعديل',
        enrollmentId: 'enrollment_1',
        courseId: 'c1',
        offeringId: 'offering_1',
        priority: TaskPriority.high,
        type: TaskType.exam,
        createdAt: now,
        updatedAt: now,
      );

      final taskProvider = FakeTaskProvider(tasks: [task]);
      final coursesProvider = FakeStudentCoursesProvider(currentCoursesValue: [courseEnrollment]);

      await tester.pumpWidget(
        _wrap(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    '/tasks/create-edit',
                    arguments: task,
                  );
                },
                child: const Text('افتح'),
              );
            },
          ),
          taskProvider: taskProvider,
          coursesProvider: coursesProvider,
        ),
      );
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();

      expect(find.text('مهمة للتعديل'), findsOneWidget);
      expect(find.text('وصف المهمة للتعديل'), findsOneWidget);
      expect(find.text('BMIS2344 - تحليل وتصميم النظم'), findsOneWidget);
    });
  });

  group('TaskDetailScreen operations', () {
    testWidgets('complete, reopen, delete confirmation flow works', (tester) async {
      _useNarrowScreen(tester);
      final task = TaskModel(
        id: 't1',
        userId: 'student1',
        title: 'تفاصيل المهمة وتفاعلاتها',
        status: TaskStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final taskProvider = FakeTaskProvider(tasks: [task]);
      final coursesProvider = FakeStudentCoursesProvider();

      await tester.pumpWidget(
        _wrap(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    '/tasks/detail',
                    arguments: 't1',
                  );
                },
                child: const Text('افتح التفاصيل'),
              );
            },
          ),
          taskProvider: taskProvider,
          coursesProvider: coursesProvider,
        ),
      );
      await tester.tap(find.text('افتح التفاصيل'));
      await tester.pumpAndSettle();

      expect(find.text('تفاصيل المهمة وتفاعلاتها'), findsOneWidget);

      // Complete Action
      await tester.tap(find.text('تم إنجاز المهمة'));
      await tester.pumpAndSettle();
      expect(taskProvider.completeTaskCount, 1);
      expect(taskProvider.lastCompletedId, 't1');

      // Reopen (Simulate task state is completed now)
      final taskCompleted = task.copyWith(status: TaskStatus.completed);
      taskProvider.tasksValue.clear();
      taskProvider.tasksValue.add(taskCompleted);
      taskProvider.notifyListeners();
      await tester.pumpAndSettle();

      await tester.tap(find.text('إعادة فتح المهمة'));
      await tester.pumpAndSettle();
      expect(taskProvider.reopenTaskCount, 1);
      expect(taskProvider.lastReopenedId, 't1');

      // Delete Action with dialog confirmation
      await tester.tap(find.text('حذف المهمة'));
      await tester.pumpAndSettle();

      expect(find.textContaining('هل أنتِ متأكدة من رغبتكِ في حذف هذه المهمة؟'), findsOneWidget);

      // Confirm Delete
      await tester.tap(find.text('حذف').last);
      await tester.pumpAndSettle();

      expect(taskProvider.deleteTaskCount, 1);
      expect(taskProvider.lastDeletedId, 't1');
    });
  });

  group('360px Narrow Screen Layout Safety', () {
    testWidgets('verifies no pixel overflows under narrow screen viewport', (tester) async {
      _useNarrowScreen(tester);
      final task = TaskModel(
        id: 't1',
        userId: 'student1',
        title: 'مهمة طويلة جداً جداً جداً جداً جداً لتجربة طفح البكسل والاتساق مع العرض الضيق ٣٦٠ بكسل',
        description: 'تفاصيل المهمة الطويلة لتجربة محاذاة النص والبطاقة الطويلة',
        dueAt: DateTime(now.year, now.month, now.day, 15, 0),
        status: TaskStatus.pending,
        priority: TaskPriority.high,
        type: TaskType.assignment,
        enrollmentId: 'enrollment_1',
        courseId: 'c1',
        offeringId: 'offering_1',
        createdAt: now,
        updatedAt: now,
      );

      final taskProvider = FakeTaskProvider(tasks: [task]);
      final coursesProvider = FakeStudentCoursesProvider(currentCoursesValue: [courseEnrollment]);

      await tester.pumpWidget(
        _wrap(
          child: const TasksScreen(),
          taskProvider: taskProvider,
          coursesProvider: coursesProvider,
        ),
      );
      await tester.pumpAndSettle();

      // If overflow exists, flutter test will throw an exception during layout build.
      expect(tester.takeException(), isNull);
    });
  });
}
