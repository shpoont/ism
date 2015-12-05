# ism
Interactive Shell Monitor

## Features
- Collect and display stats about sucessful and unsuccessful commands that are executed in interactive shell.
- Display notifications when a command is failing too often (e.g. you type "sl" instead of "ls").

## Requirements
- Only bash is supported for now
- bash-preexec - https://github.com/rcaloras/bash-preexec
- jq - https://stedolan.github.io/jq
- python

## Installation instructions

### OS X
```sh
$ brew install jq
$ brew install bash-preexec
$ echo "source \$(brew --prefix)/etc/profile.d/bash-preexec.sh" >> ~/.bashrc

$ curl https://raw.githubusercontent.com/shpoont/ism/master/ism.sh -o ~/.ism.sh
$ echo "source ~/.ism.sh" >> ~/.bashrc
```

### Linux
- Install jq and bash-preexec manually
- Make sure you have python installed

```sh
$ curl https://raw.githubusercontent.com/shpoont/ism/master/ism.sh -o ~/.ism.sh
$ echo "source ~/.ism.sh" >> ~/.bashrc
```

## Usage

### Displaying usage stats
[Animation]

### Getting notifications about unsuccessful commands
[Animation]

## Settings

You can add settings to your ~/.bashrc file, before ism.sh is sourced. See example below.

*ISM_DATA_DIR* - Directory where ism will store data. Default is "~/.ism".

*ISM_DATA_TTL* - Amount of days to keep information about inactive commands. Default is "30".

*ISM_ALERT_FAILURES_COUNT* - Amount of unsuccessful command executions, after which a notification will be triggerred. Default is "10". Setting to "0" will turn the alert off.

*ISM_STATS_LIMIT* - Limit of commands displayed when using "ism --stats". Default is "20".

Example: 
```sh

ISM_STATS_LIMIT=30
ISM_DATA_TTL=10
ISM_ALERT_FAILURES_COUNT=5

source ~/.ism.sh

```
