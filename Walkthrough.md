---
Title: "Zoro-Zero Turnkey Setup Walkthrough & Verification Guide"
Description: "Onboarding and host volume mapping verification guide for students."
License: "MIT License (https://opensource.org/license/mit)"
Author: "Team-404, Michelle Stonecastle-20260527: v1.0.0"
---

# Zoro-Zero Turnkey Setup Walkthrough & Verification Guide

This guide outlines the architecture, setup instructions, state preservation policies, and troubleshooting procedures for the **Zoro-Zero** local turnkey student agent stack.

All components are engineered to spin up in a fully isolated, secure, and GPU-accelerated local environment with zero data leakage.

---

## 🚀 Out-of-the-Box Turnkey Architecture (Zero Configuration)

### Pre-Built Image Orchestration
You will notice this repository does **not** contain a `Dockerfile`. This is an intentional, industry-standard architectural choice. Zoro-Zero is engineered for pure deployment orchestration rather than local compilation. Instead of building the components from raw source code locally, it leverages Docker Compose to download and network **pre-built, production-ready images** securely hosted on Docker Hub (`ollama/ollama:latest` and `nousresearch/hermes-agent:latest`). By omitting a local build step, we guarantee that every student executes exactly the same compiled binaries, eliminating compilation errors. This approach makes the entire stack completely **platform-independent (cross-platform accessible)**, ensuring it functions identically across Windows, macOS, and Linux.

### Zero-Configuration Launch
To ensure a seamless, friction-free educational setup, the Zoro-Zero container stack is pre-seeded with a production-grade configuration. Unlike standard Hermes installations that require manual file editing after first boot, **Zoro-Zero runs turnkey immediately out-of-the-box**.

This is achieved by mounting a workspace-level pre-configured `config.yaml` directly over the container's supervisor directory:
- **Workspace Source**: `./config.yaml` (Self-contained in the repository root)
- **Container Destination**: `/opt/data/config.yaml`

This volume override pre-seeds the supervisor on first launch, configuring:
1. **Model Defaults**: Automatically selects `qwen3:8b-64k` as the local baseline.
2. **Inference Routing**: Binds directly to the local Ollama container `http://ollama:11434/v1`.
3. **Structured Tool Belt**: Restricts CLI toolsets to `[hermes-cli]` (the full suite of agent tools), taking full advantage of the 65,536 token context window and Qwen 3's advanced JSON parsing capabilities without flooding the memory.

Students do **not** need to perform any manual configuration file edits after startup.

---

## 💾 State Preservation & Bind Mounts

The Zoro-Zero container stack utilizes external host bind-mounts to guarantee that all runtime data, memory records, and model weights are **100% preserved** on your host filesystem when the containers are stopped or updated.

### 1. Host State Directory (`c:\Users\<username>\.hermes\`)
All operational database files, memory caches, logs, and pairing logs are persisted under your Windows User Profile directory:
* **SQLite Databases**:
  * `state.db`: Tracks general assistant state, authentication metadata, and CLI console histories.
  * `kanban.db`: Manages active planning and task-tracking states.
* **Logs & Memories**: Active session transcripts and parsed memories are stored in `c:\Users\<username>\.hermes\sessions\` and `c:\Users\<username>\.hermes\memories\`.
* **Skills**: 90+ dynamically-compiled skill documents are saved to `c:\Users\<username>\.hermes\skills\`.

### 2. Model Weights Cache (`./.ollama/models`)
To prevent large-scale weight re-downloads (4.7 GB+ per model) across session rebuilds, the Ollama model cache is bind-mounted directly inside the workspace folder at **`./.ollama/models`** (remapping to `/root/.ollama` inside the container).
---

## 🌐 Secure Web Search & Page Extraction

Zoro-Zero includes built-in internet research capabilities, allowing the local agent to query the web for real-time documentation and facts. To support student setups without paid requirements, this is engineered as a zero-key, zero-config search module that is hardened behind a Zero-Trust network policy.

### 1. Out-of-the-Box Zero-Key Search
By default, the stack is configured to route web searches through **DuckDuckGo Search (`ddgs`)**. 
* **Zero Configuration**: No API keys, billing accounts, or sign-ups are required. It works out-of-the-box using the container's standard bridge network.
* **Under the Hood**: When a student asks the agent to look up a topic, the agent invokes `web_search(query="...")` through the pre-installed `ddgs` library inside the gateway virtual environment, returning structured titles, URLs, and summaries.

### 2. SSRF Prevention & Hardened Website Blocklist
To ensure complete system and network isolation in academic environments, the web tools are locked down using a hardlined **Website Blocklist** under the `security` section in `config.yaml`.
* **The Vulnerability**: Without blocklisting, a malicious prompt or compromised page could coerce the local agent into making local requests (Server-Side Request Forgery), scanning the student's private LAN, or hitting administrative container endpoints (such as `http://localhost:11434` to delete local Ollama models).
* **The Mitigation**: All outgoing HTTP requests are dynamically parsed and matched against a strict blocklist *before* execution. The following ranges are hard-blocked:
  * Local Loopback: `localhost`, `127.0.0.1`, `0.0.0.0`
  * Link-Local & LAN: `*.local`, `*.lan`
  * Private RFC1918 subnets: `10.*`, `192.168.*`, `172.16.*`, `172.17.*`, `172.18.*`, `172.19.*`, `172.20.*`
