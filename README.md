# ism
Interactive Shell Monitor

__This is a work-in-progress repo for now, wait till the first release.__

## Features
- Collect stats about sucessful and unsuccessful commands, being executed in interactive shell.
- Display notifications when a command is failing too often (e.g. you type "sl" instead of "ls").
- Display daily work summary on ism startup.

## Requirements
- Only bash is supported for now
- bash-preexec - https://github.com/rcaloras/bash-preexec
- jq - https://stedolan.github.io/jq
- python

## Installation instructions
Download https://raw.githubusercontent.com/shpoont/ism/master/ism.sh to your $HOME

Add this to your $HOME/.bashrc
```sh
source ~/ism.sh
```

## Usage
If you make too many mistakes with the same command, ism will notify you: 

```
$ sl
-bash: sl: command not found
$ sl
-bash: sl: command not found
$ sl
-bash: sl: command not found
-----------
ism notice: This command is failing too often

    sl

try to fix this
-----------
$
```

## Settings
ISM_DATA_DIR - Directory where ism will store data. Default is "~/.ism".

ISM_DATA_TTL - Amount of days to keep information about inactive commands. Default is "30".

ISM_ALERT_FAILURES_COUNT - Amount of unsuccessful command executions, after which a notification will be triggerred. Default is "10". Setting to "0" will turn the alert off.


Example: 
```sh

ISM_DATA_TTL=10
ISM_ALERT_FAILURES_COUNT=5

source ~/ism.sh

```
