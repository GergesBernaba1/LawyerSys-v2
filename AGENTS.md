# LawyerSys-v2 Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-04-02

## Active Technologies
- C# 12 on .NET 8, TypeScript 5.x for the existing client context + ASP.NET Core Web API, EF Core 8, ASP.NET Identity, JWT Bearer auth, Serilog, xUnit, Moq, Next.js 14.2, React 18 (002-service-layer-refactor)
- PostgreSQL via `ApplicationDbContext` and `LegacyDbContext` in `LawyerSys.Domain`/`LawyerSys.Infrastructure` (002-service-layer-refactor)
- TypeScript 5.x, React 18, Next.js 14.2, CSS via existing global styles and Material UI theming + Next.js, React, Material UI, Emotion, i18next, axios (001-clientapp-ui-refresh)
- Flutter 3.x, Dart 3.x for mobile (iOS/Android) + flutter_bloc/riverpod, dio/http, shared_preferences, flutter_secure_storage, flutter_localizations (planned)
- C# 12 on .NET 8 (backend), TypeScript 5.x (Next.js 14.2 / React 18 web client) + ASP.NET Core Web API, EF Core 8, ASP.NET Identity, JWT Bearer auth, Serilog, Material UI, i18next, axios (005-competitor-feature-parity)
- PostgreSQL through `ApplicationDbContext` and `LegacyDbContext` (005-competitor-feature-parity)

## Project Structure

```text
LawyerSys/          # ASP.NET Core backend + Next.js web client
LawyerSys.Domain/
LawyerSys.Infrastructure/
LawyerSys.Service/
MobileApp/          # Flutter mobile app (iOS/Android)
specs/
tests/
```

## Commands

- dotnet test
- npm --prefix LawyerSys/ClientApp test
- npm --prefix LawyerSys/ClientApp run lint
- flutter test (when mobile app is implemented)
- flutter analyze (when mobile app is implemented)

## Code Style

TypeScript 5.x, React 18, Next.js 14.2, CSS via existing global styles and Material UI theming: Follow standard conventions

## Recent Changes
- 006-mobile-support-agent-kb: Added `docs/mobile-support-agent-knowledge-base.md` as the technical support workflow and diagnostics reference for developer-facing mobile assistance.
- 005-competitor-feature-parity: Added C# 12 on .NET 8 (backend), TypeScript 5.x (Next.js 14.2 / React 18 web client) + ASP.NET Core Web API, EF Core 8, ASP.NET Identity, JWT Bearer auth, Serilog, Material UI, i18next, axios
- 002-service-layer-refactor: Added C# 12 on .NET 8, TypeScript 5.x for the existing client context + ASP.NET Core Web API, EF Core 8, ASP.NET Identity, JWT Bearer auth, Serilog, xUnit, Moq, Next.js 14.2, React 18

- 001-clientapp-ui-refresh: Added TypeScript 5.x, React 18, Next.js 14.2, CSS via existing global styles and Material UI theming + Next.js, React, Material UI, Emotion, i18next, axios

<!-- MANUAL ADDITIONS START -->
## Project Constitution

1. Keep `AGENTS.md` as the single source of truth for workspace policy notes and team conventions.
2. Update this document when development workflows or agent responsibilities change (e.g., changed from main->feature branch, updated required tech stack, or new linting / security requirements).
3. Include active branch and team-specific instructions explicitly as bullet points under `## Recent Changes` for clarity.
4. For code reviews, include both the app policy and expected style in PR descriptions.
5. For agent-specific commands, include references to built-in skills and required file patterns.

## Custom Agent Instructions

- Agent name: GitHub Copilot
- Model: Raptor mini (Preview)
- Behavior: concise, factual, no self-harm or abusive content.
- Always answer with short, structured markdown.

<!-- MANUAL ADDITIONS END -->
