#!/bin/bash sh

##
## Author(s):    Alex Portell <github.com/portellam>
##

declare -i int_thisExitCode=$?          # NOTE: necessary for exit code preservation, for conditional statements
declare -r str_pwd=$( pwd )

# prep and I/O functions #
    # function ChangeOwnershipOfFileOrDir
    # {
    #     # behavior:
    #     # change ownership of existing file to current user
    #     # current user may be the sudoer or root (either is not necessarily the same)
    #     # note: $UID is intelligent enough to differentiate between the two
    #     #

    #     if [[ -z $1 ]]; then        # null exception
    #         (exit 254)
    #         SaveThisExitCode
    #     else
    #         echo '$UID =='"'$UID'"
    #         chown -f $UID $1
    #         (exit 0)
    #         SaveThisExitCode
    #     fi
    # }

    function CheckIfUserIsRoot
    {
        if [[ $( whoami ) != "root" ]]; then
            str_thisFile=$( echo ${0##/*} )                         # reformat string
            str_thisFile=$( echo $str_thisFile | cut -d '/' -f2 )
            echo -e "\e[33mWARNING:\e[0m"" Script must execute as root. In terminal, run:\n\t'sudo bash $str_thisFile'"
            SaveThisExitCode        # call functions
            ExitWithThisExitCode
        fi
    }

    function CheckIfFileOrDirExists
    {
        echo -en "Checking if file or directory exists... "

        if [[ -z $1 ]]; then        # null exception
            (exit 254)
            SaveThisExitCode
        fi

        if [[ ! -e $1 ]]; then      # dir/file not found
            case $1 in
                *"/"*)
                    find $1 | uniq &> /dev/null || (exit 250)
                    SaveThisExitCode;;
                *)
                    find . -name $1 | uniq &> /dev/null || (exit 250)
                    SaveThisExitCode;;
            esac
        fi

        EchoPassOrFailThisExitCode  # call functions
        ParseThisExitCode
    }

    function CheckIfTwoFilesAreSame
    {
        echo -e "Verifying two files... "

        if [[ -z $1 || -z $2 ]]; then           # null exception
            (exit 254)
            SaveThisExitCode

        elif [[ ! -e $1 || ! -e $2 ]]; then     # file not found exception
            (exit 250)
            SaveThisExitCode

        elif [[ ! -r $1 || ! -r $2 ]]; then     # file not readable exception
            (exit 249)
            SaveThisExitCode

        else
            if cmp -s "$1" "$2"; then
                echo -e 'Positive Match.\n\t"%s"\n\t"%s"' "$1" "$2"
                (exit 0)
                SaveThisExitCode

            else
                echo -e 'False Match.\n\t"%s"\n\t"%s"' "$1" "$2"
                (exit 1)
                SaveThisExitCode
            fi
        fi
    }

    function CreateBackupFromFile
    {
        echo -en "Backing up file... "
        str_thisFile=$1

        # create false match statements before work begins, to catch exceptions #
        if [[ -z $str_thisFile ]]; then         # null exception
            (exit 254)
            SaveThisExitCode

        elif [[ ! -e $str_thisFile ]]; then     # file not found exception
            (exit 250)
            SaveThisExitCode

        elif [[ ! -r $str_thisFile ]]; then     # file not readable exception
            (exit 249)
            SaveThisExitCode

        else
            if [[ $int_thisExitCode -eq 0 ]]; then

                # parameters #
                declare -r str_suffix=".old"
                declare -r str_thisDir=$( dirname $1 )
                declare -ar arr_thisDir=( $( ls -1v $str_thisDir | grep $str_thisFile | grep $str_suffix | uniq ) )

                if [[ "${#arr_thisDir[@]}" -ge 1 ]]; then       # positive non-zero count

                    # parameters #
                    declare -ir int_maxCount=5
                    str_line=${arr_thisDir[0]}
                    str_line=${str_line%"${str_suffix}"}        # substitution
                    str_line=${str_line##*.}                    # ditto

                    if [[ "${str_line}" -eq "$(( ${str_line} ))" ]] 2> /dev/null; then      # check if string is a valid integer
                        declare -ir int_firstIndex="${str_line}"
                    else
                        (exit 254)
                        SaveThisExitCode
                    fi

                    for str_element in ${arr_thisDir[@]}; do
                        if cmp -s $str_thisFile $str_element; then
                            (exit 131)
                            SaveThisExitCode
                            break
                        fi
                    done

                    if cmp -s $str_thisFile ${arr_thisDir[-1]}; then        # if latest backup is same as original file, exit
                        (exit 131)
                        SaveThisExitCode
                    fi

                    while [[ ${#arr_thisDir[@]} -ge $int_maxCount ]]; do    # before backup, delete all but some number of backup files
                        if [[ -e ${arr_thisDir[0]} ]]; then
                            rm ${arr_thisDir[0]}
                            break
                        fi
                    done

                    if cmp -s $str_thisFile ${arr_thisDir[0]}; then         # if *first* backup is same as original file, exit
                        (exit 131)
                        SaveThisExitCode
                    fi

                    # parameters #
                    str_line=${arr_thisDir[-1]%"${str_suffix}"}     # substitution
                    str_line=${str_line##*.}                        # ditto

                    if [[ "${str_line}" -eq "$(( ${str_line} ))" ]] 2> /dev/null; then      # check if string is a valid integer
                        declare -i int_lastIndex="${str_line}"
                    else
                        (exit 254)
                        SaveThisExitCode
                    fi

                    (( int_lastIndex++ ))           # counter

                    if [[ $str_thisFile -nt ${arr_thisDir[-1]} && ! ( $str_thisFile -ef ${arr_thisDir[-1]} ) ]]; then       # source file is newer and different than backup, add to backups
                        cp $str_thisFile "${str_thisFile}.${int_lastIndex}${str_suffix}"
                    elif [[ $str_thisFile -ot ${arr_thisDir[-1]} && ! ( $str_thisFile -ef ${arr_thisDir[-1]} ) ]]; then
                        (exit 131)
                    else
                        (exit 131)
                    fi

                    SaveThisExitCode
                else
                    cp $str_thisFile "${str_thisFile}.0${str_suffix}"   # no backups, create backup
                    SaveThisExitCode
                fi
            fi
        fi

        EchoPassOrFailThisExitCode  # call functions
        ParseThisExitCode

        case $int_thisExitCode in   # append output and return code
            131)
                echo -e "No changes from most recent backup."
        esac
    }

    function CreateFile
    {
        echo -en "Creating file... "

        if [[ -z $1 ]]; then            # null exception
            (exit 254)
            SaveThisExitCode
        fi

        if [[ ! -e $1 ]]; then          # file not found
            touch $1 &> /dev/null || (exit 250)
            SaveThisExitCode
        else
            (exit 131)
            SaveThisExitCode
        fi

        EchoPassOrFailThisExitCode      # call functions
        ParseThisExitCode
    }

    function DeleteFile
    {
        echo -en "Deleting file... "

        if [[ -z $1 ]]; then            # null exception
            (exit 254)
            SaveThisExitCode
        fi

        if [[ ! -e $1 ]]; then          # file not found exception
            (exit 131)
            SaveThisExitCode

        else
            rm $1 &> /dev/null || (exit 255)
            SaveThisExitCode
        fi

        EchoPassOrFailThisExitCode          # call functions
        ParseThisExitCode
    }

    function EchoPassOrFailThisExitCode
    {
        # behavior:
        # output a pass or fail depending on the exit code
        #
        # reserved/unreserved exit codes:
        #
        #   0       == always pass
        #   3       == free
        #   131-255 == free
        #

        if [[ ! -z $1 ]]; then                      # append output
            echo -en "$1"
        fi

        case "$int_thisExitCode" in                 # append output
            0|3)
                echo -e " \e[32mSuccessful. \e[0m";;

            131)
                echo -e " \e[33mSkipped. \e[0m";;

            *)
                echo -e " \e[31mFailed. \e[0m";;
        esac
    }

    function EchoPassOrFailThisTestCase
    {
        # behavior:
        # output a pass or fail depending on the test case exut cide
        #

        str_testCaseName=$1

        if [[ ! -z $str_testCaseName ]]; then
            str_testCaseName="TestCase"
        fi

        case "$int_thisExitCode" in                 # append output
            0)
                echo -e "\e[32mPASS:\e[0m""\t$str_testCaseName";;
            *)
                echo -e " \e[33mFAIL:\e[0m""\t$str_testCaseName";;
        esac
    }

    function ExitWithThisExitCode
    {
        echo -e "Exiting."
        exit $int_thisExitCode
    }

    function ParseThisExitCode
    {
        # behavior:
        # output a specific error/exception given exit code
        #
        # relative exit codes:
        #
        #   3       == pass with some errors
        #   255-248 == specified
        #   <= 247  == function specific
        #

        if [[ ! -z $1 ]]; then      # append output
            echo -en "$1"
        fi

        case $int_thisExitCode in   # append output
            # 255)
            #     echo;;      # unspecified error
            254)
                echo -e "\e[33mException:\e[0m Null input.";;
            253)
                echo -e "\e[33mException:\e[0m Invalid input.";;
            252)
                echo -e "\e[33mError:\e[0m Missed steps; missed execution of key subfunctions.";;
            251)
                echo -e "\e[33mError:\e[0m Missing components/variables.";;
            250)
                echo -e "\e[33mException:\e[0m File/Dir does not exist.";;
            249)
                echo -e "\e[33mException:\e[0m File/Dir is not readable.";;
            248)
                echo -e "\e[33mException:\e[0m File/Dir is not writable.";;
            # *)
            #     echo;;
        esac
    }

    function ReadFile
    {
        echo -en "Reading file... "

        if [[ -z $1 ]]; then        # null exception
            (exit 254)
            SaveThisExitCode
        fi

        if [[ ! -e $1 ]]; then      # file not found exception
            (exit 250)
            SaveThisExitCode
        fi

        if [[ ! -r $1 ]]; then      # file is not readable exception
            (exit 249)
            SaveThisExitCode
        fi

        declare -la arr_output_thisFile=()

        while read str_line; do
            arr_output_thisFile+=("$str_line") || ( (exit 249) && SaveThisExitCode && arr_output_thisFile=() && break )
        done < $1

        EchoPassOrFailThisExitCode  # call functions
        ParseThisExitCode
    }

    function ReadInput
    {
        # behavior:
        # ask for Yes/No answer, return boolean,
        # default selection is N/false
        # always returns bool
        #

        # parameters #
        declare -ir int_maxCount=3
        declare -ar arr_count=$( seq $int_maxCount )

        for int_element in ${arr_count[@]}; do
            echo -en "$1 \e[30;43m[Y/n]:\e[0m "
            read str_input1
            str_input1=$( echo $str_input1 | tr '[:lower:]' '[:upper:]' )

            case $str_input1 in
                "Y"|"N")
                    break;;
                *)
                    if [[ $int_element -eq $int_maxCount ]]; then
                        str_input1="N"
                        echo -e "Exceeded max attempts. Default selection: \e[30;42m$str_input1\e[0m"
                        break
                    fi

                    echo -en "\e[33mInvalid input.\e[0m ";;
            esac
        done

        case $str_input1 in
            "Y")
                true;;
            "N")
                (exit 131);;
        esac

        SaveThisExitCode        # call functions
        echo
    }

    function ReadInputFromMultipleChoiceIgnoreCase
    {
        # behavior:
        # ask for multiple choice, up to eight choices
        # default selection is first choice
        # proper use always returns valid answer
        #

        if [[ -z $2 ]]; then
            (exit 254)
        else

            # parameters
            declare -ir int_maxCount=3
            declare -ar arr_count=$( seq $int_maxCount )

            for int_element in ${arr_count[@]}; do
                echo -en "$1 "
                read str_input1
                # str_input1=$( echo $str_input1 | tr '[:lower:]' '[:upper:]' )

                if [[ -z $2 && $str_input1 == $2 ]]; then
                    break
                elif [[ -z $3 && $str_input1 == $3 ]]; then
                    break
                elif [[ -z $4 && $str_input1 == $4 ]]; then
                    break
                elif [[ -z $5 && $str_input1 == $5 ]]; then
                    break
                elif [[ -z $6 && $str_input1 == $6 ]]; then
                    break
                elif [[ -z $7 && $str_input1 == $7 ]]; then
                    break
                elif [[ -z $8 && $str_input1 == $8 ]]; then
                    break
                elif [[ -z $9 && $str_input1 == $9 ]]; then
                    break
                else
                    if [[ $int_element -eq $int_maxCount ]]; then
                        str_input1=$2                       # default selection: first choice
                        echo -e "Exceeded max attempts. Default selection: \e[30;42m$str_input1\e[0m"
                        break
                    fi

                    echo -en "\e[33mInvalid input.\e[0m "
                    (exit 253)
                fi
            done
        fi

        SaveThisExitCode    # call functions
        ParseThisExitCode
    }

    function ReadInputFromMultipleChoiceUpperCase
    {
        # behavior:
        #
        # ask for multiple choice, up to eight choices
        # default selection is first choice
        # proper use always returns valid answer
        #

        if [[ -z $2 ]]; then
            (exit 254)
        else

            # parameters #
            declare -ir int_maxCount=3
            declare -ar arr_count=$( seq $int_maxCount )

            for int_element in ${arr_count[@]}; do
                echo -en "$1 "
                read str_input1
                str_input1=$( echo $str_input1 | tr '[:lower:]' '[:upper:]' )

                if [[ ! -z $2 && $str_input1 == $2 ]]; then
                    break
                elif [[ ! -z $3 && $str_input1 == $3 ]]; then
                    break
                elif [[ ! -z $4 && $str_input1 == $4 ]]; then
                    break
                elif [[ ! -z $5 && $str_input1 == $5 ]]; then
                    break
                elif [[ ! -z $6 && $str_input1 == $6 ]]; then
                    break
                elif [[ ! -z $7 && $str_input1 == $7 ]]; then
                    break
                elif [[ ! -z $8 && $str_input1 == $8 ]]; then
                    break
                elif [[ ! -z $9 && $str_input1 == $9 ]]; then
                    break
                else
                    if [[ $int_element -eq $int_maxCount ]]; then
                        str_input1=$2                       # default selection: first choice
                        echo -e "Exceeded max attempts. Default selection: \e[30;42m$str_input1\e[0m"
                        break
                    fi

                    echo -en "\e[33mInvalid input.\e[0m "
                    (exit 253)
                fi
            done
        fi

        SaveThisExitCode    # call functions
        ParseThisExitCode
    }

    function ReadInputFromRangeOfNums
    {
        # behavior:
        # ask for multiple choice, up to eight choices
        # default selection is first choice
        # proper use always returns valid answer
        #

        # parameters #
        declare -ir int_maxCount=3
        declare -ar arr_count=$( seq $int_maxCount )

        for int_element in ${arr_count[@]}; do
            echo -en "$1 "
            read str_input1

            if [[ $str_input1 -ge $2 && $str_input1 -le $3 ]]; then     # valid input
                break
            else
                if [[ $int_element -eq $int_maxCount ]]; then           # default input
                    str_input1=$2                                       # default selection: first choice
                    echo -e "Exceeded max attempts. Default selection: \e[30;42m$str_input1\e[0m"
                    break
                fi

                # if [[ ! ( "${str_input1}" -ge "$(( ${str_input1} ))" ) ]] 2> /dev/null; then  # check if string is a valid integer
                #     echo -en "\e[33mInvalid input.\e[0m "
                # fi

                echo -en "\e[33mInvalid input.\e[0m "
            fi
        done
    }

    function SaveThisExitCode
    {
        int_thisExitCode=$?     # NOTE: this statement must follow an exit code statement, and come before any new statement
    }

    function TestNetwork
    {
        # behavior:
        #   test internet connection and DNS servers
        #   return boolean, to be used by main
        #

        # test IP resolution #
        echo -en "Testing Internet connection... "
        ( ping -q -c 1 8.8.8.8 &> /dev/null || ping -q -c 1 1.1.1.1 &> /dev/null ) || false

        SaveThisExitCode            # call functions
        EchoPassOrFailThisExitCode

        echo -en "Testing connection to DNS... "
        ( ping -q -c 1 www.google.com &> /dev/null && ping -q -c 1 www.yandex.com &> /dev/null ) || false

        SaveThisExitCode            # call functions
        EchoPassOrFailThisExitCode

        if [[ $int_thisExitCode -ne 0 ]]; then
            echo -e "Failed to ping Internet/DNS servers. Check network settings or firewall, and try again."
        fi

        echo
    }

    function WriteArrayToFile
    {
        # TODO: not working!

        # behavior:
        # input variable #2 ( $2 ) is the name of the variable we wish to point to
        # this may help with calling/parsing arrays
        # when passing the var, write the name without " $ "
        #

        SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)    # NOTE: necessary for newline preservation in arrays and files
        IFS=$'\n'      # Change IFS to newline char
        var_input=$2

        echo -en "Writing to file... "

        if [[ -z $1 || -z $var_input ]]; then   # null exception
            (exit 254)
        fi

        if [[ ! -e $1 ]]; then          # file not found exception
            (exit 253)
        fi

        if [[ ! -r $1 ]]; then          # file not readable exception
            (exit 252)
        fi

        if [[ ! -w $1 ]]; then          # file not readable exception
            (exit 251)
        fi

        if [[ $int_thisExitCode -eq 0 ]]; then
            case ${!var_input[@]} in                                                    # check number of key-value pairs
                0)                                                                      # check if var is not an array
                    echo -e $var_input >> $1 || ( (exit 255) && SaveThisExitCode );;
                *)                                                                      # check if var is an array
                    for str_element in ${var_input[@]}; do
                        echo -e $str_element >> $1 || ( (exit 255) && SaveThisExitCode && break )
                    done;;
            esac
        fi

        SaveThisExitCode                # call functions
        EchoPassOrFailThisExitCode
        ParseThisExitCode
    }

    function WriteVarToFile
    {
        # behavior:
        # input variable #2 ( $2 ) is the name of the variable we wish to point to
        # this may help with calling/parsing arrays
        # when passing the var, write the name without " $ "
        #

        SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)    # NOTE: necessary for newline preservation in arrays and files
        IFS=$'\n'      # Change IFS to newline char

        echo -en "Writing to file... "

        if [[ -z $1 || -z $2 ]]; then   # null exception
            (exit 254)
        fi

        if [[ ! -e $1 ]]; then          # file not found exception
            (exit 253)
        fi

        if [[ ! -r $1 ]]; then          # file not readable exception
            (exit 252)
        fi

        if [[ ! -w $1 ]]; then          # file not readable exception
            (exit 251)
        fi

        if [[ $int_thisExitCode -eq 0 ]]; then
            echo -e $2 >> $1 || (exit 255)
        fi

        SaveThisExitCode                # call functions
        EchoPassOrFailThisExitCode
        ParseThisExitCode
    }

