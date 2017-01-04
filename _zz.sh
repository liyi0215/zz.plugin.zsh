#compdef zz

zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion::complete:zz:*:commands' group-name commands
zstyle ':completion::complete:zz:*:key_value' group-name key_value
zstyle ':completion::complete:zz::' list-grouped

zmodload zsh/mapfile

function _zz() {
  local CONFIG=$HOME/.zzrc
  local ret=1

  local -a commands
  local -a key_value

  key_value=( "${(f)mapfile[$CONFIG]//$HOME/~}" )

  commands=(
    'add:Adds the current working directory to your Keys values'
    'copy:Copy the value of key'
    'rm:Removes the given warp point'
    'ls:Show files from given warp point'
    'help:Show this extremely helpful text'
    'clean:Remove points warping to nonexistent directories'
  )

  _arguments -C \
    '1: :->first_arg' \
    '2: :->second_arg' && ret=0

  case $state in
    first_arg)
      _describe -t key_value "Keys values" key_value && ret=0
      _describe -t commands "Commands" commands && ret=0
      ;;
    second_arg)
      case $words[2] in
        rm)
          _describe -t points "Keys values" key_value && ret=0
          ;;
        add)
          _message 'Write the key and value' && ret=0
          ;;
        ls)
          _describe -t points "Keys values" key_value && ret=0
          ;;
      esac
      ;;
  esac

  return $ret
}

_zz "$@"