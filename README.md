# ism
Interactive Shell Monitor

__This is a work-in-progress repo for now, wait till the first release.__

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
$ sl
-bash: sl: command not found
$ sl
-bash: sl: command not found
-----------
ism notice: This command is failing too often

    sl

try to fix this
-----------
$
```
