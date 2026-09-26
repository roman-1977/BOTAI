# BOTAI Architecture

Status: Working architecture.

## Principles

### App-Store-first

Архитектура и продуктовые решения должны учитывать требования Apple с начала разработки.

### Local-first

Основные учебные функции должны работать без постоянного подключения к интернету.

### Backend is not UI state

SwiftUI-экраны не должны напрямую зависеть от Supabase как от источника состояния интерфейса.

Основная схема:

SwiftUI
    ↓
Repositories
    ↓
Local Database ←→ Sync Engine ←→ Supabase
    ↓
Learning Engine

## iOS

- Swift
- SwiftUI
- feature-based structure

Предварительная структура:

ios/BOTAI/
├── App/
├── Core/
│   ├── Models/
│   ├── Database/
│   ├── Networking/
│   ├── Sync/
│   └── DesignSystem/
├── Features/
│   ├── Home/
│   ├── Learn/
│   ├── Library/
│   ├── Goals/
│   ├── Statistics/
│   ├── ContentEditor/
│   ├── Social/
│   └── Profile/
└── Tests/

## Backend

Working decision:

- Supabase
- PostgreSQL
- Supabase Auth
- Supabase Storage
- Row Level Security
- Edge Functions where trusted server-side logic is required

## Authentication

Primary iOS authentication:

Sign in with Apple.

Other authentication methods may be added later.

## Learning Engine

Scheduling logic must be isolated from UI.

LearningEngine receives learning state, goals, history and time information and creates the study plan.

This allows the scheduling algorithm to evolve independently.

## Offline

Downloaded learning material must remain usable without internet access.

Required locally:

- subscribed learning content;
- required media;
- learning state;
- today's study queue;
- pending attempts awaiting sync.

## Content vs Learning Data

Published learning content and personal learning progress are separate domains.

One public question may be studied by many users without copying the question itself for every user.

## Media

Images are stored remotely in object storage and cached locally.

Questions and answers must support multiple content forms including:

- text;
- LaTeX;
- images.

## Future AI

BOLDAI is not part of MVP.

Future AI communication must go through trusted backend infrastructure.

AI provider credentials must never be stored in the iOS application.
