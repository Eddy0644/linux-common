#!/bin/bash

appendToBashrc() {
  # Check if /etc/bash.bashrc exists and is writable
  if [ -f /etc/bash.bashrc ] && [ -w /etc/bash.bashrc ]; then
    bashrc_file="/etc/bash.bashrc"
  else
    # If /etc/bash.bashrc does not exist or is not writable, use ~/.bashrc
    echo "No /etc/bash.bashrc available, selecting ~/.bashrc. You have 3 seconds to stop this script."
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
alias pins='sudo pacman -S --needed'
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

# -------------------- main() -----------------------
# Define an associative array of commands with descriptions
declare -A commands=(
  # Replaced by new restart command: pkill plasmashell; screen -dmS psh plasmashell
  [1]="appendToBashrc"
  [2]=""
  [3]=''
  [4]=""
)

# Define an associative array of command descriptions
declare descriptions=(
  [1]="Append quick commands to .bashrc"
  [2]=""
  [3]=""
  [4]=""
)
failCount=0
while true; do

  if ((failCount > 6));then
    echo "Max retries limit exceeded. To avoid looped stdin the script stopped. Please re-run it."
    exit 0
  fi

  # Prompt the user for input and show command details
  echo "Please select a command (1-${#commands[@]}):"
  for i in "${!descriptions[@]}"; do
    echo "$i - ${descriptions[$i]}"
  done

  read -p "Select: " user_input

  # Check if the input is a valid number
  if [[ $user_input =~ ^[0-9]+$ ]] && ((user_input >= 1 && user_input <= ${#commands[@]})); then
    selected_command="${commands[$user_input]}"
    # Execute the selected command
    eval "$selected_command"
  else
    echo "Invalid input. Please enter a valid number."
    ((failCount++))
  fi

done
