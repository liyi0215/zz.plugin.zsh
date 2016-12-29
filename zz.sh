#!/bin/zsh

# version
readonly ZZ_VERSION=0.0.1

# colors
readonly ZZ_BLUE="\033[96m"
readonly ZZ_GREEN="\033[92m"
readonly ZZ_YELLOW="\033[93m"
readonly ZZ_RED="\033[91m"
readonly ZZ_NOC="\033[m"

# function

zz_print_usage(){
cat <<- EOF
Commands:
    add <name> <value>
    add! <name> <value> Overwrites existing key value
    rm <name>
    list
    copy <name>         Copy value from give name

Specify configs in the ini-formatted file:
    $HOME/.zzrc
EOF
}

# type 接受的值 "warn", "fail", "info", "success"
zz_print_msg(){
    local type=$1
    local msg=$2
    # echo "type:"$type:"msg:"$msg

    if [[ $color == "" || $msg == "" ]]
    then
        print " ${ZZ_RED}*${ZZ_NOC} Could not print message. Sorry!"
    else
        case $type in
            warn)
                print " ${ZZ_YELLOW}*${ZZ_NOC} ${msg}"
                ;;
            fail)
                print " ${ZZ_RED}*${ZZ_NOC} ${msg}"
                ;;
            info)
                print " ${ZZ_BLUE}*${ZZ_NOC} ${msg}"
                ;;
            success)
                print " ${ZZ_GREEN}*${ZZ_NOC} ${msg}"
                ;;
            *)
                print " ${type}"
                ;;
        esac
    fi
}

zz_add(){
    local force=$1
    local name=$2
    local token=$3
    if [[ -z $name || -z $token ]]
    then
        zz_print_msg fail "参数格式不对，格式如下"
        zz_print_msg success "eg: zz add key value"
    elif [[ -z ${keys[$name]} ]] || $force
    then
        zz_remove $name > /dev/null
        printf "%q:%s\n" "${name}" "${token}" >> $ZZ_CONFIG
        zz_print_msg success "Key Value added"
    else
        zz_add_ow true $name $token
    fi
}

zz_add_ow(){
    echo -n "Key '$2' already exists. overwrite? [y/n] "
    read
    case $REPLY in
        [yY]*)
            zz_add $1 $2 $3
            ;;
        [nN]*)
            exit
            ;;
        *)
            exit
            ;;
    esac
}

zz_remove(){
    local key=$1

    if [[ -n ${keys[$key]} ]]
    then
        local configb=$ZZ_CONFIG.tmp
        if sed "/^${key}:.*$/d" $ZZ_CONFIG > $configb  && mv $configb $ZZ_CONFIG
        then
            zz_print_msg success "${key} removed."
        else
            zz_print_msg fail "Something Wrong."
        fi
    else
        zz_print_msg fail "Key '${key}' was not found."
    fi
}

zz_copy(){
    local key=$1

    if [[ -n ${keys[$key]} ]]
    then
        if sed -n "s/${key}:\(.*\)/\1/pg" $ZZ_CONFIG | tr -d "\n" | pbcopy
        then
            print "\033[7;30;42m Already Copied \033[0m"
        else
            zz_print_msg fail "Something Wrong."
        fi
    else
        zz_print_msg fail "Key '${key}' was not found."
    fi
}

zz_list(){
    zz_print_msg info "All keys-values :"
    entries=$(sed "s:${HOME}:~:g" $ZZ_CONFIG)

    max_warp_point_length=0
    while IFS= read -r line
    do
        arr=(${(s,:,)line})
        key=${arr[1]}
        length=${#key}
        if [[ length -gt max_warp_point_length ]]
        then
            max_warp_point_length=$length
        fi
    done <<< $entries
    while IFS= read -r line
    do
        if [[ $line != "" ]]
        then
            arr=(${(s,:,)line})
            key=${arr[1]}
            val=${arr[2]}

            printf "\033[7;30;$(($RANDOM%5+42))m %${max_warp_point_length}s  ->  %s" $key $val
            printf "\033[0m\n"
        fi
    done <<< $entries
}

local ZZ_CONFIG=$HOME/.zzrc

# check if config file exists
if [ ! -e $ZZ_CONFIG ]
then
    # if not, create config file
    touch $ZZ_CONFIG
fi

# load all keys
typeset -A keys
while read -r line
do
    arr=(${(s,:,)line})
    key=${arr[1]}
    val=${arr[2]}

    keys[$key]=$val
done < $ZZ_CONFIG


# check if no arguments were given, and that version is not set
if [[ ($? -ne 0 || $#* -eq 0) ]]
then
    zz_print_usage
    # check if config file is writeable
elif [ ! -w $ZZ_CONFIG ]
then
    # do nothing
    # can't run `exit`, as this would exit the executing shell
    zz_exit_fail "\'$ZZ_CONFIG\' is not writeable."
else
    # parse rest of options
    for o
    do
        case "$o"
            in
            -a|--add|add)
                zz_add false $2 $3
                break
                ;;
            -r|remove|rm)
                zz_remove $2
                break
                ;;
            -l|list|ls)
                zz_list
                break
                ;;
            -h|--help|help)
                zz_print_usage
                break
                ;;
            -c|--copy|copy)
                zz_copy $2
                break
                ;;
            *)
                zz_warp $o
                break
                ;;
            --)
                break
                ;;
        esac
    done
fi

unset zz_add
unset zz_add_ow
unset zz_remove
unset zz_list
unset zz_print_msg
unset zz_print_usage
unset zz_copy
unset keys