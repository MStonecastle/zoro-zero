# Memory Core: Zoro-Zero

This file contains the persistent environment configuration and structural facts cached natively for the Zoro-Zero Turnkey Agent.

## 🧭 Active Environment Coordinates
*   **Inference Server**: `http://ollama:11434/v1` (container local)
*   **Active Model Tag**: `qwen3:8b-64k` (pre-seeded via Modelfile with custom VRAM KV cache)
*   **Local State Mount**: `/opt/data/` (Volume bind-mounted to Windows Host User Profile `C:\Users\<username>\.hermes\`)
*   **Workspace root inside container**: `/workspace` (isolated read-write environment)

## 🌐 Networking & Web Tools
*   **Active Search Backend**: `ddgs` (DuckDuckGo Search) - zero API key, search-only backend.
*   **Active Extraction Backend**: Configurable via host `.env` file (e.g. Tavily/Firecrawl keys).
*   **Active Website Blocklist**: Strict SSRF prevention enabled under `security.website_blocklist` in config.yaml. Blocks all loopback ranges (`127.0.0.1`, `localhost`), link-local nodes (`*.local`, `*.lan`), and private RFC1918 subnets (`10.*`, `192.168.*`, `172.16.*` to `172.20.*`).

## 🧠 Core Directives
*   **SOUL.md Location**: Your root identity and core system prompt directives are physically stored at `/opt/data/SOUL.md`. If asked to review your core directives, read this file directly.


