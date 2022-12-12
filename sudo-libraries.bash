#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

### main parameters ###
# <code>
    declare -r str_pwd=$( pwd )

    # <summary>
    # Necessary for exit code preservation, for conditional statements.
    # </summary>
    declare -i int_thisExitCode=$?
# </code>

### exit code functions ###
# <code>
    # <summary>
    # This statement (function) must follow an exit code statement.
    #   Exit Code   |   Description
    #
    #   0               True
    #   1               False; Catch-all for general errors.
    #   2               Misuse of shell built-ins.
    #
    #   126             Command invoked cannot execute.
    #   127             Command not found.
    #   128             Invalid argument to exit.
    #   128 + n         Where 'n' is a number, '$?' returns '128 + n'.
    #   130             Script terminated by 'CTRL+C'.
    #
    #   131-255         Unreserved
    #
    #   255             Unspecified error.
    #   254             Input is null.
    #   253             File/Dir is null.
    #   252             File/Dir is not readable.
    #   251             File/Dir is not writable.
    #   250             File/Dir is not executable.
    #   131             Neither pass or fail; Skipped execution.
    #
    # </summary>

    # <summary>
    # Output error given exception.
    # </summary>
    # <return>exit code</return>
    function ParseThisExitCode {
        case $int_thisExitCode in
            ### script agnostic ###
            255)
                echo -e "\e[33mError:\e[0m Unspecified error.";;
            254)
                echo -e "\e[33mException:\e[0m Null input.";;

            ### file operands ###
            253)
                echo -e "\e[33mException:\e[0m File/Dir does not exist.";;
            252)
                echo -e "\e[33mException:\e[0m File/Dir is not readable.";;
            251)
                echo -e "\e[33mException:\e[0m File/Dir is not writable.";;
            249)
                echo -e "\e[33mException:\e[0m Invalid input.";;

            ### script specific ###
            248)
                echo -e "\e[33mError:\e[0m Missed steps; missed execution of key subfunctions.";;
            251)
                echo -e "\e[33mError:\e[0m Missing components/variables.";;
        esac
    }

    # <summary>
    # Exit bash session/script with current exit code.
    # </summary>
    # <return>exit code</return>
    function ExitWithThisExitCode
    {
        echo -e "Exiting."
        exit $int_thisExitCode
    }

    # <summary>
    # Updates main parameter.
    # </summary>
    # <return>exit code</return>
    function SaveThisExitCode {
        int_thisExitCode=$?
    }

    function SetExitCodeOnError {
        (exit 255)
    }

    function SetExitCodeIfVarIsNull {
        (exit 254)
    }

    function SetExitCodeIfFileOrDirIsNull {
        (exit 253)
    }

    function SetExitCodeIfFileIsNotReadable {
        (exit 252)
    }

    function SetExitCodeIfFileIsNotWritable {
        (exit 251)
    }

    function SetExitCodeIfFileIsNotExecutable {
        (exit 250)
    }

    function SetExitCodeIfPassNorFail {
        (exit 131)
    }
# </code>

### exception functions ###
# <code>
    # <summary>
    # Checks if input parameter is null,
    # and returns exit code given result.
    # </summary>
    # <return>exit code</return>
    function CheckIfVarIsNull {
        if [[ -z "$1" ]]; then
            SetExitCodeIfVarIsNull; SaveThisExitCode
        else
            true; SaveThisExitCode
        fi
    }

    # <summary>
    # Checks if file exists,
    # and returns exit code if failed.
    # </summary>
    # <return>exit code</return>
    function CheckIfFileIsNull {
        if [[ ! -e $1 ]]; then
            SetExitCodeIfFileOrDirIsNull; SaveThisExitCode
        else
            true; SaveThisExitCode
        fi
    }

    # <summary>
    # Checks if directory exists,
    # and returns exit code if failed.
    # </summary>
    # <return>exit code</return>
    function CheckIfDirIsNull {
        if [[ ! -d $1 ]]; then
            SetExitCodeIfFileOrDirIsNull; SaveThisExitCode
        else
            true; SaveThisExitCode
        fi
    }

    # <summary>
    # Checks if file is executable,
    # and returns exit code if failed.
    # </summary>
    # <return>exit code</return>
    function CheckIfFileIsExecutable {
        if [[ ! -x $1 ]]; then
            SetExitCodeIfFileIsNotReadable; SaveThisExitCode
        else
            true; SaveThisExitCode
        fi
    }

    # <summary>
    # Checks if file is readable,
    # and returns exit code if failed.
    # </summary>
    # <return>exit code</return>
    function CheckIfFileIsReadable {
        if [[ ! -r $1 ]]; then
            SetExitCodeIfFileIsNotReadable; SaveThisExitCode
        else
            true; SaveThisExitCode
        fi
    }

    # <summary>
    # Checks if file is writable,
    # and returns exit code if failed.
    # </summary>
    # <return>exit code</return>
    function CheckIfFileIsWritable {
        if [[ ! -w $1 ]]; then
            SetExitCodeIfFileIsNotWritable; SaveThisExitCode
        else
            true; SaveThisExitCode
        fi
    }
# </code>

### special functions ###
# <code>
    # <summary>
    # Checks if current user is sudo/root.
    # </summary>
    # <return>exit code</return>
    function CheckIfUserIsRoot {
        if [[ $( whoami ) != "root" ]]; then
            local str_thisFile=$( echo ${0##/*} )
            CheckIfFileIsNull $str_thisFile &> /dev/null
            echo -en "\e[33mWARNING:\e[0m"" Script must execute as root. "

            if [[ $int_thisExitCode -eq 0 ]]; then
                readonly str_thisFile=$( echo $str_thisFile | cut -d '/' -f2 )
                echo -e " In terminal, run:\n\t'sudo bash $str_thisFile'"
            fi

            ExitWithThisExitCode
        fi
    }

    # <summary>
    # Output pass or fail statement given exit code.
    # </summary>
    # <return>exit code</return>
    function EchoPassOrFailThisExitCode {
        CheckIfVarIsNull $1 &> /dev/null

        if [[ $int_thisExitCode -eq 0 ]]; then
            echo -en "$1 "
        fi

        case "$int_thisExitCode" in
            0)
                echo -e "\e[32mSuccessful. \e[0m";;
            131)
                echo -e "\e[33mSkipped. \e[0m";;
            *)
                echo -e "\e[31mFailed. \e[0m";;
        esac
    }

    # <summary>
    # Output pass or fail test-case given exit code.
    # </summary>
    # <return>exit code</return>
    function EchoPassOrFailThisTestCase {
        str_testCaseName=$1
        CheckIfVarIsNull $str_testCaseName &> /dev/null

        if [[ $int_thisExitCode -eq 0 ]]; then
            str_testCaseName="TestCase"
        fi

        case "$int_thisExitCode" in
            0)
                echo -e "\e[32mPASS:\e[0m""\t$str_testCaseName";;
            *)
                echo -e " \e[33mFAIL:\e[0m""\t$str_testCaseName";;
        esac
    }

    # <summary>
    # Output variable given if valid.
    # </summary>
    # <return>exit code</return>
    function EchoVarIfVarIsNotNull {
        CheckIfVarIsNull $1 &> /dev/null

        if [[ $int_thisExitCode -eq 0 ]]; then
            echo $1
        fi
    }
