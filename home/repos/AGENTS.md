# Stack choices in ~/repos

Before a new project, or a new component that needs its own stack
(a UI, a service, a desktop app), propose a stack and discuss it with
me before writing code. In an existing repository its stack is the
starting point, but if it is a poor fit for the task, say so plainly
and why.

My preferences, as input to that discussion, not rules:
- Entry points: Makefile targets rather than loose scripts.
- UI: Svelte + Vite with TypeScript; Nord or One Dark theme.
- Desktop apps: Tauri.
- Backend and CLI tools: Go or Python.

Code, comments, commits and docs are in English only.
