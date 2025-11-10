#!/bin/zsh
# === COLOR VARIABLES ===
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
MAGENTA="\033[0;35m"
BOLD="\033[1m"
RESET="\033[0m"

# === COLOR HELPERS ===
# Example usage: color_echo $RED "Error message"
color_echo() {
  local color="$1"
  shift
  echo "${color}$@${RESET}"
}
