#!/bin/bash


appendToBashrc() {
  # Check if /etc/bash.bashrc exists and is writable
  if [ -f /etc/bash.bashrc ] && [ -w /etc/bash.bashrc ]; then
    bashrc_file="/etc/bash.bashrc"
  else
    # If /etc/bash.bashrc does not exist or is not writable, use ~/.bashrc
    echo "No /etc/bash.bashrc available (maybe no permission?), selecting ~/.bashrc. You have 3 seconds to stop this script."
    sleep 3
    bashrc_file="$HOME/.bashrc"
  fi

  # Check if the "# appended by linux-common v1" line exists in the file
  if ! grep -q "# appended by linux-common v1" "$bashrc_file"; then
    # Append the comment and the 'alias' commands to the end of the file
    echo "Adding general quick commands."
    cat >>"$bashrc_file" <<EOL

  # appended by linux-common v1
alias cls='clear'
alias psf='ps -ef | grep'
alias scr='screen'
alias vi='vim'
alias c77='sudo chmod 777'
alias sys='sudo systemctl'
alias syse='sudo systemctl enable'
alias syst='sudo systemctl status'
alias syss='sudo systemctl start'
alias sysr='sudo systemctl daemon-reload && systemctl restart'
alias jrn='journalctl'
alias vibash='vi ~/.bash_history'
alias lsa='ls -a'
alias lsh='ls -lh'
alias si='sudo -i'
alias rm='rm -I'

shopt -s autocd
export HISTSIZE=-1
export HISTFILESIZE=-1
export HISTCONTROL=ignoredups

EOL
    if command -v pacman &>/dev/null; then
        if ! grep -q "alias pins='sudo pacman -S --needed'" "$bashrc_file"; then
            echo "Adding 'pins' alias for pacman."
            echo "alias pins='sudo pacman -S --needed'" >> "$bashrc_file"
        fi
    fi

    # Check if 'apt' is available and add the 'ains' alias
    if command -v apt &>/dev/null; then
        if ! grep -q "alias ains='sudo apt install'" "$bashrc_file"; then
            echo "Adding 'ains' alias for apt."
            echo "alias ains='sudo apt install'" >> "$bashrc_file"
        fi
    fi

    echo "Aliases successfully appended to $bashrc_file."
    echo "# End (appended by linux-common v1)" >> "$bashrc_file"
  else
    echo "Comment and aliases already exist in $bashrc_file."
  fi
}

fixLocale(){
  echo "Uncommenting en_US.UTF-8 in locale.gen..."
  sed -i '/^#[[:space:]]*en_US.UTF-8 UTF-8/s/^#//' /etc/locale.gen

  echo "Uncommenting zh_CN.UTF-8 in locale.gen..."
  sed -i '/^#[[:space:]]*zh_CN.UTF-8 UTF-8/s/^#//' /etc/locale.gen

  echo "Re-generating locale..."
  locale-gen

  echo "-----------[Complete!]--------------"
}

Cleanup(){
  local script_path
  script_path=$(readlink -f "$0")
  echo "Deleting script at: $script_path"
  sleep 1
  # Delete with background process to avoid issues with deleting a running script
  (sleep 1; rm "$script_path") &
  exit 0
}

# -------------------- main() -----------------------
# Define an associative array of commands with descriptions
declare -A commands=(
  [2]="appendToBashrc"
  [3]="fixLocale"
  [1]='Cleanup'
  [4]=""
)

# Define an associative array of descriptions
declare descriptions=(
  [2]="Append quick commands to .bashrc"
  [3]="Fix 'LC_ALL: cannot change locale' problem"
  [1]="Delete the script itself."
  [4]=""
)

if [[ -n "$1" ]]; then
    if [[ -n "${commands[$1]}" ]]; then
        eval "${commands[$1]}"
        exit 0
    fi
    # If $1 doesn't match any command index, continue to menu
fi

failCount=0
while true; do
  if ((failCount > 6)); then
    echo "Max retries limit exceeded. To avoid looped stdin the script stopped. Please re-run it."
    exit 0
  fi

  # Clear screen and show menu
  clear
  echo "Please select a command (0-${#commands[@]}):"
  echo "0 - Exit"
  for i in "${!descriptions[@]}"; do
    echo "$i - ${descriptions[$i]}"
  done

  # Use read with options for better input handling
  read -r -p "Select: " user_input

  # Check for exit condition first
  if [[ "$user_input" == "0" ]]; then
    echo "Exiting..."
    exit 0
  fi

  # Check if the input is a valid number
  if [[ $user_input =~ ^[0-9]+$ ]] && ((user_input >= 1 && user_input <= ${#commands[@]})); then
    selected_command="${commands[$user_input]}"
    if [[ -n "$selected_command" ]]; then
      eval "$selected_command"
      # Reset fail count after successful command
      failCount=0
    else
      echo "Command not implemented yet."
      ((failCount++))
    fi
  else
    echo "Invalid input. Please enter a number between 0 and ${#commands[@]}."
    ((failCount++))
  fi

  # Add pause to see results
  echo
  read -n 1 -s -r -p "Press any key to continue..."
done
