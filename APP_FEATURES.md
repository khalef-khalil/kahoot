# Kahoot Clone - Feature List

## Home Screen
- View list of available quizzes
- Add sample quiz when no quizzes exist
- Create new quizzes via floating action button
- Delete quizzes via swipe gesture or delete button
- Confirmation dialog before quiz deletion
- Edit existing quizzes
- Duplicate quizzes with all questions and options
- Export quizzes to JSON format for sharing
- Import quizzes from JSON files
- Easy-access quiz menu with bottom sheet
- Quick access to statistics and settings
- Search and filter quizzes by title or description
- Sort quizzes by title (A-Z/Z-A) or creation order (newest/oldest)
- Mark quizzes as favorites and filter by favorites
- Filter quizzes by difficulty level (Easy, Medium, Hard)
- Filter quizzes by categories with intuitive icons
- Visual difficulty indicators with color coding
- Category display with appropriate icons

## Quiz Creation & Editing
- Add title and description for quizzes
- Create multiple-choice questions with 4 options each
- Set time limits for each question
- Mark correct answers
- Preview questions before saving
- Edit existing questions and options
- Delete questions from quizzes
- Set difficulty level for quizzes (Easy, Medium, Hard)
- Categorize quizzes with predefined categories
- Visual category selection with intuitive icons

## Quiz Experience
- Countdown timer for each question
- Total quiz timer to track completion time
- Progress tracking through quiz
- Color-coded answer buttons (Kahoot style)
- Immediate feedback on correct/incorrect answers
- Score tracking and final results screen
- Automatic saving of quiz results
- Display of total time spent on quiz completion

## Statistics & History
- Performance summary dashboard
- Quiz history with dates and scores
- Grade distribution visualization
- Track best and average scores
- Average quiz completion time tracking
- Swipe-to-delete individual history entries
- Clear all history option
- Performance metrics (total quizzes, unique quizzes, etc.)
- Detailed time information for each quiz attempt
- Export quiz results to CSV format
- Share quiz results via system share sheet

## Settings
- Theme selector with multiple color options
- App information (version and developer)

## User Authentication
- User registration with username, email, and password
- User login with username/email and password
- Secure password hashing
- Persistent login using shared preferences
- User-specific quizzes and statistics
- Logout functionality
- User profile information display

## Multiplayer Mode
- Host quizzes with unique session codes
- Join existing quiz sessions with session codes
- Real-time player roster in waiting room
- Host controls for starting the quiz
- Competitive gameplay with multiple participants
- Color-coded answer buttons in Kahoot style
- Automatic scoring system with time bonuses
- Live leaderboard between questions
- Final results with player rankings
- Personal score tracking during gameplay

## Database
- Local SQLite storage for quizzes, questions and answers
- Persistent quiz data between app sessions
- Cascading delete for quizzes and related data
- Update functionality for all quiz components
- Duplicate functionality for entire quizzes
- Quiz results and statistics tracking
- Quiz completion time tracking
- Difficulty level support for quizzes
- Category support for better organization 