# executive functions #
    function CheckIfIOMMU_IsEnabled
    {
        echo -en "Checking if Virtualization is enabled/supported... "

        # call functions #
        if [[ ! -z $( compgen -G "/sys/kernel/iommu_groups/*/devices/*" ) ]]; then
            SaveThisExitCode
            EchoPassOrFailThisExitCode
        else
            SaveThisExitCode
            EchoPassOrFailThisExitCode
            ParseThisExitCode
            ExitWithThisExitCode
        fi
    }

    function CloneOrUpdateGitRepositories
    {
        echo -en "Cloning Git repositories... "

        # dir #
        if [[ -z $1 || -z $2 ]]; then       # null exception
            (exit 254)
        fi

        if [[ ! -d $1 ]]; then              # dir not found exception
            (exit 250)
        fi

        if [[ ! -w $1 ]]; then              # dir not writeable exception
            (exit 248)
        fi

        if [[ $int_thisExitCode -eq 0 ]]; then
            cd $1

            # git repos #
            if [[ -z $1 || -z $2 ]]; then   # null exception
                (exit 254)
            fi

            if [[ ! -d $1 ]]; then          # dir not found exception
                (exit 250)
            fi

            if [[ ! -w $1 ]]; then          # dir not writeable exception
                (exit 248)
            fi
        fi

        if [[ $int_thisExitCode -eq 0 ]]; then

            # if a given element is a string longer than one char, the var is an array #
            for str_element in ${2}; do
                if [[ ${#str_element} -gt 1 ]]; then
                    bool_varIsAnArray=true
                    break
                fi
            done

            declare -i int_count=1

            if [[ $bool_varIsAnArray == true ]]; then       # git clone from array
                for str_element in ${2}; do
                    if [[ -e $( basename $1 ) ]]; then      # cd into repo, update, and back out
                        cd $( basename $1 )
                        git pull $str_element &> /dev/null || ( ((int_count++)) && (exit 131) )
                        cd ..

                    else                                    # clone new repo
                        git clone $str_element &> /dev/null || ( ((int_count++)) && (exit 131) )
                    fi

                done

                if [[ ${#2[@]} -eq $int_count ]]; then      # if all repos failed to clone, change exit code
                    (exit 255)
                fi

            else                                            # git clone a repo
                echo $2 >> $1 || (exit 255)
            fi
        fi

        SaveThisExitCode                                    # call functions
        EchoPassOrFailThisExitCode
        ParseThisExitCode

        case $int_thisExitCode in
            131)
                echo -e "One or more Git repositories could not be cloned.";;
        esac

        echo
    }

    function ParseCPU
    {
        # TODO: fix var names for ENVIRONMENT VARIABLES

        # parameters #
        declare -r arr_coresByThread=($(cat /proc/cpuinfo | grep 'core id' | cut -d ':' -f2 | cut -d ' ' -f2))
        declare -r int_totalCores=$( cat /proc/cpuinfo | grep 'cpu cores' | uniq | grep -o '[0-9]\+' )
        declare -r int_totalThreads=$( cat /proc/cpuinfo | grep 'siblings' | uniq | grep -o '[0-9]\+' )
        declare -r int_SMT_multiplier=$(( $int_totalThreads / $int_totalCores ))
        # declare -a arr_totalCores=()
        declare -a arr_hostCores=()
        declare -a arr_hostThreads=()
        declare -a arr_hostThreadSets=()
        # declare -a arr_virtCores=()
        declare -a arr_virtThreadSets=()
        declare -i int_hostCores=1          # default value

        # reserve remainder cores to host #
        if [[ $int_totalCores -ge 4 ]]; then                                # >= 4-core CPU, leave max 2
            declare -r int_hostCores=2
        elif [[ $int_totalCores -le 3 && $int_totalCores -ge 2 ]]; then     # 2 or 3-core CPU, leave max 1
            declare -r int_hostCores=1
        else                                                                # 1-core CPU, do not reserve cores to virt
            declare -r int_hostCores=$int_totalCores
            (exit 255)
        fi

        # group threads for host #
        for (( int_i=0 ; int_i<$int_SMT_multiplier ; int_i++ )); do
            # declare -i int_firstHostCore=$int_hostCores
            declare -i int_firstHostThread=$((int_hostCores+int_totalCores*int_i))
            declare -i int_lastHostCore=$((int_totalCores-1))
            declare -i int_lastHostThread=$((int_lastHostCore+int_totalCores*int_i))

            if [[ $int_firstHostThread -eq $int_lastHostThread ]]; then
                str_virtThreads+="${int_firstHostThread},"
            else
                str_virtThreads+="${int_firstHostThread}-${int_lastHostThread},"
            fi
        done

        if [[ ${str_virtThreads: -1} == "," ]]; then                # update parameters
            str_virtThreads=${str_virtThreads::-1}
        fi

        for (( int_i=0 ; int_i<$int_totalCores ; int_i++ )); do     # group threads by core id
            str_line1=""
            declare -i int_thisCore=${arr_coresByThread[int_i]}

            for (( int_j=0 ; int_j<$int_SMT_multiplier ; int_j++ )); do
                int_thisThread=$((int_thisCore+int_totalCores*int_j))
                str_line1+="$int_thisThread,"

                if [[ $int_thisCore -lt $int_hostCores ]]; then
                    arr_hostThreads+=("$int_thisThread")
                fi
            done

            # str_output1="Setup 'Static' CPU isolation? [Y/n]: "       # update

            arr_totalThreads+=("$str_line1")

            if [[ $int_thisCore -lt $int_hostCores ]]; then             # save output for cpu isolation (host)
                arr_hostCores+=("$int_thisCore")
                arr_hostThreadSets+=("$str_line1")
            else                                                        # save output for cpuset/cpumask (qemu cpu pinning)
                # arr_virtCores+=("$int_thisCore")
                arr_virtThreadSets+=("$str_line1")
            fi
        done

        # update parameters #
        declare -r arr_totalThreads
        declare -r arr_hostCores
        declare -r arr_hostThreadSets
        declare -r arr_virtThreadSets

        # save output to string for cpuset and cpumask #
        #
        # example:
        #
        # host 0-1,8-9
        #
        # virt 2-7,10-15
        #
        #
        # cores     bit masks       mask
        # 0-7       0b11111111      FF      # total cores
        # 0,4       0b00010001      11      # host cores
        #
        # 0-11      0b111111111111  FFF     # total cores
        # 0-1,6-7   0b000011000011  C3      # host cores
        #
        # find cpu mask #
        declare -r int_totalThreads_mask=$(( ( 2 ** $int_totalThreads ) - 1 ))
        declare -i int_hostThreads_mask=0

        for int_thisThread in ${arr_hostThreads[@]}; do
            int_hostThreads_mask+=$(( 2 ** $int_thisThread ))
        done

        # save output #
        if [[ $int_thisExitCode -eq 0 ]]; then
            declare -r int_hostThreads_mask
            declare -r hex_totalThreads_mask=$(printf '%x\n' $int_totalThreads_mask)  # int to hex
            declare -r hex_hostThreads_mask=$(printf '%x\n' $int_hostThreads_mask)    # int to hex
            declare -r str_GRUB_CMDLINE_CPU_Isolation="isolcpus=$str_virtThreads nohz_full=$str_virtThreads rcu_nocbs=$str_virtThreads"
        fi
    }

    function ParseIOMMUandPCI
    {
        echo -en "Parsing IOMMU groups... "

        # parameters #
        declare -ir int_lastIOMMU="$( basename $( ls -1v /sys/kernel/iommu_groups/ | sort -hr | head -n1 ) )"
        declare -a arr_DeviceIOMMU=()
        declare -a arr_DevicePCI_ID=()
        declare -a arr_DeviceDriver=()
        declare -a arr_DeviceName=()
        declare -a arr_DeviceType=()
        declare -a arr_DeviceVendor=()
        declare -a arr_IOMMU_hasUSB=()
        declare -a arr_IOMMU_hasVGA=()
        declare -a arr_IOMMU_hasInternalPCI=()
        declare -a arr_IOMMU_hasExternalPCI=()
        declare -l bool_missingDriver=false
        declare -l bool_foundVFIO=false
        declare -l str_IGPU_fullName=""
        declare -lr str_logFile="logs/iommu.log"

        for str_element1 in $( find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V ); do           # parse list of IOMMU groups
            str_thisIOMMU=$( basename $str_element1 )

            for str_element2 in $( ls ${str_element1}/devices ); do         # parse given IOMMU group for PCI IDs

                # save output of given device #
                declare -l str_thisDevicePCI_ID="${str_element2##"0000:"}"
                declare -l str_thisDeviceBusID=$( echo $str_thisDevicePCI_ID | cut -d ':' -f1 )

                if [[ ${str_thisDeviceBusID::1} -eq 0 ]]; then
                    declare -li int_thisDeviceBusID=$(( ${str_thisDeviceBusID:1:2} ))
                else
                    declare -li int_thisDeviceBusID=$(( $str_thisDeviceBusID ))
                fi

                declare -l str_thisDeviceName="$( lspci -ms ${str_element2} | cut -d '"' -f6 )"
                declare -l str_thisDeviceType="$( lspci -ms ${str_element2} | cut -d '"' -f2 )"
                declare -l str_thisDeviceVendor="$( lspci -ms ${str_element2} | cut -d '"' -f4 )"
                declare -l str_thisDeviceDriver="$( lspci -ks ${str_element2} | grep driver | cut -d ':' -f2 )"

                if [[ -z $str_thisDeviceDriver ]]; then                     # check for valid driver
                    str_thisDeviceDriver="N/A"
                    (exit 3)
                    SaveThisExitCode
                else
                    if [[ $str_thisDeviceDriver == *"vfio-pci"* ]]; then
                        str_thisDeviceDriver="N/A"
                        (exit 253)
                        SaveThisExitCode
                        break
                    else
                        str_thisDeviceDriver="${str_thisDeviceDriver##" "}"
                    fi
                fi

                # append to VFIO PCI and find IGPU #
                if [[ ${#arr_IOMMU_hasVGA[@]} -eq 0 || ( ${#arr_IOMMU_hasVGA[@]} -gt 0 && $str_thisIOMMU != ${arr_IOMMU_hasVGA[-1]} ) ]]; then
                    case $( echo ${str_thisDeviceType} | tr '[:lower:]' '[:upper:]' ) in                # check for VGA type
                        *"3D"*|*"DISPLAY"*|*"GRAPHICS"*|*"VGA"*)
                            arr_IOMMU_hasVGA+=( "$str_thisIOMMU" );                                     # append to list only once

                            if [[ $int_thisDeviceBusID -eq 0 && ${#str_IGPU_fullName} -eq 0 ]]; then    # append IGPU name
                            declare -r str_IGPU_fullName="${str_thisDeviceVendor} ${str_thisDeviceName}"
                        fi

                        if [[ $int_thisDeviceBusID -gt 0 && ${#str_IGPU_fullName} -eq 0 ]]; then
                            declare -r str_IGPU_fullName="N/A"
                        fi;;
                    esac
                fi

                # append to PCI STUB #
                if [[ ${#arr_IOMMU_hasUSB[@]} -eq 0 || ( ${#arr_IOMMU_hasUSB[@]} -gt 0 && $str_thisIOMMU != ${arr_IOMMU_hasUSB[-1]} ) ]]; then
                    case $( echo ${str_thisDeviceType} | tr '[:lower:]' '[:upper:]' ) in        # check for USB type
                        *"USB"*)
                            arr_IOMMU_hasUSB+=( "$str_thisIOMMU");;                             # append to list only once
                    esac
                fi

                # append to VFIO PCI #
                if [[ $int_thisDeviceBusID -eq 0 ]]; then                                       # check for internal PCI
                    if [[ ${#arr_IOMMU_hasInternalPCI[@]} -eq 0 || ( ${#arr_IOMMU_hasInternalPCI[@]} -gt 0 && $str_thisIOMMU != ${arr_IOMMU_hasInternalPCI[-1]} ) ]]; then
                        arr_IOMMU_hasInternalPCI+=( "$str_thisIOMMU" )                          # append to list only once
                    fi
                else                                                                            # check for external PCI
                    if [[ ${#arr_IOMMU_hasExternalPCI[@]} -eq 0 || ( ${#arr_IOMMU_hasExternalPCI[@]} -gt 0 && $str_thisIOMMU != ${arr_IOMMU_hasExternalPCI[-1]} ) ]]; then
                        arr_IOMMU_hasExternalPCI+=( "$str_thisIOMMU" )                          # append to list only once
                    fi
                fi

                # parameters #
                arr_DeviceIOMMU+=( "${str_thisIOMMU}" )
                arr_DevicePCI_ID+=( "${str_thisDevicePCI_ID}" )
                arr_DeviceDriver+=( "${str_thisDeviceDriver}" )
                arr_DeviceName+=( "${str_thisDeviceName}" )
                arr_DeviceType+=( "${str_thisDeviceType}" )
                arr_DeviceVendor+=( "${str_thisDeviceVendor}" )
            done
        done

        # parameters #
        declare -r arr_DeviceIOMMU
        declare -r arr_DevicePCI_ID
        declare -r arr_DeviceDriver
        declare -r arr_DeviceName
        declare -r arr_DeviceType
        declare -r arr_DeviceVendor
        declare -r arr_IOMMU_hasUSB
        declare -r arr_IOMMU_hasVGA
        declare -r arr_IOMMU_hasInternalPCI
        declare -r arr_IOMMU_hasExternalPCI

        EchoPassOrFailThisExitCode  # call functions

        case $int_thisExitCode in
            3)
                echo -e "\e[33mWarning:\e[0m One or more external PCI device(s) missing drivers.";;
            # 254)
            #     echo -e "\e[33mException: \e[0mNo devices found.";;
            253)
                echo -e "\e[33mException: \e[0mExisting VFIO setup found.";;
        esac

        case $int_thisExitCode in
            # NOTE: do not write to logfile if VFIO drivers are found #
            0)
                CheckIfFileOrDirExists $str_logFile && DeleteFile $str_logFile || CreateFile $str_logFile
                WriteVarToFile $str_logFile '# Generated by 'portellam/deploy-VFIO-setup'\n#\n# WARNING: Any modifications to this file will be modified by 'deploy-VFIO-setup'\n#'
                WriteVarToFile $str_logFile "{str_IGPU_fullName}\t'${str_IGPU_fullName}'" &> /dev/null

                for int_key in ${!arr_DeviceIOMMU[@]}; do
                    declare -l str_element="{arr_DeviceIOMMU[$int_key]}\t'${arr_DeviceIOMMU[$int_key]}'"
                    WriteVarToFile $str_logFile $str_element &> /dev/null
                done

                for int_key in ${!arr_DevicePCI_ID[@]}; do
                    declare -l str_element="{arr_DevicePCI_ID[$int_key]}\t'${arr_DevicePCI_ID[$int_key]}'"
                    WriteVarToFile $str_logFile $str_element &> /dev/null
                done

                for int_key in ${!arr_DeviceDriver[@]}; do
                    declare -l str_element="{arr_DeviceDriver[$int_key]}\t'${arr_DeviceDriver[$int_key]}'"
                    WriteVarToFile $str_logFile $str_element &> /dev/null
                done

                for int_key in ${!arr_DeviceType[@]}; do
                    declare -l str_element="{arr_DeviceType[$int_key]}\t'${arr_DeviceType[$int_key]}'"
                    WriteVarToFile $str_logFile $str_element &> /dev/null
                done

                for int_key in ${!arr_IOMMU_hasUSB[@]}; do
                    declare -l str_element="{arr_IOMMU_hasUSB[$int_key]}\t'${arr_IOMMU_hasUSB[$int_key]}'"
                    WriteVarToFile $str_logFile $str_element &> /dev/null
                done

                for int_key in ${!arr_IOMMU_hasVGA[@]}; do
                    declare -l str_element="{arr_IOMMU_hasVGA[$int_key]}\t'${arr_IOMMU_hasVGA[$int_key]}'"
                    WriteVarToFile $str_logFile $str_element &> /dev/null
                done

                for int_key in ${!arr_IOMMU_hasInternalPCI[@]}; do
                    declare -l str_element="{arr_IOMMU_hasInternalPCI[$int_key]}\t'${arr_IOMMU_hasInternalPCI[$int_key]}'"
                    WriteVarToFile $str_logFile $str_element &> /dev/null
                done

                for int_key in ${!arr_IOMMU_hasExternalPCI[@]}; do
                    declare -l str_element="{arr_IOMMU_hasExternalPCI[$int_key]}\t'${arr_IOMMU_hasExternalPCI[$int_key]}'"
                    WriteVarToFile $str_logFile $str_element &> /dev/null
                done

                # ChangeOwnershipOfFileOrDir $str_logFile
                # chown -f 1000 $str_logFile
                ;;
        esac

        echo
    }

    function ReadIOMMUFromLogFile       # NOTE: added file check and test case boolean conditional
    {
        echo -en "Parsing IOMMU groups from logfile... "

        # parameters #
        declare -ir int_lastIOMMU="$( basename $( ls -1v /sys/kernel/iommu_groups/ | sort -hr | head -n1 ) )"
        declare -a arr_DeviceIOMMU=()
        declare -a arr_DevicePCI_ID=()
        declare -a arr_DeviceDriver=()
        declare -a arr_DeviceName=()
        declare -a arr_DeviceType=()
        declare -a arr_DeviceVendor=()
        declare -a arr_IOMMU_hasUSB=()
        declare -a arr_IOMMU_hasVGA=()
        declare -a arr_IOMMU_hasInternalPCI=()
        declare -a arr_IOMMU_hasExternalPCI=()

        if [[ $bool_executeTestCases == true ]]; then
            declare -lr str_file1="logs/iommu.log"

        else
            declare -lr str_file1="logs/iommu.log"
        fi

        CheckIfFileOrDirExists $str_file1 &> /dev/null && (
            while read str_line; do
                declare -l str_element=$( echo $str_line | cut -d "'" -f2 )

                case $str_line in
                    "arr_DeviceIOMMU"*)
                        arr_DeviceIOMMU+=( "${str_element}" );;
                    "arr_DevicePCI_ID"*)
                        arr_DevicePCI_ID+=( "${str_element}" );;
                    "arr_DeviceDriver"*)
                        arr_DeviceDriver+=( "${str_element}" );;
                    "arr_DeviceName"*)
                        arr_DeviceName+=( "${str_element}" );;
                    "arr_DeviceType"*)
                        arr_DeviceType+=( "${str_element}" );;
                    "arr_DeviceVendor"*)
                        arr_DeviceVendor+=( "${str_element}" );;
                    "arr_IOMMU_hasUSB"*)
                        arr_IOMMU_hasUSB+=( "${str_element}" );;
                    "arr_IOMMU_hasVGA"*)
                        arr_IOMMU_hasVGA+=( "${str_element}" );;
                    "arr_IOMMU_hasInternalPCI"*)
                        arr_IOMMU_hasInternalPCI+=( "${str_element}" );;
                    "arr_IOMMU_hasExternalPCI"*)
                        arr_IOMMU_hasExternalPCI+=( "${str_element}" );;
                esac
            done < $str_file1

            # parameters #
            declare -r arr_DeviceIOMMU
            declare -r arr_DevicePCI_ID
            declare -r arr_DeviceDriver
            declare -r arr_DeviceName
            declare -r arr_DeviceType
            declare -r arr_DeviceVendor
            declare -r arr_IOMMU_hasUSB
            declare -r arr_IOMMU_hasVGA
            declare -r arr_IOMMU_hasInternalPCI
            declare -r arr_IOMMU_hasExternalPCI
        ) || SaveThisExitCode

        EchoPassOrFailThisExitCode  # call functions
    }

    function SelectAnIOMMUGroup
    {
        echo -e "Reviewing IOMMU groups..."

        declare -l bool_thisIOMMU_hasVGA=false

        # parameters #
        # lists of Key value pairs (IOMMU group number to device indexes)
        declare -la arr_IOMMU_forHost=()
        declare -la arr_IOMMU_forSTUB=()
        declare -la arr_IOMMU_forVFIO=()
        declare -la arr_IOMMU_withVGA_forHost=()
        declare -la arr_IOMMU_withVGA_forVFIO=()

        # parse only external PCI #
        for int_key in ${!arr_IOMMU_hasExternalPCI[@]}; do

            # reset parameters for this pass #
            declare -la arr_thisIOMMU_devices=()
            declare -la arr_thisIOMMU_devicesWithUSB_forSTUB=()
            declare -la arr_thisIOMMU_devicesWithVGA_forVFIO=()
            declare -li int_IOMMU=${arr_IOMMU_hasExternalPCI[$int_key]}

            # check if given IOMMU group contains USB #
            for int_thisKey in ${!arr_IOMMU_hasUSB[@]}; do
                declare -li int_thisIOMMU=${arr_DeviceIOMMU[$int_thisKey]}

                if [[ $int_thisIOMMU -eq $int_IOMMU ]]; then
                    bool_thisIOMMU_hasUSB=true
                    arr_thisIOMMU_devicesWithUSB_forSTUB+=( "${int_thisKey}" )
                fi
            done

            # check if given IOMMU group contains VGA #
            for int_thisKey in ${!arr_IOMMU_hasVGA[@]}; do
                declare -li int_thisIOMMU=${arr_DeviceIOMMU[$int_thisKey]}

                if [[ $int_thisIOMMU -eq $int_IOMMU ]]; then
                    bool_thisIOMMU_hasVGA=true
                    arr_thisIOMMU_devicesWithVGA_forVFIO+=( "${int_thisKey}" )
                fi
            done

            # parse all devices in given IOMMU group #
            for int_thisKey in ${!arr_DeviceIOMMU[@]}; do
                declare -li int_thisIOMMU=${arr_DeviceIOMMU[$int_thisKey]}

                if [[ $int_thisIOMMU -eq $int_IOMMU ]]; then
                    arr_thisIOMMU_devices+=( "${int_thisKey}" )
                fi
            done


            echo -e "IOMMU group #:\t${int_IOMMU}\n"

            # output all devices in given IOMMU group #
            for int_thisKey in ${!arr_thisIOMMU_devices[@]}; do
                str_thisDevicePCI_ID="${arr_DevicePCI_ID[$int_thisKey]}"
                str_thisDeviceDriver="${arr_DeviceDriver[$int_thisKey]}"
                str_thisDeviceName="${arr_DeviceName[$int_thisKey]}"
                str_thisDeviceType="${arr_DeviceType[$int_thisKey]}"
                str_thisDeviceVendor="${arr_DeviceVendor[$int_thisKey]}"

                echo -e "Device #:\t\t${int_thisKey}"
                echo -e "\tPCI ID:\t\t${str_thisDevicePCI_ID}"
                echo -e "\tDevice driver:\t${str_thisDeviceDriver}"
                echo -e "\tDevice name:\t${str_thisDeviceName}"
                echo -e "\tDevice type:\t${str_thisDeviceType}"
                echo -e "\tVendor name:\t${str_thisDeviceVendor}"
                echo
            done

            ReadInput "Select IOMMU group '${int_IOMMU}'?"

            case $str_input in
                "Y")

                    # append to list a valid array or empty value #
                    if [[ $bool_thisIOMMU_hasUSB == true ]]; then
                        arr_IOMMU_forSTUB+=( "${arr_thisIOMMU_devicesWithUSB_forSTUB[@]}" )
                    else
                        arr_IOMMU_forSTUB+=("")
                    fi

                    if [[ $bool_thisIOMMU_hasVGA == true ]]; then
                        arr_IOMMU_forVFIO+=("")
                        arr_IOMMU_withVGA_forVFIO+=( "${arr_thisIOMMU_devicesWithVGA_forVFIO[@]}" )
                    else
                        arr_IOMMU_forVFIO+=( "${arr_thisIOMMU_devices[@]}" )
                        arr_IOMMU_withVGA_forVFIO+=("")
                    fi;;

                "N")

                    # append to list a valid array or empty value #
                    if [[ $bool_thisIOMMU_hasVGA == true ]]; then
                        arr_IOMMU_forHost+=("")
                        arr_IOMMU_withVGA_forHost+=( "${arr_thisIOMMU_devicesWithVGA_forVFIO[@]}" )
                    else
                        arr_IOMMU_forHost+=( "${arr_thisIOMMU_devices[@]}" )
                        arr_IOMMU_withVGA_forHost+=("")
                    fi;;
            esac

            # reset vars for next pass #
            bool_thisIOMMU_hasUSB=false
            bool_thisIOMMU_hasVGA=false
        done

        # check if all IOMMU groups remain assigned to host #
        # yes, fail setup
        # if one isn't, complete setup
        (exit 255)
        SaveThisExitCode

        for str_element in ${arr_IOMMU_forHost[@]}; do
            if [[ $str_element == "" || -z $str_element ]]; then
                (exit 0)
                SaveThisExitCode
            fi
        done

        ParseThisExitCode "Reviewing IOMMU groups..."
    }

    function SetupAutoXorg
    {
        declare -r str_pwd=$( pwd )
        echo -e "Installing Auto-Xorg... "
        cd $( find -wholename Auto-Xorg | uniq | head -n1 ) && bash ./installer.bash && cd $str_pwd
        SaveThisExitCode            # call functions
        EchoPassOrFailThisExitCode
        ParseThisExitCode
        echo
    }

    function SetupEvdev
    {
        # behavior:
        # ask user to prep setup of Evdev
        # add active desktop users to groups for Libvirt, QEMU, Input devices, etc.
        # write to logfile
        #

        # parameters #
        declare -r str_thisFile1="/logs/qemu-evdev.log"
        declare -r str_thisFile2="/etc/apparmor.d/abstractions/libvirt-qemu"

        echo -e "Evdev (Event Devices) is a method of creating a virtual KVM (Keyboard-Video-Mouse) switch between host and VM's.\n\tHOW-TO: Press 'L-CTRL' and 'R-CTRL' simultaneously.\n"
        ReadInput "Setup Evdev?"

        if [[ $int_thisExitCode -eq 0 ]]; then
            # declare -r str_firstUser=$( id -u 1000 -n ) && echo -e "Found the first desktop user of the system: $str_firstUser"

            # add users to groups #
            declare -a arr_User=($( getent passwd {1000..60000} | cut -d ":" -f 1 ))

            for str_element in $arr_User; do
                adduser $str_element input &> /dev/null       # quiet output
                adduser $str_element libvirt &> /dev/null     # quiet output
            done

            # output to file #
            CheckIfFileOrDirExists $str_thisFile1 &> /dev/null && DeleteFile $str_thisFile1 &> /dev/null
            ( CreateFile $str_thisFile1 ) || false

            if [[ $int_thisExitCode -eq 0 ]]; then

                # list of input devices #
                declare -ar arr_InputDeviceID=($( ls /dev/input/by-id ))
                declare -ar arr_InputEventDeviceID=($( ls -l /dev/input/by-id | cut -d '/' -f2 | grep -v 'total 0' ))
                declare -a arr_output_evdevQEMU=()

                for str_element in ${arr_InputDeviceID[@]}; do                          # append output
                    arr_output_evdevQEMU+=("    \"/dev/input/by-id/$str_element\",")
                done

                for str_element in ${arr_InputEventDeviceID[@]}; do                     # append output
                    arr_output_evdevQEMU+=("    \"/dev/input/by-id/$str_element\",")
                done

                declare -r arr_output_evdevQEMU

                # append output #
                declare -ar arr_output_evdevApparmor=(
                    "  "
                    "  # Generated by 'portellam/deploy-VFIO-setup'"
                    "  #"
                    "  # WARNING: Any modifications to this file will be modified by 'deploy-VFIO-setup'"
                    "  #"
                    "  # Run 'systemctl restart apparmor.service' to update."
                    "  "
                    "  # Evdev #"
                    "  /dev/input/* rw,"
                    "  /dev/input/by-id/* rw,"
                )

                # debug #
                # echo -e '${#arr_InputDeviceID[@]}='"'${#arr_InputDeviceID[@]}'"
                # echo -e '${#arr_InputEventDeviceID[@]}='"'${#arr_InputEventDeviceID[@]}'"
                # echo -e '${#arr_output_evdevQEMU[@]}='"'${#arr_output_evdevQEMU[@]}'"

                CheckIfFileOrDirExists $str_thisFile1

                if [[ $int_thisExitCode -eq 0 ]]; then                                                      # append file
                    for str_element in ${arr_output_evdevQEMU[@]}; do
                        WriteVarToFile $str_thisFile1 $str_element &> /dev/null || ( false && break )       # should this loop fail at any given time, exit
                    done
                fi

                # NOTE: will require restart of apparmor service or system
                if [[ $int_thisExitCode -eq 0 ]]; then
                    CheckIfFileOrDirExists $str_thisFile2 &> /dev/null

                    if [[ $int_thisExitCode -eq 0 ]]; then                                                  # append file
                        for str_element in ${arr_output_evdevApparmor[@]}; do
                            WriteVarToFile $str_thisFile2 $str_element &> /dev/null || ( false && break )   # should this loop fail at any given time, exit
                        done

                        echo $arr_output_evdevQEMU &> /dev/null || false
                    fi
                fi
            fi
        fi

        # call functions
        SaveThisExitCode
        EchoPassOrFailThisExitCode "Setup Evdev..."
        ParseThisExitCode
    }

    function SetupHugepages
    {
        # behavior:
        # find vars necessary for Hugepages setup
        # function can never *fail*, just execute or exit
        # write to logfile
        #

        # parameters #
        declare -r str_thisFile1="/logs/qemu-hugepages.log"
        declare -ir int_HostMemMaxK=$( cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1 )      # sum of system RAM in KiB
        str_GRUB_CMDLINE_Hugepages="default_hugepagesz=1G hugepagesz=1G hugepages=0"                                # default output

        echo -e "Hugepages is a feature which statically allocates system memory to pagefiles.\n\tVirtual machines can use Hugepages to a peformance benefit.\n\tThe greater the Hugepage size, the less fragmentation of memory, and the less latency/overhead of system memory-access.\n"
        ReadInput "Setup Hugepages?"

        if [[ $int_thisExitCode -eq 0 ]]; then
            declare -ar arr_User=($( getent passwd {1000..60000} | cut -d ":" -f 1 ))   # add users to groups

            for str_element in $arr_User; do
                adduser $str_element input &> /dev/null       # quiet output
                adduser $str_element libvirt &> /dev/null     # quiet output
            done

            # prompt #
            ReadInputFromMultipleChoiceUpperCase "Enter Hugepage size and byte-size \e[30;43m[1G/2M]:\e[0m" "1G" "2M"
            str_HugePageSize=$str_input1

            declare -ir int_HostMemMinK=4194304         # min host RAM in KiB

            case $str_HugePageSize in                   # Hugepage Size
                "2M")
                    declare -ir int_HugePageK=2048      # Hugepage size
                    declare -ir int_HugePageMin=2;;     # min HugePages
                "1G")
                    declare -ir int_HugePageK=1048576   # Hugepage size
                    declare -ir int_HugePageMin=1;;     # min HugePages
            esac

            declare -ir int_HugePageMemMax=$(( $int_HostMemMaxK - $int_HostMemMinK ))
            declare -ir int_HugePageMax=$(( $int_HugePageMemMax / $int_HugePageK ))       # max HugePages

            # prompt #
            ReadInputFromRangeOfNums "Enter number of HugePages (n * $str_HugePageSize) \e[30;43m[$int_HugePageMin <= n <= $int_HugePageMax pages]:\e[0m" $int_HugePageMin $int_HugePageMax
            declare -ir int_HugePageNum=$str_input1

            # output #
            declare -r str_output_hugepagesGRUB="default_hugepagesz=${str_HugePageSize} hugepagesz=${str_HugePageSize} hugepages=${int_HugePageNum}"
            declare -r str_output_hugepagesQEMU="hugetlbfs_mount = \"/dev/hugepages\""

            # write to file #
            CheckIfFileOrDirExists $str_thisFile1 &> /dev/null && DeleteFile $str_thisFile1 &> /dev/null
            CreateFile $str_thisFile1 &> /dev/null

            if [[ $int_thisExitCode -eq 0 ]]; then
                WriteVarToFile $str_thisFile1 $str_output_hugepagesQEMU &> /dev/null && echo
            fi
        fi

        # SaveThisExitCode                                  # call functions
        EchoPassOrFailThisExitCode "Setup Hugepages..."
        ParseThisExitCode
    }

    function SetupStaticCPU_isolation
    {
        echo -e "CPU isolation (Static or Dynamic) is a feature which allocates system CPU threads to the host and Virtual machines (VMs), separately.\n\tVirtual machines can use CPU isolation or 'pinning' to a peformance benefit\n\t'Static' is more 'permanent' CPU isolation: installation will append to GRUB after VFIO setup.\n\tAlternatively, 'Dynamic' CPU isolation is flexible and on-demand: post-installation will execute as a libvirt hook script (per VM)."
        ReadInput "Setup 'Static' CPU isolation?" && echo -en "Executing CPU isolation setup... " && ParseCPU
        EchoPassOrFailThisExitCode              # call functions
        echo
    }

    function SetupZRAM_Swap
    {
        # parameters #
        declare -lr str_pwd=$( pwd )

        # prompt #
        echo -e "Installing zram-swap... "

        # TODO: change this!
        if [[ $( systemctl status asshole &> /dev/null ) != *"could not be found"* ]]; then
            systemctl stop zramswap &> /dev/null
            systemctl disable zramswap &> /dev/null
        fi

        ( cd $( find -wholename zram-swap | uniq | head -n1 ) && sh ./install.sh && cd $str_pwd ) || (exit 255)

        # setup ZRAM #
        if [[ $int_thisExitCode -eq 0 ]]; then

            # disable all existing zram swap devices
            if [[ $( swapon -v | grep /dev/zram* ) == "/dev/zram"* ]]; then
                swapoff /dev/zram* &> /dev/null
            fi

            declare -lir int_hostMemMaxG=$(( int_HostMemMaxK / 1048576 ))
            declare -lir int_sysMemMaxG=$(( int_hostMemMaxG + 1 ))

            echo -e "Total system memory: <= ${int_sysMemMaxG}G.\nIf 'Z == ${int_sysMemMaxG}G - (V + X)', where ('Z' == ZRAM, 'V' == VM(s), and 'X' == remainder for Host machine).\n\tCalculate 'Z'."

            # free memory #
            if [[ ! -z $str_HugePageSize && ! -z $int_HugePageNum ]]; then
                case $str_HugePageSize in
                    "1G")
                        declare -lir int_hugePageSizeK=1048576;;

                    "2M")
                        declare -lir int_hugePageSizeK=2048;;
                esac

                declare -lir int_hugepagesMemG=$int_HugePageNum*$int_hugePageSizeK/1048576
                declare -lir int_hostMemFreeG=$int_sysMemMaxG-$int_hugepagesMemG
                echo -e "Free system memory after hugepages (${int_hugepagesMemG}G): <= ${int_hostMemFreeG}G."
            else
                declare -lir int_hostMemFreeG=$int_sysMemMaxG
                echo -e "Free system memory: <= ${int_hostMemFreeG}G."
            fi

            str_output1="Enter zram-swap size in G (0G < n < ${int_hostMemFreeG}G): "

            ReadInputFromRangeOfNums "Enter zram-swap size in G (0G < n < ${int_hostMemFreeG}G): " 0 $int_hostMemFreeG
            declare -lir int_ZRAM_sizeG=$str_input1

            # while true; do

            #     # attempt #
            #     if [[ $int_count -ge 2 ]]; then
            #         ((int_ZRAM_sizeG=int_hostMemFreeG/2))      # default selection
            #         echo -e "Exceeded max attempts. Default selection: ${int_ZRAM_sizeG}G"
            #         break

            #     else
            #         if [[ -z $int_ZRAM_sizeG || $int_ZRAM_sizeG -lt 0 || $int_ZRAM_sizeG -ge $int_hostMemFreeG ]]; then
            #             echo -en "\e[33mInvalid input.\e[0m\n$str_output1"
            #             read -r int_ZRAM_sizeG

            #         else
            #             break
            #         fi
            #     fi

            #     ((int_count++))
            # done

            declare -lir int_denominator=$(( $int_sysMemMaxG / $int_ZRAM_sizeG ))
            str_output1="\n_zram_fraction=\"1/$int_denominator\""
            # str_outFile1="/etc/default/zramswap"
            str_outFile1="/etc/default/zram-swap"

            CreateBackupFromFile $str_outFile1
            WriteVarToFile $str_outFile1 $str_output1 || (exit 255)
        fi

        SaveThisExitCode            # call functions
        EchoPassOrFailThisExitCode "Zram-swap setup "
        ParseThisExitCode
        echo
    }

# main functions #
    function DeleteSetup
    {
        ReadInput "Are you sure you want to uninstall the existing VFIO setup?"

        if [[ $int_thisExitCode -ne 0 ]]; then
            ExitWithThisExitCode
        fi

        echo -en "Executing Uninstaller... "
        ParseIOMMUandPCI &> /dev/null

        # VFIO setup detected #
        if [[ $int_thisExitCode -eq 253 ]]; then
            (exit 0)
            SaveThisExitCode

            declare -ar arr_files=(
                "/etc/grub.d/proxifiedScripts/custom"
                ,"/etc/initramfs-tools/modules"
                ,"/etc/modules"
                ,"/etc/modprobe.d/pci-blacklists.conf"
                ,"/etc/modprobe.d/vfio.conf"
            )

            for str_element in ${arr_files[@]}; do
                CheckIfFileOrDirExists $str_element &> /dev/null && (
                    # str_oldFile=$( ls -l $str_element".old"* | sort -r | head -n1 )           # find most recent backup
                    DeleteFile $str_element &> /dev/null
                ) || (
                    (exit 255) && SaveThisExitCode && break )
            done && (
                update-initramfs -u -k all &> /dev/null
            )

            str_file1="/etc/default/grub"

            CheckIfFileOrDirExists $str_file1 &> /dev/null && (
                CreateBackupFromFile $str_file1 &> /dev/null
                str_oldFile=$str_file1".old"

                CheckIfFileOrDirExists $str_oldFile* &> /dev/null && (
                    str_oldFile=$( ls -l $str_file1".old"* | sort -r | head -n1  )          # find most recent backup
                )

                # declare -l str_thisBasename=$( basename $str_file1)                            # old
                # declare -li int_thisBasename=$(( 0 - ${#str_thisBasename} ))
                # declare -l str_thisDir=${#str_file1::int_thisBasename}
                # cd $str_thisDir
                # str_oldFile=$( find . -name $str_thisBasename | sort -r | head -n1 )

                CheckIfFileOrDirExists $str_oldFile &> /dev/null && (
                    while read str_line; do                                                 # read from backup, write overwrite current file
                        case $str_line in                                                   # match given lines, overwrite with defaults
                            'GRUB_CMDLINE_LINUX'*'="'*'"'*)
                                str_line=$( echo $str_line | cut -d '=' -f1 )'quiet splash'
                                ;;
                        esac

                        WriteVarToFile $str_file1 $str_line &> /dev/null || ( SaveThisExitCode && break )
                    done < $str_oldFile && (
                        update-grub &> /dev/null
                    )
                ) || ( SaveThisExitCode )
            )
        else
            (exit 255)
            SaveThisExitCode
        fi

        EchoPassOrFailThisExitCode
        ParseThisExitCode
    }

    function Help
    {
        declare -r str_helpPrompt="Usage: $0 [ OPTIONS | ARGUMENTS ]
            \nwhere OPTIONS
            \n\t-h  --help\t\t\tPrint this prompt.
            \n\t-d  --delete\t\t\tDelete existing VFIO setup.
            \n\t-w  --write <logfile>\t\tWrite output (IOMMU groups) to <logfile>
            \n\t-m  --multiboot <ARGUMENT>\tExecute Multiboot VFIO setup.
            \n\t-s  --static <ARGUMENT>\t\tExecute Static VFIO setup.
            \n\nwhere ARGUMENTS
            \n\t-f  --full\t\t\tExecute pre-setup and post-setup.
            \n\t-r  --read <logfile>\t\tRead previous output (IOMMU groups) from <logfile>, and update VFIO setup.
            \n"

        echo -e $str_helpPrompt

        ExitWithThisExitCode
    }

    function MultiBootSetup
    {
        echo -e "Executing Multi-boot setup..."

        # parameters #
        declare -l bool_outputToGRUB=false
        # declare -lr str_logFile1="/logs/${0##*/}.log"       # NOTE: what does this do?
        declare -la arr_GRUBmenuEntry=()
        declare -la arr_rootKernel+=( $( ls -1 /boot/vmli* | cut -d "z" -f 2 | sort -r | head -n3 ) )       # first three kernels
        declare -la arr_VFIO_driver=()
        declare -la arr_VFIOVGA_driver=()
        declare -l str_thisGPU_FullName=""
        declare -lr str_rootDisk=$( df / | grep -iv 'filesystem' | cut -d '/' -f3 | cut -d ' ' -f1 )
        declare -lr str_rootDistro=$( lsb_release -i -s )                                                   # Linux distro name
        declare -lr str_rootUUID=$( blkid -s UUID | grep $str_rootDisk | cut -d '"' -f2 )
        declare -l str_rootFSTYPE=$( blkid -s TYPE | grep $str_rootDisk | cut -d '"' -f2 )

        if [[ $str_rootFSTYPE == "ext4" || $str_rootFSTYPE == "ext3" ]]; then       # NOTE: this implementation is hacky. This does not account for other root filesystems
            declare -lr str_rootFSTYPE="ext2"
        fi

        # files #
        # NOTES:
        #
        #   file0   == iommu logfile
        #   file1   == multi-boot-template file for '/etc/grub.d/proxifiedScripts/custom'
        #   file2   == '/etc/grub.d/proxifiedScripts/custom'
        #   file3   == '/etc/default/grub'
        #

        declare -lr str_file0="iommu.log"
        declare -lr str_file1="multi-boot-template"
        declare -lr str_file2="etc_grub.d_proxifiedScripts_custom"
        declare -lr str_file3="etc_default_grub"

        if [[ $bool_executeTestCases == true ]]; then   # read from test-case input
            declare -lar arr_rootKernel=(               # taken from test input
                "5.18.0-0.deb11.3-amd64"
                "5.10.0-18-amd64"
                "5.10.0-15-amd64"
            )

            str_dir1=$( find tests/test-input | head -n1 )                                        # test input IOMMU file
            CheckIfFileOrDirExists $str_dir1 &> /dev/null && cd $str_dir1 || SaveThisExitCode

            declare -lr str_inFile0=$( find . -name $str_file0 )
            declare -lr str_inFile1=$( find . -name $str_file1 )
            CheckIfFileOrDirExists $str_inFile0 &> /dev/null || SaveThisExitCode
            CheckIfFileOrDirExists $str_inFile1 &> /dev/null || SaveThisExitCode

            if [[ $int_thisExitCode -eq 0 ]]; then      # read from test input IOMMU file
                ReadIOMMUFromLogFile $str_inFile0 || SaveThisExitCode
            fi

            str_dir1=$( find tests/test-input | head -n1 )                                        # test input system files
            CheckIfFileOrDirExists $str_dir1 &> /dev/null && cd $str_dir1 || SaveThisExitCode

            declare -lr str_inFile2=$( find . -name $str_file2 )
            declare -lr str_inFile3=$( find . -name $str_file3 )
            CheckIfFileOrDirExists $str_inFile2 &> /dev/null || SaveThisExitCode
            CheckIfFileOrDirExists $str_inFile3 &> /dev/null || SaveThisExitCode

            str_dir1=$( find tests/actual-output/multi-boot-setup | head -n1 )                    # actual output system files
            CheckIfFileOrDirExists $str_dir1 &> /dev/null && cd $str_dir1 || SaveThisExitCode

            declare -lr str_outFile2=$( find . -name $str_file2 )
            declare -lr str_outFile3=$( find . -name $str_file3 )
            CheckIfFileOrDirExists $str_outFile2 &> /dev/null || SaveThisExitCode
            CheckIfFileOrDirExists $str_outFile3 &> /dev/null || SaveThisExitCode

            str_dir1=$( find tests/expected-output | head -n1 )                                   # expected output system files
            CheckIfFileOrDirExists $str_dir1 &> /dev/null && cd $str_dir1 || SaveThisExitCode

            declare -lr str_expectedOutFile2=$( find . -name $str_file2 )
            declare -lr str_expectedOutFile3=$( find . -name $str_file3 )
            CheckIfFileOrDirExists $str_expectedOutFile2 &> /dev/null || SaveThisExitCode
            CheckIfFileOrDirExists $str_expectedOutFile3 &> /dev/null || SaveThisExitCode

        else                                            # read normally
            str_dir1=$( find .. -name logs )
            CheckIfFileOrDirExists $str_dir1 &> /dev/null && cd $str_dir1 || SaveThisExitCode

            declare -lr str_inFile0=$( find . -name $str_file0 )
            CheckIfFileOrDirExists $str_inFile0 &> /dev/null || SaveThisExitCode

            str_dir1=$( find .. -name files )
            CheckIfFileOrDirExists $str_dir1 &> /dev/null && cd $str_dir1 || SaveThisExitCode

            declare -lr str_inFile1=$( find . -name $str_file1 )
            declare -lr str_inFile2=$( find . -name $str_file2 )
            declare -lr str_inFile3=$( find . -name $str_file3 )
            CheckIfFileOrDirExists $str_inFile1 &> /dev/null || SaveThisExitCode
            CheckIfFileOrDirExists $str_inFile2 &> /dev/null || SaveThisExitCode
            CheckIfFileOrDirExists $str_inFile3 &> /dev/null || SaveThisExitCode

            declare -lr str_outFile1="/etc/grub.d/proxifiedScripts/custom"

            ParseIOMMUandPCI

            if [[ $int_thisExitCode -ne 0 ]]; then      # call function
                ReadIOMMUFromLogFile $str_inFile0 || SaveThisExitCode
            fi
        fi

        while [[ $int_thisExitCode -eq 0 ]]; do                                                 # execute code until break at end or if an error occurs
            SelectAnIOMMUGroup                                                                  # call function
            CreateBackupFromFile $str_outFile2 &> /dev/null
            CheckIfFileOrDirExists $str_inFile2 &> /dev/null && cp $str_inFile2 $str_outFile2   # restore backup
            # CheckIfFileOrDirExists $str_logFile1 &> /dev/null && DeleteFile $str_logFile1 &> /dev/null
            # CreateFile $str_logFile1 &> /dev/null

            for str_element in ${arr_IOMMU_forSTUB[@]}; do                          # devices for PCI STUB
                for int_key in ${str_element}; do
                    str_driverListForSTUB+="${arr_DeviceDriver[$int_key]},"
                    str_HWIDlist_forSTUB+="${arr_DeviceHWID[$int_key]},"
                done
            done

            for str_element in ${arr_IOMMU_forVFIO[@]}; do                          # devices for VFIO PCI
                for int_key in ${str_element}; do
                    str_driverListForVFIO+="${arr_DeviceDriver[$int_key]},"
                    str_HWID_list_forVFIO+="${arr_DeviceHWID[$int_key]},"
                done
            done

            for str_element in ${arr_IOMMU_withVGA_forVFIO[@]}; do                  # devices for VFIO PCI
                for int_key in ${str_element}; do
                    str_driverListWithVGA_forVFIO+="${arr_DeviceDriver[$int_key]},"
                    str_HWID_listWithVGA_forVFIO+="${arr_DeviceHWID[$int_key]},"
                done
            done

            # remove last separator #
            str_driverListForSTUB=${str_driverListForSTUB::-1}
            str_driverListForVFIO=${str_driverListForVFIO::-1}
            str_driverListWithVGA_forVFIO=${str_driverListWithVGA_forVFIO::-1}
            str_HWIDlist_forSTUB=${str_HWIDlist_forSTUB::-1}
            str_HWID_list_forVFIO=${str_HWID_list_forVFIO::-1}
            str_HWID_listWithVGA_forVFIO=${str_HWID_listWithVGA_forVFIO::-1}

            if [[ ${#str_driverListWithVGA_forVFIO} -gt 0 ]]; then
                str_driverListForVFIO+=",${str_driverListWithVGA_forVFIO}"
            fi

            if [[ ${#str_HWID_listWithVGA_forVFIO} -gt 0 ]]; then
                str_HWID_list_forVFIO+=",${str_HWID_listWithVGA_forVFIO}"
            fi

            if [[ $str_IGPU_fullName != "N/A" && -z $str_IGPU_fullName ]]; then     # append IGPU name
                str_thisGPU_FullName=$str_IGPU_fullName
            fi

            # write to file #                                                       # NOTE: update here!
            str_GRUB_CMDLINE="${str_GRUB_CMDLINE_prefix} modprobe.blacklist=${str_driverListForVFIO} pci-stub.ids=${str_driverListForSTUB} vfio_pci.ids=${str_HWID_list_forVFIO}"
            # WriteVarToFile $str_logFile1 "#${arr_IOMMU_withVGA_forVFIO[1]} #${str_thisGPU_FullName} #${str_GRUB_CMDLINE}" &> /dev/null  # log file

            # NOTE: does this currently only parse one IOMMU group?

            # /etc/grub.d/proxifiedScripts/custom #
            for int_key in ${!arr_rootKernel[@]}; do                                # parse kernels
                declare -l str_element=${arr_rootKernel[$int_key]}

                if [[ -e $str_element || $str_element != "" ]]; then                # match
                    str_thisRootKernel=${arr_rootKernel[$int_key]:1}
                    str_thisGRUBmenuEntry=$( lsb_release -i -s )" "$( uname -o )", with "$( uname )" ${str_thisRootKernel} (VFIO, w/o IOMMU '${arr_IOMMU_withVGA_forVFIO[1]}}', w/ boot VGA '${str_thisGPU_FullName}')"
                    arr_GRUBmenuEntry+=( "${str_thisGRUBmenuEntry}" )

                    str_output1="menuentry \"${str_thisGRUBmenuEntry}\" {"
                    str_output1_log="\n"'menuentry "'$( lsb_release -i -s )" "$( uname -o )", with "$( uname )" #kernel_'${int_key}'# (VFIO, w/o IOMMU '${arr_IOMMU_withVGA_forVFIO[1]}', w/ boot VGA '${str_thisGPU_FullName}'\") {"

                    str_output2="\tinsmod ${str_rootFSTYPE}"
                    str_output3="\tset root='/dev/disk/by-uuid/${str_rootUUID}'"
                    str_output4="\t"'if [ x$feature_platform_search_hint = xy ]; then'"\n\t\t"'search --no-floppy --fs-uuid --set=root '"${str_rootUUID}\n\t"'fi'

                    str_output5="\techo    'Loading Linux ${str_thisRootKernel} ...'"
                    str_output5_log="\techo    'Loading Linux #kernel'${int_key}'# ...'"

                    str_output6="\tlinux   /boot/vmlinuz-$str_thisRootKernel root=UUID=${str_rootUUID} ${str_GRUB_CMDLINE}"
                    str_output6_log="\tlinux   /boot/vmlinuz-#kernel'$int_key'# root=UUID=${str_rootUUID} ${str_GRUB_CMDLINE}"

                    str_output7="\tinitrd  /boot/initrd.img-${str_thisRootKernel}"
                    str_output7_log="\tinitrd  /boot/initrd.img-"'#kernel'${int_key}'#'

                    # debug prompt #
                    # echo -e "'$""str_output0'\t\t= $str_output0"
                    # echo -e "'$""str_output1'\t\t= $str_output1"
                    # echo -e "'$""str_output2'\t\t= $str_output2"
                    # echo -e "'$""str_output3'\t\t= $str_output3"
                    # echo -e "'$""str_output4'\t\t= $str_output4"
                    # echo -e "'$""str_output5'\t\t= $str_output5"
                    # echo -e "'$""str_output6'\t\t= $str_output6"
                    # echo -e "'$""str_output7'\t\t= $str_output7"
                    # echo

                    # write to tempfile #
                    CheckIfFileOrDirExists $str_inFile1 &> /dev/null && CheckIfFileOrDirExists $str_inFile0 &> /dev/null && (
                        echo -e >> $str_outFile2

                        while read -r str_line; do
                            case $str_line in
                                *'#$str_output1'*)
                                    str_outLine="$str_output1";;
                                *'#$str_output2'*)
                                    str_outLine="$str_output2";;
                                *'#$str_output3'*)
                                    str_outLine="$str_output3";;
                                *'#$str_output4'*)
                                    str_outLine="$str_output4";;
                                *'#$str_output5'*)
                                    str_outLine="$str_output5";;
                                *'#$str_output6'*)
                                    str_outLine="$str_output6";;
                                *'#$str_output7'*)
                                    str_outLine="$str_output7";;
                                *)
                                    str_outLine="$str_line";;
                            esac

                            WriteVarToFile $str_outFile2 $str_outLine &> /dev/null || ( SaveThisExitCode && break )     # write to system file and logfile (post_install: update Multi-boot)
                        done < $str_inFile0                                                                             # read from template
                    ) || (
                        (exit 250) && SaveThisExitCode && break
                    )
                fi
            done && (
                chmod 755 $str_outFile2 $str_oldFile1 &> /dev/null && (exit 0) && SaveThisExitCode  # set proper permissions
            )

            break
        done

        EchoPassOrFailThisExitCode "Executing Multi-boot setup..."

        if [[ $int_thisExitCode -eq 250 ]]; then                    # file check
            echo -e "File(s) missing:"
            CheckIfFileOrDirExists $str_inFile0 &> /dev/null || echo -e "\t'$str_inFile0'"
            CheckIfFileOrDirExists $str_inFile1 &> /dev/null || echo -e "\t'$str_inFile1'"
            CheckIfFileOrDirExists $str_inFile2 &> /dev/null || echo -e "\t'$str_inFile2'"
            CheckIfFileOrDirExists $str_inFile3 &> /dev/null || echo -e "\t'$str_inFile3'"
        fi

        if [[ $bool_executeTestCases == true ]]; then               # read from test-case input
            true && SaveThisExitCode

            CheckIfTwoFilesAreSame $str_outFile2 $str_expectedOutFile2 || SaveThisExitCode
            CheckIfTwoFilesAreSame $str_outFile3 $str_expectedOutFile3 || SaveThisExitCode

            EchoPassOrFailThisTestCase "MultiBootSetup_GivenInputIsValid_ReturnExpectedResult"
        fi
    }

    function ParseInputParamForOptions
    {
        if [[ "$1" =~ ^- || "$1" == "--" ]]; then           # parse input parameters
            while [[ "$1" =~ ^-  ]]; do
                case $1 in
                    "")                                     # no option
                        (exit 255)
                        SaveThisExitCode
                        break;;

                    -h | --help )                           # options
                        declare -lir int_aFlag=1
                        break;;
                    -d | --delete )
                        declare -lir int_aFlag=2
                        break;;
                    -m | --multiboot )
                        declare -lir int_aFlag=3;;
                    -s | --static )
                        declare -lir int_aFlag=4;;
                    -w | --write )
                        declare -lir int_aFlag=5;;

                    -f | --full )                           # arguments
                        declare -lir int_bFlag=1;;
                    -r | --read )
                        declare -lir int_bFlag=2;;
                esac

                shift
            done
        else                                                # invalid option
            (exit 255)
            SaveThisExitCode
            ParseThisExitCode
            Help
            ExitWithThisExitCode
        fi

        # if [[ "$1" == '--' ]]; then
        #     shift
        # fi

        case $int_aFlag in                                  # execute second options before first options
            3|4)
                case $int_bFlag in
                    1)
                        PreInstallSetup;;
                    # 2)
                    #     ReadIOMMU_FromFile;;
                esac;;
        esac

        case $int_aFlag in                                  # execute first options
            1)
                Help;;
            2)
                DeleteSetup;;
            3)
                MultiBootSetup;;
            4)
                StaticSetup;;
            # 5)
            #     WriteIOMMU_ToFile;;
        esac

        case $int_aFlag in                                  # execute second options after first options
            3|4)
                case $int_bFlag in
                    1)
                        PostInstallSetup;;
                esac;;
        esac
    }

    # TODO: fix here !
        # function ParseInputParamForOptions_2
        # {
        #     str_option=$1
        #     str_args=$2

        #     case $str_option in
        #         "--"*)
        #             str_option=${str_option:2};;
        #         "-"*)
        #             str_option=${str_option:1};;
        #     esac

        #     case $str_args in
        #         "--"*)
        #             str_args=${str_args:2};;
        #         "-"*)
        #             str_args=${str_args:1};;
        #     esac

        #     declare -lar arr_options=(
        #         "help"
        #         ,"delete"
        #         ,"multiboot"
        #         ,"static"
        #         ,"write"
        #     )

        #     declare -lar arr_args=(
        #         "full"
        #         ,"read"
        #     )

        #     for int_key in ${!arr_options[@]}; do
        #         declare -l str_element=${arr_options[$int_key]}

        #         if [[ $str_option == $str_element ]]; then
        #             declare -lir int_option=$int_key
        #             break
        #         fi
        #     done

        #     # Get the options
        #     while getopts ":h" option; do
        #         case $option in
        #             "")                                     # no option
        #                 (exit 255)
        #                 SaveThisExitCode
        #                 break;;

        #             h)                                      # options
        #                 declare -lir int_aFlag=1
        #                 break;;
        #             d)
        #                 declare -lir int_aFlag=2
        #                 break;;
        #             m)
        #                 declare -lir int_aFlag=3;;
        #             s)
        #                 declare -lir int_aFlag=4;;
        #             w)
        #                 declare -lir int_aFlag=5;;

        #             f)                                      # arguments
        #                 declare -lir int_bFlag=1;;
        #             r)
        #                 declare -lir int_bFlag=2;;

        #             *)                                      # invalid option
        #                 declare -lir int_aFlag=1
        #                 (exit 254)
        #                 SaveThisExitCode
        #                 ParseThisExitCode
        #                 echo
        #                 break;;
        #         esac
        #     done

        #     case $int_aFlag in                                  # execute second options before first options
        #         3|4)
        #             case $int_bFlag in
        #                 1)
        #                     PreInstallSetup;;
        #                 # 2)
        #                 #     ReadIOMMU_FromFile;;
        #             esac;;
        #     esac

        #     case $int_aFlag in                                  # execute first options
        #         1)
        #             Help
        #             ExitWithThisExitCode;;
        #         2)
        #             DeleteSetup;;
        #         3)
        #             MultiBootSetup;;
        #         4)
        #             StaticSetup;;
        #         # 5)
        #         #     WriteIOMMU_ToFile;;
        #     esac

        #     case $int_aFlag in                                  # execute second options after first options
        #         3|4)
        #             case $int_bFlag in
        #                 1)
        #                     PostInstallSetup;;
        #             esac;;
        #     esac
        # }

    function PreInstallSetup            # NOTE: reviewed 22-11-12. Refactored boolean functions. Looks good.
    {
        echo -e "Executing Pre-install setup..."

        # parameters
        declare -lr str_inFile1="etc_libvirt_qemu.conf"
        declare -lr str_outFile1="/etc/libvirt/qemu.conf"
        declare -lr str_outFile2="/logs/etc_libvirt_qemu.conf"

        CreateFile $str_outFile2 &> /dev/null

        # restore system file from repo backup if declare -l backups do not exist #
        CheckIfFileOrDirExists $str_outFile1 || (
            CheckIfFileOrDirExists $str_inFile1 && (
                cp $str_inFile1 $str_outFile1
                cp $str_inFile1 $str_outFile2
            )
        )

        # append to system file
        declare -a arr_output1=(
            "# Generated by 'portellam/deploy-VFIO-setup'"
            "#"
            "# WARNING: Any modifications to this file will be modified by 'deploy-VFIO-setup'"
            "#"
            "# Run 'systemctl restart libvirtd.service' to update."
            " "
            "# User permissions #"
            "#     user = \"user\""
            "#     group = \"user\""
            "#"
        )

        # find first desktop user, add user to groups for libvirt/qemu, hugepages, and evdev
        declare -r str_firstUser=$( id -u 1000 -n ) && (
            adduser $str_firstUser libvirt &> /dev/null
            adduser $str_firstUser input &> /dev/null
        )

        SaveThisExitCode            # NOTE: is this necessary?

        # append to system file
        if [[ $int_thisExitCode -eq 0 ]]; then
            arr_output1+=(
                "user = \"${str_firstUser}\""
                "group = \"user\""
                "#"
            )
        fi

        # execute Hugepages setup #
        SetupHugepages && (
            # echo -e "str_GRUB_CMDLINE_Hugepages:'${str_GRUB_CMDLINE_Hugepages}'"  # this scope does work!
            #arr_output1+=("${str_output_hugepagesQEMU}")   # append

            while read str_line; do
                arr_output1+=("$str_line")
                echo $str_line
            done < "logs/qemu-hugepages.log"

            arr_output1+=("#")
        )

        # append
        arr_output1+=(
            "cgroup_device_acl = ["
        )

        # execute Evdev setup #
        SetupEvdev && (
            # echo -e '${#arr_output_evdevQEMU[@]}='"'${#arr_output_evdevQEMU[@]}'"

            # for str_element in ${arr_output_evdevQEMU[@]}; do
            #     arr_output1+=("${str_element}")
            # done

            # arr_output1+=($( cat $str_thisFile1 ))

            # echo $str_thisFile1

            # ReadFile "qemu-evdev.log"

            # for str_element in ${arr_output_thisFile[@]}; do
            #     arr_output1+=("${str_element}")
            #     echo $str_element
            # done

            while read str_line; do         # append
                arr_output1+=("$str_line")
                echo $str_line
            done < "qemu-evdev.log"
        )

        # append #
        arr_output1+=(
            "    \"/dev/null\", \"/dev/full\", \"/dev/zero\","
            "    \"/dev/random\", \"/dev/urandom\","
            "    \"/dev/ptmx\", \"/dev/kvm\","
            "    \"/dev/rtc\",\"/dev/hpet\""
            "]"
            "#"
        )

        if ( CreateBackupFromFile $str_outFile1 &> /dev/null == true ); then
            for str_element in ${arr_output1[@]}; do
                if [[ $int_thisExitCode -ne 0 ]]; then
                    break
                fi

                ( WriteVarToFile $str_outFile1 $str_element &> /dev/null ) || ( false && SaveThisExitCode )
                ( WriteVarToFile $str_outFile2 $str_element &> /dev/null ) || ( false && SaveThisExitCode )
            done

        else
            echo -e "\e[33mWARNING:\e[0m"" Setup cannot continue." && ExitWithThisExitCode
        fi

        SetupStaticCPU_isolation || ( false && SaveThisExitCode )

        # TO-DO: add check for necessary dependencies or packages

        declare -r str_dir1=$( find .. -name git )
        ( CheckIfFileOrDirExists $str_dir1 &> /dev/null && cd $str_dir1 ) && (
            if [[ TestNetwork == true ]]; then

            # zram-swap
            if ( CloneOrUpdateGitRepositories "FoundObjects/zram-swap" ); then
                SetupZRAM_Swap || ( false && SaveThisExitCode )
            fi

            # auto-xorg
            if ( CloneOrUpdateGitRepositories "portellam/auto-xorg" ); then
                SetupAutoXorg || ( false && SaveThisExitCode )
            fi

            else

                # zram-swap
                if ( CheckIfFileOrDirExists "zram-swap" == true ); then
                    SetupZRAM_Swap || ( false && SaveThisExitCode )
                fi

                # auto-xorg
                if ( CheckIfFileOrDirExists "auto-xorg" ); then
                    SetupAutoXorg || ( false && SaveThisExitCode )
                fi
            fi

            if [[ $int_thisExitCode -ne 0 ]]; then
                echo -e "\e[34mWARNING:\e[0m"" Pre-setup incomplete."
            fi
        ) || ( false && SaveThisExitCode )

        # GRUB output           # NOTE: update here!
        str_output_GRUB_prefix="quiet splash video=efifb:off,vesafb:off acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 "

        if [[ ${#str_output_hugepagesGRUB} -gt 0 ]]; then
            str_output_GRUB_prefix+="${str_output_hugepagesGRUB} "
        fi

        if [[ ${#str_output_isolateCPU} -gt 0 ]]; then
            str_output_GRUB_prefix+="${str_output_isolateCPU} "
        fi

        EchoPassOrFailThisExitCode "Executing Pre-install setup..."
    }

    function PostInstallSetup           # TODO: fill out this function
    {
        echo -e "Executing Post-install setup..."
        # code here

        EchoPassOrFailThisExitCode "Executing Post-install setup..."
    }

    function SelectVFIOSetup            # NOTE: this needs no further refactoring.
    {
        ReadInputFromMultipleChoiceUpperCase "Execute Multiboot or Static setup? [M/s]:" "M" "S"

        case $str_input1 in
            "M")
                MultiBootSetup;;
            "S")
                StaticSetup;;
        esac
    }

    function StaticSetup                # NOTE: try this with test cases.
    {
        echo -e "Executing Static setup..."

        # parameters #
        declare -a arr_VFIO_driver=()
        declare -a arr_VFIOVGA_driver=()
        bool_missingFiles=false
        str_PCISTUB_HWIDlist=""
        str_driverList_forVFIO_softdep=""
        str_VFIO_driverList=""
        str_VFIO_HWIDList=""

        # NOTES:
        #
        #   file0   == iommu logfile
        #   file1   == multi-boot-template file for '/etc/grub.d/proxifiedScripts/custom'
        #   file2   == '/etc/grub.d/proxifiedScripts/custom'
        #   file3   == '/etc/default/grub'
        #

        declare -lr str_file0="iommu.log"
        declare -lr str_file1="etc_default_grub"
        declare -lr str_file2="etc_modules"
        declare -lr str_file3="etc_initramfs-tools_modules"
        declare -lr str_file4="etc_modprobe.d_pci-blacklists.conf"
        declare -lr str_file5="etc_modprobe.d_vfio.conf"

        if [[ $bool_executeTestCases == true ]]; then   # read from test-case input
            str_dir1=$( find tests/test-input | head -n1 )                                      # test input IOMMU file
            CheckIfFileOrDirExists $str_dir1 || (
                SaveThisExitCode && EchoPassOrFailThisExitCode
            )
            cd $str_pwd

            str_dir1=$( find tests/test-input | head -n1 )                                      # test input system files
            CheckIfFileOrDirExists $str_dir1 && cd $str_dir1 || SaveThisExitCode
            cd $str_pwd

            declare -r str_inFile0=$( find . -name $str_file0 )
            declare -r str_inFile1=$( find . -name $str_file1 )
            declare -r str_inFile2=$( find . -name $str_file2 )
            declare -r str_inFile3=$( find . -name $str_file3 )
            declare -r str_inFile4=$( find . -name $str_file4 )
            declare -r str_inFile5=$( find . -name $str_file5 )
            CheckIfFileOrDirExists $str_inFile0 || SaveThisExitCode
            CheckIfFileOrDirExists $str_inFile1 || SaveThisExitCode
            CheckIfFileOrDirExists $str_inFile2 || SaveThisExitCode
            CheckIfFileOrDirExists $str_inFile3 || SaveThisExitCode
            CheckIfFileOrDirExists $str_inFile4 || SaveThisExitCode
            CheckIfFileOrDirExists $str_inFile5 || SaveThisExitCode

            str_dir1=$( find tests/actual-output/static-setup | head -n1 )                      # actual output system files
            CheckIfFileOrDirExists $str_dir1 && cd $str_dir1 || SaveThisExitCode
            cd $str_pwd

            declare -r str_outFile1=$( find . -name etc_default_grub )
            declare -r str_outFile2=$( find . -name etc_modules )
            declare -r str_outFile3=$( find . -name etc_initramfs-tools_modules )
            declare -r str_outFile4=$( find . -name etc_modprobe.d_pci-blacklists.conf )
            declare -r str_outFile5=$( find . -name etc_modprobe.d_vfio.conf )
            CheckIfFileOrDirExists $str_outFile1 || SaveThisExitCode
            CheckIfFileOrDirExists $str_outFile2 || SaveThisExitCode
            CheckIfFileOrDirExists $str_outFile3 || SaveThisExitCode
            CheckIfFileOrDirExists $str_outFile4 || SaveThisExitCode
            CheckIfFileOrDirExists $str_outFile5 || SaveThisExitCode

            str_dir1=$( find tests/expected-output/static-setup | head -n1 )                    # expected output system files
            CheckIfFileOrDirExists $str_dir1 && cd $str_dir1 || SaveThisExitCode
            cd $str_pwd

            declare -r str_expectedOutFile1=$( find . -name etc_default_grub )
            declare -r str_expectedOutFile2=$( find . -name etc_modules )
            declare -r str_expectedOutFile3=$( find . -name etc_initramfs-tools_modules )
            declare -r str_expectedOutFile4=$( find . -name etc_modprobe.d_pci-blacklists.conf )
            declare -r str_expectedOutFile5=$( find . -name etc_modprobe.d_vfio.conf )
            CheckIfFileOrDirExists $str_expectedOutFile1 || SaveThisExitCode
            CheckIfFileOrDirExists $str_expectedOutFile2 || SaveThisExitCode
            CheckIfFileOrDirExists $str_expectedOutFile3 || SaveThisExitCode
            CheckIfFileOrDirExists $str_expectedOutFile4 || SaveThisExitCode
            CheckIfFileOrDirExists $str_expectedOutFile5 || SaveThisExitCode

        else                                            # read normally
            str_dir1=$( find .. -name logs )
            CheckIfFileOrDirExists $str_dir1 || SaveThisExitCode
            cd $str_pwd

            declare -r str_inFile0=$( find . -name $str_file0 )
            CheckIfFileOrDirExists $str_inFile0 || SaveThisExitCode
            cd $str_pwd

            str_dir1=$( find .. -name files )
            CheckIfFileOrDirExists $str_dir1 || SaveThisExitCode
            cd $str_pwd

            declare -r str_inFile1=$( find . -name $str_file1 )
            declare -r str_inFile2=$( find . -name $str_file2 )
            declare -r str_inFile3=$( find . -name $str_file3 )
            declare -r str_inFile4=$( find . -name $str_file4 )
            declare -r str_inFile5=$( find . -name $str_file5 )
            CheckIfFileOrDirExists $str_inFile1 || SaveThisExitCode
            CheckIfFileOrDirExists $str_inFile2 || SaveThisExitCode
            CheckIfFileOrDirExists $str_inFile3 || SaveThisExitCode
            CheckIfFileOrDirExists $str_inFile4 || SaveThisExitCode
            CheckIfFileOrDirExists $str_inFile5 || SaveThisExitCode

            declare -r str_outFile1="/etc/default/grub"
            declare -r str_outFile2="/etc/modules"
            declare -r str_outFile3="/etc/initramfs-tools/modules"
            declare -r str_outFile4="/etc/modprobe.d/pci-blacklists.conf"
            declare -r str_outFile5="/etc/modprobe.d/vfio.conf"
            CheckIfFileOrDirExists $str_outFile1 || SaveThisExitCode
            CheckIfFileOrDirExists $str_outFile2 || SaveThisExitCode
            CheckIfFileOrDirExists $str_outFile3 || SaveThisExitCode
            CheckIfFileOrDirExists $str_outFile4 || SaveThisExitCode
            CheckIfFileOrDirExists $str_outFile5 || SaveThisExitCode
        fi

        while [[ $int_thisExitCode -eq 0 ]]; do                                     # execute code until break at end or if an error occurs
            ParseIOMMUandPCI || (
                CheckIfFileOrDirExists $str_inFile0 &> /dev/null || SaveThisExitCode

                if [[ $int_thisExitCode -eq 0 ]]; then
                    ReadIOMMUFromLogFile $str_inFile0 &> /dev/null
                fi
            ) || (
                    SaveThisExitCode
            )

            SelectAnIOMMUGroup

            CreateBackupFromFile $str_outFile1 &> /dev/null                         # create backups
            CreateBackupFromFile $str_outFile2 &> /dev/null
            CreateBackupFromFile $str_outFile3 &> /dev/null
            CreateBackupFromFile $str_outFile4 &> /dev/null
            CreateBackupFromFile $str_outFile5 &> /dev/null

            # prompt #
            ReadInput "Append changes to '/etc/default/grub' or no (system files)? [Y/n]: "

            case $str_input1 in
                "Y")
                    bool_outputToGRUB=true;;
                "N")
                    bool_outputToGRUB=false;;
            esac

            for str_element in ${arr_IOMMU_forSTUB[@]}; do                          # devices for PCI STUB
                for int_key in ${str_element}; do
                    str_driverListForSTUB+="${arr_DeviceDriver[$int_key]},"
                    str_HWIDlist_forSTUB+="${arr_DeviceHWID[$int_key]},"
                done
            done

            for str_element in ${arr_IOMMU_forVFIO[@]}; do                          # devices for VFIO PCI
                for int_key in ${str_element}; do
                    str_driverListForVFIO+="${arr_DeviceDriver[$int_key]},"
                    str_HWID_list_forVFIO+="${arr_DeviceHWID[$int_key]},"
                done
            done

            for str_element in ${arr_IOMMU_withVGA_forVFIO[@]}; do                  # devices for VFIO PCI
                for int_key in ${str_element}; do
                    str_driverListWithVGA_forVFIO+="${arr_DeviceDriver[$int_key]},"
                    str_HWID_listWithVGA_forVFIO+="${arr_DeviceHWID[$int_key]},"
                done
            done

            # remove last separator #
            str_driverListForSTUB=${str_driverListForSTUB::-1}
            str_driverListForVFIO=${str_driverListForVFIO::-1}
            str_driverListWithVGA_forVFIO=${str_driverListWithVGA_forVFIO::-1}
            str_HWIDlist_forSTUB=${str_HWIDlist_forSTUB::-1}
            str_HWID_list_forVFIO=${str_HWID_list_forVFIO::-1}
            str_HWID_listWithVGA_forVFIO=${str_HWID_listWithVGA_forVFIO::-1}

            if [[ ${#str_driverListWithVGA_forVFIO} -gt 0 ]]; then
                str_driverListForVFIO+=",${str_driverListWithVGA_forVFIO}"
            fi

            if [[ ${#str_HWID_listWithVGA_forVFIO} -gt 0 ]]; then
                str_HWID_list_forVFIO+=",${str_HWID_listWithVGA_forVFIO}"
            fi

            if [[ $str_IGPU_fullName != "N/A" && -z $str_IGPU_fullName ]]; then     # append IGPU name
                str_thisGPU_FullName=$str_IGPU_fullName
            fi

            str_output_thisGRUB="${str_output_GRUB_prefix} modprobe.blacklist= pci-stub.ids= vfio_pci.ids="

            # VFIO soft dependencies #
                for int_key in ${arr_IOMMU_forVFIO[@]}; do              # parse VFIO groups
                    str_element=${arr_DeviceDriver[$int_key]}
                    str_driverList_forVFIO_softdep+="\nsoftdep $str_element pre: vfio-pci"
                    str_driverList_forVFIO_softdepFull+="\nsoftdep $str_element pre: vfio-pci\n$str_element"
                done

                for int_key in ${arr_IOMMU_withVGA_forVFIO[@]}; do      # parse VFIO VGA groups
                    str_element=${arr_DeviceDriver[$int_key]}
                    str_driverList_forVFIO_softdep+="\nsoftdep $str_element pre: vfio-pci"
                    str_driverList_forVFIO_softdepFull+="\nsoftdep $str_element pre: vfio-pci\n$str_element"
                done

            if [[ $bool_outputToGRUB == true ]]; then                   # write to files

                # /etc/default/grub #
                str_output_thisGRUB="${str_output_GRUB_prefix} modprobe.blacklist=${str_driverListForVFIO} pci-stub.ids=${str_driverListForSTUB} vfio_pci.ids=${str_HWID_list_forVFIO}"

                cp $str_inFile2 $str_outFile2
                cp $str_inFile3 $str_outFile3
                cp $str_inFile4 $str_outFile4
                cp $str_inFile5 $str_outFile5

            else
                # /etc/default/grub #
                str_output_thisGRUB="${str_output_GRUB_prefix} modprobe.blacklist= pci-stub.ids= vfio_pci.ids="

                # /etc/modules #
                str_output1="vfio_pci ids=${str_HWID_list_forSTUB}${str_HWID_list_forVFIO}"

                CheckIfFileOrDirExists $str_inFile2 &> /dev/null && (
                    CheckIfFileOrDirExists $str_outFile2 &> /dev/null && DeleteFile $str_outFile2 &> /dev/null
                    CreateFile $str_outFile2 &> /dev/null

                    while read -r str_line; do                          # write to file
                        if [[ $str_line == '#$str_output1'* ]]; then
                            str_line=$str_output1
                        fi

                        WriteVarToFile $str_outFile2 $str_line
                    done < $str_inFile2
                ) || bool_missingFiles=true

                # /etc/initramfs-tools/modules #
                str_output1=$str_driverList_forVFIO_softdepFull
                str_output2="options vfio_pci ids=${str_HWIDlist_forSTUB}${str_HWID_list_forVFIO}\nvfio_pci ids=${str_HWIDlist_forSTUB}${str_HWID_list_forVFIO}\nvfio-pci"

                CheckIfFileOrDirExists $str_inFile3 &> /dev/null && (
                    CheckIfFileOrDirExists $str_outFile3 &> /dev/null && DeleteFile $str_outFile3 &> /dev/null
                    CreateFile $str_outFile3 &> /dev/null

                    while read -r str_line; do                          # write to file
                        if [[ $str_line == '#$str_output1'* ]]; then
                            str_line=$str_output1
                        fi

                        if [[ $str_line == '#$str_output2'* ]]; then
                            str_line=$str_output2
                        fi

                        WriteVarToFile $str_outFile3 $str_line
                    done < $str_inFile3
                ) || bool_missingFiles=true

                # /etc/modprobe.d/pci-blacklists.conf #
                str_output1=""

                for str_thisDriver in ${arr_VFIO_driver[@]}; do         # NOTE: update
                    str_output1+="blacklist $str_thisDriver\n"
                done

                CheckIfFileOrDirExists $str_inFile4 &> /dev/null && (
                    CheckIfFileOrDirExists $str_outFile4 &> /dev/null && DeleteFile $str_outFile4 &> /dev/null
                    CreateFile $str_outFile4 &> /dev/null

                    while read -r str_line; do                          # write to file
                        if [[ $str_line == '#$str_output1'* ]]; then
                            str_line=$str_output1
                        fi

                        WriteVarToFile $str_outFile4 $str_line
                    done < $str_inFile4
                ) || bool_missingFiles=true


                # /etc/modprobe.d/vfio.conf #
                str_output1="$str_driverList_forVFIO_softdep"
                str_output2="options vfio_pci ids=${str_HWIDlist_forSTUB}${str_HWID_list_forVFIO}"

                CheckIfFileOrDirExists $str_inFile5 &> /dev/null && (
                    CheckIfFileOrDirExists $str_outFile5 &> /dev/null && DeleteFile $str_outFile5 &> /dev/null
                    CreateFile $str_outFile5 &> /dev/null

                    while read -r str_line; do                          # write to file
                        if [[ $str_line == '#$str_output1'* ]]; then
                            str_line=$str_output1
                        fi

                        if [[ $str_line == '#$str_output2'* ]]; then
                            str_line=$str_output2
                        fi

                        WriteVarToFile $str_outFile5 $str_line
                    done < $str_inFile5
                ) || bool_missingFiles=true
            fi

            # /etc/default/grub #
            str_output1="GRUB_DISTRIBUTOR=\)lsb_release -i -s 2> /dev/null || echo "$( lsb_release -i -s )"\)"
            str_output2="GRUB_CMDLINE_LINUX_DEFAULT=\"$str_output_thisGRUB\""

            CheckIfFileOrDirExists $str_inFile1 &> /dev/null && (
                ( CheckIfFileOrDirExists $str_outFile1 &> /dev/null && DeleteFile $str_outFile1 &> /dev/null ) || SaveThisExitCode
                CreateFile $str_outFile1 &> /dev/null

                while read -r str_line; do                              # write to file
                    if [[ $str_line == '#$str_output1'* ]]; then
                        str_line=$str_output1
                    fi

                    if [[ $str_line == '#$str_output2'* ]]; then
                        str_line=$str_output2
                    fi

                    WriteVarToFile $str_outFile1 $str_line
                done < $str_inFile1
            ) || SaveThisExitCode

            break
        done

        EchoPassOrFailThisExitCode "Executing Static setup..."

        if [[ $int_thisExitCode -eq 250 ]]; then                    # file check
            echo -e "File(s) missing:"
            CheckIfFileOrDirExists $str_inFile1 &> /dev/null || echo -e "\t'$str_inFile1'"
            CheckIfFileOrDirExists $str_inFile2 &> /dev/null || echo -e "\t'$str_inFile2'"
            CheckIfFileOrDirExists $str_inFile3 &> /dev/null || echo -e "\t'$str_inFile3'"
            CheckIfFileOrDirExists $str_inFile4 &> /dev/null || echo -e "\t'$str_inFile4'"
            CheckIfFileOrDirExists $str_inFile5 &> /dev/null || echo -e "\t'$str_inFile5'"

        else
            chmod 755 $str_outFile1 $str_oldFile1                   # set proper permissions
        fi

        if [[ $bool_executeTestCases == true ]]; then               # read from test-case input
            true && SaveThisExitCode

            CheckIfTwoFilesAreSame $str_outFile1 $str_expectedOutFile1 || SaveThisExitCode
            CheckIfTwoFilesAreSame $str_outFile2 $str_expectedOutFile2 || SaveThisExitCode
            CheckIfTwoFilesAreSame $str_outFile3 $str_expectedOutFile3 || SaveThisExitCode
            CheckIfTwoFilesAreSame $str_outFile4 $str_expectedOutFile4 || SaveThisExitCode
            CheckIfTwoFilesAreSame $str_outFile5 $str_expectedOutFile5 || SaveThisExitCode

            EchoPassOrFailThisTestCase "StaticSetup_GivenInputIsValid_ReturnExpectedResult"
        fi
    }

# main #
    # NOTE: necessary for newline preservation in arrays and files
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

    bool_executeDeleteSetup=false
    bool_executeFullSetup=false
    bool_executeMultiBootSetup=false
    bool_executeStaticSetup=false
    bool_executeDeleteSetup=false

    if [[ -z $2 ]]; then
        # ParseInputParamForOptions $1            # TODO: need to fix params function
        CheckIfUserIsRoot
        CheckIfIOMMU_IsEnabled

        case true in
            $bool_executeDeleteSetup)
                DeleteSetup;;
            $bool_executeFullSetup)
                PreInstallSetup
                SelectVFIOSetup
                PostInstallSetup;;
            $bool_executeMultiBootSetup)
                MultiBootSetup;;
            $bool_executeStaticSetup)
                StaticSetup;;
            *)
                SelectVFIOSetup;;
        esac
    else
        (exit 254)
        SaveThisExitCode
        ParseThisExitCode "Cannot parse multiple options."
    fi

    # if [[ -z $2 ]]; then
    #     CheckIfUserIsRoot
    #     CheckIfIOMMU_IsEnabled
    #     ParseInputParamForOptions_2 $1 || SelectVFIOSetup
    # else
    #     (exit 254)
    #     SaveThisExitCode
    #     ParseThisExitCode "Cannot parse multiple options."
    # fi

    ExitWithThisExitCode