# AI Study Coach — Product Requirements Document (PRD)

**Document Version:** 1.0  
**Status:** Draft  
**Last Updated:** April 23, 2026  
**Author:** Product Team  
**Confidentiality:** Internal — Not for External Distribution

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Problem Statement](#2-problem-statement)
3. [Target Users](#3-target-users)
4. [Core Features — MVP (Phase 1)](#4-core-features--mvp-phase-1)
5. [Advanced Features (Phase 2)](#5-advanced-features-phase-2)
6. [Future Scope (Phase 3)](#6-future-scope-phase-3)
7. [User Flow](#7-user-flow)
8. [Tech Stack](#8-tech-stack)
9. [System Architecture Overview](#9-system-architecture-overview)
10. [API Structure (High-Level)](#10-api-structure-high-level)
11. [Database Schema (Basic)](#11-database-schema-basic)
12. [Security Considerations](#12-security-considerations)
13. [Scalability Considerations](#13-scalability-considerations)
14. [Non-Functional Requirements](#14-non-functional-requirements)
15. [Future Enhancements & Roadmap](#15-future-enhancements--roadmap)

---

## 1. Introduction

### 1.1 Product Overview

**AI Study Coach** is a cross-platform mobile application designed to help students study smarter, track their progress, and receive intelligent, personalized academic guidance. Powered by AI, the app combines study session management, performance analytics, and an adaptive learning engine to create a comprehensive academic companion for students at every level.

The application replaces fragmented tools — separate timers, planners, flashcard apps, and tutoring services — with a unified, intelligent platform that learns from the student's behavior and continuously optimizes their study experience.

### 1.2 Vision

> *"To be the most trusted AI-powered academic companion for every student — making personalized learning accessible, consistent, and measurable for millions of learners worldwide."*

### 1.3 Goals

| Goal | Description |
|------|-------------|
| **Engagement** | Drive daily active usage through habit-forming features like streaks and session tracking |
| **Performance** | Measurably improve student academic outcomes via analytics and adaptive learning |
| **Accessibility** | Deliver a premium, coach-level experience to students without access to private tutors |
| **Scalability** | Build a cloud-native architecture capable of serving 10M+ users globally |
| **Monetization** | Establish a freemium model with a clear path to premium subscriptions |

---

## 2. Problem Statement

### 2.1 The Core Challenge

Students across the world — from high school to university — struggle with academic performance not due to lack of intelligence, but due to systemic issues in how they plan, execute, and reflect on their studies. Despite an abundance of content online, most students lack a structured, personalized approach to learning.

### 2.2 Key Pain Points

**Lack of Planning**  
Most students do not have a structured study plan. Without time allocation by subject or topic, students tend to over-study areas of comfort and neglect weak subjects. There are no widely adopted tools that provide intelligent planning recommendations based on individual performance data.

**Distractions and Low Focus**  
The same device used for studying is also a source of entertainment. Without active focus tools — such as timed sessions and focus scoring — students suffer from frequent interruptions, leading to shallow, ineffective study sessions.

**Inconsistency and Loss of Motivation**  
Students often start strong but lose momentum. There is no feedback loop that rewards consistent effort or alerts students when they are falling behind. Motivation drops sharply without visible progress indicators.

**No Personalized Feedback**  
Traditional study methods provide no data on what topics a student struggles with most. Without a feedback mechanism, students repeat the same mistakes and do not adjust their study strategy. Private tutors provide this personalization, but are expensive and inaccessible to most students.

**Fragmented Tooling**  
Students currently use a patchwork of apps: one for timers, another for notes, another for flashcards, and perhaps a separate platform for tests. This fragmentation leads to poor data continuity and no holistic view of their academic health.

### 2.3 Market Opportunity

The global EdTech market is projected to exceed $400 billion by 2028. Mobile-first AI study tools represent one of the fastest-growing segments, driven by increasing smartphone penetration in emerging markets (India, Southeast Asia, Africa) and rising student demand for affordable, on-demand academic support.

---

## 3. Target Users

### 3.1 Primary User Segments

**Segment 1 — High School Students (Ages 14–18)**  
Students preparing for board exams, college entrance tests (JEE, NEET, SAT, A-Levels), or national competitive exams. These users are highly goal-oriented and benefit most from structured session tracking, test analytics, and streak motivation.

**Segment 2 — Undergraduate College Students (Ages 18–24)**  
University students managing multiple subjects, assignments, and exams across a semester. These users need subject-wise analytics, flexible session planning, and AI-assisted doubt resolution to manage higher academic complexity.

**Segment 3 — Competitive Exam Aspirants (Ages 18–28)**  
Self-study learners preparing for professional entrance exams (UPSC, GATE, CPA, Bar Exams). These users have high motivation, long study hours, and strong demand for adaptive test generation and weak topic detection.

### 3.2 User Personas

---

**Persona 1: Priya Sharma**

| Attribute | Detail |
|-----------|--------|
| Age | 17 |
| Occupation | Class 12 student, JEE aspirant |
| Location | Pune, India |
| Device | Android smartphone |
| Goals | Crack JEE Main with 95+ percentile; manage Physics, Chemistry, and Math efficiently |
| Frustrations | Doesn't know which topics need more time; gets distracted by Instagram |
| Needs | Pomodoro timer, subject-wise tracking, streak motivation, weak topic alerts |

**Behavioral Notes:** Priya studies 6–8 hours daily but feels her time is not being used effectively. She wants visual proof of her consistency and needs guidance on where to focus next.

---

**Persona 2: Arjun Mehta**

| Attribute | Detail |
|-----------|--------|
| Age | 21 |
| Occupation | B.Tech 3rd Year, Computer Science |
| Location | Bangalore, India |
| Device | iPhone 14 |
| Goals | Score well in semester exams while working on side projects; reduce last-minute cramming |
| Frustrations | Poor study-life balance; no visibility into how much time he actually spends per subject |
| Needs | Weekly study reports, session tracking, AI tutor for quick doubts, calendar integration |

**Behavioral Notes:** Arjun is tech-savvy and expects a polished, fast experience. He would use AI Tutor heavily and share weekly reports for accountability with peers.

---

**Persona 3: Fatima Al-Rashid**

| Attribute | Detail |
|-----------|--------|
| Age | 25 |
| Occupation | UPSC aspirant, self-study |
| Location | Delhi, India |
| Device | Android tablet + smartphone |
| Goals | Clear UPSC Prelims and Mains in first attempt |
| Frustrations | Vast syllabus, no way to track revision cycles, burnout after 10-hour sessions |
| Needs | Adaptive test generation, burnout detection, knowledge graph notes, predictive score system |

**Behavioral Notes:** Fatima is a power user who will engage with every advanced feature. She needs the app to function as a complete academic operating system.

---

## 4. Core Features — MVP (Phase 1)

Phase 1 defines the Minimum Viable Product. These features must be stable, performant, and polished before any Phase 2 development begins.

### 4.1 Study Timer & Session Tracking

**Description:** A configurable study timer that lets students set study sessions with subject tagging, break intervals, and session goals.

**Functional Requirements:**
- Support Pomodoro mode (25 min study / 5 min break) and custom timer mode
- Allow subject selection before starting a session
- Auto-save session on app background/close with partial credit
- Display real-time session stats: elapsed time, subject, goal completion
- Session notes input (optional) at session end
- Push notification reminders for scheduled sessions

**Acceptance Criteria:**
- Timer accuracy within ±1 second
- Sessions saved successfully even if app is force-closed
- Supports concurrent background audio (music apps) without interruption

### 4.2 Subject-wise Study Analytics

**Description:** A visual dashboard showing how study time is distributed across subjects over daily, weekly, and monthly periods.

**Functional Requirements:**
- Pie/donut chart of study time distribution per subject
- Bar chart for daily/weekly study hours
- Total hours studied this week vs. last week (trend indicator)
- Subject-level drill-down: sessions per subject, average session length, last studied date
- Color-coded subject tags (user-customizable)

**Acceptance Criteria:**
- Dashboard loads within 1.5 seconds on 4G connection
- Charts render correctly on screen sizes from 5" to 7"
- Data updates in real-time after each session ends

### 4.3 Daily / Weekly Reports

**Description:** Auto-generated summary reports delivered in-app and via push notification, summarizing the student's study activity.

**Functional Requirements:**
- Daily Report (generated every night at 9 PM local time): total hours studied, subjects covered, streak status, top-studied subject
- Weekly Report (generated every Sunday): weekly total hours, subject distribution chart, best/worst study day, streak maintained/broken, suggested focus areas for next week
- Shareable report card (PNG export) for social sharing
- In-app report history (last 12 weeks)

**Acceptance Criteria:**
- Reports generated within 30 seconds of trigger time
- PNG export renders correctly at 1080×1920 resolution
- Suggestions in weekly report are dynamically generated (not hardcoded)

### 4.4 Streak System

**Description:** A daily study streak counter that incentivizes consistent study habits through gamification.

**Functional Requirements:**
- Streak increments when student completes a minimum study session (configurable, default: 30 minutes) on a calendar day
- Streak freezes available (1 per week for free users; unlimited for premium)
- Streak milestones: 7, 30, 60, 100, 365 days — with in-app badge rewards
- Streak leaderboard among friends (social feature, optional)
- Grace period: streak preserved if session completed by 11:59 PM local time

**Acceptance Criteria:**
- Streak calculation is timezone-aware and accurate
- Milestones trigger badge animation within 1 second of achievement
- Streak freeze usage reflected instantly in UI

### 4.5 User Authentication

**Description:** Secure, seamless user registration and login with support for social sign-in.

**Functional Requirements:**
- Email/password registration with email verification
- Google OAuth and Apple Sign-In
- JWT-based session management with refresh token rotation
- Forgot password via email OTP
- Account deletion with full data erasure (GDPR compliance)
- Profile setup: name, grade/year, target exam (optional), subjects

**Acceptance Criteria:**
- Login flow completed in under 5 seconds on standard connection
- JWT tokens expire in 15 minutes; refresh tokens valid for 30 days
- Failed login attempts locked after 5 tries (with CAPTCHA on retry)

---

## 5. Advanced Features (Phase 2)

Phase 2 features are built upon a stable Phase 1 foundation. Development begins after the MVP achieves a 4.2+ App Store rating and 50,000 active users.

### 5.1 Focus Score

**Description:** An AI-computed score (0–100) that measures the quality — not just quantity — of a study session, based on session continuity, interruptions, and device usage patterns.

**How It Works:**
- Detects session interruptions (app switching, screen-off events, notification interactions)
- Calculates focus percentage: (uninterrupted time / total session time) × 100
- Assigns a Focus Score label: Poor (<40), Fair (40–60), Good (60–80), Excellent (80–100)
- Provides post-session feedback: "You checked your phone 8 times. Try enabling Do Not Disturb next session."
- Tracks Focus Score trend over time in the analytics dashboard

### 5.2 AI Tutor

**Description:** An in-app AI-powered tutor that answers academic doubts, explains concepts, and provides study suggestions based on the student's subject context.

**Functional Requirements:**
- Chat interface integrated within the app
- Subject-aware context: student selects subject before asking a doubt
- Support for text-based questions and image uploads (for handwritten problems or textbook photos)
- Powered by OpenAI GPT-4o API (or equivalent)
- Response guardrails: AI stays strictly within academic context; refuses off-topic queries
- Session-linked suggestions: after a session, AI suggests related topics to review
- Usage limits: 10 queries/day (free tier); unlimited (premium)

### 5.3 Weak Topic Detection

**Description:** Analyzes quiz and test performance data to automatically identify topics where the student consistently underperforms and surfaces them as priority focus areas.

**How It Works:**
- Student takes in-app tests (MCQ format) per subject after each chapter/topic
- System tracks accuracy per topic over time
- Topics with accuracy below 60% over 3+ attempts flagged as "Weak"
- Weak topics displayed prominently on the dashboard with recommended actions
- Study plan automatically adjusts to prioritize weak topics

### 5.4 Adaptive Test Generation

**Description:** Generates personalized quizzes that adapt in difficulty based on the student's demonstrated performance, ensuring they are always tested at the right level.

**Functional Requirements:**
- Tests generated per subject and chapter using AI (OpenAI API + curated question bank)
- Difficulty levels: Beginner, Intermediate, Advanced
- Adaptive engine: if student scores >80%, next test increases in difficulty; if <50%, difficulty decreases
- Test result stored and linked to weak topic detection engine
- Detailed answer explanations after test submission
- Estimated exam readiness score generated after 5+ tests per subject

---

## 6. Future Scope (Phase 3)

Phase 3 represents the long-term product vision. These features require significant AI/ML infrastructure and will be developed based on Phase 1–2 data learnings and user demand signals.

### 6.1 Predictive Score System

Using historical study data, test performance, and session quality, the AI will predict the student's likely exam score range. This gives students a tangible performance benchmark and allows them to simulate "what if I study X more hours" scenarios. The model will be trained on anonymized, aggregated user performance data.

### 6.2 Burnout Detection

The system will passively monitor study patterns for signs of academic burnout: declining session lengths, dropping focus scores, reduced streak engagement, and irregular study hours. When burnout risk is detected, the app will surface wellness nudges, suggest mandatory breaks, recommend lighter study activities, and optionally connect users to counselor resources.

### 6.3 Voice Assistant

A conversational voice interface that allows students to interact with the app hands-free. Students can start/stop sessions, ask quick doubts, get daily summaries, and receive motivation — all via voice. Built using a combination of on-device speech recognition and cloud NLP processing.

### 6.4 Knowledge Graph Notes

An AI-assisted note-taking system that automatically organizes student notes into an interactive knowledge graph — visualizing how concepts connect across topics and subjects. Students can see how "Newton's Laws" relate to "Work-Energy Theorem," creating a web of interconnected knowledge that enhances retention and revision efficiency.

---

## 7. User Flow

### 7.1 Onboarding Flow

```
App Launch
    │
    ▼
Splash Screen (2 sec) + App Logo Animation
    │
    ▼
Welcome Screen
    ├── Sign Up (New User) ──────────────────────────────────┐
    └── Log In (Returning User)                              │
              │                                              │
              ▼                                              ▼
        Enter Credentials                        Enter Name, Email, Password
        or Google/Apple SSO                      └── Email Verification OTP
              │                                              │
              ▼                                              ▼
        Home Dashboard                           Profile Setup
                                                 ├── Select Grade / Year
                                                 ├── Select Target Exam (optional)
                                                 ├── Add Subjects (minimum 1)
                                                 └── Set Daily Study Goal (hours)
                                                              │
                                                              ▼
                                                        Home Dashboard
```

### 7.2 Study Session Flow

```
Home Dashboard
    │
    ▼
Tap "Start Session"
    │
    ▼
Session Setup Screen
    ├── Select Subject
    ├── Select Timer Mode (Pomodoro / Custom)
    ├── Set Duration (if Custom)
    └── Optional: Add Session Goal (e.g., "Complete Chapter 5")
    │
    ▼
Session Active Screen
    ├── Countdown Timer (prominent)
    ├── Subject Tag Displayed
    ├── Pause / Stop Controls
    └── Focus Mode (optional: blocks notifications)
    │
    ▼
Break Screen (if Pomodoro)
    └── Resume After Break
    │
    ▼
Session End Screen
    ├── Session Summary (duration, subject, focus score)
    ├── Add Notes (optional)
    ├── Rate Session (1–5 stars)
    └── Tap "Done"
    │
    ▼
Home Dashboard (streak updated, analytics refreshed)
```

### 7.3 Analytics Flow

```
Home Dashboard
    │
    ▼
Tap "Analytics" (bottom nav)
    │
    ▼
Analytics Dashboard
    ├── Today's Summary (hours studied, subjects)
    ├── Weekly Bar Chart
    ├── Subject Distribution Donut Chart
    └── Streak Status
    │
    ├── Tap Subject Card
    │       │
    │       ▼
    │   Subject Detail Screen
    │       ├── Total time this week/month
    │       ├── Session history list
    │       └── Weak topics (Phase 2)
    │
    └── Tap "View Report"
            │
            ▼
        Weekly Report Screen
            ├── Full performance breakdown
            ├── AI suggestions (Phase 2)
            └── Share / Export button
```

---

## 8. Tech Stack

### 8.1 Frontend

| Technology | Purpose |
|------------|---------|
| **Flutter (Dart)** | Cross-platform mobile development (iOS + Android from a single codebase) |
| **Riverpod / Bloc** | State management |
| **fl_chart** | Charting and data visualization |
| **Dio** | HTTP client for API communication |
| **Hive / Isar** | Local storage for offline session caching |
| **Firebase Messaging** | Push notifications |

**Rationale:** Flutter enables high-performance, native-feeling apps on both major mobile platforms, reducing development cost significantly while maintaining UI consistency.

### 8.2 Backend

| Technology | Purpose |
|------------|---------|
| **Node.js (Express.js)** | Primary REST API server |
| **TypeScript** | Type safety across backend services |
| **Bull / BullMQ** | Job queues for report generation and AI tasks |
| **Redis** | Caching, session store, rate limiting |
| **Socket.io** | Real-time session sync (future: collaborative study rooms) |

### 8.3 Database

| Technology | Purpose |
|------------|---------|
| **MongoDB Atlas** | Primary document database for user data, sessions, analytics |
| **Firebase Firestore** | Real-time sync for streaks and live session data |
| **Redis** | Ephemeral cache layer for hot data (dashboards, leaderboard) |

### 8.4 AI & ML

| Technology | Purpose |
|------------|---------|
| **OpenAI GPT-4o API** | AI Tutor, adaptive test generation, content explanations |
| **LangChain** | AI orchestration, prompt chaining for complex tutor flows |
| **Python (FastAPI)** | Dedicated AI microservice for ML model inference |
| **Scikit-learn / TensorFlow Lite** | On-device burnout detection model (Phase 3) |
| **Pinecone** | Vector database for knowledge graph notes (Phase 3) |

### 8.5 Cloud Infrastructure & DevOps

| Technology | Purpose |
|------------|---------|
| **AWS (primary)** | EC2, EKS (Kubernetes), S3, CloudFront, RDS |
| **GCP (secondary)** | Vertex AI for custom ML model training (Phase 3) |
| **Docker + Kubernetes** | Containerization and orchestration |
| **GitHub Actions** | CI/CD pipeline |
| **Terraform** | Infrastructure-as-code |
| **Datadog / Sentry** | Monitoring, error tracking, and APM |

---

## 9. System Architecture Overview

```
┌────────────────────────────────────────────────────────────┐
│                    CLIENT LAYER                            │
│          Flutter Mobile App (iOS + Android)                │
│    ┌──────────┐  ┌──────────┐  ┌──────────────────────┐   │
│    │  Timer   │  │Analytics │  │    AI Tutor Chat     │   │
│    │  Module  │  │Dashboard │  │       Interface      │   │
│    └────┬─────┘  └────┬─────┘  └──────────┬───────────┘   │
└─────────┼──────────────┼─────────────────────┼────────────┘
          │              │                     │
          ▼              ▼                     ▼
┌────────────────────────────────────────────────────────────┐
│                 API GATEWAY (AWS API Gateway)               │
│         Rate Limiting │ Auth Validation │ Routing           │
└───────────────────────┬────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
┌───────────────┐ ┌───────────────┐ ┌─────────────────────┐
│  Auth Service │ │Session Service│ │  Analytics Service  │
│  (Node.js)    │ │  (Node.js)    │ │    (Node.js)        │
│               │ │               │ │                     │
│ - JWT Mgmt    │ │ - CRUD Session│ │ - Report Generation │
│ - OAuth SSO   │ │ - Timer Sync  │ │ - Streak Calc       │
│ - User Mgmt   │ │ - Focus Track │ │ - Subject Analytics │
└───────┬───────┘ └───────┬───────┘ └──────────┬──────────┘
        │                 │                     │
        ▼                 ▼                     ▼
┌────────────────────────────────────────────────────────────┐
│                    DATA LAYER                              │
│  ┌──────────────┐  ┌───────────────┐  ┌────────────────┐  │
│  │   MongoDB    │  │    Redis      │  │   Firebase     │  │
│  │   Atlas      │  │   Cache       │  │   Firestore    │  │
│  │ (Primary DB) │  │               │  │ (Real-time)    │  │
│  └──────────────┘  └───────────────┘  └────────────────┘  │
└────────────────────────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────┐
│                 AI MICROSERVICE LAYER                     │
│              (Python FastAPI on AWS ECS)                  │
│  ┌──────────────────┐    ┌──────────────────────────┐    │
│  │  OpenAI GPT-4o   │    │  Custom ML Models         │    │
│  │  (AI Tutor,      │    │  (Weak Topic Detection,   │    │
│  │   Test Gen)      │    │   Burnout Detection)      │    │
│  └──────────────────┘    └──────────────────────────┘    │
└───────────────────────────────────────────────────────────┘
```

**Architecture Principles:**
- **Microservices:** Each domain (Auth, Session, Analytics, AI) is an independently deployable service
- **Event-driven:** Services communicate via message queues (Bull/Redis) for non-blocking operations
- **API-first:** All features are exposed via versioned REST APIs, enabling future web app or third-party integrations
- **Offline-first (client):** Flutter app caches session data locally using Hive; syncs to backend when online

---

## 10. API Structure (High-Level)

All APIs are versioned under `/api/v1/`. All endpoints (except Auth) require a valid Bearer JWT token.

### 10.1 Auth APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/auth/register` | Register new user with email/password |
| `POST` | `/auth/login` | Login and receive JWT + refresh token |
| `POST` | `/auth/refresh` | Refresh expired access token |
| `POST` | `/auth/logout` | Invalidate refresh token |
| `POST` | `/auth/forgot-password` | Send OTP to registered email |
| `POST` | `/auth/reset-password` | Reset password using OTP |
| `POST` | `/auth/google` | Google OAuth sign-in |
| `DELETE` | `/auth/account` | Delete account and all associated data |

### 10.2 Study Session APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/sessions/start` | Create and start a new study session |
| `PATCH` | `/sessions/:id/pause` | Pause an active session |
| `PATCH` | `/sessions/:id/resume` | Resume a paused session |
| `PATCH` | `/sessions/:id/end` | End session and save final data |
| `GET` | `/sessions` | List all sessions (paginated, filterable by date/subject) |
| `GET` | `/sessions/:id` | Get a single session detail |
| `DELETE` | `/sessions/:id` | Delete a session record |

### 10.3 Analytics APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/analytics/dashboard` | Fetch aggregated dashboard data (today, this week) |
| `GET` | `/analytics/subjects` | Subject-wise time distribution |
| `GET` | `/analytics/streak` | Current streak, freeze count, milestones |
| `GET` | `/analytics/reports/daily` | Daily report for a given date |
| `GET` | `/analytics/reports/weekly` | Weekly report for a given week |
| `GET` | `/analytics/reports/export` | Export report as PNG/PDF |

### 10.4 AI APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/ai/tutor/ask` | Submit a doubt/question to AI Tutor |
| `GET` | `/ai/tutor/history` | Fetch conversation history |
| `POST` | `/ai/tests/generate` | Generate an adaptive test for a subject/chapter |
| `POST` | `/ai/tests/:id/submit` | Submit test answers and receive results |
| `GET` | `/ai/weak-topics` | Retrieve detected weak topics for the user |
| `GET` | `/ai/focus-score/:sessionId` | Retrieve computed focus score for a session |

---

## 11. Database Schema (Basic)

### 11.1 Users Collection

```json
{
  "_id": "ObjectId",
  "name": "String",
  "email": "String (unique, indexed)",
  "passwordHash": "String",
  "authProvider": "Enum: ['local', 'google', 'apple']",
  "profile": {
    "grade": "String",
    "targetExam": "String",
    "subjects": ["String"],
    "dailyGoalMinutes": "Number (default: 120)"
  },
  "subscription": {
    "plan": "Enum: ['free', 'premium']",
    "expiresAt": "Date"
  },
  "streak": {
    "current": "Number",
    "longest": "Number",
    "lastStudiedDate": "Date",
    "freezesAvailable": "Number"
  },
  "createdAt": "Date",
  "updatedAt": "Date"
}
```

### 11.2 Study Sessions Collection

```json
{
  "_id": "ObjectId",
  "userId": "ObjectId (ref: Users, indexed)",
  "subject": "String",
  "mode": "Enum: ['pomodoro', 'custom']",
  "status": "Enum: ['active', 'paused', 'completed', 'abandoned']",
  "startTime": "Date",
  "endTime": "Date",
  "plannedDurationMinutes": "Number",
  "actualDurationMinutes": "Number",
  "focusScore": "Number (0–100)",
  "interruptions": "Number",
  "notes": "String",
  "rating": "Number (1–5)",
  "goal": "String",
  "goalCompleted": "Boolean",
  "createdAt": "Date"
}
```

### 11.3 Performance Data Collection

```json
{
  "_id": "ObjectId",
  "userId": "ObjectId (ref: Users, indexed)",
  "subject": "String",
  "chapter": "String",
  "topic": "String",
  "tests": [
    {
      "testId": "ObjectId",
      "dateTaken": "Date",
      "score": "Number",
      "totalQuestions": "Number",
      "correctAnswers": "Number",
      "difficulty": "Enum: ['beginner', 'intermediate', 'advanced']",
      "timeTakenMinutes": "Number"
    }
  ],
  "averageAccuracy": "Number",
  "isWeakTopic": "Boolean",
  "lastUpdated": "Date"
}
```

### 11.4 Reports Collection

```json
{
  "_id": "ObjectId",
  "userId": "ObjectId (ref: Users, indexed)",
  "reportType": "Enum: ['daily', 'weekly']",
  "periodStart": "Date",
  "periodEnd": "Date",
  "totalStudyMinutes": "Number",
  "subjectBreakdown": [
    {
      "subject": "String",
      "minutes": "Number",
      "sessionCount": "Number"
    }
  ],
  "avgFocusScore": "Number",
  "streakAtPeriodEnd": "Number",
  "aiSuggestions": ["String"],
  "generatedAt": "Date"
}
```

---

## 12. Security Considerations

### 12.1 Authentication & Authorization

**JWT Implementation:**
- Access tokens expire in 15 minutes to minimize exposure risk
- Refresh tokens are stored as HTTP-only, Secure cookies (not localStorage)
- Refresh token rotation on every use; old tokens immediately invalidated
- Token blacklist maintained in Redis for logout and suspicious activity scenarios

**Authorization:**
- Role-based access control (RBAC): User, Premium User, Admin
- All endpoints validate token ownership — users can only access their own data
- Admin endpoints require a separate admin JWT with IP whitelisting

### 12.2 Data Encryption

- All data in transit encrypted via TLS 1.3
- MongoDB Atlas encryption at rest (AES-256)
- Passwords hashed using bcrypt with a minimum cost factor of 12
- Sensitive fields (email, name) encrypted at the application level before storage using AES-256-GCM

### 12.3 API Security

- Rate limiting enforced at API Gateway level: 100 requests/minute per user; 10 requests/minute for Auth endpoints
- OWASP Top 10 mitigations applied: input validation, parameterized queries, SQL/NoSQL injection prevention
- Helmet.js applied to all Express routes (XSS, CSRF, clickjacking protection)
- CORS configured to allow only known client origins
- All AI API calls proxied through backend — OpenAI API key never exposed to client

### 12.4 Compliance

- GDPR: Users can export their data and request full deletion
- COPPA: Users under 13 are blocked during registration (DOB validation)
- Privacy Policy and Terms of Service presented during onboarding (click-to-accept, logged with timestamp)

---

## 13. Scalability Considerations

### 13.1 Target Scale

| Metric | Phase 1 Target | Phase 2 Target | Phase 3 Target |
|--------|---------------|---------------|---------------|
| Registered Users | 100,000 | 1,000,000 | 10,000,000+ |
| Daily Active Users | 20,000 | 200,000 | 2,000,000+ |
| Concurrent Sessions | 5,000 | 50,000 | 500,000 |
| API Requests/sec | 500 | 5,000 | 50,000 |

### 13.2 Cloud Infrastructure

**Compute:**
- Backend services deployed on Amazon EKS (Kubernetes) with Horizontal Pod Autoscaling (HPA)
- AI microservice on AWS ECS with GPU-enabled instances (for ML inference in Phase 3)
- Auto Scaling Groups ensure capacity scales with traffic spikes (e.g., exam season)

**Database Scaling:**
- MongoDB Atlas: sharded cluster with read replicas for analytics queries
- Redis Cluster: distributed caching with consistent hashing
- Database connection pooling via PgBouncer-equivalent for Node.js

**Content Delivery:**
- Static assets (app images, report exports) served via AWS CloudFront CDN
- CDN edge nodes in India, US, Europe, and Southeast Asia for low-latency delivery

### 13.3 Load Balancing

- AWS Application Load Balancer (ALB) distributes traffic across service instances
- Weighted routing enables canary deployments (e.g., 5% traffic to new version before full rollout)
- Circuit breaker pattern implemented (via `opossum`) to prevent cascade failures

### 13.4 Modular Backend Design

Each microservice is independently:
- Deployable (separate Docker image, CI/CD pipeline)
- Scalable (own HPA policies based on CPU/memory/queue depth)
- Fault-isolated (a failure in the AI service does not impact session tracking)

---

## 14. Non-Functional Requirements

### 14.1 Performance

| Requirement | Target |
|-------------|--------|
| API Response Time (P95) | < 300ms |
| Dashboard Load Time | < 1.5 seconds (4G network) |
| App Cold Start Time | < 2 seconds |
| Timer Accuracy | ± 1 second |
| Report Generation Time | < 30 seconds |
| AI Tutor Response Time | < 5 seconds |

### 14.2 Reliability

| Requirement | Target |
|-------------|--------|
| Service Uptime (SLA) | 99.9% (≤ 8.7 hours downtime/year) |
| Data Durability | 99.999999999% (11 nines — MongoDB Atlas standard) |
| Session Data Loss on Crash | Zero — sessions auto-saved every 30 seconds |
| Failed API Retry Policy | Exponential backoff with 3 max retries |

### 14.3 Availability

- Multi-Availability Zone (Multi-AZ) deployment for all critical services on AWS
- Automated failover for database primary failure (< 30 second recovery)
- Health checks on all services via Kubernetes liveness/readiness probes
- Maintenance windows scheduled between 2–4 AM local time, announced 48 hours in advance

### 14.4 Usability

- App supports English, Hindi, and Tamil at Phase 1 launch (internalization framework: Flutter Intl)
- Minimum supported OS: Android 8.0 (API Level 26); iOS 14.0
- WCAG 2.1 Level AA accessibility compliance (screen reader support, contrast ratios)
- Offline mode: timer and local session storage fully functional without internet

---

## 15. Future Enhancements & Roadmap

### Quarterly Roadmap

```
Q1 2026 — Phase 1 MVP Launch
├── User Authentication & Onboarding
├── Study Timer (Pomodoro + Custom)
├── Subject-wise Analytics Dashboard
├── Streak System & Milestones
└── Daily & Weekly Reports

Q2 2026 — Growth & Stabilization
├── Performance optimization based on real user data
├── Android & iOS app store ratings improvement
├── A/B testing framework implementation
├── Friend groups & streak leaderboard
└── Referral program launch

Q3 2026 — Phase 2: AI Intelligence Layer
├── Focus Score system
├── AI Tutor (text + image input)
├── Adaptive Test Generation (MCQ)
└── Weak Topic Detection engine

Q4 2026 — Phase 2: Deepening
├── AI-powered weekly study plan generation
├── Exam countdown & readiness score
├── Premium subscription (₹299/month or $4.99/month)
└── School/coaching institute partnerships (B2B pilot)

Q1–Q2 2027 — Phase 3: Advanced AI
├── Predictive Score System
├── Burnout Detection & wellness nudges
├── Voice Assistant integration
└── Knowledge Graph Notes (beta)

Q3–Q4 2027 — Platform Expansion
├── Web app launch (Next.js)
├── Parent dashboard (progress visibility for minors)
├── API for third-party EdTech integrations
└── Regional language expansion (5+ languages)
```

### Long-Term Vision

By 2028, AI Study Coach aims to be:

**The academic operating system for 10 million students** — a platform where every student, regardless of their socioeconomic background, has access to a world-class AI-powered study coach that knows their strengths, addresses their weaknesses, keeps them motivated, and guides them toward their academic goals with the precision of a personal tutor and the scale of a platform.

---

## Appendix

### A. Glossary

| Term | Definition |
|------|------------|
| **Pomodoro** | A time management technique: 25 minutes of focused work followed by a 5-minute break |
| **Focus Score** | AI-computed quality metric for a study session (0–100) |
| **Streak** | Consecutive days of meeting the minimum daily study goal |
| **Streak Freeze** | A token that preserves a streak when a student misses a day |
| **Weak Topic** | A topic where the student's average test accuracy falls below 60% |
| **Adaptive Test** | A test whose difficulty adjusts dynamically based on prior performance |
| **MVP** | Minimum Viable Product — the smallest functional version of the product |
| **SLA** | Service Level Agreement — a commitment to system uptime and performance |
| **JWT** | JSON Web Token — a secure, stateless authentication mechanism |

### B. Key Assumptions

1. Students have access to a smartphone running Android 8+ or iOS 14+
2. Minimum 2G connectivity available for session sync (offline-first for timer)
3. OpenAI API pricing remains commercially viable at scale
4. App Store and Play Store guidelines permit all described features at launch

### C. Open Questions

1. Should AI Tutor responses be moderated for academic integrity (anti-cheating policy)?
2. What is the data retention policy for session data of deleted accounts?
3. Will the app support parental controls for users under 18?
4. Should test questions be fully AI-generated or from a curated, human-verified question bank?

---

*This document is maintained by the AI Study Coach Product Team. For questions or contributions, contact the Product Manager. All changes must be reviewed and approved before being merged into the main document.*

*© 2026 AI Study Coach. All rights reserved.*