# Arth - Finance Management App

A comprehensive Flutter finance management application with expense tracking, budget management, savings goals, and AI-powered financial insights.

## Features

- **Expense Tracking**: Log and categorize daily expenses
- **Budget Management**: Set monthly budgets with category limits
- **Savings Goals**: Create short-term and long-term savings goals
- **AI Chat**: Get financial advice and insights through AI-powered chat
- **Financial Health**: Track your net worth with assets and liabilities
- **Authentication**: Email-based authentication with OTP verification
- **Voice Input**: Log expenses using voice commands

## Screens

- **Home Dashboard**: Overview of expenses, budget status, and quick actions
- **Budget Screen**: Net worth tracking, budget categories, and savings goals
- **Transactions**: Detailed transaction history with filtering
- **AI Chat**: Interactive financial assistant
- **Profile**: User settings, income sources, and preferences

## Architecture

The app follows Provider pattern for state management:
- `TransactionProvider`: Manages expense transactions
- `BudgetProvider`: Handles budget and savings data
- `AuthProvider`: Manages user authentication
- `ProfileProvider`: Handles user profile data
- `DashboardProvider`: Manages dashboard analytics
- `AIChatProvider`: Handles AI chat functionality

## Getting Started

1. Clone the repository
2. Run `flutter pub get`
3. Configure your API endpoints in `lib/api_service.dart`
4. Run `flutter run`

## UI Design

The app uses a modern, clean design inspired by the Silk AI Chat interface from Stitch, featuring:
- Soft rounded corners
- Card-based layouts
- Gradient accents
- Clean typography
- Dot-grid background pattern (optional)

## License

MIT License
