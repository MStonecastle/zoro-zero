---
Title: "Zoro-Zero: Operator's Playbook & Runbook"
Description: "Daily operations runbook, state management, and critical port allocation troubleshooting protocols."
License: "MIT License (https://opensource.org/license/mit)"
Author: "Team-404, Michelle Stonecastle-20260527: v1.0.0"
---

# Zoro-Zero: Operator's Playbook & Runbook

This playbook provides standard operating procedures, state management guidelines, and troubleshooting protocols for the **Zoro-Zero Turnkey Agent Stack** under `C:\Users\<username>\Zoro-Zero`.

---

## 🧭 Operational Architecture & Port Map

The Zoro-Zero stack isolates services within a private Docker network (`zoro-network`), routing communication securely over loopback interfaces.

| Service Name | Container Name | Host Port | Bound Interface | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **Ollama Engine** | `zoro-ollama` | `11434` | `127.0.0.1` | Local GPU-accelerated LLM inference |
| **Model Compiler** | `zoro-ollama-init` | *None* | *Internal Only* | Ephemeral build script; compiles the `qwen3` model then intentionally exits. |
| **Hermes Gateway** | `zoro-gateway` | *None* | *Internal Only* | Supervisor orchestrating tool calls & memory |
| **Web Dashboard** | `zoro-dashboard` | `9119` | `127.0.0.1` | Graphical execution panel & skill manager |

---

## 🐳 Docker Desktop: Graphical Interface Operations

For a more visual, user-friendly experience, students can utilize **Docker Desktop** to manage and monitor the Zoro-Zero container stack graphically rather than using the command line.