# </code>

### general functions ###
# <code>
    # <summary>
    # Change ownership of given file to current user.
    # NOTE: $UID is intelligent enough to differentiate between the two
    # </summary>
    # <return>exit code</return>
    function ChangeOwnershipOfFileOrDir {
        CheckIfVarIsNull $1 &> /dev/null

        while [[ $int_thisExitCode -eq 0 ]]; do
            CheckIfVarIsNull $1 &> /dev/null
            # echo '$UID =='"'$UID'"
            chown -f $UID $1 && ( true; SaveThisExitCode)
            break
        done

        EchoPassOrFailThisExitCode; ParseThisExitCode
    }

    # <summary>
    # Checks if two given files are the same, in composition.
    # </summary>
    # <return>exit code</return>
    function CheckIfTwoFilesAreSame {
        echo -e "Verifying two files... "

        while [[ $int_thisExitCode -eq 0 ]]; do
            CheckIfVarIsNull $1 &> /dev/null
            CheckIfVarIsNull $2 &> /dev/null
            CheckIfFileIsNull $1 &> /dev/null
            CheckIfFileIsNull $2 &> /dev/null
            CheckIfFileIsReadable $1 &> /dev/null
            CheckIfFileIsReadable $2 &> /dev/null

            if cmp -s "$1" "$2"; then
                echo -e 'Positive Match.\n\t"%s"\n\t"%s"' "$1" "$2"
            else
                echo -e 'False Match.\n\t"%s"\n\t"%s"' "$1" "$2"
                false; SaveThisExitCode
            fi

            break
        done

        EchoPassOrFailThisExitCode; ParseThisExitCode
    }

    # <summary>
    # Checks if two given files are the same, in composition.
    # </summary>
    # <return>exit code</return>
    function CreateBackupFromFile {
        echo -en "Backing up file... "
        declare -lr str_file=$1
        CheckIfVarIsNull $str_file &> /dev/null
        CheckIfFileIsNull $str_file &> /dev/null
        CheckIfFileIsReadable $str_file &> /dev/null

        if [[ $int_thisExitCode -eq 0 ]]; then
            declare -r str_suffix=".old"
            declare -r str_dir=$( dirname $1 )
            declare -ar arr_dir=( $( ls -1v $str_dir | grep $str_file | grep $str_suffix | uniq ) )

            if [[ "${#arr_dir[@]}" -ge 1 ]]; then           # positive non-zero count
                # <parameters>
                    declare -ir int_maxCount=5
                    str_line=${arr_dir[0]}
                    str_line=${str_line%"${str_suffix}"}    # substitution
                    str_line=${str_line##*.}                # ditto
                # </parameters>

                if [[ "${str_line}" -eq "$(( ${str_line} ))" ]] 2> /dev/null; then  # check if string is a valid integer
                    declare -ir int_firstIndex="${str_line}"
                else
                    false; SaveThisExitCode                                         # NOTE: redundant?
                fi

                for str_element in ${arr_dir[@]}; do
                    if cmp -s $str_thisFile $str_element; then
                        false; SaveThisExitCode
                        break
                    fi
                done

                # if cmp -s $str_thisFile ${arr_dir[-1]}; then        # if latest backup is same as original file, exit
                #     true; SaveThisExitCode
                # fi

                while [[ ${#arr_dir[@]} -ge $int_maxCount ]]; do    # before backup, delete all but some number of backup files
                    if [[ -e ${arr_dir[0]} ]]; then
                        rm ${arr_dir[0]}
                        break
                    fi
                done

                if cmp -s $str_file ${arr_dir[0]}; then             # if *first* backup is same as original file, exit
                    false; SaveThisExitCode
                fi

                # <parameters>
                    str_line=${arr_dir[-1]%"${str_suffix}"}         # substitution
                    str_line=${str_line##*.}                        # ditto
                # </parameters>

                if [[ "${str_line}" -eq "$(( ${str_line} ))" ]] 2> /dev/null; then  # check if string is a valid integer
                    declare -i int_lastIndex="${str_line}"
                else
                    false; SaveThisExitCode
                fi

                (( int_lastIndex++ ))                                               # counter

                if [[ $str_file -nt ${arr_dir[-1]} && ! ( $str_file -ef ${arr_dir[-1]} ) ]]; then       # source file is newer and different than backup, add to backups
                    cp $str_file "${str_file}.${int_lastIndex}${str_suffix}"
                # elif [[ $str_file -ot ${arr_dir[-1]} && ! ( $str_file -ef ${arr_dir[-1]} ) ]]; then
                #     false; SaveThisExitCode
                else
                    false; SaveThisExitCode
                fi
            else
                cp $str_file "${str_file}.0${str_suffix}"           # no backups, create backup
                SaveThisExitCode                                    # NOTE: redundant?
            fi
        fi

        EchoPassOrFailThisExitCode
        ParseThisExitCode

        if [[ $int_thisExitCode -ne 0 ]]; then
            echo -e "No changes from most recent backup."
        fi
    }

    # <summary>
    # Creates a directory.
    # </summary>
    # <return>exit code</return>
    function CreateDir {
        echo -en "Creating directory... "

        while [[ $int_thisExitCode -eq 0 ]]; do
            CheckIfVarIsNull $1 &> /dev/null
            CheckIfFileIsNull $1 &> /dev/null
            mkdir -p $1 &> /dev/null && ( true; SaveThisExitCode)
            break
        done

        EchoPassOrFailThisExitCode; ParseThisExitCode
    }

    # <summary>
    # Creates a file.
    # </summary>
    # <return>exit code</return>
    function CreateFile {
        echo -en "Creating file... "

        while [[ $int_thisExitCode -eq 0 ]]; do
            CheckIfVarIsNull $1 &> /dev/null
            CheckIfFileIsNull $1 &> /dev/null
            touch $1 &> /dev/null && ( true; SaveThisExitCode)
            break
        done

        EchoPassOrFailThisExitCode; ParseThisExitCode
    }

    # <summary>
    # Deletes a file.
    # </summary>
    # <return>exit code</return>
    function DeleteFile {
        echo -en "Deleting file... "

        while [[ $int_thisExitCode -eq 0 ]]; do
            CheckIfVarIsNull $1 &> /dev/null
            CheckIfFileIsNull $1 &> /dev/null
            rm $1 &> /dev/null && ( true; SaveThisExitCode)
            break
        done

        EchoPassOrFailThisExitCode; ParseThisExitCode
    }

    # <summary>
    # Reads a file.
    # </summary>
    # <return>string array</return>
    function ReadFile {
        echo -en "Reading file... "

        while [[ $int_thisExitCode -eq 0 ]]; do
            CheckIfVarIsNull $1 &> /dev/null
            CheckIfFileIsNull $1 &> /dev/null
            CheckIfFileIsReadable $1 &> /dev/null

            while read str_line1; do
                echo $str_line1 || ( SetExitCodeIfFileIsNotReadable; break )
            done < $1
            break
        done

        EchoPassOrFailThisExitCode; ParseThisExitCode
    }

    # <summary>
    # Ask for Yes/No answer, return exit code.
    # Default selection is N/false.
    # </summary>
    # <return>exit code</return>
    function ReadInput {
        CheckIfVarIsNull $1 &> /dev/null

        # <parameters> #
        declare -il int_count=0
        declare -lir int_maxCount=2
        declare -lr str_output1=""

        if [[ $int_thisExitCode -eq 0 ]]; then
            declare -lr str_output1=$1
        fi
        # </parameters> #

        true; SaveThisExitCode

        while [[ $int_thisExitCode -eq 0 ]]; do
            # <summary>
            # After given number of attempts, input is set to default: false.
            # </summary>
            if [[ $int_count -gt $int_maxCount ]]; then
                str_input1="N"
                echo -e "Exceeded max attempts. Default selection: \e[30;42m$str_input1\e[0m"
                false; SaveThisExitCode; break
            fi

            echo -en "$1 \e[30;43m[Y/n]:\e[0m "
            read str_input1
            str_input1=$( echo $str_input1 | tr '[:lower:]' '[:upper:]' )

            # <summary>
            # Check if string is a valid input.
            # </summary>
            case $str_input1 in
                "Y")
                    true; SaveThisExitCode; break;;
                "N")
                    false; SaveThisExitCode; break;;
            esac

            # <summary>
            # Input is invalid, increment counter.
            # </summary>
            echo -en "\e[33mInvalid input.\e[0m "
            (( int_count++ ))
        done

        echo
    }

    # <summary>
    # Ask for multiple choice, up to eight choices.
    # Default selection is first choice.
    # </summary>
    # <return>string</return>
    function ReadInputFromMultipleChoiceIgnoreCase {
        # <parameters> #
        declare -il int_count=0
        declare -lir int_maxCount=2
        declare -lr str_output1=""

        if [[ $int_thisExitCode -eq 0 ]]; then
            declare -lr str_output1=$1
        fi
        # </parameters> #

        CheckIfVarIsNull $2 &> /dev/null

        while [[ $int_thisExitCode -eq 0 ]]; do
            # <summary>
            # After given number of attempts, input is set to default: false.
            # </summary>
            if [[ $int_count -gt $int_maxCount ]]; then
                str_input1="$2"
                echo -e "Exceeded max attempts. Default selection: \e[30;42m$str_input1\e[0m"
                false; SaveThisExitCode; break
            fi

            echo -en "$str_output1 "
            read str_input1

            # <summary>
            # Check if string is a valid input.
            # </summary>
            case $str_input1 in
                $2|$3|$4|$5|$6|$7|$8|$9)
                    true; SaveThisExitCode; break;
            esac

            # <summary>
            # Input is invalid, increment counter.
            # </summary>
            echo -en "\e[33mInvalid input.\e[0m "
            (( int_count++ ))
        done

        EchoVarIfVarIsNotNull $str_input1
    }

    # <summary>
    # Ask for multiple choice, up to eight choices.
    # Default selection is first choice.
    # </summary>
    # <return>string</return>
    function ReadInputFromMultipleChoiceUpperCase {
        # <parameters> #
        declare -il int_count=0
        declare -lir int_maxCount=2
        declare -lr str_output1=""

        if [[ $int_thisExitCode -eq 0 ]]; then
            declare -lr str_output1=$1
        fi
        # </parameters> #

        CheckIfVarIsNull $2 &> /dev/null

        while [[ $int_thisExitCode -eq 0 ]]; do
            # <summary>
            # After given number of attempts, input is set to default: false.
            # </summary>
            if [[ $int_count -gt $int_maxCount ]]; then
                str_input1="$2"
                echo -e "Exceeded max attempts. Default selection: \e[30;42m$str_input1\e[0m"
                false; SaveThisExitCode; break
            fi

            echo -en "$str_output1 "
            read str_input1
            str_input1=$( echo $str_input1 | tr '[:lower:]' '[:upper:]' )

            # <summary>
            # Check if string is a valid input.
            # </summary>
            case $str_input1 in
                $2|$3|$4|$5|$6|$7|$8|$9)
                    true; SaveThisExitCode; break;
            esac

            # <summary>
            # Input is invalid, increment counter.
            # </summary>
            echo -en "\e[33mInvalid input.\e[0m "
            (( int_count++ ))
        done

        EchoVarIfVarIsNotNull $str_input1
    }

    # <summary>
    # Ask for number, within a given range.
    # Default selection is first choice.
    # </summary>
    # <return>int</return>
    function ReadInputFromRangeOfNums {
        # <parameters> #
        declare -il int_count=0
        declare -lir int_maxCount=2
        # </parameters> #

        while [[ $int_thisExitCode -eq 0 ]]; do
            # <summary>
            # After given number of attempts, input is set to default: min value.
            # </summary>
            if [[ $int_count -gt $int_maxCount ]]; then
                str_input1=$2
                echo -e "Exceeded max attempts. Default selection: \e[30;42m$str_input1\e[0m"
                true; SaveThisExitCode; break
            fi

            echo -en "$1 "
            read str_input1

            # <summary>
            # Check if string is a valid integer and within given range.
            # </summary>
            if [[ $str_input1 -ge $2 && $str_input1 -le $3 && ( "${str_input1}" -ge "$(( ${str_input1} ))" ) ]] 2> /dev/null;; then
                true; SaveThisExitCode; break
            fi

            # <summary>
            # Input is invalid, increment counter.
            # </summary>
            echo -en "\e[33mInvalid input.\e[0m "
            (( int_count++ ))
        done

        EchoVarIfVarIsNotNull $str_input1
    }

    # <summary>
    # Test network connection to Internet.
    # Ping DNS servers by address and name.
    # </summary>
    # <return>exit code</return>
    function TestNetwork {
        echo -en "Testing Internet connection... "
        ( ping -q -c 1 8.8.8.8 &> /dev/null || ping -q -c 1 1.1.1.1 &> /dev/null ) || false
        SaveThisExitCode; EchoPassOrFailThisExitCode

        echo -en "Testing connection to DNS... "
        ( ping -q -c 1 www.google.com &> /dev/null && ping -q -c 1 www.yandex.com &> /dev/null ) || false
        SaveThisExitCode; EchoPassOrFailThisExitCode

        if [[ $int_thisExitCode -ne 0 ]]; then
            echo -e "Failed to ping Internet/DNS servers. Check network settings or firewall, and try again."
        fi

        echo
    }

    # <summary>
    # NOTE: not working!
    # Input variable #2 ( $2 ) is the name of the variable we wish to point to.
    # This may help with calling/parsing arrays.
    # When passing the var, write the name without " $ ".
    # </summary>
    # <return>exit code</return>
    # function WriteArrayToFile {
    #     SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)    # NOTE: necessary for newline preservation in arrays and files
    #     IFS=$'\n'      # Change IFS to newline char
    #     var_input=$2

    #     echo -en "Writing to file... "

    #     while [[ $int_thisExitCode -eq 0 ]]; do
    #         CheckIfVarIsNull $1 &> /dev/null
    #         CheckIfVarIsNull $var_input &> /dev/null
    #         CheckIfFileIsNull $1 &> /dev/null
    #         CheckIfFileIsReadable $1 &> /dev/null
    #         CheckIfFileIsWritable $1 &> /dev/null

    #         case ${!var_input[@]} in                                                    # check number of key-value pairs
    #             0)                                                                      # check if var is not an array
    #                 echo -e $var_input >> $1 || ( SetExitCodeOnError; SaveThisExitCode );;
    #             *)                                                                      # check if var is an array
    #                 for str_element in ${var_input[@]}; do
    #                     echo -e $str_element >> $1 || ( SetExitCodeOnError; SaveThisExitCode )
    #                 done;;
    #         esac

    #         break
    #     done

    #     IFS=$SAVEIFS
    #     EchoPassOrFailThisExitCode; ParseThisExitCode
    # }

    # <summary>
    # Input variable #2 ( $2 ) is the name of the variable we wish to point to.
    # This may help with calling/parsing arrays.
    # When passing the var, write the name without " $ ".
    # </summary>
    # <return>exit code</return>
    function WriteVarToFile {
        SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)    # NOTE: necessary for newline preservation in arrays and files
        IFS=$'\n'      # Change IFS to newline char

        echo -en "Writing to file... "

        while [[ $int_thisExitCode -eq 0 ]]; do
            CheckIfVarIsNull $1 &> /dev/null
            CheckIfVarIsNull $2 &> /dev/null
            CheckIfFileIsNull $1 &> /dev/null
            CheckIfFileIsReadable $1 &> /dev/null
            CheckIfFileIsWritable $1 &> /dev/null
            echo -e $2 >> $1 &> /dev/null || false; SaveThisExitCode
            break
        done

        IFS=$SAVEIFS
        EchoPassOrFailThisExitCode; ParseThisExitCode
    }
