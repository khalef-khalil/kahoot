# Kahoot Clone

A simple Kahoot-style quiz application built with Flutter and SQLite.

## Features

- **Home Screen**
  - View list of available quizzes
  - Add sample quiz when no quizzes exist
  - Create new quizzes via floating action button
  - Delete quizzes via swipe gesture or delete button
  - Confirmation dialog before quiz deletion

- **Quiz Creation**
  - Add title and description for quizzes
  - Create multiple-choice questions with 4 options each
  - Set time limits for each question
  - Mark correct answers
  - Preview questions before saving

- **Quiz Experience**
  - Countdown timer for each question
  - Progress tracking through quiz
  - Color-coded answer buttons (Kahoot style)
  - Immediate feedback on correct/incorrect answers
  - Score tracking and final results screen

- **Database**
  - Local SQLite storage for quizzes, questions and answers
  - Persistent quiz data between app sessions
  - Cascading delete for quizzes and related data

## Tech Stack

- Flutter for cross-platform mobile UI
- SQLite for local database storage
- Dart programming language

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
