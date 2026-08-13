# ?? AI Study Coach

A personalized AI-powered study companion app with a Flutter frontend and Node.js backend.

---

## ??? Project Structure

```
studyapp/
+-- Frontend/   ? Flutter app (mobile & web)
+-- Backend/    ? Node.js REST API server
```

---

## ?? How to Run

### Backend
```bash
cd Backend
npm run dev
```
Runs on **http://localhost:3000**

### Frontend
```bash
cd Frontend
flutter run -d chrome        # Run on Chrome (web)
flutter run -d windows       # Run as Windows desktop app
```

> **Note:** If `flutter` is not recognized, run this first in PowerShell:
> ```powershell
> $env:PATH += ";C:\flutter\flutter_windows_3.44.9-stable\flutter\bin"
> ```
> Then open a **new terminal** — it will work automatically after that.

---

## ??? Frontend — Flutter

| Category | Technology |
|---|---|
| Language | Dart |
| Framework | Flutter 3.44.9 |
| State Management | Flutter Riverpod |
| Navigation | Go Router |
| HTTP Client | Dio |
| Local Storage | Hive Flutter, Shared Preferences |
| Secure Storage | Flutter Secure Storage |
| Charts | FL Chart, Percent Indicator |
| UI | Google Fonts, Shimmer, Lottie, Flutter SVG |
| Push Notifications | Firebase Messaging |
| PDF Generation | PDF package |
| Speech | Speech to Text, Flutter TTS |
| File Handling | File Picker, Path Provider |
| Real-time | Socket.io Client |
| Sharing | Share Plus, Screenshot |
| Images | Cached Network Image |

---

## ?? Backend — Node.js

| Category | Technology |
|---|---|
| Language | JavaScript (Node.js) |
| Framework | Express.js |
| Database | MongoDB (Atlas) + Mongoose |
| Cache | Redis (Upstash) |
| Authentication | JWT (Access + Refresh tokens) |
| AI / LLM | Groq API (LLaMA 3.3 70B, LLaMA 3.1 8B fallback) |
| Real-time | Socket.io |
| Email | Nodemailer |
| File Upload | Multer |
| PDF Parsing | pdf-parse |
| Security | Helmet, bcryptjs, express-rate-limit |
| Task Queue | Bull |
| Dev Server | Nodemon |
| Testing | Jest, Supertest |

---

## ?? AI Features

- **AI Test Analysis** — After every test, AI analyses your performance using Groq (LLaMA 3.3 70B)
- **Revision Plan** — AI generates a personalized revision plan with high/medium/low priority topics
- **AI Chat** — Chat with AI study assistant
- **AI Quiz** — AI-generated quizzes on any subject
- **Exam Planner** — AI-powered exam preparation planner

---

## ?? Environment Variables (Backend)

Create a `.env` file in the `Backend/` folder:

```env
PORT=3000
NODE_ENV=development

# MongoDB
MONGO_URL=your_mongodb_atlas_url

# Redis
REDIS_URL=your_redis_url

# JWT
JWT_ACCESS_SECRET=your_secret
JWT_REFRESH_SECRET=your_secret
JWT_ACCESS_EXPIRES_IN=30d
JWT_REFRESH_EXPIRES_IN=30d

# AI (Groq)
GROQ_API_KEY=your_groq_api_key

# Firebase
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_CLIENT_EMAIL=your_email
FIREBASE_PRIVATE_KEY=your_private_key

# CORS
CLIENT_ORIGIN=*
```

---

## ?? Key Scripts

| Command | Description |
|---|---|
| `npm run dev` | Start backend with auto-reload (nodemon) |
| `npm start` | Start backend in production |
| `npm test` | Run backend tests |
| `flutter run -d chrome` | Run frontend on Chrome |
| `flutter run -d windows` | Run frontend on Windows |
| `flutter build web` | Build frontend for web production |

---

## ?? App Screens

- Splash, Welcome, Login, Signup, OTP Verification
- Home Dashboard
- AI Chat & Quiz
- Test Setup, Active Test, Results, Report, History, Analytics
- Exam Planner & Setup
- Profile, Settings, Change Password
- Flashcards, Planner
