#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

# check if sudo/root #
    function CheckIfUserIsRoot
    {
        if [[ $(whoami) != "root" ]]; then
            str_file1=$(echo ${0##/*})
            str_file1=$(echo $str_file1 | cut -d '/' -f2)
            echo -e "WARNING: Script must execute as root. In terminal, run:\n\t'sudo bash $str_file1'\n\tor\n\t'su' and 'bash $str_file1'."
            exit 1
        fi
    }

# procede with echo prompt for input #
    # ask user for input then validate #
    function ReadInput {

        # parameters #
        str_input1=$(echo $str_input1 | tr '[:lower:]' '[:upper:]')
        str_input1=${str_input1:0:1}
        declare -i int_count=0      # reset counter

        while true; do

            # manual prompt #
            if [[ $int_count -ge 3 ]]; then
                echo -en "Exceeded max attempts. "
                str_input1="N"                    # default input     # NOTE: update here!

            else
                echo -en "\t$1 [Y/n]: "
                read str_input1

                str_input1=$(echo $str_input1 | tr '[:lower:]' '[:upper:]')
                str_input1=${str_input1:0:1}
            fi

            case $str_input1 in
                "Y"|"N")
                    break;;

                *)
                    echo -en "\tInvalid input. ";;
            esac

            ((int_count++))         # increment counter
        done
    }

