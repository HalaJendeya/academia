# Academia

**Academia** is a smart academic mobile application designed to help university students organize their academic life through one unified platform. The application brings together courses, assignments, personal tasks, study sessions, academic files, notifications, and role-based academic management features.

The project was developed as a graduation project for the Department of Management Information Systems at Al-Aqsa University - Gaza.

---

## Project Title

**Academia: Smart Academic Platform for Managing University Student Academic Life**

---

## Project Overview

Academia is a mobile application that supports academic organization for university students. It aims to reduce the fragmentation caused by using multiple separate tools such as Moodle, calendar apps, notes apps, messaging groups, and task managers.

The current version of Academia has evolved into a multi-role academic platform serving three authenticated user roles:

- Student
- Teacher
- Admin

The system is designed as a complementary productivity layer for academic life. It does not replace Moodle, but it provides additional organizational features that are not available in traditional Learning Management Systems.

---

## Problem Statement

University students often rely on several disconnected tools to manage their academic responsibilities. Moodle is mainly used for official academic content such as courses, files, assignments, and grades, while students still need other tools to manage personal tasks, deadlines, study sessions, reminders, and collaboration.

This creates several problems:

- Students are scattered between multiple applications.
- Assignments and personal tasks are not managed in one place.
- Moodle lacks modern productivity features such as focus study sessions and smart planning.
- Weak or unstable internet connectivity can affect access to academic materials.
- Students may miss deadlines because reminders are distributed across different platforms.

Academia addresses these issues by providing a unified mobile application that organizes the student's academic workflow in a clear and accessible way.

---

## Proposed Solution

Academia provides a single mobile platform that helps students manage their academic responsibilities more effectively.

The application allows students to view their dashboard, courses, assignments, personal tasks, academic files, study sessions, notifications, and profile settings. It also provides separate interfaces for teachers and administrators.

Teachers can manage assigned course offerings, create and archive assignments, manage course files, and interact with students through shared academic spaces.

Admins can manage academic structures, courses, offerings, enrollments, teacher accounts, and system data through a dedicated admin interface.

---

## User Roles

### 1. Student

The student is the main user of the application. The student can:

- Create an account and log in.
- Complete initial study preferences setup.
- View a personalized dashboard.
- Browse registered courses.
- View course details and files.
- View academic assignments.
- Create and manage personal tasks.
- Start and track focused study sessions.
- Manage profile and study preferences.
- Receive notifications and reminders.
- Participate in shared academic spaces.

### 2. Teacher

The teacher can:

- Log in using a teacher account.
- View assigned course offerings.
- View students enrolled in assigned offerings.
- Create academic assignments.
- Edit and archive assignments.
- Manage course files.
- Participate in course shared spaces.
- Manage teacher profile and log out.

### 3. Admin

The admin can:

- Access an admin dashboard.
- View system indicators and counts.
- Manage academic departments, majors, courses, semesters, and offerings.
- Manage student enrollments.
- Manage teacher accounts.
- Activate or deactivate teacher accounts.
- Review reported shared-space content.
- Manage academic data stored in the system database.

---

## Implemented Features

The current version includes the following implemented modules:

- Authentication and user verification
- Initial onboarding and study preferences setup
- Student dashboard
- Course browsing and course details
- Course files management
- Unified assignments and personal tasks module
- Personal task creation, update, completion, and deletion
- Focused study sessions
- Study session history
- Weekly study summary
- Student profile and settings
- Notification settings and reminders
- Teacher interface
- Teacher course offerings
- Teacher assignments management
- Teacher course files management
- Shared academic space
- Post creation, likes, comments, and reporting
- Admin dashboard
- Academic structure management
- Teacher accounts management
- Reported content review
- Role-based access control

---

## Features Not Implemented Yet

The following features are planned as future work and are not fully implemented in the current version:

- Academic Calendar
- Study Schedule
- AI Academic Assistant
- Smart study plan generation
- Full Offline-First support
- Global Search
- Moodle API Integration
- APK release

---

## Technology Stack

### Mobile Development

- Flutter
- Dart

### Backend and Database

- Firebase Authentication
- Cloud Firestore
- Firestore Security Rules

### State Management

- Provider

### Local and Supporting Services

- Shared Preferences
- Flutter Local Notifications
- Connectivity Plus
- Path Provider
- File Picker
- Image Picker
- URL Launcher
- Share Plus

### File and Media Handling

- Cloudinary
- HTTP Multipart Upload

### UI/UX Design

- Figma
- Arabic RTL interface
- Tajawal font family

---

## Database and Security

Academia uses **Cloud Firestore** as the main database. The system stores users, roles, academic data, assignments, personal tasks, study sessions, shared-space posts, files metadata, and related records.

Authorization is controlled using a role-based access model. Each user has a role stored in the database:

- `student`
- `teacher`
- `admin`

Firestore Security Rules are used to enforce access permissions at the database level, not only at the user interface level.

---

## Moodle Integration Status

Moodle integration is part of the planned future development.

In the current version, academic data is managed inside the project's own Firestore database. Admins can create and manage academic structures, courses, offerings, and enrollments directly in the application.

The application is designed to complement Moodle, not replace it.

---

## Project Structure

```text
academia/
│
├── android/
├── ios/
├── assets/
│   ├── images/
│   └── fonts/
│
├── lib/
│   ├── app/
│   ├── core/
│   ├── features/
│   │   ├── academics/
│   │   ├── admin/
│   │   ├── analytics/
│   │   ├── assignments/
│   │   ├── auth/
│   │   ├── courses/
│   │   ├── curriculum/
│   │   ├── dashboard/
│   │   ├── enrollments/
│   │   ├── files/
│   │   ├── notifications/
│   │   ├── onboarding/
│   │   ├── profile/
│   │   ├── search/
│   │   ├── semesters/
│   │   ├── shared_space/
│   │   ├── study/
│   │   ├── tasks/
│   │   └── teacher/
│   │
│   ├── firebase_options.dart
│   └── main.dart
│
├── test/
├── tool/
├── firebase.json
├── firestore.rules
├── firestore.indexes.json
├── pubspec.yaml
└── README.md
```
----

## Running The Application
- Clone the project
- Open with VS Code or Android Studio
- flutter pub get
- flutter run

## Users
- admin: admin@test.com
- admin password: password123

- teacher: teacher@example.edu
- teacher password: 123456789

- student: student@test.com
- student password: 123456789