* **Network Access Policy**:
  > [!IMPORTANT]
  > When a blocked URL is requested, the tool immediately halts execution and returns a hardline safety block error, e.g.:
  > `Blocked by website policy: '127.0.0.1' matched rule '127.0.0.1' from config`

### 3. Student Guide: Upgrading to Deep Page Extraction (`web_extract`)
Because DuckDuckGo is a search-only index, the `web_extract` tool (which downloads the complete raw text of a specific URL and runs it through the local LLM for summarization) is disabled by default to prevent failed requests.

If students require the agent to scrape and read full documentation pages, they must configure a dedicated **extraction backend** using one of the following free-tier providers:

#### Option A: Tavily AI (1,000 free searches/month)
1. Sign up for a free developer account at [app.tavily.com](https://app.tavily.com/home).
2. Copy your generated API key.
3. Open your host `.env` file and append the key:
   ```bash
   TAVILY_API_KEY=tvly-your-actual-key-here
   ```
4. Open `./config.yaml` and configure the extract backend:
   ```yaml
   web:
     search_backend: "ddgs"
     extract_backend: "tavily"
   ```

#### Option B: Firecrawl (500 free credits/month)
1. Sign up for a free developer account at [firecrawl.dev](https://www.firecrawl.dev/).
2. Copy your API key.
3. Open your host `.env` file and append:
   ```bash
   FIRECRAWL_API_KEY=fc-your-actual-key-here
   ```
4. Open `./config.yaml` and configure:
   ```yaml
   web:
     search_backend: "ddgs"
     extract_backend: "firecrawl"
   ```

*Note: Once configured, the gateway container automatically inherits the API keys from `.env` and activates full `web_extract` and website crawling capabilities.*

---

## 🧠 Personalizing the Agent's Brain

To support multiple students sharing and running this stack independently, Zoro-Zero uses a robust **template seeding** mechanism. It is critical to understand the difference between your Git workspace files and the agent's live memory.

### The Architecture: Templates vs. Live Memory

Based on the official Nous Research architecture, Hermes strictly manages its memory in its native data directory. It does *not* read directly from the workspace.

1.  **Workspace Templates (`./SOUL.md`, `./USER.md`, `./MEMORY.md`)**: These files in your Git checkout are strictly read-only templates. 
2.  **First Boot Seeding**: When you run `docker compose up` for the very first time, a split-second custom entrypoint script copies these templates from your workspace into the agent's native brain directory (`C:\Users\<username>\.hermes\`).
3.  **Live Memory (`~/.hermes/memories/`)**: Once booted, the agent *only* reads and writes to the files in your `~/.hermes` host profile.

### Strict Character Limits

The agent manages its memory with strict character bounds to protect its LLM prefix cache:
*   **`USER.md` (Operator Profile)**: 1,375 character limit. Stored at `~/.hermes/memories/USER.md`.
*   **`MEMORY.md` (Agent Notes)**: 2,200 character limit. Stored at `~/.hermes/memories/MEMORY.md`.
*   **`SOUL.md` (Global Context)**: 20,000 character limit. Stored at `~/.hermes/SOUL.md`.

> [!WARNING]
> Do not add `# Headers` or markdown formatting bloat to `USER.md` or `MEMORY.md`. The Hermes framework dynamically calculates percentages and wraps the content in a UI block before sending it to the LLM. Raw text facts are all that is required.

### How to Customize Your Agent

**Before First Boot (Day 1)**:
Edit the `./USER.md` template in your workspace. Replace the `Kaizoku` placeholders with your actual name and preferences. When you launch Docker, your custom profile will be seeded.

**After First Boot**:
Because the templates are only seeded once, changing the workspace `./USER.md` will not affect a running agent. To update the agent's brain *after* you've started using it, you have two options:
1.  **Ask the Agent**: Simply tell the agent, "Update my user profile to say my name is John." The agent will use its native tools to edit the file itself.
2.  **Edit the Live File**: Open `C:\Users\<username>\.hermes\memories\USER.md` in your editor and manually change it. The agent will load the fresh snapshot on your next session.

---

## ⚠️ Critical Troubleshooting & Port Triage

> [!TIP]
> **Visual Debugging: Don't Panic at the Terminal**
> If a container fails to boot or exits unexpectedly, you do not need to parse confusing PowerShell error traces. Simply open the **Docker Desktop** application, click on the `zoro-zero` stack, and click on the failed container. The **Logs** tab provides a clean, graphical interface where you can easily scroll through exactly what went wrong.

> [!WARNING]
> **Native Ollama Port Conflict (Port 11434)**:
> If the student already has a native Windows instance of Ollama running on the host system (e.g., as a system-tray daemon or local background service), it will bind to host port `11434`.
> 
> When Docker attempts to launch `zoro-ollama`, Docker Desktop will fail to bind container port `11434` to host interface `127.0.0.1:11434`, triggering a fatal `port is already allocated` container crash.
> 
> **How to Resolve**:
> 1. Right-click the Ollama icon in the Windows taskbar system tray and select **"Quit Ollama"**.
> 2. Alternatively, terminate the host process using PowerShell:
>    ```powershell
>    Stop-Process -Name "ollama" -Force
>    ```
> 3. Once the host port is cleared, launch the Docker stack.

---

## 🛠️ Step-by-Step Launch & Interaction

To prevent blind reliance on pre-configured templates and support academic validation, follow these sequential steps to initialize, configure, and inspect the stack. Each element is linked to official specifications for deep technical verification.

### 1. Initialize Your Local Environment Configuration (`.env`)
When a student clones the Zoro-Zero repository, the actual `.env` file is excluded from Git to prevent credential leakage. You must bootstrap your local configuration using the checked-in standard template:

*   **Command**: Copy the template using PowerShell:
    ```powershell
    Copy-Item -Path .env.example -Destination .env
    ```

#### Comprehensive Environmental Key Analysis & Official Specifications:

*   **`OLLAMA_HOST=http://ollama:11434`**
    *   *System Mechanics*: Configures the DNS endpoint for the agent gateway to connect to Ollama. Within the virtual container bridge network (`zoro-network`), Docker acts as a private DNS resolver, routing the hostname `ollama` directly to the `zoro-ollama` container interface on port `11434`.
    *   *Reference Specification*: [Docker Compose Networking Specification](https://docs.docker.com/compose/how-tos/networking/)
*   **`MODEL=qwen3:8b-64k`**
    *   *System Mechanics*: Declares the target model tag built inside Ollama. By utilizing the customized context parameter `num_ctx 65536`, the Ollama inference engine allocates a mathematically perfect native 4.2 GB KV cache in VRAM to safely process massive context windows.
    *   *Reference Specification*: [Ollama Modelfile Reference Guide](https://github.com/ollama/ollama/blob/main/docs/modelfile.mdx)
*   **`TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOWED_USERS`, `TELEGRAM_HOME_CHANNEL`**
    *   *System Mechanics*: Standard parameters to orchestrate the Telegram API Gateway. The token authenticates the container's gateway handler. The allowed user parameter acts as an access control list (ACL), parsing incoming chat payloads and silently dropping instructions from user IDs not listed on the whitelist, preventing remote terminal execution by unauthorized third parties.
    *   *Reference Specification*: [Telegram BotFather API Reference](https://core.telegram.org/bots/features#botfather)
*   **`DISCORD_BOT_TOKEN`, `DISCORD_ALLOWED_USERS`**
    *   *System Mechanics*: Authenticates the gateway against Discord's WebSocket API. Under the hood, this establishes a persistent gateway connection. Like the Telegram gateway, the user ACL filters messages before passing them to the supervisor logic, shifting security left to the ingress boundary.
    *   *Reference Specification*: [Discord Developer Portal Application Guide](https://docs.discord.com/developers/intro)

---

### 2. Boot the Container Stack
Launch the isolated container services using the pre-flight hardware detection script. By double-clicking the `.bat` file (or running it in the terminal), you automatically bypass Windows script restrictions, check if you have an NVIDIA GPU, and seamlessly deploy the correct Compose configuration:

```powershell
.\Start-Zoro-Zero.bat
```

> [!NOTE]
> **Security Transparency: How the `.bat` wrapper works**
> Windows restricts running `.ps1` files by default to prevent malicious scripts from executing (Execution Policy). To provide a turnkey experience, we use `Start-Zoro-Zero.bat` as a secure bridge.
> Inside the file, it executes this command: `powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0Start-Zoro-Zero.ps1" %*`
> *   `Bypass`: Only drops the restriction for this *single* session, keeping your system secure.
> *   `%~dp0`: Dynamically resolves to the absolute folder path where the `.bat` file lives. This ensures it reliably finds the `.ps1` script without relative path errors.
> *   `%*`: Forwards any command line arguments you provide directly into the PowerShell script.
> 
> You are encouraged to open `Start-Zoro-Zero.bat` in a text editor to verify its contents!

*   *Compose Mechanics*: The script probes `nvidia-smi`. If successful, it merges the GPU reservation override. It then reads `docker-compose.yml`, injects variables from `.env`, pulls target container images, constructs the private `zoro-network` bridge, sets up the physical host volume bind-mounts, and boots all services in background mode.
*   *Reference Specification*: [Docker Compose Storage Bind-Mount Reference](https://docs.docker.com/engine/storage/bind-mounts/)

---

### 3. Verify Container Telemetry
Ensure that all services started cleanly without crashing or entering infinite loop cycles:

```powershell
docker compose ps
```
Nominal output shows the core services running and the initialization script gracefully exited:
```text
NAME               SERVICE       STATUS          PORTS
zoro-dashboard     dashboard     running (Up)    127.0.0.1:9119->9119/tcp       
zoro-gateway       gateway       running (Up)    
zoro-ollama        ollama        running (Up)    127.0.0.1:11434->11434/tcp 
zoro-ollama-init   ollama-init   exited (0)
```

*   **Host-to-Container Data Persistence Audit**:
    All database transactions, session traces, and state records are physically synchronized to your host system under `C:\Users\<username>\.hermes\`. If you recreate the containers, your memories and files are 100% preserved. You can inspect this path physically on your host using PowerShell or your explorer to confirm direct write-persistence.

---

### 3. Automated 64k Model Compilation
Unlike older architectures, Zoro-Zero handles the complex compilation of the context window autonomously. When the startup script is run, an ephemeral `zoro-ollama-init` container detects when the engine is healthy, executes `ollama create qwen3:8b-64k -f /root/.ollama/Modelfile` to hard-configure the 65,536 token KV VRAM parameter natively, and gracefully exits.

> [!WARNING]
> **Compilation Takes Several Minutes**
> The model compiler must transfer and rewrite multiple gigabytes of weights to inject the new context window. This process can take several minutes. 
> 
> If you are worried the deployment is stuck:
> 1. Open the **Docker Desktop** application.
> 2. Click on the `zoro-zero` stack to expand it.
> 3. Click on the `zoro-ollama-init` container.
> 4. Select the **Logs** tab.
> 
> Here, you will see real-time output showing things like `transferring` or `writing layer`. When the compilation is fully finished, the log will simply print `success`.

> [!TIP]
> **Why does `zoro-ollama-init` say "Exited" in Docker Desktop?**
> Do not be alarmed! This is an architectural pattern known as an Ephemeral Init Container. Its sole purpose is to compile the model *once* during startup. After it successfully completes its script, it powers itself off and sits silently in the stack to free up system resources.
> *   *Reference Specification*: [Docker Compose `depends_on: condition: service_healthy` Initialization Pattern](https://docs.docker.com/reference/compose-file/services/#depends_on)

---

### 5. Open the Web Dashboard
Navigate your host web browser to the graphical control panel:

```text
http://127.0.0.1:9119
```
*   *Mechanics*: Serves the interactive dashboard, letting you review pairing logs, inspect dynamically-created skills, and monitor the gateway.
*   *Reference Repository*: [Official Nous Research Hermes Agent codebase](https://github.com/NousResearch/hermes-agent) for structural verification of the dashboard interface.

---

### 6. Powering Down vs. Pausing the Stack
When you are finished with a session, you have two options for managing the container lifecycle:

**Option A: Pause (Stop) the Stack**
*   **Command**: `docker compose stop` (or clicking the Square "Stop" button in Docker Desktop).
*   **Mechanics**: This gracefully stops the containers and releases system RAM/VRAM. The container filesystems remain intact. When you issue `docker compose start` again, they boot up instantly from their previous state.

**Option B: Tear Down the Stack**
*   **Command**: `docker compose down`
*   **Mechanics**: This completely destroys the containers and tears down the private `zoro-network`. 
*   **Is this safe?** YES! Because of the strict host volume mappings we explored in Step 3, all your memories, skills, configurations, and model weights are physically stored on your Windows hard drive. You can safely tear down the stack every day, and your agent will wake up with perfect memory the next time you run `docker compose up -d`.