# </code>

### executive functions ###
# <code>
    # <summary>
    # Check linux distro
    # </summary>
    # <return>exit code</return>
    function CheckCurrentDistro {
        if [[ $( command -v apt ) == "/usr/bin/apt" ]]; then
            true; SaveThisExitCode
        else
            echo -e "\e[33mWARNING:\e[0m"" Unrecognized Linux distribution; Apt not installed. Skipping..."
            false; SaveThisExitCode
        fi
    }

    # <summary>
    # Clone given GitHub repositories.
    # </summary>
    # <return>exit code</return>
    function CloneOrUpdateGitRepositories
    {
        echo "Cloning/Updating Git repos..."

        # <parameters>
        declare -lr str_dir1="/root/source/repos"
        # </parameters>

        CreateDir $str_dir1 &> /dev/null
        CheckIfFileIsWritable $str_dir1 &> /dev/null

        if [[ $int_thisExitCode -eq 0 ]]; then
            # <summary>
            # List of Git repositories.
            # Example: "username/reponame"
            # </summary>
            # <parameters>
            declare -alr arr_repo=(
                "corna/me_cleaner"
                "dt-zero/me_cleaner"
                "foundObjects/zram-swap"
                "portellam/Auto-Xorg"
                "portellam/deploy-VFIO-setup"
                "pyllyukko/user.js"
                "StevenBlack/hosts"
            )
            # </parameters>

            for str_repo in ${arr_repo[@]}; do
                cd $str_dir1

                # <parameters>
                local str_userName=$( basename $str_repo )
                # </parameters>

                CheckIfDirIsNull ${str_dir1}${str_userName} &> /dev/null

                if [[ $int_thisExitCode -ne 0 ]]; then
                    CreateDir ${str_dir1}${str_userName} &> /dev/null
                fi

                CheckIfDirIsNull ${str_dir1}${str_repo} &> /dev/null

                if [[ $int_thisExitCode -eq 0 ]]; then
                    cd ${str_dir1}${str_repo}
                    git pull https://github.com/$str_repo
                else
                    ReadInput "Clone repo '$str_repo'?"

                    if [[ $int_thisExitCode -eq 0 ]]; then
                        cd ${str_dir1}${str_userName}
                        git clone https://github.com/$str_repo || SetExitCodeIfPassNorFail
                    fi
                fi
            done
        fi

        SaveThisExitCode; EchoPassOrFailThisExitCode; ParseThisExitCode

        if [[ $int_thisExitCode -eq 131 ]]; then
            echo -e "One or more Git repositories could not be cloned.";;
        fi
    }

    # <summary>
    # Install from Debian repositories.
    # </summary>
    # <return>exit code</return>
    function InstallFromDebianRepos {
        echo -e "Installing from $( lsb_release -is ) $( uname -o ) repositories..."
        ReadInput "Auto-accept install prompts? "

        case "$int_thisExitCode" in
            0)
                local str_args="-y";;
            *)
                local str_args="";;
        esac

        # <summary>
        # Update and upgrade local packages
        # </summary>
        apt clean
        apt update

        # <summary>
        # Desktop environment checks
        # </summary>
        str_aptCheck=""
        str_aptCheck=$( apt list --installed plasma-desktop lxqt )      # Qt DE (KDE-plasma, LXQT)

        if [[ $str_aptCheck != "" ]]; then
            apt install -y plasma-discover-backend-flatpak
        fi

        str_aptCheck=""
        str_aptCheck=$( apt list --installed gnome xfwm4 )              # GNOME DE (gnome, XFCE)

        if [[ $str_aptCheck != "" ]]; then
            apt install -y gnome-software-plugin-flatpak
        fi

        echo    # output padding

        # <summary>
        # APT packages sorted by type.
        # </summary>
        # <parameters>
        str_aptAll=""
        str_aptDeveloper=""
        str_aptDrivers="steam-devices"
        str_aptGames=""
        str_aptInternet="firefox-esr filezilla"
        str_aptMedia="vlc"
        str_aptOffice="libreoffice"
        str_aptPrismBreak=""
        str_aptSecurity="apt-listchanges bsd-mailx fail2ban gufw ssh ufw unattended-upgrades"
        str_aptSuites="debian-edu-install science-all"
        str_aptTools="apcupsd bleachbit cockpit curl flashrom git grub-customizer java-common lm-sensors neofetch python3 qemu rtl-sdr synaptic unzip virt-manager wget wine youtube-dl zram-tools"
        str_aptUnsorted=""
        str_aptVGAdrivers="nvidia-detect xserver-xorg-video-all xserver-xorg-video-amdgpu xserver-xorg-video-ati xserver-xorg-video-cirrus xserver-xorg-video-fbdev xserver-xorg-video-glide xserver-xorg-video-intel xserver-xorg-video-ivtv-dbg xserver-xorg-video-ivtv xserver-xorg-video-mach64 xserver-xorg-video-mga xserver-xorg-video-neomagic xserver-xorg-video-nouveau xserver-xorg-video-openchrome xserver-xorg-video-qxl/ xserver-xorg-video-r128 xserver-xorg-video-radeon xserver-xorg-video-savage xserver-xorg-video-siliconmotion xserver-xorg-video-sisusb xserver-xorg-video-tdfx xserver-xorg-video-trident xserver-xorg-video-vesa xserver-xorg-video-vmware"
        # </parameters>

        # <summary>
        # Select and Install software sorted by type.
        # </summary>
        function InstallAptByType {
            if [[ $1 != "" ]]; then
                echo -e $2

                if [[ $1 == *" "* ]]; then
                    declare -il int_i=1

                    while [[ $( echo $1 | cut -d ' ' -f$int_i ) ]]; do
                        echo -e "\t"$( echo $1 | cut -d ' ' -f$int_i )
                        (( int_i++ ))                                   # counter
                    done
                else
                    echo -e "\t$1"
                fi

                ReadInput

                if [[ $int_thisExitCode -eq 0 ]]; then
                    str_aptAll+="$1 "
                fi

                echo    # output padding
            fi
        }

        InstallAptByType $str_aptUnsorted "Select given software?"
        InstallAptByType $str_aptDeveloper "Select Development software?"
        InstallAptByType $str_aptGames "Select games?"
        InstallAptByType $str_aptInternet "Select Internet software?"
        InstallAptByType $str_aptMedia "Select multi-media software?"
        InstallAptByType $str_aptOffice "Select office software?"
        InstallAptByType $str_aptPrismBreak "Select recommended \"Prism break\" software?"
        InstallAptByType $str_aptSecurity "Select security tools?"
        InstallAptByType $str_aptSuites "Select software suites?"
        InstallAptByType $str_aptTools "Select software tools?"
        InstallAptByType $str_aptVGAdrivers "Select VGA drivers?"

        if [[ $str_aptAll != "" ]]; then
            apt install $str_args $str_aptAll
        fi

        # <summary>
        # Clean up
        # </summary>
        apt autoremove $str_args
    }

    # <summary>
    # Install from Flathub software repositories.
    # </summary>
    # <return>exit code</return>
    function InstallFromFlathubRepos {
        echo -e "Installing from alternative $( uname -o ) repositories..."

        # <summary>
        # Flatpak
        # </summary>
        if [[ $( command -v flatpak ) != "/usr/bin/flatpak" ]]; then
            echo -e "WARNING: Flatpak not installed. Skipping..."
            false; SaveThisExitCode
        else
            ReadInput "Auto-accept install prompts? "

            case "$int_thisExitCode" in
                0)
                    local str_args="-y";;
                *)
                    local str_args="";;
            esac

            # <summary>
            # Add remote repository.
            # </summary>
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

            # <summary>
            # Update local packages.
            # </summary>
            flatpak update $str_args
            echo    # output padding

            # <summary>
            # Flatpak packages sorted by type.
            # </summary>
            # <parameters>
                str_flatpakAll=""
                str_flatpakUnsorted="com.adobe.Flash-Player-Projector com.calibre_ebook.calibre com.makemkv.MakeMKV com.obsproject.Studio com.poweriso.PowerISO com.stremio.Stremio com.valvesoftware.Steam com.valvesoftware.SteamLink com.visualstudio.code com.vscodium.codium fr.handbrake.ghb io.github.Hexchat io.gitlab.librewolf-community nz.mega.MEGAsync org.bunkus.mkvtoolnix-gui org.filezillaproject.Filezilla org.freedesktop.LinuxAudio.Plugins.TAP org.freedesktop.LinuxAudio.Plugins.swh org.freedesktop.Platform org.freedesktop.Platform.Compat.i386 org.freedesktop.Platform.GL.default org.freedesktop.Platform.GL.default org.freedesktop.Platform.GL32.default org.freedesktop.Platform.GL32.nvidia-460-91-03 org.freedesktop.Platform.VAAPI.Intel.i386 org.freedesktop.Platform.ffmpeg-full org.freedesktop.Platform.openh264 org.freedesktop.Sdk org.getmonero.Monero org.gnome.Platform org.gtk.Gtk3theme.Breeze org.kde.KStyle.Adwaita org.kde.Platform org.kde.digikam org.kde.kdenlive org.keepassxc.KeePassXC org.libreoffice.LibreOffice org.mozilla.Thunderbird org.openshot.OpenShot org.videolan.VLC org.videolan.VLC.Plugin.makemkv org.libretro.RetroArch"
                str_flatpakPrismBreak="" # include from all, monero etc.
            # </parameters>

            # <summary>
            # Select and Install software sorted by type.
            # </summary>
            # <code>
                function InstallFlatpakByType {
                    if [[ $1 != "" ]]; then
                        echo -e $2

                        if [[ $1 == *" "* ]]; then
                            declare -il int_i=1

                            while [[ $( echo $1 | cut -d ' ' -f$int_i ) ]]; do
                                echo -e "\t"$( echo $1 | cut -d ' ' -f$int_i )
                                (( int_i++ ))                                   # counter
                            done
                        else
                            echo -e "\t$1"
                        fi

                        ReadInput

                        if [[ $int_thisExitCode -eq 0 ]]; then
                            str_flatpakAll+="$1 "
                        fi

                        echo    # output padding
                    fi
                }

                InstallAptByType $str_flatpakUnsorted "Select given Flatpak software?"
                InstallAptByType $str_flatpakPrismBreak "Select recommended Prism Break Flatpak software?"

                if [[ $str_flatpakAll != "" ]]; then
                    echo -e "Install selected Flatpak apps?"
                    apt install $str_args $str_aptAll
                fi
            # </code>
        fi

        ParseThisExitCode
    }

    # <summary>
    # Install from Git repositories.
    # </summary>
    # <return>exit code</return>
    function InstallFromGitRepos
    {
        echo "Executing Git scripts..."

        # <summary>
        # Prompt user to execute script or skip.
        # </summary>
        function ExecuteScript {
            cd $str_dir1

            # <parameters>
            local str_dir2=$( echo "$1" | awk -F'/' '{print $1"/"$2}' )
            local str_script=$( basename $str_dir2 )
            # </parameters>

            CheckIfDirIsNull $str_script &> /dev/null

            if [[ $int_thisExitCode -eq 0 ]]; then
                ReadInput "Execute script '$str_script'?"

                if [[ $int_thisExitCode -eq 0 ]]; then
                    cd $str_dir2
                    CheckIfFileIsExecutable $str_script &> /dev/null

                    if [[ $int_thisExitCode -eq 0 ]]; then
                        sudo bash $str_script || SetExitCodeIfPassNorFail
                    fi

                    cd $str_dir1
                fi
            fi
        }

        # <parameters>
        declare -lr str_dir1="/root/source/repos"
        # </parameters>

        CreateDir $str_dir1 &> /dev/null
        CheckIfFileIsWritable $str_dir1 &> /dev/null

        if [[ $int_thisExitCode -eq 0 ]]; then
            # <summary>
            # portellam/Auto-Xorg
            # Install system service from repository.
            # Finds first available non-VFIO VGA/GPU and binds to Xorg.
            # </summary>
            local str_scriptDir="portellam/Auto-Xorg/installer.bash"
            ExecuteScript $str_scriptDir

            # <summary>
            # StevenBlack/hosts
            # </summary>
            local str_scriptDir="StevenBlack/hosts"
            CheckIfDirIsNull $str_scriptDir

            if [[ $int_thisExitCode -eq 0 ]]; then
                cd $str_scriptDir
                CreateBackupFromFile "/etc/hosts" &> /dev/null

                if [[ $int_thisExitCode -eq 0 ]]; then
                    cp hosts "/etc/hosts" || SetExitCodeIfPassNorFail
                fi

                cd $str_dir1
            fi

            # <summary>
            # pyllyukko/user.js
            # </summary>
            local str_scriptDir="pyllyukko/user.js"
            CheckIfDirIsNull $str_scriptDir

            if [[ $int_thisExitCode -eq 0]]; then
                cd $str_scriptDir
                make debian_locked.js && (
                    CreateBackupFromFile "/etc/firefox-esr/firefox-esr.js" &> /dev/null

                    if [[ $int_thisExitCode -eq 0]]; then
                        cp debian_locked.js "/etc/firefox-esr/firefox-esr.js" &> /dev/null || SetExitCodeIfPassNorFail
                    fi
                )
                cd $str_dir1
            fi

            # <summary>
            # foundObjects/zram-swap
            # </summary>
            local str_scriptDir="foundObjects/zram-swap/install.sh"
            ExecuteScript $str_scriptDir
        fi

        ParseThisExitCode
    }

    # <summary>
    # Install from Snap software repositories.
    # </summary>
    # <return>exit code</return>
    function InstallFromSnapRepos {
        echo -e "Installing from alternative $( uname -o ) repositories..."

        # <summary>
        # Snap
        # </summary>
        if [[ $( command -v snap ) != "/usr/bin/snap" ]]; then
            echo -e "WARNING: Snap not installed. Skipping..."
            false; SaveThisExitCode
        else
            ReadInput "Auto-accept install prompts? "

            case "$int_thisExitCode" in
                0)
                    local str_args="-y";;
                *)
                    local str_args="";;
            esac

            # <summary>
            # Update local packages.
            # </summary>
            flatpak update $str_args
            echo    # output padding

            # <summary>
            # Snap packages sorted by type.
            # </summary>
            # <parameters>
                str_snapAll=""
                str_snapUnsorted=""
            # </parameters>

            # <summary>
            # Select and Install software sorted by type.
            # </summary>
            # <code>
                function InstallSnapByType {
                    if [[ $1 != "" ]]; then
                        echo -e $2

                        if [[ $1 == *" "* ]]; then
                            declare -il int_i=1

                            while [[ $( echo $1 | cut -d ' ' -f$int_i ) ]]; do
                                echo -e "\t"$( echo $1 | cut -d ' ' -f$int_i )
                                (( int_i++ ))                                   # counter
                            done
                        else
                            echo -e "\t$1"
                        fi

                        ReadInput

                        if [[ $int_thisExitCode -eq 0 ]]; then
                            str_snapAll+="$1 "
                        fi

                        echo    # output padding
                    fi
                }

                InstallSnapByType $str_snapUnsorted "Select given Snap software?"

                if [[ $str_snapAll != "" ]]; then
                    echo -e "Install selected Snap apps?"
                    apt install $str_args $str_snapAll
                fi
            # </code>
        fi

        ParseThisExitCode
    }

    # <summary>
    # Set software repositories for Debian Linux.
    # </summary>
    # <return>exit code</return>
    function ModifyDebianRepos {
        echo -e "Modifying $( lsb_release -is ) $( uname -o ) repositories..."

        # <parameters>
        declare -lr str_file1="/etc/apt/sources.list"
        local str_sources=""
        declare -lr str_newFile1="${str_file1}_new"
        declare -lr str_releaseName=$( lsb_release -sc )
        declare -lr str_releaseVer=$( lsb_release -sr )
        # </parameters>

        # <summary>
        # Create backup or restore from backup.
        # </summary>
        CheckIfFileIsNull $str_file1 &> /dev/null

        if [[ $int_thisExitCode -eq 0 ]]; then
            CreateBackupFromFile $str_file1
        fi

        # <summary>
        # Setup optional sources.
        # </summary>
        while true; do
            ReadInput "Include 'contrib' sources?"

            case $int_thisExitCode in
                0)
                    str_sources+="contrib";;
                *)
                    break;;
            esac

            ReadInput "Include 'non-free' sources?"

            case $int_thisExitCode in
                0)
                    str_sources+=" non-free";;
                *)
                    break;;
            esac

            break
        done

        # <summary>
        # Setup mandatory sources.
        # </summary>
        while [[ $int_thisExitCode -eq 0 ]]; do
            echo -e "Repositories: Enter one valid option or none for default (Current branch: $str_releaseName)."
            echo -e "\t\n\e[33mWARNING:\e[0m: It is NOT possible to revert from a Non-stable branch back to a Stable or $str_releaseName branch."
            echo -e "\tRelease branches:"
            echo -e "\t\t'stable'\t== '$str_releaseName'"
            echo -e "\t\t'testing'\t*more recent updates, slightly less stability"
            echo -e "\t\t'unstable'\t*most recent updates, least stability. NOT recommended."
            echo -e "\t\t'backports'\t== '$str_releaseName-backports'\t*optionally receive more recent updates."

            # <summary>
            # Apt sources
            # </summary>
            # <parameters>
            declare -lr str_branchName=$( ReadInputFromMultipleChoiceIgnoreCase "\tEnter option: " "stable" "testing" "unstable" "backports" )
            declare -al arr_sources=(
                "# debian $str_branchName"
                "# See https://wiki.debian.org/SourcesList for more information."
                "deb http://deb.debian.org/debian/ $str_branchName main $str_sources"
                "deb-src http://deb.debian.org/debian/ $str_branchName main $str_sources"
                $'\n'
                "deb http://deb.debian.org/debian/ $str_branchName-updates main $str_sources"
                "deb-src http://deb.debian.org/debian/ $str_branchName-updates main $str_sources"
                $'\n'
                "deb http://security.debian.org/debian-security/ $str_branchName-security main $str_sources"
                "deb-src http://security.debian.org/debian-security/ $str_branchName-security main $str_sources"
                "#"
            )
            # </parameters>

            # <summary>
            # Copy lines from original to temp file as comments.
            # </summary>
            DeleteFile $str_newFile1 &> /dev/null
            CreateFile $str_newFile1 &> /dev/null

            while read str_line1; do
                if [[ $str_line1 != "#"* ]]; then
                    str_line1="#$str_line1"
                fi

                WriteVarToFile $str_newFile1 $str_line1
            done < $str_file1

            DeleteFile $str_newFile1 &> /dev/null
            mv $str_newFile1 $str_file1 &> /dev/null || false && SaveThisExitCode

            # <summary>
            # Append to output.
            # </summary>
            case $str_branchName in
                # <summary>
                # Current branch with backports.
                # </summary>
                "backports")
                    declare -al arr_sources=(
                        $'\n'
                        "# debian $str_releaseVer/$str_releaseName"
                        "# See https://wiki.debian.org/SourcesList for more information."
                        "deb http://deb.debian.org/debian/ $str_releaseName main $str_sources"
                        "deb-src http://deb.debian.org/debian/ $str_releaseName main $str_sources"
                        $'\n'
                        "deb http://deb.debian.org/debian/ $str_releaseName-updates main $str_sources"
                        "deb-src http://deb.debian.org/debian/ $str_releaseName-updates main $str_sources"
                        $'\n'
                        "deb http://security.debian.org/debian-security/ $str_releaseName-security main $str_sources"
                        "deb-src http://security.debian.org/debian-security/ $str_releaseName-security main $str_sources"
                        "#"
                        "# debian $str_releaseVer/$str_releaseName $str_input2"
                        "deb http://deb.debian.org/debian $str_releaseName-$str_input2 main contrib non-free"
                        "deb-src http://deb.debian.org/debian $str_releaseName-$str_input2 main contrib non-free"
                        "#"
                    )

                    break;;
            esac

            # <summary>
            # Output to sources file.
            # </summary>
            case $str_branchName in
                "backports"|"testing"|"unstable")
                    while read str_line1; do
                        str_line1=${arr_sources[$int_i]}
                        WriteVarToFile "/etc/apt/sources.list.d/'$str_input2'.list" $str_line1
                    done < $str_file1;;
                *)
                    echo -e "\e[33mInvalid input.\e[0m";;
            esac

            DeleteFile $str_newFile1 &> /dev/null
            break
        done

        EchoPassOrFailThisExitCode; ParseThisExitCode

        # <summary>
        # Update packages on system.
        # </summary>
        apt clean || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
        apt update || ( SetExitCodeOnError; SaveThisExitCode )
        apt full-upgrade || ( SetExitCodeOnError; SaveThisExitCode )
        EchoPassOrFailThisExitCode; ParseThisExitCode
    }