# systemd #
    function AppendToSystemd
    {
        echo -en "Appending files to Systemd... "
        echo
        echo

        # parameters #
        str_dir1="$(pwd)/$( basename $(find . -name files | uniq | head -n1 | cut -d '/' -f2 ))"
        str_pattern=".service"
        declare -a arr1=( $( ls ${str_dir1} | uniq | grep -E *"${str_pattern}" ))

        for str_inFile1 in ${arr1[@]}; do

            # parameters #
            declare -i int_rem=${#str_pattern}
            int_rem=$((int_rem * -1))
            str_line1=${str_inFile1::int_rem}
            str_inFile2=$( basename $( find . | grep "$str_line1" | grep -Ev *".service" | uniq | head -n1 ))

            str_outFile1="/etc/systemd/system/$str_inFile1"
            str_outFile2="/usr/sbin/$str_inFile2"

            str_inFile1="${str_dir1}/"${str_inFile1}
            str_inFile2="${str_dir1}/"${str_inFile2}

            cp $str_inFile1 $str_outFile1
            chown root $str_outFile1
            chmod +x $str_outFile1

            if [[ -e $str_inFile2 ]]; then
                cp $str_inFile2 $str_outFile2
                chown root $str_outFile2
                chmod +x $str_outFile2
            fi

            str_outFile2=""
        done

        echo -e "Complete."
        systemctl daemon-reload
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

        if [[ $str_dir1 != "" ]]; then
            cd $str_dir1

            # list of cron files #
            arr1=$(ls *-cron)
        fi

        # how do i get the file name after the last delimiter "/" ? check other repos or check for pattern regex
        if [[ ${#arr1[@]} -gt 0 ]]; then
            echo -e "Appending cron entries..."

            for str_line1 in $arr1; do

                # update parameters #
                str_input1=""

                ReadInput "Append '$str_line1'?"
                echo

                if [[ $str_input1 == "Y" ]]; then

                    # parse list of packages that have cron files #
                    for str_line2 in ${arr_requiredPackages[@]}; do

                        # match given cron file, append only if package exists in system #
                        if [[ $str_line1 == *"$str_line2"* ]]; then
                            if [[ $(command -v $str_line2) != "" ]]; then
                                cp ${str_dir1}$str_line1 ${str_outDir1}${str_line1}
                                # echo -e "Appended file '$str_line1'."

                            else
                                echo -e "WARNING: Missing required package '$str_line2'. Skipping..."
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

    # NOTE: old
    # function EditCrontab
    # {
    #     str_file1="/var/spool/cron/crontabs/root"      # set working file
    #     declare -a arr_output1=()

    #     # backup system file #
    #     str_file1="/etc/ssh/ssh_config"
    #     str_oldFile1=${str_file1}"_old"

    #     if [ -e $str_file1 ]; then
    #         cp $str_file1 $str_oldFile1

    #     else
    #         touch $str_file1
    #     fi

    #     echo -en "Editing crontab.\nEnter your preferred ntp server (default: time.nist.gov): "
    #     read str_input1

    #     if [[ -z $str_input1 ]]; then
    #         str_input1="time.nist.gov";     # default value, change here!
    #     fi

    #     # append to output #
    #     if [[ $(command -v ntpdate) != "/usr/bin/ntpdate" ]]; then
    #         arr_output1+=(
    #             ""
    #             "# ntp #"
    #             "# update every 15 min"
    #             "0,15,30,45 * * * * ntpdate -s $str_input1"
    #         )
    #     fi

    #     # append to output #
    #     if [[ $(command -v unattended-upgrade) != "/usr/bin/unattended-upgrade"* ]]; then
    #         str_line1="#"

    #     else
    #         str_line1=""
    #     fi

    #     # append to output #
    #     arr_output1+=(
    #         ""
    #         "# apt #    # NOTE: better to use 'unattended-upgrades'"
    #         "# clean, update every 8 hours"
    #         "${str_line1}0 0,8,16 * * * apt clean && apt update && apt full-upgrade -y"
    #         "# clean, update, autoremove every 8 hours"
    #         "#0 0,8,16 * * * apt clean && apt update && apt full-upgrade -y && apt autoremove -y"
    #     )

    #     # append to output #
    #     if [[ $(command -v flatpak) == "/usr/bin/flatpak" ]]; then
    #         arr_output1+=(
    #             ""
    #             "# flatpak #"
    #             " update every 8 hours"
    #             "0 0,8,16 * * * flatpak update -y"
    #         )
    #     fi

    #     # append to output #
    #     if [[ $(command -v snap) == "/usr/bin/snap" ]]; then
    #         arr_output1+=(
    #             ""
    #             "# snap #"
    #             "# update every 8 hours"
    #             "0 0,8,16 * * * snap update -y"
    #         )
    #     fi
    # }

# SSH #
    function EditSSH
    {
        # parameters #
        declare -i int_count=0  # reset counter
        str_output1=""          # reset output

        # prompt #
        while [[ $int_count -le 3 ]]; do

            # default input #
            if [ $int_count -gt 2 ]; then
                str_sshAlt=22
                echo -en "Exceeded max attempts! "

            # read input #
            else
                echo -e "Enter a new IP Port number for SSH (leave blank for default):"
                read str_sshAlt
            fi

            # match string with valid integer #
            if [ "$str_sshAlt" -eq "$str_sshAlt" ] 2> /dev/null; then

                # parameters #
                declare -i int_number="$str_sshAlt"

                if [[ $int_number -gt 0 && $int_number -lt 65536 ]]; then
                    if [[ $int_number -gt 1000 ]]; then
                        if [[ $int_number == 22 ]]; then
                            echo -e "Default value."

                        # append to output #
                        else
                            str_output1+="\n#\nPort $str_sshAlt"
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

            ((int_count++))   # counter
        done

        # backup system file #
        str_file1="/etc/ssh/ssh_config"
        str_oldFile1=$str_file1"_old"

        if [ -e $str_file1 ]; then
            cp $str_file1 $str_oldFile1
        fi

        # backup system file #
        str_file1="/etc/ssh/sshd_config"
        str_oldFile1=$str_file1"_old"

        if [ -e $str_file1 ]; then
            cp $str_file1 $str_oldFile1
        fi

        # append to output #
        str_output1+="\nLoginGraceTime 1m\nPermitRootLogin prohibit-password\nMaxAuthTries 6\nMaxSessions 2"

        echo -e $str_output1 >> $str_file1

        systemctl restart ssh sshd  # restart services
    }

# security #
    function ModifySecurity
    {
        echo -e "Configuring system security..."

        # parameters #
        str_input1=""
        str_packagesToRemove="atftpd nis rsh-redone-server rsh-server telnetd tftpdtftpd-hpa xinetd yp-tools"
        str_servicesToEnable="fail2ban"

        ReadInput "Auto-accept command argument prompts (ex: '-y', '--yes') ?"

        if [[ $str_input1 == "Y" ]]; then
            str_args="-y"

        else
            str_args=""
        fi

        str_input1=""
        ReadInput "Remove given apt packages?"

        if [[ $str_input1 == "Y" ]]; then
            apt remove $str_args $str_packagesToRemove
        fi

        str_input1=""
        ReadInput "Disable given storage interfaces: USB, Firewire, Thunderbolt?"

        case $str_input1 in
            "Y")
                echo 'install usb-storage /bin/true' > /etc/modprobe.d/disable-usb-storage.conf
                echo "blacklist firewire-core" > /etc/modprobe.d/disable-firewire.conf
                echo "blacklist thunderbolt" >> /etc/modprobe.d/disable-thunderbolt.conf
                update-initramfs -u -k all
                ;;

            "N")
                if [[ -e /etc/modprobe.d/disable-usb-storage.conf ]]; then
                    rm /etc/modprobe.d/disable-usb-storage.conf
                fi

                if [[ -e /etc/modprobe.d/disable-firewire.conf ]]; then
                    rm /etc/modprobe.d/disable-firewire.conf
                fi

                if [[ -e /etc/modprobe.d/disable-thunderbolt.conf ]]; then
                    rm /etc/modprobe.d/disable-thunderbolt.conf
                fi
                update-initramfs -u -k all
                ;;
        esac

        str_dir1=$(find .. -name files | uniq | head -n1)"/"

        if [[ $str_dir1 != "" ]]; then
            cd $str_dir1
            str_inFile1="./sysctl.conf"
            str_file1="/etc/sysctl.conf"
            str_oldFile1="/etc/sysctl.conf_old"
        else
            str_inFile1=""
        fi

        echo -e "Setup /etc/sysctl.conf with defaults?"
        str_input1=""
        ReadInput

        if [[ $str_input1 == "Y" && $str_inFile1 != "" ]]; then
            cp $str_file1 $str_oldFile1
            cat $str_inFile1 >> $str_file1
        fi

        echo -e "Setup firewall?"
        str_input1=""
        ReadInput

        if [[ $str_input1 == "Y" ]]; then
            if [[ $(command -v ufw) != "" ]]; then
                # NOTE: change here!
                # basic #
                sudo ufw default allow outgoing
                sudo ufw default deny incoming

                # NOTE: default LAN subnets may be 192.168.1.0/24

                # secure-shell on local lan #
                if [[ $(command -v ssh) != "" ]]; then
                    sudo ufw limit from 192.168.0.0/16 to any port 22 proto tcp comment 'ssh'
                fi

                # services a desktop uses #
                sudo ufw allow DNS comment 'dns'
                # sudo ufw allow from 192.168.0.0/16 to any port 137:138 proto udp comment 'CIFS/Samba, local file server'
                # sudo ufw allow from 192.168.0.0/16 to any port 139,445 proto tcp comment 'CIFS/Samba, local file server'

                # sudo ufw allow from 192.168.0.0/16 to any port 2049 comment 'NFS, local file server'
                # sudo ufw allow from 192.168.0.0/16 to any port 2049 comment 'NFS, local file server'
                # sudo ufw allow from 192.168.0.0/16 to any port 3389 comment 'RDP, local remote desktop server'
                # sudo ufw allow VNC comment 'VNC, local remote desktop server'

                # services a server may use #
                # sudo ufw allow http comment 'HTTP, local Web server'
                # sudo ufw allow https comment 'HTTPS, local Web server'

                # sudo ufw allow 25 comment 'SMTPD, local mail server'
                # sudo ufw allow 110 comment 'POP3, local mail server'
                # sudo ufw allow 995 comment 'POP3S, local mail server'
                # sudo ufw allow 1194/udp 'SMTPD, local VPN server'
                # sudo ufw allow from 192.168.0.0/16 to any port 9090 proto tcp comment 'Cockpit, local Web server'

                # save changes #
                sudo ufw enable
                sudo ufw reload

            else
                echo -e "WARNING: UFW is not installed. Skipping..."
            fi
        fi
    }

# main #

    # parameters #
    str_sshAlt=""

    # NOTE: necessary for newline preservation in arrays and files #
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

    # call functions #
    CheckIfUserIsRoot
    AppendToSystemd
    AppendCron
    # EditCrontab       # deprecated
    # EditSSH
    # ModifySecurity

    IFS=$SAVEIFS        # reset IFS
    echo -e "Exiting."
    exit 0