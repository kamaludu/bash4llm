[![Bash4LLM](https://img.shields.io/badge/_Bash4LLM⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)
# INSTALLATION [🇮🇹](INSTALL.md) 🇬🇧

Bash4LLM⁺ is a portable and secure Bash wrapper for the API of various LLMs (with native support for Groq).
It requires neither Python nor external dependencies beyond POSIX/coreutils commands and basic shell utilities.
## 1. Requirements
Bash4LLM⁺ requires the following packages to be available in your PATH:
 * ***bash*** (version 4.0 or higher for associative array support)
 * coreutils (stat, chmod, mkdir commands, etc.)
 * findutils
 * util-linux
 * gawk
 * curl
 * jq
### Compatibility
Bash4LLM⁺ is tested and supported on:
 * GNU/Linux
 * macOS (with standard utilities or GNU packages from Homebrew)
 * WSL and Cygwin (Windows)
 * Termux (Android)
 * BSD (FreeBSD, OpenBSD, NetBSD)
## 2. Quick Installation (Fast Forward)
> [!TIP]
> **⏩ FAST FORWARD (Quick Installation)**
> Run these commands in your terminal to quickly download and configure **Bash4LLM⁺**:
> ```sh
> # 1. Clone the repository (shallow clone for maximum speed)
> git clone --depth 1 --branch main https://github.com/kamaludu/bash4llm.git repo-bash4llm  
> 
> # 2. Create a working directory and extract the executable
> mkdir -p bash4llm
> cp repo-bash4llm/bin/bash4llm bash4llm/
> chmod +x bash4llm/bash4llm
> 
> # 3. Enter the directory and refresh the models 
> cd bash4llm 
> ./bash4llm --refresh-models
> 
> ```
> The script will detect the missing key and prompt you for interactive input:
> Enter API key for provider groq (env GROQ_API_KEY):
> Enter your Groq API key. To avoid re-entering it in subsequent executions within the current terminal session, export it:
> export GROQ_API_KEY="gsk_xxxxxxxxxxxxxxxxx"
> Recommended: ***install the optional Extras*** (additional providers, REPL chat, templates):
> ```sh
> # 4. Install Extras
> ./bash4llm --install-extras ../repo-bash4llm/extras/
> 
> ```
> Use Bash4llm ⚡
> 
### 2.1 Manual Installation
Make the main file executable after downloading or copying it:
chmod +x bash4llm
### 2.2 Setting the API Key
Bash4LLM⁺ reads the API key from the environment. Export it in your shell configuration file (e.g., ~/.bashrc or ~/.bash_profile):
export GROQ_API_KEY="your_key_here"
## 3. Directory Structure
Upon the first execution, the script creates the following working structure inside the runtime directory (bash4llm.d/), applying restrictive permissions 700 (directories) and 600 (files) to prevent access by other system users:
```text
bash4llm.d/
    config/                # Configuration and persistence for default providers/models
        providers/         # Provider-specific configurations (e.g., hf_endpoints)
        ui_state/          # State JSON files for GUI and automations
            threads/       # Metadata and indexes of active sessions
        thread_cache/      # Local caching of thread responses (if active)
    models/                # Txt files for model whitelists per provider
    templates/             # Reusable prompt templates
    history/               # Automatically saved output history
        threads/           # Conversational history of threads in NDJSON format
    tmp/                   # Secure, isolated directory for locks and temporary files
    extras/                # Optional add-ons (installed via --install-extras)
        providers/         # External provider scripts (Gemini, Hugging Face, Mistral)

```
## 4. Installing Extras (--install-extras)
To use advanced features (the key encryption console, additional providers like Gemini or Hugging Face, or the interactive REPL chat interface), install the Extras:
./bash4llm --install-extras
If you run the executable outside the cloned repository directory, specify the path to the extras folder:
./bash4llm --install-extras /path/to/source/extras
The installer will recursively copy the necessary files into the secure bash4llm.d/extras/ perimeter, applying restrictive 700 permissions to executable files (such as provider modules and the TUI chat) and 600 to help documents or templates.
If you are operating on a non-natively POSIX filesystem (such as an NTFS share under Windows or certain network mounts), the script will detect the limitations in applying permissions and print a non-blocking warning.
## 5. Troubleshooting
### Security Error (Exit Code 17 - BASH4LLM_ERR_SEC)
If the script terminates with the BASH4LLM_ERR_SEC error, it means a static security check has detected overly permissive write permissions on the local configuration file or the program folder. Secure your working environment by running:
```sh
chmod 700 bash4llm.d
chmod 600 bash4llm.d/config/config

```
### Filesystem Lock Timeouts
If you receive a timeout error while writing models or threads due to prolonged concurrent operations, you can increase the maximum wait time (expressed in seconds) by exporting the correct environment variable:
export BASH4LLM_LOCK_TIMEOUT_HISTORY=30
## 6. Uninstallation
Bash4LLM⁺ is entirely self-contained. To permanently remove it from the system, simply delete the executable and its working directory:
```sh
rm -rf bash4llm.d
rm bash4llm

```
## 7. License
Bash4LLM⁺ is free software distributed under the **GNU GPL v3** license.