# </code>

### main functions ###
# <code>

    ### NOTE: needs work.
    # <summary>
    # Display Help to console.
    # </summary>
    # <return>exit code</return>
    function Help {
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

    ### NOTE: needs work.
    # <summary>
    # Parse input parameters for given options.
    # </summary>
    # <return>exit code</return>
    function ParseInputParamForOptions {
        if [[ "$1" =~ ^- || "$1" == "--" ]]; then           # parse input parameters
            while [[ "$1" =~ ^-  ]]; do
                case $1 in
                    "")                                     # no option
                        SetExitCodeOnError
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
            SetExitCodeOnError
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

    # <summary>
    # Execute setup of all software repositories.
    # </summary>
    # <return>exit code</return>
    function ExecuteSetupOfSoftwareSources {
        CheckCurrentDistro

        if [[ $int_thisExitCode -eq 0 ]]; then
            ModifyDebianRepos
            InstallFromDebianRepos
        fi

        InstallFromFlathubRepos
        InstallFromSnapRepos

        echo -e "\n\e[33mWARNING:\e[0m If system update is/was prematurely stopped, to restart progress, execute in terminal:\n\t'sudo dpkg --configure -a"
    }

    # <summary>
    # Execute setup of GitHub repositories (of which that are executable and installable).
    # </summary>
    # <return>exit code</return>
    function ExecuteSetupOfGitRepos {
        if [[ $( command -v git ) == "/usr/bin/git" ]]; then
            CloneOrUpdateGitRepositories
            InstallFromGitRepos
        else
            EchoPassOrFailThisExitCode "\n\e[33mWARNING:\e[0m Git is not installed on this system."
        fi
    }

    # systemd #
    function AppendServices
    {
        echo -e "Appending files to Systemd..."

        # parameters #
        str_dir1="$(pwd)/$( basename $(find . -name services | uniq | head -n1 ))"
        str_pattern=".service"
        cd ${str_dir1}

        declare -a arr1=( $( ls | uniq | grep -Ev ${str_pattern} ))

        for str_inFile1 in ${arr1[@]}; do
            str_outFile1="/usr/sbin/${str_inFile1}"
            cp ${str_inFile1} ${str_outFile1}
            chown root ${str_outFile1}
            chmod +x ${str_outFile1}
        done

        declare -a arr1=( $( ls | uniq | grep ${str_pattern} ))

        for str_inFile1 in ${arr1[@]}; do
            declare -i int_fileNameLength=$((${#str_inFile1} - ${#str_pattern}))
            str_outFile1="/etc/systemd/system/${str_inFile1}"

            cp ${str_dir1}"/"${str_inFile1} ${str_outFile1}
            chown root ${str_outFile1}
            chmod +x ${str_outFile1}

            systemctl daemon-reload
            str_input1=""
            ReadInput "Enable/disable '${str_inFile1}'?"

            case ${str_input1} in
                "Y")
                    systemctl enable ${str_inFile1};;

                "N")
                    systemctl disable ${str_inFile1};;
            esac
        done

        systemctl daemon-reload
        echo -e "Appending files to Systemd... Complete."
    }

    # crontab #
    function AppendCron
    {
        # parameters #
        declare -a arr1=()
        str_outDir1="/etc/cron.d/"
        str_dir1=$(find .. -name files | uniq | head -n1)"/"

        # list of packages that have cron files (see below) #
        # NOTE: may change depend on content of cron files (ex: simple, common commands that are not from given specific packages, i.e "cp" or "rm")
        # NOTE: update here!
        declare -a arr_requiredPackages=(
            "flatpak"
            "ntpdate"
            "rsync"
            "snap"
        )

        if [[ $(command -v unattended-upgrades) == "" ]]; then
            arr_requiredPackages+=("apt")
        fi

        if [[ ${str_dir1} != "" ]]; then
            cd ${str_dir1}

            # list of cron files #
            arr1=$(ls *-cron)
        fi

        # how do i get the file name after the last delimiter "/" ? check other repos or check for pattern regex
        if [[ ${#arr1[@]} -gt 0 ]]; then
            echo -e "Appending cron entries..."

            for str_line1 in ${arr1}; do

                # update parameters #
                str_input1=""

                ReadInput "Append '${str_line1}'?"
                echo

                if [[ ${str_input1} == "Y" ]]; then

                    # parse list of packages that have cron files #
                    for str_line2 in ${arr_requiredPackages[@]}; do

                        # match given cron file, append only if package exists in system #
                        if [[ ${str_line1} == *"${str_line2}"* ]]; then
                            if [[ $(command -v ${str_line2}) != "" ]]; then
                                cp ${str_dir1}${str_line1} ${str_outDir1}${str_line1}
                                # echo -e "Appended file '${str_line1}'."

                            else
                                echo -e "WARNING: Missing required package '${str_line2}'. Skipping..."
                            fi
                        fi
                    done
                fi
            done

            echo -e "Review changes made. "

        else
            echo -e "WARNING: Missing files. Skipping..."
        fi

        # restart service #
        systemctl restart cron
    }

    # SSH #
    function ModifySSH
    {
        # parameters #
        str_input1=""
        ReadInput "Modify SSH?"

        if [[ $str_input1 = "Y" ]]; then
            if [[ $( command -v ssh ) != "" ]]; then
                declare -i int_count=0
                str_output1=""

                # prompt #
                while [[ ${int_count} -le 3 ]]; do

                    # default input #
                    if [ ${int_count} -gt 2 ]; then
                        str_sshAlt=22
                        echo -en "Exceeded max attempts! "

                    # read input #
                    else
                        echo -en "\tEnter a new IP Port number for SSH (leave blank for default): "
                        read str_sshAlt
                    fi

                    # match string with valid integer #
                    if [ "${str_sshAlt}" -eq "$(( ${str_sshAlt} ))" ] 2> /dev/null; then
                        declare -i int_result="${str_sshAlt}"

                        if [[ ${int_result} -gt 0 && ${int_result} -lt 65536 ]]; then
                            if [[ ${int_result} -gt 1000 ]]; then
                                if [[ ${int_result} == 22 ]]; then
                                    echo -e "Default value."

                                # append to output #
                                else
                                    str_output1+="\n#\nPort ${str_sshAlt}"
                                    break
                                fi

                            else
                                echo -e "Invalid selection. Available port range: 1000-65535"
                            fi

                        else
                            echo -e "Invalid integer. Valid port range: 1-65535."
                        fi

                    # false match string with valid integer #
                    else
                        echo -e "Invalid input."
                    fi

                    ((int_count++))
                done

                # backup and write to file #
                    str_file1="/etc/ssh/ssh_config"
                    str_oldFile1=${str_file1}"_old"

                    if [ -e ${str_file1} ]; then
                        cp ${str_file1} ${str_oldFile1}
                    fi

                    echo -e ${str_output} >> ${str_file1}

                # backup and write to file #
                    str_output1+="\nLoginGraceTime 1m\nPermitRootLogin prohibit-password\nMaxAuthTries 6\nMaxSessions 2"    # append to output
                    str_file1="/etc/ssh/ssh_config"
                    str_oldFile1=${str_file1}"_old"

                    if [ -e ${str_file1} ]; then
                        cp ${str_file1} ${str_oldFile1}
                    fi

                    echo -e ${str_output1} >> ${str_file1}

                systemctl restart ssh sshd  # restart services

            else
                echo -e "WARNING: SSH not installed! Skipping..."
            fi
        fi

        echo
    }

    # security #
    function ModifySecurity
    {
        echo -e "Configuring system security..."

        # parameters #
        bool_runOperationIfFileExists=false
        str_input1=""
        # str_packagesToRemove="atftpd nis rsh-redone-server rsh-server telnetd tftpd tftpd-hpa xinetd yp-tools"
        str_services="acpupsd cockpit fail2ban ssh ufw"     # include services to enable OR disable: cockpit, ssh, some/all packages installed that are a security-risk or benefit.

        # echo -e "Remove given apt packages?"
        # apt remove ${str_packagesToRemove}

        str_input1=""
        ReadInput "Disable given device interfaces (for storage devices only): USB, Firewire, Thunderbolt?"

        case ${str_input1} in
            "Y")
                echo 'install usb-storage /bin/true' > /etc/modprobe.d/disable-usb-storage.conf
                echo "blacklist firewire-core" > /etc/modprobe.d/disable-firewire.conf
                echo "blacklist thunderbolt" >> /etc/modprobe.d/disable-thunderbolt.conf
                update-initramfs -u -k all
                ;;

            "N")
                if [[ -e /etc/modprobe.d/disable-usb-storage.conf ]]; then
                    rm /etc/modprobe.d/disable-usb-storage.conf
                    bool_runOperationIfFileExists=true
                fi

                if [[ -e /etc/modprobe.d/disable-firewire.conf ]]; then
                    rm /etc/modprobe.d/disable-firewire.conf
                    bool_runOperationIfFileExists=true
                fi

                if [[ -e /etc/modprobe.d/disable-thunderbolt.conf ]]; then
                    rm /etc/modprobe.d/disable-thunderbolt.conf
                    bool_runOperationIfFileExists=true
                fi

                if [[ $bool_runOperationIfFileExists == true ]]; then
                    update-initramfs -u -k all
                fi
                ;;
        esac

        echo

        str_dir1=$(find .. -name files | uniq | head -n1)"/"

        if [[ ${str_dir1} != "" ]]; then
            cd ${str_dir1}
            str_inFile1="./sysctl.conf"
            str_file1="/etc/sysctl.conf"
            str_oldFile1="/etc/sysctl.conf_old"
        else
            str_inFile1=""
        fi

        if [[ -e ${str_inFile1} ]]; then
            str_input1=""
            ReadInput "Setup /etc/sysctl.conf with defaults?"

            if [[ ${str_input1} == "Y" && ${str_inFile1} != "" ]]; then
                cp ${str_file1} ${str_oldFile1}
                cat ${str_inFile1} >> ${str_file1}
            fi

        else
            echo -e "WARNING: '/etc/sysctl.conf' missing. Skipping..."
        fi

        echo

        str_input1=""
        ReadInput "Setup firewall with UFW?"

        if [[ ${str_input1} == "Y" ]]; then
            if [[ $(command -v ufw) != "" ]]; then
                # NOTE: change here!
                # basic #
                ufw reset
                ufw default allow outgoing
                ufw default deny incoming

                # NOTE: default LAN subnets may be 192.168.1.0/24

                # secure-shell on local lan #
                if [[ $(command -v ssh) != "" ]]; then
                    if [[ ${str_sshAlt} != "" ]]; then
                        ufw deny ssh comment 'deny default ssh'
                        ufw limit from 192.168.0.0/16 to any port ${str_sshAlt} proto tcp comment 'ssh'

                    else
                        ufw limit from 192.168.0.0/16 to any port 22 proto tcp comment 'ssh'
                    fi

                    ufw deny ssh comment 'deny default ssh'
                fi

                # services a desktop uses #
                ufw allow DNS comment 'dns'
                ufw allow from 192.168.0.0/16 to any port 137:138 proto udp comment 'CIFS/Samba, local file server'
                ufw allow from 192.168.0.0/16 to any port 139,445 proto tcp comment 'CIFS/Samba, local file server'

                ufw allow from 192.168.0.0/16 to any port 2049 comment 'NFS, local file server'
                ufw allow from 192.168.0.0/16 to any port 2049 comment 'NFS, local file server'
                ufw allow from 192.168.0.0/16 to any port 3389 comment 'RDP, local remote desktop server'
                ufw allow VNC comment 'VNC, local remote desktop server'

                # services a server may use #
                # ufw allow http comment 'HTTP, local Web server'
                # ufw allow https comment 'HTTPS, local Web server'

                # ufw allow 25 comment 'SMTPD, local mail server'
                # ufw allow 110 comment 'POP3, local mail server'
                # ufw allow 995 comment 'POP3S, local mail server'
                # ufw allow 1194/udp 'SMTPD, local VPN server'
                ufw allow from 192.168.0.0/16 to any port 9090 proto tcp comment 'Cockpit, local Web server'

                # save changes #
                ufw enable
                ufw reload

            else
                echo -e "WARNING: UFW is not installed. Skipping..."
            fi
        fi

        # edit hosts file here?
    }
# </code>

### main ###
# <code>
    # NOTE: necessary for newline preservation in arrays and files
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

    CheckIfUserIsRoot
    ExecuteSetupOfSoftwareSources
    ExitWithThisExitCode
    IFS=$SAVEIFS
# </code>