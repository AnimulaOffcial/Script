# Animula Official — Script & Core System

> Complete ecosystem for Animula Hub Roblox Script, Web Key Validation System (Anti-Bypass), Supabase Cloud Synchronizer, LootLabs API Integration, and Furina Ocean UI Library.

## 📂 Project Structure
```
Animula/
├── Script/             # Roblox entry points, Game Loaders & Menu modules
│   ├── MainScript/     # Hub loader & game routing
│   └── MainUI/         # Furina Ocean UI Library
├── MainUI/             # UI Library root mirror
├── Web/                # Express & SPA anti-bypass key generation server
├── Supabase/           # Database schema, triggers, RLS policies, & views
├── LootLabs/           # LootLabs quest reward configs & docs
└── Discord/            # Bot & webhook integrations
```

## 🚀 Execution
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/AnimulaOffcial/Script/main/Script/MainScript/MainScript.lua"))()
```
