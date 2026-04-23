# AI Study Coach — System Design Document

> **Version:** 1.0.0  
> **Status:** Production-Ready Draft  
> **Audience:** Engineering, Product, and Architecture Teams  

---

## Table of Contents

1. [Overview](#1-overview)
2. [High-Level Architecture](#2-high-level-architecture)
3. [Architecture Diagram (Text Explanation)](#3-architecture-diagram-text-explanation)
4. [Frontend Architecture](#4-frontend-architecture)
5. [Backend Architecture](#5-backend-architecture)
6. [Database Design](#6-database-design)
7. [API Design (High-Level)](#7-api-design-high-level)
8. [Data Flow](#8-data-flow)
9. [Authentication & Authorization](#9-authentication--authorization)
10. [Scalability Strategy](#10-scalability-strategy)
11. [Performance Optimization](#11-performance-optimization)
12. [Security Considerations](#12-security-considerations)
13. [Deployment Architecture](#13-deployment-architecture)
14. [Monitoring & Logging](#14-monitoring--logging)
15. [Future Enhancements](#15-future-enhancements)

---

## 1. Overview

### 1.1 System Description

**AI Study Coach** is a cross-platform mobile application that leverages artificial intelligence to deliver personalized, adaptive learning experiences. The application tracks user study sessions, generates intelligent analytics on learning patterns, provides AI-driven recommendations, answers subject-specific questions, and helps users build consistent study habits through smart nudges and goal management.

The system is designed to serve students from high school through postgraduate levels, as well as self-directed learners and professionals engaged in continuous education.

### 1.2 Goals

| Goal | Description |
|---|---|
| **Scalability** | Support horizontal scaling to handle tens of thousands of concurrent users without architectural rewrites |
| **Performance** | API response times under 200ms for standard operations; AI-assisted responses under 3 seconds |
| **Reliability** | Target 99.9% uptime (≤ 8.7 hours downtime/year) with graceful degradation for AI service failures |
| **Security** | End-to-end encryption, JWT-based auth, rate limiting, and OWASP-compliant API design |
| **Maintainability** | Modular, well-documented codebase following clean architecture principles |
| **Developer Experience** | CI/CD pipelines, environment parity, and automated testing at all layers |

---

## 2. High-Level Architecture

The system follows a **client–server architecture** with a clear separation between the mobile frontend, the application backend, persistent data storage, and third-party AI services.

### 2.1 Components

#### Mobile App — Flutter (Frontend)
The Flutter application serves as the primary user interface across iOS and Android from a single codebase. It handles:
- User authentication flows (login, signup, token refresh)
- Study session creation, tracking, and management
- Analytics dashboards and progress visualization
- AI chat interface for the study coach persona
- Offline-capable session logging with sync on reconnect

#### Backend Server — Node.js with Express
A RESTful API server built on Node.js and Express.js acts as the central orchestration layer. It is stateless, enabling horizontal scaling. Responsibilities include:
- Routing and request validation
- Business logic execution (session scoring, streak calculation)
- Delegating AI requests to OpenAI or equivalent services
- Managing database reads and writes
- Enforcing authentication and authorization policies

#### Database — MongoDB (Primary) + Firebase (Supplementary)
- **MongoDB Atlas** serves as the primary database for user profiles, study sessions, and analytics — chosen for its flexible document model and native horizontal sharding.
- **Firebase Firestore** (optional supplementary layer) can be used for real-time features such as live session sync and push notification triggers.
- **Redis** is used as an in-memory cache for session tokens, rate limiting counters, and frequently accessed aggregates.

#### AI Services — OpenAI API (GPT-4o / GPT-4 Turbo)
AI capabilities are provided via the OpenAI API (or an equivalent provider such as Anthropic Claude or Gemini). The backend proxies all AI requests, injecting user context, study history, and system prompts before forwarding. This design:
- Keeps API keys server-side and never exposed to the client
- Enables context enrichment before each AI call
- Allows future swap of the AI provider with no frontend changes

### 2.2 Component Interaction Summary

```
Flutter App  ←→  Node.js / Express API  ←→  MongoDB Atlas
                         ↕                        ↕
                    OpenAI API               Redis Cache
                         ↕
                  Firebase (optional real-time)
```

All client-server communication occurs over HTTPS. The backend communicates with AI APIs over secure HTTPS with API key authentication managed via environment secrets.

---

## 3. Architecture Diagram (Text Explanation)

### End-to-End Request Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                        USER DEVICE (Mobile)                         │
│                        Flutter Application                          │
│  ┌──────────┐   ┌───────────────┐   ┌───────────────────────────┐  │
│  │  UI Layer│→  │ State Manager │→  │   API Integration Layer   │  │
│  │ (Widgets)│   │  (Riverpod)   │   │ (Dio HTTP Client + Repos) │  │
│  └──────────┘   └───────────────┘   └────────────┬──────────────┘  │
└────────────────────────────────────────────────────┼────────────────┘
                                                     │ HTTPS / REST
                                                     ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     BACKEND SERVER (Node.js)                        │
│  ┌──────────────┐  ┌───────────────┐  ┌────────────────────────┐  │
│  │    Nginx     │→ │  Express App  │→ │  Route → Controller →  │  │
│  │ Load Balancer│  │  (Middleware) │  │  Service → Repository  │  │
│  └──────────────┘  └───────────────┘  └────────┬───────────────┘  │
└───────────────────────────────────────────────┬─┴────────────────── ┘
                        ┌──────────────────────┘│
                        ▼                       ▼
        ┌───────────────────────┐    ┌──────────────────────┐
        │    MongoDB Atlas      │    │     OpenAI API        │
        │  (Primary Database)   │    │  (AI Completions /   │
        │  Users, Sessions,     │    │   Embeddings)        │
        │  Analytics            │    └──────────┬───────────┘
        └───────────────────────┘               │
        ┌───────────────────────┐               │
        │      Redis Cache      │◄──────────────┘
        │  (Tokens, Rate Limits,│  (Response cached
        │   Hot Aggregates)     │   where appropriate)
        └───────────────────────┘
                        │
                        ▼
        ┌───────────────────────┐
        │  Firebase / FCM       │
        │  (Push Notifications, │
        │   Real-time Sync)     │
        └───────────────────────┘
```

### Request Lifecycle (Step by Step)

1. **User Action** — The user starts a study session or sends a message to the AI coach.
2. **State Update** — Riverpod state notifier updates optimistically; a repository method is called.
3. **HTTP Request** — Dio client sends an authenticated REST request with a JWT Bearer token.
4. **Nginx Ingress** — Load balancer routes the request to an available backend instance.
5. **Middleware Chain** — Rate limiter → JWT verifier → request logger → body validator.
6. **Controller** — Receives the validated request, invokes the appropriate service.
7. **Service Layer** — Applies business logic. For AI requests, enriches the prompt with user context.
8. **Database / AI Call** — Reads/writes MongoDB; calls OpenAI API if required.
9. **Cache Check** — Redis checked before expensive DB aggregations.
10. **Response** — Structured JSON response returned through the chain back to the Flutter app.
11. **UI Update** — Riverpod rebuilds affected widgets; user sees updated state.

---

## 4. Frontend Architecture

### 4.1 Technology Stack

| Concern | Choice | Rationale |
|---|---|---|
| Framework | Flutter 3.x | Single codebase for iOS & Android; high performance rendering |
| Language | Dart | Strongly typed; great async support |
| State Management | Riverpod 2.x | Compile-safe providers; testable; no BuildContext dependency |
| HTTP Client | Dio | Interceptors, retry logic, cancellation tokens |
| Local Storage | Hive / SharedPreferences | Lightweight persistence for offline session buffering |
| Routing | GoRouter | Declarative, URL-based; deep link support |
| Charts | FL Chart | Lightweight, customizable analytics visualizations |

### 4.2 State Management — Riverpod

Riverpod is used throughout the application. Each feature domain exposes:
- **Providers** — Dependency injection for repositories and services
- **StateNotifierProviders** — Mutable state for session tracking, auth, analytics
- **FutureProviders** — Async data fetching with built-in loading/error states
- **StreamProviders** — For real-time Firebase data (optional)

Example mental model:
```
AuthNotifierProvider  →  AuthState (unauthenticated | loading | authenticated)
SessionNotifierProvider  →  SessionState (idle | active | paused | completed)
AnalyticsProvider  →  AsyncValue<AnalyticsSummary>
AICoachProvider  →  List<ChatMessage>
```

### 4.3 Folder Structure

```
lib/
├── core/
│   ├── config/           # App constants, environment variables
│   ├── errors/           # Failure classes, exception handlers
│   ├── network/          # Dio client setup, interceptors
│   ├── router/           # GoRouter configuration
│   └── utils/            # Date helpers, formatters, validators
│
├── features/
│   ├── auth/
│   │   ├── data/         # AuthRepository, AuthRemoteDataSource, DTOs
│   │   ├── domain/       # User model, AuthFailure types
│   │   └── presentation/ # LoginScreen, SignupScreen, AuthNotifier
│   │
│   ├── study_session/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/ # SessionScreen, TimerWidget, SessionNotifier
│   │
│   ├── analytics/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/ # AnalyticsDashboard, Charts, HeatmapWidget
│   │
│   └── ai_coach/
│       ├── data/
│       ├── domain/
│       └── presentation/ # ChatScreen, MessageBubble, CoachNotifier
│
├── shared/
│   ├── widgets/          # Reusable UI components (buttons, cards, inputs)
│   └── theme/            # Typography, colors, ThemeData
│
└── main.dart             # App entry point, ProviderScope root
```

### 4.4 API Integration Layer

All backend communication is abstracted behind **Repository** interfaces. The `Dio` HTTP client is configured with:
- **Auth Interceptor** — Attaches Bearer token to every request
- **Refresh Interceptor** — Automatically attempts token refresh on 401 responses
- **Error Interceptor** — Transforms HTTP errors into typed `Failure` objects
- **Logging Interceptor** — Debug-mode request/response logging

```dart
// Example: Dio instance configuration
final dio = Dio(BaseOptions(baseUrl: Env.apiBaseUrl))
  ..interceptors.addAll([
    AuthInterceptor(tokenStorage),
    TokenRefreshInterceptor(authRepository),
    ErrorMappingInterceptor(),
    if (kDebugMode) LoggingInterceptor(),
  ]);
```

---

## 5. Backend Architecture

### 5.1 Technology Stack

| Concern | Choice |
|---|---|
| Runtime | Node.js 20 LTS |
| Framework | Express.js 4.x |
| Language | TypeScript |
| ODM | Mongoose 8.x |
| Caching | Redis (ioredis) |
| Job Queue | Bull (Redis-backed) |
| Validation | Zod |
| Auth | jsonwebtoken + bcryptjs |
| Testing | Jest + Supertest |

### 5.2 Modular Project Structure

```
src/
├── config/
│   ├── db.ts             # MongoDB connection
│   ├── redis.ts          # Redis client
│   └── env.ts            # Validated environment config (Zod)
│
├── modules/
│   ├── auth/
│   │   ├── auth.controller.ts
│   │   ├── auth.service.ts
│   │   ├── auth.routes.ts
│   │   └── auth.dto.ts
│   │
│   ├── session/
│   │   ├── session.controller.ts
│   │   ├── session.service.ts
│   │   ├── session.routes.ts
│   │   └── session.dto.ts
│   │
│   ├── analytics/
│   │   ├── analytics.controller.ts
│   │   ├── analytics.service.ts
│   │   └── analytics.routes.ts
│   │
│   └── ai/
│       ├── ai.controller.ts
│       ├── ai.service.ts      # OpenAI client wrapper
│       └── ai.routes.ts
│
├── middleware/
│   ├── authenticate.ts    # JWT verification
│   ├── authorize.ts       # Role-based access control
│   ├── rateLimiter.ts     # express-rate-limit + Redis store
│   ├── validate.ts        # Zod schema validation middleware
│   ├── errorHandler.ts    # Global error handler
│   └── requestLogger.ts   # Morgan / structured logging
│
├── models/               # Mongoose schema definitions
├── jobs/                 # Bull queue workers (analytics aggregation)
├── utils/                # Shared helpers
└── app.ts                # Express app setup
```

### 5.3 REST API Design Principles

- **Versioned routes** — All routes prefixed with `/api/v1/`
- **Resource-based naming** — Nouns, not verbs (`/sessions`, not `/getSession`)
- **Consistent response envelope:**

```json
{
  "success": true,
  "data": { ... },
  "meta": { "page": 1, "total": 42 },
  "error": null
}
```

- **HTTP status codes used semantically** — 200, 201, 400, 401, 403, 404, 422, 429, 500

### 5.4 Middleware Pipeline

Every incoming request traverses the following middleware chain in order:

```
Request
  → CORS Headers
  → Helmet (Security Headers)
  → Rate Limiter
  → JSON Body Parser
  → Request Logger
  → Route Match
    → JWT Authentication
    → Role Authorization (where applicable)
    → Zod Schema Validation
    → Controller Handler
  → Global Error Handler
  → Response
```

### 5.5 Error Handling

A centralized `AppError` class wraps all operational errors:

```typescript
class AppError extends Error {
  constructor(
    public message: string,
    public statusCode: number,
    public code: string,
    public isOperational = true
  ) { super(message); }
}
```

The global error handler middleware distinguishes between operational errors (return structured 4xx/5xx) and programming errors (log and return generic 500). Unhandled promise rejections and uncaught exceptions are captured and trigger graceful shutdown with alerting.

---

## 6. Database Design

### 6.1 MongoDB Collections

#### `users`

```json
{
  "_id": "ObjectId",
  "email": "string (unique, indexed)",
  "passwordHash": "string",
  "displayName": "string",
  "avatarUrl": "string | null",
  "role": "enum: student | admin",
  "preferences": {
    "dailyGoalMinutes": "number",
    "subjects": ["string"],
    "notificationsEnabled": "boolean",
    "timezone": "string"
  },
  "streak": {
    "current": "number",
    "longest": "number",
    "lastStudiedDate": "ISODate"
  },
  "createdAt": "ISODate",
  "updatedAt": "ISODate"
}
```

**Indexes:** `email` (unique), `createdAt` (TTL index for unverified accounts)

---

#### `studySessions`

```json
{
  "_id": "ObjectId",
  "userId": "ObjectId (ref: users, indexed)",
  "subject": "string",
  "topic": "string | null",
  "startTime": "ISODate",
  "endTime": "ISODate | null",
  "durationSeconds": "number",
  "status": "enum: active | completed | abandoned",
  "focusScore": "number (0-100)",
  "breakCount": "number",
  "notes": "string | null",
  "tags": ["string"],
  "aiInteractions": "number",
  "createdAt": "ISODate"
}
```

**Indexes:**
- `{ userId: 1, startTime: -1 }` — Compound index for per-user chronological queries
- `{ userId: 1, subject: 1 }` — Subject-based analytics queries
- `{ status: 1 }` — Querying active sessions

---

#### `analytics`

Pre-aggregated daily snapshots for fast dashboard loading.

```json
{
  "_id": "ObjectId",
  "userId": "ObjectId (ref: users, indexed)",
  "date": "ISODate (date-only, indexed)",
  "totalMinutes": "number",
  "sessionCount": "number",
  "subjectBreakdown": {
    "mathematics": 45,
    "physics": 30
  },
  "averageFocusScore": "number",
  "goalAchieved": "boolean",
  "streakDay": "number",
  "createdAt": "ISODate"
}
```

**Indexes:**
- `{ userId: 1, date: -1 }` — Primary query pattern
- `{ userId: 1, date: 1 }` — Sparse unique index to prevent duplicate daily records

---

#### `aiConversations`

```json
{
  "_id": "ObjectId",
  "userId": "ObjectId (ref: users)",
  "sessionId": "ObjectId (ref: studySessions, nullable)",
  "messages": [
    {
      "role": "enum: user | assistant | system",
      "content": "string",
      "timestamp": "ISODate"
    }
  ],
  "subject": "string | null",
  "tokensUsed": "number",
  "createdAt": "ISODate",
  "updatedAt": "ISODate"
}
```

**Note:** Messages are embedded (not referenced) for atomic reads. Conversations with very large message counts are paginated via the `messages` array slice.

### 6.2 Relationships

```
users  ──< studySessions     (one-to-many, via userId)
users  ──< analytics         (one-to-many, via userId; one per day)
users  ──< aiConversations   (one-to-many, via userId)
studySessions ──< aiConversations (optional link via sessionId)
```

### 6.3 Indexing Strategy

- All foreign key fields (`userId`, `sessionId`) are indexed
- Compound indexes follow query patterns (`{ userId, date }`, `{ userId, startTime }`)
- Text index on `studySessions.notes` and `studySessions.tags` for full-text search
- Analytics collection uses a unique sparse index on `{ userId, date }` to enforce one document per user per day

---

## 7. API Design (High-Level)

All routes are prefixed: `/api/v1/`

### 7.1 Authentication APIs

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/auth/signup` | Register a new user | No |
| `POST` | `/auth/login` | Authenticate and receive JWT tokens | No |
| `POST` | `/auth/refresh` | Refresh access token using refresh token | No (refresh token) |
| `POST` | `/auth/logout` | Invalidate refresh token | Yes |
| `POST` | `/auth/forgot-password` | Initiate password reset flow | No |
| `POST` | `/auth/reset-password` | Complete password reset | No |
| `GET` | `/auth/me` | Get current authenticated user profile | Yes |

### 7.2 Study Session APIs

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/sessions` | Create and start a new study session | Yes |
| `GET` | `/sessions` | List user's sessions (paginated, filterable) | Yes |
| `GET` | `/sessions/:id` | Get a specific session by ID | Yes |
| `PATCH` | `/sessions/:id` | Update session (pause, resume, end) | Yes |
| `DELETE` | `/sessions/:id` | Delete a session | Yes |
| `GET` | `/sessions/active` | Get currently active session (if any) | Yes |

**Query Parameters for `GET /sessions`:** `page`, `limit`, `subject`, `status`, `from`, `to`, `sortBy`

### 7.3 Analytics APIs

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `GET` | `/analytics/summary` | Overall summary stats | Yes |
| `GET` | `/analytics/daily` | Daily analytics for a date range | Yes |
| `GET` | `/analytics/weekly` | Weekly aggregated view | Yes |
| `GET` | `/analytics/subjects` | Per-subject breakdown | Yes |
| `GET` | `/analytics/streak` | Current and longest streak info | Yes |
| `GET` | `/analytics/heatmap` | Study activity heatmap data | Yes |

### 7.4 AI Integration APIs

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/ai/chat` | Send a message to the AI study coach | Yes |
| `GET` | `/ai/conversations` | List conversation histories | Yes |
| `GET` | `/ai/conversations/:id` | Get a specific conversation | Yes |
| `POST` | `/ai/explain` | Ask AI to explain a concept | Yes |
| `POST` | `/ai/quiz` | Generate a quiz on a topic | Yes |
| `POST` | `/ai/recommend` | Get personalized study recommendations | Yes |

### 7.5 User Profile APIs

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `GET` | `/users/profile` | Get user profile | Yes |
| `PATCH` | `/users/profile` | Update profile and preferences | Yes |
| `PATCH` | `/users/password` | Change password | Yes |
| `DELETE` | `/users/account` | Delete account (soft delete) | Yes |

---

## 8. Data Flow

### 8.1 Study Session Tracking Flow

```
1. User taps "Start Session" in the Flutter app
2. SessionNotifier calls SessionRepository.startSession(subject, topic)
3. Dio client sends POST /api/v1/sessions with JWT Bearer token
4. Backend: authenticate → validate body (Zod) → SessionController.create()
5. SessionService checks for any existing active session for this user
6. If none: creates a new StudySession document in MongoDB (status: "active")
7. Returns session object with _id and startTime
8. Flutter: SessionNotifier updates state → TimerWidget begins counting
9. At session end: User taps "End Session"
10. PATCH /api/v1/sessions/:id with { status: "completed", endTime, focusScore }
11. Backend: SessionService calculates durationSeconds, updates document
12. Triggers async analytics aggregation job via Bull queue
13. Streak calculation runs and updates users.streak fields
14. Response returned; Flutter navigates to session summary screen
```

### 8.2 Analytics Generation Flow

```
1. Session completion triggers a Bull queue job: "aggregate-daily-analytics"
2. Analytics Worker picks up the job
3. Worker queries studySessions for all sessions on the user's current date
4. Aggregates: totalMinutes, sessionCount, subjectBreakdown, averageFocusScore
5. Compares totalMinutes to users.preferences.dailyGoalMinutes → sets goalAchieved
6. Upserts the analytics document for { userId, date }
7. Updates Redis cache key "analytics:{userId}:summary" with new data
8. If goalAchieved: triggers Firebase FCM push notification ("Daily goal reached! 🎉")
9. Flutter app polls GET /analytics/summary → cache hit, returns instantly
```

### 8.3 AI Request/Response Flow

```
1. User types a message in the AI Coach chat screen
2. CoachNotifier optimistically appends user message to chat state
3. POST /api/v1/ai/chat with { message, conversationId? }
4. Backend: AIController.chat() → AIService.processMessage()
5. AIService fetches conversation history from MongoDB (last N messages)
6. Fetches user context: current subject, recent sessions, focus score trend
7. Constructs enriched system prompt:
   - Persona: "You are a supportive, expert AI study coach..."
   - Context: "User is studying {subject}. Avg focus today: {score}. Struggling topics: {list}"
   - History: Last N conversation turns
8. Calls OpenAI API: POST https://api.openai.com/v1/chat/completions
9. Streams response tokens back to backend (streaming optional)
10. Backend appends both user message and AI reply to aiConversations document
11. Records tokensUsed for cost tracking
12. Returns AI response to client
13. Flutter: CoachNotifier appends AI message → ChatBubble renders with typewriter animation
```

---

## 9. Authentication & Authorization

### 9.1 JWT-Based Authentication

The system uses a **dual-token strategy:**

| Token | Lifespan | Storage | Purpose |
|---|---|---|---|
| Access Token | 15 minutes | In-memory (Riverpod state) | Authorizes API requests |
| Refresh Token | 30 days | Secure HTTP-only cookie or encrypted storage | Obtains new access tokens |

**Token Structure (Access Token Payload):**
```json
{
  "sub": "userId",
  "email": "user@example.com",
  "role": "student",
  "iat": 1714000000,
  "exp": 1714000900
}
```

**Refresh Flow:**
1. Access token expires → Dio's refresh interceptor automatically calls `POST /auth/refresh`
2. Backend validates refresh token (signature + expiry + Redis blocklist check)
3. Issues new access token (and optionally rotates refresh token)
4. Original request is retried transparently

**Token Invalidation:**
- On logout, the refresh token is added to a Redis blocklist with a TTL matching its expiry
- Password change invalidates all existing refresh tokens for that user

### 9.2 Authorization

Role-based access is enforced via the `authorize` middleware:

```typescript
// Example: Admin-only route
router.get('/admin/users', authenticate, authorize('admin'), AdminController.listUsers);
```

Resource-level ownership is validated in the service layer:
```typescript
if (session.userId.toString() !== requestingUserId) {
  throw new AppError('Forbidden', 403, 'ACCESS_DENIED');
}
```

### 9.3 Security Hardening

- Passwords hashed with **bcrypt** (cost factor 12)
- JWT signed with **RS256** (asymmetric) in production — private key signs, public key verifies
- All tokens transmitted only over HTTPS
- `Helmet.js` sets security-relevant HTTP headers on all responses

---

## 10. Scalability Strategy

### 10.1 Stateless Backend

The Express server holds no session state in memory. All state is externalized to MongoDB and Redis. This means any number of server instances can handle any request — a foundational requirement for horizontal scaling.

### 10.2 Horizontal Scaling

- Backend deployed as Docker containers managed by **Kubernetes (EKS / GKE)**
- Kubernetes Horizontal Pod Autoscaler (HPA) scales pods based on CPU and memory thresholds
- Target: scale out beyond 4 pods when CPU > 70% sustained

### 10.3 Load Balancing

- **AWS Application Load Balancer (ALB)** or **GCP Cloud Load Balancing** distributes traffic across pods
- Nginx ingress controller manages internal routing within the cluster
- Session stickiness is not required since the backend is stateless

### 10.4 Database Scaling

- **MongoDB Atlas** enables horizontal sharding on `userId` as the shard key — ensuring a single user's data is co-located, while distributing across shards by user
- **Read replicas** serve analytics read queries, isolating heavy aggregation from write operations
- **Redis Cluster** for cache layer availability

### 10.5 Queue-Based Workload Offloading

Heavy or slow operations (analytics aggregation, email delivery, AI batch processing) are offloaded to **Bull job queues** backed by Redis. This prevents slow operations from blocking API response times.

### 10.6 Microservices — Future Scope

The current modular monolith is structured to be decomposed into microservices when warranted by load:

```
Monolith Module   →   Future Microservice
──────────────────────────────────────────
auth/             →   auth-service
session/          →   session-service
analytics/        →   analytics-service (most likely first to split)
ai/               →   ai-gateway-service
```

Each module has clear boundaries, its own routes and services, and minimal cross-module dependencies.

---

## 11. Performance Optimization

### 11.1 Caching Strategy (Redis)

| Cache Key Pattern | TTL | Purpose |
|---|---|---|
| `user:{id}:profile` | 5 min | Avoid repeated user lookups |
| `analytics:{id}:summary` | 10 min | Dashboard load speed |
| `analytics:{id}:heatmap` | 1 hour | Expensive date-range aggregation |
| `ratelimit:{ip}` | 1 min | Rate limiting counters |
| `blocklist:{token}` | Token TTL | Invalidated JWT refresh tokens |

Cache invalidation follows **write-through**: on any data mutation, the relevant cache keys are deleted immediately, ensuring consistency on the next read.

### 11.2 Pagination

All list endpoints use **cursor-based pagination** for study sessions (more efficient than offset for large collections) and **offset pagination** for analytics ranges:

```
GET /sessions?limit=20&cursor=<lastId>
GET /analytics/daily?from=2025-01-01&to=2025-03-31&page=1&limit=90
```

### 11.3 Database Query Optimization

- All query patterns are backed by compound indexes (see Section 6.3)
- MongoDB **projection** used to return only required fields (`{ subject: 1, durationSeconds: 1 }`)
- **Aggregation pipelines** used for analytics instead of application-level computation
- Long-running analytics aggregations run in background Bull workers, not in request handlers

### 11.4 AI Response Optimization

- **OpenAI streaming** enabled for chat responses — first tokens arrive in ~300ms, improving perceived latency
- Conversation history truncated to last 20 messages to control token usage and latency
- Common AI responses (quiz templates, topic explanations) cached in Redis for 1 hour by hash of the prompt

### 11.5 Mobile Optimizations

- **Offline-first sessions** — Session timing continues locally if network drops; sync on reconnect
- **Image caching** — Cached via Flutter's built-in image cache + `cached_network_image`
- **Lazy loading** — Analytics charts only render when scrolled into view

---

## 12. Security Considerations

### 12.1 Transport Security

- All client-server communication over **TLS 1.2+** (enforced via ALB policy)
- HSTS headers (`Strict-Transport-Security`) prevent protocol downgrade attacks
- Certificate management via **AWS ACM** (auto-renewing)

### 12.2 Data Encryption

- **At rest:** MongoDB Atlas encrypts data at rest with AES-256 by default
- **In transit:** TLS for all DB connections (MongoDB + Redis with TLS enabled)
- **Sensitive fields:** Passwords stored as bcrypt hashes; never logged or returned in responses
- **PII minimization:** Analytics aggregates contain no raw message content

### 12.3 API Rate Limiting

Rate limiting enforced per user (authenticated) and per IP (unauthenticated):

| Endpoint Group | Limit |
|---|---|
| Auth endpoints | 10 requests / 15 minutes per IP |
| General API | 300 requests / 15 minutes per user |
| AI endpoints | 30 requests / minute per user |
| Analytics endpoints | 60 requests / minute per user |

Implemented with `express-rate-limit` using a Redis store for distributed enforcement across multiple backend instances.

### 12.4 Input Validation

All incoming request bodies and query parameters are validated with **Zod schemas** before reaching the controller. Invalid requests receive a `422 Unprocessable Entity` response with field-level error detail. Raw user input is never interpolated into MongoDB queries (Mongoose ODM parameterizes all queries, preventing NoSQL injection).

### 12.5 AI Prompt Injection Defense

User messages passed to OpenAI are:
- Sanitized to remove control characters
- Wrapped in clearly delineated prompt sections
- Subject to content moderation pre-check using OpenAI's moderation endpoint before processing

### 12.6 Other Measures

- `cors` configured with an explicit origin allowlist (no wildcard in production)
- `helmet` sets `X-Content-Type-Options`, `X-Frame-Options`, `Content-Security-Policy`
- Server-side secrets (API keys, DB URIs) stored in **AWS Secrets Manager** — never in code or environment files committed to version control
- Dependency auditing via `npm audit` in CI pipeline; critical vulnerabilities block deployment

---

## 13. Deployment Architecture

### 13.1 Cloud Infrastructure

**Primary:** AWS (preferred) or GCP

| Service | AWS | GCP |
|---|---|---|
| Container Orchestration | EKS (Kubernetes) | GKE |
| Container Registry | ECR | Artifact Registry |
| Load Balancer | ALB | Cloud Load Balancing |
| Database | MongoDB Atlas (multi-cloud) | MongoDB Atlas |
| Cache | ElastiCache (Redis) | Memorystore |
| Object Storage | S3 | Cloud Storage |
| Secrets | Secrets Manager | Secret Manager |
| CDN | CloudFront | Cloud CDN |

### 13.2 Environments

| Environment | Purpose | Data |
|---|---|---|
| `development` | Local developer machines | Mocked / seeded local DB |
| `staging` | Pre-production testing; mirrors production config | Anonymized production snapshot |
| `production` | Live user traffic | Production databases with backups |

Environment-specific configuration is managed via environment variables, validated at startup using Zod. No environment-specific code branches — only configuration differs.

### 13.3 Containerization

```dockerfile
# Multi-stage build for minimal production image
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json .
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine AS production
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 3000
CMD ["node", "dist/app.js"]
```

### 13.4 CI/CD Pipeline (GitHub Actions)

```
Push to branch
  → Lint (ESLint + Prettier check)
  → Unit Tests (Jest)
  → Integration Tests (Supertest against test DB)
  → Build Docker Image
  → Security Scan (Trivy for image vulnerabilities)
  → npm audit (dependency CVE check)

Merge to main (staging deploy)
  → All above steps
  → Push image to ECR (tagged with commit SHA)
  → Deploy to staging EKS namespace via Helm chart
  → Run smoke tests against staging

Tag release (production deploy)
  → Approve production deployment (manual gate)
  → Blue-green deployment to production EKS
  → Post-deploy health checks
  → Rollback automatically if health checks fail within 5 minutes
```

### 13.5 Infrastructure as Code

- Kubernetes manifests managed via **Helm charts**
- Cloud infrastructure provisioned via **Terraform**
- GitOps approach: infrastructure changes reviewed as pull requests before application

---

## 14. Monitoring & Logging

### 14.1 Structured Logging

All backend logs are emitted as **structured JSON** using **Winston**:

```json
{
  "level": "info",
  "timestamp": "2025-04-23T10:30:00.000Z",
  "requestId": "req_abc123",
  "userId": "usr_xyz789",
  "method": "POST",
  "path": "/api/v1/sessions",
  "statusCode": 201,
  "durationMs": 47,
  "message": "Study session created"
}
```

Logs are shipped to **AWS CloudWatch Logs** (or **GCP Cloud Logging**) and queryable with structured filters.

### 14.2 Error Tracking

**Sentry** is integrated at both the backend (Node.js SDK) and frontend (Flutter SDK):
- Captures unhandled exceptions with full stack traces
- Groups duplicate errors automatically
- Attaches user context (userId, session) for faster debugging
- Configurable alert thresholds trigger PagerDuty or Slack notifications

### 14.3 Application Performance Monitoring

**Datadog APM** (or **New Relic**) provides:
- Distributed tracing across API → DB → Redis → OpenAI calls
- P50/P95/P99 latency dashboards per endpoint
- Error rate monitoring with SLO tracking (target: < 1% error rate)
- AI endpoint token usage and cost tracking

### 14.4 Infrastructure Monitoring

- **Kubernetes Metrics Server** + **Prometheus** scrapes pod-level CPU, memory, and request metrics
- **Grafana** dashboards visualize cluster health, scaling events, and queue depths
- **AlertManager** triggers on: pod crash loops, CPU > 85% sustained, error rate spike, Redis memory > 80%

### 14.5 Uptime Monitoring

- **Better Uptime** or **Checkly** runs synthetic health checks every 60 seconds against `/health` endpoint from multiple global regions
- Health endpoint returns: `{ status: "ok", db: "connected", cache: "connected", uptime: 3600 }`
- Alerts trigger within 2 minutes of an outage

---

## 15. Future Enhancements

### 15.1 Microservices Decomposition

As user scale grows, the `analytics` module (highest computation load) is the natural first candidate for extraction into a standalone **Analytics Microservice** with its own database. Communication between services would use **gRPC** for internal calls and an **event-driven** approach (AWS SQS / Kafka) for eventual consistency.

### 15.2 AI Model Fine-Tuning

The system is designed to collect anonymized interaction data that can be used to fine-tune a domain-specific model (via OpenAI fine-tuning API or an open-source alternative). A fine-tuned model specialized in educational assistance would reduce token usage and improve response quality and consistency.

### 15.3 Real-Time Features

**WebSocket support** (via Socket.io or native WebSockets) would enable:
- Live collaborative study rooms (study with friends)
- Real-time progress notifications ("You've hit your daily goal!")
- Instant AI coach responses without polling

### 15.4 Adaptive Learning Engine

A dedicated ML service could analyze historical study data to:
- Predict optimal study times based on past focus scores
- Identify knowledge gaps using spaced repetition algorithms (SM-2 / FSRS)
- Auto-generate personalized daily study plans

### 15.5 Offline-First Architecture

Expand the current offline session buffering to a full **offline-first** approach using Flutter's local database (Drift / Isar) with background sync — allowing full app functionality without network connectivity, with conflict resolution on reconnect.

### 15.6 Multi-Tenancy (B2B)

Future B2B expansion (schools, tutoring companies) would introduce a `tenants` collection, scoped authorization, custom branding per tenant, and organization-level analytics dashboards.

---

## Appendix

### A. Technology Summary

| Layer | Technology |
|---|---|
| Mobile Frontend | Flutter 3.x, Dart, Riverpod, GoRouter, Dio |
| Backend | Node.js 20, Express.js, TypeScript, Mongoose, Zod |
| Primary Database | MongoDB Atlas |
| Cache | Redis (ElastiCache) |
| AI Provider | OpenAI API (GPT-4o) |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| Job Queue | Bull + Redis |
| Container Platform | Docker + Kubernetes (EKS/GKE) |
| CI/CD | GitHub Actions + Helm |
| Infrastructure as Code | Terraform |
| Monitoring | Datadog APM, Sentry, Prometheus, Grafana |
| Cloud | AWS (primary) |

### B. Key Non-Functional Requirements

| Requirement | Target |
|---|---|
| API Response Time (p95) | < 200ms (non-AI endpoints) |
| AI Response Time (p95) | < 3 seconds |
| System Uptime | 99.9% |
| Max Concurrent Users (initial) | 10,000 |
| Data Retention | 3 years (sessions), 1 year (AI conversations) |
| GDPR Compliance | Full right-to-erasure support via account deletion |

---

*This document is a living artifact and should be updated as the system evolves. All architectural decisions should be documented as Architecture Decision Records (ADRs) in the project repository.*