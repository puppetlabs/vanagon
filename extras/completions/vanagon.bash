#!/usr/bin/env bash

_vanagon()
{
  local cur prev projects commands template_arg_commands 

  # COMREPLY is an array variable used to store completions  
  # the completion mechanism uses COMPRELY to display its contents as completions
  # COMP_WORDS is an array of all the words typed after the name of the program 
  # COMP_CWORD is an index of the COMP_WORDS array pointing to the current word
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  projects=($({ vanagon list -r | sed 1d; } 2>/dev/null))
  commands="build build_host_info build_requirements completion inspect list render sign ship help"
  template_arg_commands="build build_host_info build_requirements inspect render "

  # completes with a project if the previous word was a command in template_arg_commands
  if [[ $template_arg_commands =~ (^| )$prev($| ) ]] ; then
      _vanagon_avail_templates_projects=$({ vanagon list -r | sed 1d; } 2>/dev/null)
      # compgen generates completions filtered based on what has been typed by the user
      COMPREPLY=( $(compgen -W "${_vanagon_avail_templates_projects}" -- "${cur}") )
  fi 

  # allows multiple platforms to be tab completed 
  if [[ ${#COMP_WORDS[@]} -gt 3 ]] ; then 
    _vanagon_avail_templates_platforms=$({ vanagon list -l | sed 1d; } 2>/dev/null)
    COMPREPLY=( $(compgen -W "${_vanagon_avail_templates_platforms}" -- "${cur}") )
  fi

  if [[ $1 == $prev ]] ; then
    # only show top level commands we are at root
    COMPREPLY=( $(compgen -W "${commands}" -- "${cur}") )
  fi
}

# assign tab complete function `_vanagon ` to `vanagon` command 
complete -F _vanagon vanagon
