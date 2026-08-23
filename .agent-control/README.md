
# Claude Hybrid Agent Environment

Main repository:

    C:\Users\Jack\Documents\BioshockHavok


Local model:

    qwen3-coder:30b


Context window:

    32768


## Start REAL Claude Code

Run:

    powershell -ExecutionPolicy Bypass -File "C:\Users\Jack\Documents\BioshockHavok\.agent-control\Start-ClaudeCloud.ps1"


This removes any local Ollama routing variables before
launching Claude.


## Start LOCAL Claude Code

Run:

    powershell -ExecutionPolicy Bypass -File "C:\Users\Jack\Documents\BioshockHavok\.agent-control\Start-ClaudeLocal.ps1"


This routes Claude Code to:

    http://127.0.0.1:11434


using:

    qwen3-coder:30b


## Start the entire local agent team

Run:

    powershell -ExecutionPolicy Bypass -File "C:\Users\Jack\Documents\BioshockHavok\.agent-control\Start-AgentTeam.ps1"


Agents:

    researcher
    coder
    tester
    reviewer


## Check GPU usage

Run:

    powershell -ExecutionPolicy Bypass -File "C:\Users\Jack\Documents\BioshockHavok\.agent-control\Status.ps1"


## Ollama settings

OLLAMA_CONTEXT_LENGTH=32768

OLLAMA_NUM_PARALLEL=1

OLLAMA_MAX_LOADED_MODELS=1

OLLAMA_MAX_QUEUE=32


The AI workers use separate Git worktrees so they cannot
silently overwrite each other's working files.


The model is shared.

You have four logical agents but only one copy of the model
needs to generate at a time.

