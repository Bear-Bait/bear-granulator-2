# Gemini Code Companion Notes: BEARULATOR Project

This document contains the analysis of the "BEARULATOR" SuperCollider project and a proposed collaborative workflow for development. We can use this as a shared context for our coding sessions.

---

## Task 1: Codebase Examination Summary

*   **1. Project's Purpose:** The project, named "BEARULATOR," is a sophisticated 4-track granular and spectral synthesis workstation designed for live performance and sound design. It allows for real-time manipulation of audio from files or live input, featuring extensive modulation capabilities, built-in effects, and MIDI controller integration.

*   **2. Architecture:** The project uses a clear, MVC-like (Model-View-Controller) architecture that separates state management, audio processing, and user interface logic.
    *   **Model (The Brain):** `core/track-manager.scd` is the central component. It manages the state of four independent audio tracks, handles parameter updates, and serves as the single source of truth for the application. All control messages (from the GUI or MIDI) are routed through this manager.
    *   **View (The Interface):** `gui/four-track-view.scd` builds the main graphical user interface. It sends control messages to the `track-manager` when a user interacts with a slider or button. It also receives real-time data (like audio levels) back from the audio engine via OSC messages to keep the display updated.
    *   **Controller (The Engine):** The core audio processing happens in `SynthDef`s defined in files like `core/grain-engine.scd`. These are the actual instruments that run on the SuperCollider audio server. They are designed as monolithic units that receive control data from the `track-manager` to shape the sound.

*   **3. Key Files:**
    *   `main.scd`: The primary entry point. It configures the environment, loads all necessary modules in the correct order, and instantiates the main components (`track-manager`, GUI, etc.).
    *   `core/track-manager.scd`: The most critical file for understanding the application's logic. It defines the `~bearulatorTrackManager` class, which manages all parameters and state.
    *   `core/grain-engine.scd`: Contains the `SynthDef` for the main granular synthesis engine, including the core granulation logic (`GrainBuf`) and the integrated effects chain.
    *   `gui/four-track-view.scd`: Defines the primary user interface, connecting UI elements to the `track-manager`'s control functions.
    *   `START-HERE.scd`: The designated script for users to boot the entire application.

*   **4. Language and Dependencies:**
    *   **Language:** The entire project is written in SuperCollider (`.scd`).
    *   **Dependencies:** There is one critical external dependency: the **`sc3-plugins`** quark.

*   **5. Testing Strategy:** The project relies on a **manual, script-driven testing methodology** as documented in `TESTING-GUIDE.md`. Developers run specific `.scd` files and code snippets to verify functionality.

---

## Task 2: Collaborative AI Development Plan

This is a proposed plan for using the gemini-mcp server for collaborative development.

*   **1. Proposed Workflow: The Architect-Specialist Model**

    *   **Claude (The Architect):** Handles high-level reasoning, logic, and architectural decisions. It analyzes requests, forms a plan, and writes the logical SuperCollider code, delegating specific tasks to Gemini.
    *   **Gemini (The Specialist):** Acts as a tool-user, invoked by Claude via the MCP server. It handles file reading/writing, precise code replacement, and running shell commands for testing.

*   **2. Bug Fixing Example: Fixing a Faulty Filter**

    This example illustrates fixing a hypothetical bug where filter resonance cuts out audio.

    1.  **Claude Initiates:** Claude receives the bug report and instructs Gemini to `read_file('core/grain-engine.scd')`.
    2.  **Claude Analyzes:** Claude examines the code and hypothesizes that a `.clip()` function is the cause.
    3.  **Gemini Verifies Bug:** Claude instructs Gemini to run a shell command (`sclang -e "..."`) to execute a test snippet that reproduces the bug.
    4.  **Gemini Implements Fix:** Claude provides a precise `replace` command to fix the incorrect line of code.
    5.  **Gemini Verifies Fix:** Claude instructs Gemini to run the same test snippet again to confirm the fix.

*   **3. Feature Addition Example: Adding a New Effect**

    This example illustrates adding a new, hypothetical effect (e.g., a simple Chorus).

    1.  **Claude Initiates:** Claude receives the feature request.
    2.  **Gemini Retrieves Files:** Claude instructs Gemini to read `core/grain-engine.scd` and `core/track-manager.scd`.
    3.  **Claude Designs:** Claude determines the necessary changes: add a parameter to the track manager, add an input bus to the `SynthDef`, and add the new effect UGen (e.g., `CombL.ar`) to the signal chain.
    4.  **Gemini Implements:** Claude issues a series of precise `replace` commands to Gemini to implement the changes in both files.
    5.  **Gemini Creates Test:** Claude generates the code for a new test script and instructs Gemini to `write_file('tests/test-new-effect.scd', ...)`.
    6.  **Gemini Runs Test:** Claude instructs Gemini to run the new test file via `run_shell_command` to verify the feature.

*   **4. Best Practices for This Project**

    1.  **Trust the Track Manager:** Route all state changes and new parameters through `core/track-manager.scd`.
    2.  **Respect the Testing Guide:** Use the existing manual, script-driven testing methodology. Create new test scripts for new features.
    3.  **Isolate Changes:** Make small, incremental changes and test each one.
    4.  **Use Gemini for Precision:** Delegate concrete, atomic tasks to Gemini (read, write, replace, run) rather than broad requests.
    5.  **Start with `main.scd` to Understand Loading:** Use `main.scd` as a map to understand how components are loaded and connected.
