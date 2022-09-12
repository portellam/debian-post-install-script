#!/bin/bash sh

exit 0

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo -e "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi
#

# user input #
str_input1=""

function UserInput {
    declare -i int_count=0            # reset counter
    echo $str_input1
    while true; do
        # passthru input variable if it is valid #
        if [[ $1 == "Y"* || $1 == "y"* ]]; then
            str_input1=$1     # input variable
            break
        fi
        #
        # manual prompt #
        if [[ $int_count -ge 3 ]]; then       # auto answer
            echo -e "$0: Exceeded max attempts."
            str_input1="N"                     # default input     # NOTE: change here
        else                                        # manual prompt
            echo -en "$0: [Y/n]: "
            read str_input1
            # string to upper
            str_input1=$(echo $str_input1 | tr '[:lower:]' '[:upper:]')
            str_input1=${str_input1:0:1}
            #
        fi
        #
        case $str_input1 in
            "Y"|"N")
                break
            ;;
            *)
                echo -e "$0: Invalid input."
            ;;
        esac  
        ((int_count++))   # counter
    done  
}
#

### NOTE: clone/update git repos here 

echo "$0: Cloning/Updating Git repos."
str_dir1="/root/git/"
if [[ ! -d $str_dir1 ]]; then mkdir -p $str_dir1; fi     # if dir doesn't exist, create it

# here goes useful repos for system deployment
# list of git repos     # NOTE: update here
declare -a arr_repo=(   

#"username/reponame"
"corna/me_cleaner"
"dt-zero/me_cleaner"
"foundObjects/zram-swap"
"portellam/VFIO-setup"
"portellam/Auto-Xorg"
"pyllyukko/user.js"
"StevenBlack/hosts"

)
    
# loop thru list
int_repo=${#arr_repo[@]}
for (( int_index=0; int_index<$int_repo; int_index++ )); do
    
    # reset working dir
    cd ~/
        
    str_repo=${arr_repo[$int_index]}
    str_user=$(echo $str_repo | cut -d "/" -f1)
        
    if [[ ! -d $str_dir1$str_user ]]; then mkdir -p $str_dir1$str_user; fi     # create folder
        
    # update local repo #
    if [[ -e $str_dir1$str_repo ]]; then
        cd $str_dir1$str_repo
        git pull https://github.com/$str_repo
    else
        # validate input variable #
        if [[ $1 != "Y"* ]]; then
            echo -en "$0: Clone repo '$str_repo'? [Y/n]: "
            read str_input1
            str_input1=$(echo $str_input1 | tr '[:lower:]' '[:upper:]')
            str_input1=${str_input1:0:1}
            UserInput $str_input1

            if [[ $str_input1 != "Y"* ]]; then
                cd $str_dir1$str_user
                git clone https://github.com/$str_repo
            fi

        # automatic input #
        else
            cd $str_dir1$str_user
            git clone https://github.com/$str_repo
        fi
        #
    fi
    #
        
done

### NOTE: execute git scripts here ###

echo "$0: Executing Git scripts."

# prompt user to execute script or do so automatically #
function ExecuteScript {
    if [[ $1 != "Y" ]]; then
        echo -e "$0: Execute script '$str_repo'?"
        read str_input1
        str_input1=$(echo $str_input1 | tr '[:lower:]' '[:upper:]')
    else str_input1="Y"; fi
}
#

## portellam/Auto-Xorg ##
str_repo="portellam/Auto-Xorg"
ExecuteScript $str_repo

if [[ $str_input1 != "Y"* ]]; then
    cd $str_dir1$str_repo
    sudo bash ./installer.sh
fi
##

## StevenBlack/hosts ##
str_repo="StevenBlack/hosts"
ExecuteScript $str_repo

if [[ $str_input1 != "Y"* ]]; then
    cd $str_dir1$str_repo
    str_file1="/etc/hosts"

    if [[ -d $str_file1'_old' ]]; then sudo cp $str_file1 $str_file1'_old'     # backup hosts
    else sudo cp $str_file1'_old' $str_file1; fi                                    # restore backup

    echo $'\n#' >> $str_file1
    cat hosts >> $str_file1
fi
##
    
## pyllyukko/user.js ##
str_repo="pyllyukko/user.js"
ExecuteScript $str_repo

if [[ $str_input1 != "Y"* ]]; then
    cd $str_dir1$str_repo
    make debian_locked.js
    str_file1="/etc/firefox-esr/firefox-esr.js"

    if [[ -d $str_file1'_old' ]]; then cp $str_file1 $str_file1'_old'; fi          # backup system user.js

    cp debian_locked.js $str_file1
    #ln -s debian_locked.js /etc/firefox-esr/firefox-esr.js      # NOTE: unused
fi
##
    
## foundObjects/zram-swap ##
str_repo="foundObjects/zram-swap"
ExecuteScript $str_repo

if [[ $str_input1 != "Y"* ]]; then
    cd $str_dir1$str_repo
    sudo sh ./install.sh
fi
##

IFS=$SAVEIFS                # reset IFS
echo -e "$0: Exiting."
exit 0