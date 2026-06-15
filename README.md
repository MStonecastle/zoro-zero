---
Title: "Zoro-Zero: Turnkey Local Offline AI Agent Stack"
Description: "A turnkey, isolated, GPU-accelerated, offline local AI agent stack deployed securely in Docker containers."
License: "MIT License (https://opensource.org/license/mit)"
Author: "Team-404, Michelle Stonecastle-20260527: v1.0.0"
---

# Zoro-Zero: Turnkey Local Offline AI Agent Stack

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/license/MIT)
[![Docker](https://img.shields.io/badge/Docker-Containerized-blue.svg)](https://www.docker.com/)
[![Ollama](https://img.shields.io/badge/Ollama-Inference-orange.svg)](https://ollama.com/)
![Model: Qwen 3](https://img.shields.io/badge/Model-Qwen_3_8B-purple.svg)

**Zoro-Zero** is an offline-capable, fully containerized, GPU-accelerated local AI agent stack. It orchestrates the highly agentic **Qwen 3 8B** model alongside **Ollama** and the **Nous Hermes Agent framework**, deployed securely in isolated Docker containers with zero cloud dependencies.

Built under a DevSecOps **Zero-Trust** philosophy, this repository allows students, developers, and researchers to operate a premium AI assistant stack locally on consumer hardware without exposing endpoints to local area networks (LAN) or leaking private keys.

---

## 🚀 Key Features

*   **Zero Configuration (Turnkey Launch)**: Instantly pre-seeded with custom model overrides, base URLs, and streamlined CLI toolsets. Ready to run immediately upon container initialization.
*   **First-Boot Template Seeding**: Automatically injects read-only workspace templates (`SOUL.md`, `MEMORY.md`, `USER.md`) into the live `~/.hermes/` host directory on initial boot to establish the agent's baseline identity.
*   **Secure Web Research (Zero-Key Search)**: Includes out-of-the-box internet search capability via DuckDuckGo Search (`ddgs`) with zero credentials required. Fully hardened behind an always-on **Zero-Trust Website Blocklist** to prevent SSRF vulnerabilities targeting the local network, subnets, and host loopbacks.
*   **Isolated private networking**: No external ports are exposed on the local network interface. Services reside entirely in a private Docker bridge (`zoro-network`), with Ollama and the dashboard bound strictly to the loopback address (`127.0.0.1`).
*   **Host Data Persistence**: Mapped host volumes guarantee that all SQLite databases (`state.db`, `kanban.db`), memories, paired tokens, and active session histories are preserved securely under your Windows User Profile (`C:\Users\<username>\.hermes\`).
*   **Model KV VRAM Cache Optimization**: Custom Modelfile parameters compile a dedicated `qwen3:8b-64k` model tag, allocating a physical **4.2 GB KV cache in VRAM** to satisfy the framework's baseline 65,536 token context window natively.
*   **Hardware Efficiency**: Fits comfortably within standard system requirements (16 GB RAM / 12 GB VRAM e.g., NVIDIA RTX 3060).

---

## 🏗️ Architecture & Image Orchestration

Zoro-Zero is engineered for pure deployment orchestration rather than local compilation. You will notice this repository does **not** contain a `Dockerfile`. 

This is an industry-standard practice when dealing with robust, vendor-supplied container software. Instead of building the components from raw source code locally, Zoro-Zero leverages `docker-compose.yml` to download, orchestrate, and network **pre-built, production-ready images** hosted securely on Docker Hub:
*   `ollama/ollama:latest`
*   `nousresearch/hermes-agent:latest`

By omitting a local build step, we guarantee that every student executes exactly the same compiled binaries, eliminating "it works on my machine" compilation errors. This makes the entire stack completely **platform-independent (cross-platform accessible)**, ensuring a friction-free turnkey setup that functions identically whether you are on Windows, macOS, or Linux.

### 🛡️ Secure Execution Wrapper
To launch the deployment, this repository provides `Start-Zoro-Zero.bat`. Windows natively blocks `.ps1` (PowerShell) scripts from executing to protect users from malware. The `.bat` file acts as a transparent, secure bridge that temporarily bypasses the Execution Policy for that single session, ensuring a seamless start without permanently lowering your system's security posture. Students are encouraged to open the `.bat` file in any text editor to verify its contents.

---

## 🗺️ Architectural Port Map

| Container Name | Service | Host Port | Mapped Interface | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `zoro-ollama` | Ollama Engine | `11434` | `127.0.0.1` | Local GPU-accelerated model inference |
| `zoro-ollama-init` | Model Compiler | *None* | *Internal Network Only* | Ephemeral script; compiles the `qwen3` context and intentionally exits |
| `zoro-gateway` | Hermes Gateway | *None* | *Internal Network Only* | Core supervisor agent orchestrating tools and DB |
| `zoro-dashboard` | Web Dashboard | `9119` | `127.0.0.1` | Visual execution monitor & skill manager |

---

## ⚡ Quickstart Guide

For exhaustive instructions, verified links to official specifications, and parameter analysis, refer to the [**Student Walkthrough & Verification Guide**](Walkthrough.md).

### 1. Bootstrap the Environment
Clone this repository to your local host and duplicate the environment template:
```powershell
# Copy the environment file
Copy-Item -Path .env.example -Destination .env
```
*Note: The `.env` file is excluded from Git. Students can edit this file to configure Telegram/Discord bot tokens, or add free API keys (e.g. `TAVILY_API_KEY`, `FIRECRAWL_API_KEY`) to enable full text extraction (`web_extract`) in the agent.*

### 2. Boot the Container Stack
Launch the isolated container services in detached mode. The stack features an automated `ollama-init` orchestrator that will pull, compile, and configure the custom model tag seamlessly before launching the gateway.
```powershell
docker compose up -d
```

### 3. Direct Interactivity
Once the model compilation finishes and the gateway launches, interact directly with the agent inside the Gateway container console:
```powershell
docker exec -it zoro-gateway hermes chat
```
*REPL Console Navigation*:
*   Type `/model custom/qwen3:8b-64k` to ensure the gateway locks onto the new target.
*   Type your prompt and press **Enter** to submit.
*   Type `/help` to see all available CLI commands.
*   Type `/exit` or press **Ctrl+D** to close the session.

### 4. Access the Dashboard
Navigate your web browser to `http://127.0.0.1:9119` to visually monitor execution, review pairing logs, and manage skills.

### 5. Safe Teardown
When your session is complete, destroy the stack to release system RAM. Because of the host bind-mounts, this is 100% safe and your data will persist:
```powershell
docker compose down
```

---

## 🛡️ Zero-Trust Verification (Physical Mapping Proof)
To ensure data persistence works securely and is not a hallucinated claim made by the model in the chat window, perform these direct, LLM-independent validation checks:

*   **Host-to-Container**: Create `verify.txt` in your host's `$env:USERPROFILE\.hermes\` folder, then run `docker exec -it zoro-gateway cat /opt/data/verify.txt`.
*   **Container-to-Host**: Run `docker exec -it zoro-gateway sh -c "echo 'functional' > /opt/data/verify.txt"`, then check your host profile's `.hermes\verify.txt` content.

## 📂 Public Documentation
*   [**`Walkthrough.md`**](Walkthrough.md): The primary end-user onboarding guide, including detailed parameter explanations and official references.
*   [**`Zoro-Zero_Playbook.md`**](Zoro-Zero_Playbook.md): The daily operational runbook and troubleshooting triage steps for host port allocation collisions and VRAM boundary overflows.

---

## ⚖️ License
Distributed under the **MIT License**. See `LICENSE` for details.
