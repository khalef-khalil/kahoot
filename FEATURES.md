# Kahoot Clone Features List

## User Interface
1. Material Design-based UI with Purple theme
2. Responsive layout for various screen sizes
3. Intuitive navigation between screens
4. Loading indicators for asynchronous operations
5. Bottom sheet menu for quiz options

## Home Screen
1. List view of all available quizzes
2. Each quiz shows title and description
3. "Add Sample Quiz" button when no quizzes exist
4. Floating action button to create new quizzes
5. Swipe-to-delete gesture for removing quizzes
6. Options menu for each quiz (more_vert button)
7. Confirmation dialog before quiz deletion
8. Edit button for each quiz
9. Duplicate quiz functionality
10. Tap on quiz to start playing it

## Quiz Creation
1. Form with validation for quiz title and description
2. Add multiple questions to a quiz
3. Set question text for each question
4. Configure time limit for each question (in seconds)
5. Add 4 options for each question
6. Mark one option as correct using radio buttons
7. Preview list of added questions
8. Delete questions before saving
9. Form validation for all fields
10. Success/error feedback via snackbar

## Quiz Editing
1. Load and display existing quiz data
2. Edit quiz title and description
3. View list of existing questions
4. Add new questions to existing quiz
5. Edit existing questions (text, time limit)
6. Edit options for questions
7. Change which option is correct
8. Delete questions from the quiz
9. Save changes with validation
10. Success/error feedback via snackbar

## Quiz Management
1. Delete quizzes with confirmation
2. Edit existing quizzes
3. Duplicate quizzes with all questions and options
4. Duplicated quizzes are marked with "(Copy)" in title
5. Create new quizzes from scratch

## Quiz Experience
1. Display quiz title in app bar
2. Show current question number and total questions
3. Progress indicator showing quiz completion percentage
4. Countdown timer for each question
5. Visual timer display showing remaining seconds
6. Question text displayed prominently
7. Four colored answer buttons in grid layout (Kahoot style)
   - Red, Blue, Yellow, and Green options
8. Visual feedback on answer selection
   - Correct answers turn green
   - Incorrect answers turn red
9. Automatic progression to next question after answer or time expiration
10. Final score screen showing results
11. "Return to Home" button on completion

## Database Features
1. SQLite local database for persistent storage
2. Tables for quizzes, questions, and options
3. Foreign key relationships between tables
4. CRUD operations for all entities:
   - Create new quizzes, questions, and options
   - Read existing quiz data
   - Update quiz components
   - Delete quizzes and related data
5. Cascading deletes to maintain data integrity
6. Duplicate functionality for quizzes and related data
7. Sample data generation for testing

## Technical Features
1. Flutter framework for cross-platform compatibility
2. Optimized for Android devices
3. State management using StatefulWidget
4. Asynchronous database operations
5. Navigation using MaterialPageRoute
6. Form validation and feedback
7. Dialog-based user interactions
8. Modal bottom sheets for menu options
9. Timer-based gameplay mechanics 