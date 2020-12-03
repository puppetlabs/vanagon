_vanagon()
{
  local line commands template_arg_commands projects

  commands="build build_host_info build_requirements completion inspect list render sign ship help"
  template_arg_commands=("build" "build_host_info" "build_requirements" "inspect"  "render")
  projects=($({ vanagon list -r | sed 1d; } 2>/dev/null))

  # '%p:globbed-files:' sets completion to only offer files matching a 
  # described pattern.
  zstyle ':completion:*' file-patterns '%p:globbed-files:'
  
  # arguments function provides potential completions to zsh 
  # specs are of the form n:message:action 
  _arguments -C \
    ": :(${commands})" \
    "*::arg:->args" 

  # (Ie)prevents "invalid subscript"
  if ((template_arg_commands[(Ie)$line[1]])); then
    _vanagon_template_sub_projects
  fi
  if [[ $projects  =~ (^| )$line[2]($| ) ]]; then
    _vanagon_template_sub_platforms
  fi
}

_vanagon_template_sub_projects()
{
  # -W look in certain path but don't append path to tab compelte 
  # -g enables file matching pattern 
  # (:r) removes the file extension `.rb` from the completion 
  _arguments "1: :_files -W $(PWD)/configs/projects/ -g '*.rb(:r)'"
}

_vanagon_template_sub_platforms()
{
  _arguments "*: :_files -W $(PWD)/configs/platforms/ -g '*.rb(:r)'"
}
# compdef registeres the completion function: compdef <function-name> <program>
compdef _vanagon vanagon