> [!IMPORTANT]
> **Prerequisites**: Ensure you have downloaded and installed [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/) and that the WSL 2 backend is enabled.
> * Official Reference: [Docker Desktop Windows Installation Guide](https://docs.docker.com/desktop/install/windows-install/)

### Graphical Alternatives to CLI Operations:

*   **Powering On/Off the Stack**:
    1. Open Docker Desktop and navigate to the **Containers** tab.
    2. Locate the `zoro-zero` group (representing the compose stack).
    3. Click the **Start** (Play) button to boot all four containers simultaneously, or the **Stop** (Square) button to spin them down. *(Note: `zoro-ollama-init` will quickly stop itself and display as "Exited". This is completely normal.)*
    4. *Docs Link*: [Docker Desktop Container Management](https://docs.docker.com/desktop/use-desktop/container/)
*   **Inspecting Logs & Telemetry**:
    1. Click on the `zoro-zero` stack to expand it and view individual containers (`zoro-ollama`, `zoro-ollama-init`, `zoro-gateway`, `zoro-dashboard`).
    2. Click on any container's name to open its detail view, where the **Logs** tab displays real-time execution outputs.
    3. Use the **Stats** tab to monitor active CPU, memory, and disk utilization.
    4. *Docs Link*: [Docker Desktop Logs & Monitoring](https://docs.docker.com/desktop/use-desktop/logs/)
*   **Executing Commands Natively**:
    1. Select the `zoro-gateway` container in Docker Desktop.
    2. Click on the **Terminal** (or **Exec**) tab.
    3. You will be dropped directly into the container's interactive shell. To start the agent chat immediately without typing PowerShell commands, just type:
       ```bash
       hermes chat
       ```
*   **Volume & Memory Inspection**:
    1. Navigate to the **Volumes** tab in Docker Desktop's left sidebar.
    2. Here, you can inspect active bind mounts (such as the persistent host `.hermes` mount) and see details about size and directory paths.
    3. *Docs Link*: [Docker Desktop Volumes Guide](https://docs.docker.com/desktop/use-desktop/volumes/)

---

## ⚡ Daily Operational Cycle

Follow these standard commands in a PowerShell window inside `C:\Users\<username>\Zoro-Zero` (or your active workspace root) to operate the stack daily.

### 1. Powering On the Stack
Bring the multi-container stack online in detached mode:
```powershell
docker compose up -d
```
*Expected Outcome*: Docker will verify images, initialize the private bridge network, and spin up the four containers.

### 2. Verifying Service Telemetry
Confirm that all containers are healthy and running without crash loops:
```powershell
docker compose ps
```
Verify the GPU pass-through is active inside the Ollama container:
```powershell
docker exec -it zoro-ollama nvidia-smi
```

### 3. Creating the 64k Model Layer (One-Time / Post-Reset)
If the custom model is deleted or Ollama volumes are wiped, rebuild the custom model tag:
```powershell
docker exec -it zoro-ollama ollama create qwen3:8b-64k -f /root/.ollama/Modelfile
```

### 4. Interactive Console Operation
To interact directly with the agent inside the gateway container console:
```powershell
docker exec -it zoro-gateway hermes chat
```
*REPL Navigation*:
- Type your prompt and press **Enter** to submit.
- Run `/help` to see all active console commands.
- Run `/exit` or press **Ctrl+D** to close the session.

### 5. Pausing vs Tearing Down the Stack
When the session is complete, you can either pause the containers or completely tear them down to release system RAM and VRAM.

*   **To Pause (Stop)**:
    ```powershell
    docker compose stop
    ```
    *Expected Outcome*: Container execution halts, keeping the ephemeral filesystem intact. This is equivalent to pressing the "Stop" button in Docker Desktop.

*   **To Tear Down (Destroy)**:
    ```powershell
    docker compose down
    ```
    *Expected Outcome*: Container states are cleanly flushed, ports are released, and networks are torn down. **Because of host bind-mounts, all persistent data remains untouched on your host**, making this 100% safe to do daily.

---

## 💾 State Management & Host File Preservation

The Docker Compose configuration mounts host directories to protect your data across stack restarts.

### 1. Local State Path (`c:\Users\<username>\.hermes\`)
All operational states, databases, and logs are persisted directly to your Windows user profile:
* **`state.db`**: Tracks user profiles, auth details, and console histories.
* **`kanban.db`**: Manages the Kanban coordination board states.
* **`sessions/`**: Stores chronological `.json` session transcripts.
* **`skills/`**: Houses dynamically generated skill documents.

### 2. Turnkey Configuration Overlay (`./config.yaml`)
To prevent manual post-deployment setup steps, the repository-level `config.yaml` is mounted read-write directly into the container as `/opt/data/config.yaml`.
* **Modification Policy**: If you modify options in `./config.yaml` on the host, the changes are dynamically inherited by the containers immediately. If the agent writes configurations via `/model --global`, they are saved back to this workspace file.

### 3. Model Weights Cache (`./.ollama/models`)
To prevent massive weight downloads (4.7 GB+) during rebuilds, Ollama's library is bind-mounted directly in the workspace at `./.ollama/models`.

### 4. Direct Volume Mapping Verification (Zero-Trust Proof)

When testing containerised AI agents, **do not trust the agent's textual output** to verify volume persistence. A local 8B model (`qwen3:8b-64k`) has a cognitive ceiling and may write files relative to its workspace (`/opt/hermes/`) instead of the mapped mount (`/opt/data/`), while claiming in chat that it wrote to the persistent directory.

To prove that the physical volume binding between your host system (`C:\Users\<username>\.hermes\`) and the container (`/opt/data/`) is fully functional, bypass the LLM and execute direct, deterministic diagnostics:

#### Test A: Host-to-Container Verification
Write a file directly on your Windows host PowerShell and confirm it exists inside the container:
```powershell
# 1. On Windows Host:
Set-Content -Path "$env:USERPROFILE\.hermes\host_direct_verify.txt" -Value "Host-to-Container volume mapping functional!"

# 2. Query inside the Gateway container:
docker exec -it zoro-gateway cat /opt/data/host_direct_verify.txt
```
*Expected Outcome*: Terminal prints `Host-to-Container volume mapping functional!`.

#### Test B: Container-to-Host Verification
Write a file directly inside the container and confirm it exists on your Windows host:
```powershell
# 1. Generate file inside the Gateway container:
docker exec -it zoro-gateway sh -c "echo 'Container-to-Host volume mapping functional!' > /opt/data/container_direct_verify.txt"

# 2. On Windows Host:
Get-Content -Path "$env:USERPROFILE\.hermes\container_direct_verify.txt"
```
*Expected Outcome*: PowerShell prints `Container-to-Host volume mapping functional!`.

---

## 🏃 Post-Build Daily Operational Commands

Once the stack is initialized and running, utilize these standard operating commands inside a PowerShell window to manage, inspect, and optimize the agent's behavior.

### 1. Direct Non-Interactive Queries
Students can bypass the interactive console loop to run a single programmatic query directly from the host terminal:
```powershell
docker exec -t zoro-gateway hermes chat -q "Write a python script to parse logs."
```
*Tip: Append `-Q` (quiet mode) to suppress the ASCII banner and tool indicators, outputting only the raw final answer.*

### 2. Managing Agent Skills
Dynamic procedural knowledge (skills) is stored directly in `/opt/data/skills/`.
*   **List all preloaded and created skills**:
    ```powershell
    docker exec -t zoro-gateway hermes skills list
    ```
*   **Inspect a specific skill's instructions**:
    ```powershell
    docker exec -t zoro-gateway hermes skills view official/research/duckduckgo-search
    ```
*   **Manually install optional registry skills**:
    ```powershell
    docker exec -it zoro-gateway hermes skills install official/research/searxng-search
    ```

### 3. Wiping State Databases & Waking a Clean Agent
During security testing, you may need to wipe the agent's memory to ensure a completely clean execution path without historical bias:
*   **The Command**: Execute this PowerShell command on your host to cleanly delete general state, pairing locks, and planning databases (will be auto-regenerated empty on next launch):
    ```powershell
    # 1. Stop the stack
    docker compose down

    # 2. Clear state caches and session transcripts
    Remove-Item -Path "$env:USERPROFILE\.hermes\state.db" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:USERPROFILE\.hermes\kanban.db" -Force -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Path "$env:USERPROFILE\.hermes\sessions\*" -Force -ErrorAction SilentlyContinue

    # 3. Restart the stack
    docker compose up -d
    ```

### 4. Supply API Keys & Sync Configuration
If a student registers a free API key (like Tavily or Firecrawl) to upgrade from "search-only" to full page extraction:
1.  Open `.env` in the repository root and append the key:
    ```bash
    TAVILY_API_KEY=tvly-yourkeyhere
    ```
2.  Restart the services to inject the environment variable into the gateway container:
    ```powershell
    docker compose restart
    ```

### 5. Running Debugging & Verbose Tracing
To trace why the agent is failing a tool or see the underlying JSON exchange with Ollama:
*   **Command**: Run the interactive chat in verbose mode:
    ```powershell
    docker exec -it zoro-gateway hermes chat --verbose
    ```
*   **Log Location**: Check session transaction logs dynamically:
    Sessions are logged to `C:\Users\<username>\.hermes\logs\`. You can view them in VS Code or tail them using PowerShell:
    ```powershell
    Get-Content -Path "$env:USERPROFILE\.hermes\logs\errors.log" -Tail 50 -Wait
    ```

---

## 🚨 Critical Troubleshooting Protocols

> [!TIP]
> **Visual Debugging via Docker Desktop**
> If you are intimidated by terminal command-line traces, open the **Docker Desktop** application. Clicking on any container in the `zoro-zero` stack provides a clean, graphical **Logs** interface where you can easily read errors and warnings without having to type commands.

### Triage 1: Port Allocation Crashes (`Port 11434 is already in use`)
* **Symptom**: `zoro-ollama` fails to start, displaying:
  `Error response from daemon: Ports are not available: exposing port TCP 127.0.0.1:11434 -> 0.0.0.0:0: listen tcp 127.0.0.1:11434: bind: Address already in use`
* **Root Cause**: A native Windows Ollama background service is running on the host machine.
* **Resolution**: Terminate the host Ollama process prior to starting Docker:
  ```powershell
  Stop-Process -Name "ollama" -Force
  ```

### Triage 2: Swappage & Extreme Performance Drops (<1 token/sec)
* **Symptom**: Agent replies take minutes, showing slow token generation in Docker Desktop console.
* **Root Cause**: VRAM boundary overflow. If a massive model (like `gemma4:26b` at Q4) is loaded, VRAM caps out, forcing WSL2 to spill into host RAM. This triggers memory paging.
* **Resolution**: Ensure `qwen3:8b-64k` is selected as the default model. Run a VRAM inventory:
  ```powershell
  docker exec -it zoro-ollama nvidia-smi
  ```
  Ensure background GPU-heavy programs (video editors, 3D rendering engines) are closed on the host system during local agent execution.
