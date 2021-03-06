#!/bin/bash

# By SomeCanadian
####
# idea / bugs -> somecanadian0@gmail.com
#####
# New Idea/bug here:

#####

function usage() {
    cat <<END

Usage: ./$(basename $0) action-name tool

Where:
      tool                The name of the tool (No need to precise the category name)

Actions:
      setup                Set up the environment (Create bin dir and set bin dir to your \$PATH)
      help                 Show this menu
      info                 Show README.md of an installed tool
      list                 List all tools (Installed tools will appear in a different color)
      list-cat             List all tools of a Category (Installed tools will appear in a different color)
      list-installed       List all installed tools
      install              Install a tool
      install-cat          Install all tools of a Category
      install-all          Install all tools
      check-update         Check Update for an installed tools and Update it if you want (Only for tools from a git repo)
      check-update-all     Check Update for all installed tools
      self-update          Check Update for Some-Tools and Update if you want
      add-tool             Create template for a new tool (./$(basename $0) add-tool newtoolname category)
      uninstall            Uninstall a tool (Trying uninstall with the tool built-in uninstall.sh before Cleaning from our project)
      uninstall-cat        Uninstall all tools of a Category
      complete-uninstall   Delete all installed tools, remove bin directory and delete our modification in .zshrc or .bashrc


Usage ex: ./$(basename $0) setup
Usage ex: ./$(basename $0) list
Usage ex: ./$(basename $0) install LinEnum
You can also take the ID number from ./sometools.sh list action:
Usage ex: ./$(basename $0) install 6

For more info and examples see: http://github.com/som3canadian/Some-Tools or cat README.md
END
}

function log() {
    echo -e "${PURPLE}${BOLD}$@${RESET}"
}

PURPLE='\033[0;35m'
RESET='\033[0m'
BOLD='\033[1m'

ACTION=$1
TOOL="$2"
NEWTOOLDIR=$3

if [ -z "$TOOL" -a "$ACTION" != "list" -a "$ACTION" != "list-installed" -a "$ACTION" != "setup" -a "$ACTION" != "self-update" -a "$ACTION" != "help" -a "$ACTION" != "check-update-all" -a "$ACTION" != "install-all" -a "$ACTION" != "complete-uninstall" ]; then
    usage
    exit 1
fi

# https://medium.com/@Aenon/bash-location-of-current-script-76db7fd2e388
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd $DIR

CHECKGIT="$SOME_ROOT/check-git.sh"
CHECKGITACTION="$SOME_ROOT/check-git-action.sh"
HOME_PATH=$(cd && pwd)

########## Function to associate ID with $TOOL ($2 argument). We will set $TOOLPATH too  ##########
function toolID() {
    COUNTER=1
    echo ""
    for t in */*; do
        [ ! -e "$t/install-tool.sh" ] && continue
        echo "[$COUNTER] $t"
        #moving to the next one
        COUNTER=$((COUNTER + 1))
    done
}
function toolVAR() {
    tempTOOL="$TOOL"
    # check if tool argument is a number(integer)
    if [[ "$tempTOOL" =~ ^[0-9]+$ ]]; then
        toolID >tools.txt
        TOOL=$(sed -n "/$tempTOOL/p" tools.txt | cut -d "/" -f 2 | head -n 1)
        tempTOOLPATH=$(sed -n -e "/$tempTOOL/p" tools.txt | cut -d " " -f 2 | head -n 1)
        TOOLPATH="$tempTOOLPATH"
        rm tools.txt
    else
        TOOLPATH="$(dirname */$TOOL/install-tool.sh)"
    fi
}
toolVAR
########## End of Function to associate ID with $TOOL ($2 argument) ##########

########## Functions include in setup action  ##########
# function to help you install require packages at the begining of the setup process.
# not being used for the moment
function requirePackages() {
    #sudo apt install git python-pip build-essential libtool
    sudo apt install python3-pip python3-scrapy
    ## Python3 dependencies
    pip3 install scrapy
}

# bashrc or zshrc ?
function whichShell() {
    echo "> Which Shell are you using ?"
    echo "[*] Choose 1 for .zshrc, 2 for .bashrc or anything else to exit !"
    select zb in "Zshrc" "Bashrc"; do
        case $zb in
        Zshrc)
            echo "Selecting .zshrc as Shell"
            shellSelect="zshrc"
            break
            ;;
        Bashrc)
            echo "Selecting .bashrc as Shell"
            shellSelect="bashrc"
            break
            ;;
        *) exit 1 ;;
        esac
    done
}

########## Functions include in setup action  ##########
function setUp() {
    echo "We will use $shellSelect as shell"
    echo "Do you want to continue the setup process ?"
    select yn in "Yes" "No"; do
        case $yn in
        Yes) break ;;
        No) exit 1 ;;
        esac
    done
    pathOG=$(echo $PATH)
    SOME_ROOT=$DIR
    # backup .zshrc or .bashrc
    cp $HOME_PATH/.$shellSelect $HOME_PATH/.$shellSelect.backup
    echo "" >>$HOME_PATH/.$shellSelect
    echo "#Some-tools-start configuration below" >>$HOME_PATH/.$shellSelect
    echo "# Your PATH before any modifications: $pathOG" >>$HOME_PATH/.$shellSelect
    echo "# If you want to reset your PATH just remove all lines we created and do: export PATH=$pathOG follow by: source ~/.$shellSelect" >>$HOME_PATH/.$shellSelect
    echo "export SOME_ROOT=\"$DIR\" # DO NOT EDIT This is added by some-tools" >>$HOME_PATH/.$shellSelect
    echo "#setting path for some-tools" >>$HOME_PATH/.$shellSelect
    # echo "export PATH=\"$SOME_ROOT/bin:\$PATH\" # DO NOT EDIT This is added by some-tools" >>~/.$shellSelect
    echo "export PATH=\"\$SOME_ROOT/bin:\$PATH\" # DO NOT EDIT This is added by some-tools" >>$HOME_PATH/.$shellSelect
    echo "#Some-tools-end configuration" >>$HOME_PATH/.$shellSelect
    mkdir $SOME_ROOT/bin && mkdir $SOME_ROOT/bin/PrivEsc-Lin && mkdir $SOME_ROOT/bin/PrivEsc-Win
    log "[*] Set up done. You can now open new terminal tabs/windows or run \`source ~/.$shellSelect\` to set the new path!"
    log "[+] You can see your new path by doing: \`echo \$PATH\`"
}
########## End of Functions include in setup action  ##########

########## General Functions  ##########
function specialUpdate() {
    #cd $SOME_ROOT/$TOOLPATH
    if [ -x "./update-tool.sh" ]; then
        log "[+] [$TOOL] We found an update-tool.sh file within this tool."
        echo "> Do you want to update with update-tool.sh ?"
        echo "[*] Choose 1 or 2"
        select yn in "Yes" "No"; do
            case $yn in
            Yes)
                echo "Updating with update-tool.sh"
                ./update-tool.sh
                break
                ;;
            No)
                echo "No stress, not updating !"
                break
                ;;
            esac
        done
    else
        log "[-] [$TOOL] No update-tool.sh file or nothing to update with it. In most case, this is a normal output."
    fi
}

function checkUpdate() {
    cd $TOOLPATH
    echo ""
    if [ -f "./.installed" ]; then
        log "[+] $TOOL is installed, continuing..."
        if [ -d "./$TOOL/.git" ]; then
            cd $TOOL
            if $SOME_ROOT/check-git.sh | grep "Your repo is Behind. You Need to Pull." >/dev/null; then
                log "[+] [$TOOL] Checking for Update with checkgit."
                $CHECKGITACTION
                log "[+] [$TOOL] Continuing... Checking for custom update-tool.sh !"
                cd $SOME_ROOT/$TOOLPATH
                specialUpdate
            else
                log "[+] [$TOOL] You are not behind!"
                log "[+] [$TOOL] Continuing... Checking for custom update-tool.sh !"
                cd $SOME_ROOT/$TOOLPATH
                specialUpdate
            fi
        else
            log "[-] [$TOOL] Not a git repo !"
            log "[+] [$TOOL] Continuing... Checking for custom update-tool.sh !"
            cd $SOME_ROOT/$TOOLPATH
            specialUpdate
        fi
    else
        echo ""
        log "[-] [$TOOL] No .installed file. Are you sure $TOOL is installed ?"
    fi
}

# ask to open install-tool.sh and uninstall-tool.sh with vscode(code command) when add-tool.
# very useful to me, you can change it to another code editor if you want.
function askCode() {
    whichCode=$(which code)
    if [ -x "$whichCode" ]; then
        echo ""
        log "[+] Looks like Visual Studio Code is installed !"
        echo "> Do you want to open install-tool.sh and uninstall-tool.sh with code ?"
        echo "[*] Choose 1 or 2"
        select yn in "Yes" "No"; do
            case $yn in
            Yes)
                code uninstall-tool.sh
                code install-tool.sh
                exit 0
                ;;
            No)
                echo "No stress! Quitting..."
                exit 0
                ;;
            *)
                log "[-] Not an option... quitting !"
                exit 1
                ;;
            esac
        done
    else
        exit 0
    fi
}

function addTool() {
    cd $NEWTOOLDIR
    mkdir $TOOL && cd $TOOL
    echo $TOOL >.gitignore
    echo ".installed" >>.gitignore
    echo "echo \"This tool is installed\" > .installed" >install-tool.sh
    echo "#---Install cmd start here---" >>install-tool.sh
    echo "" >>install-tool.sh
    echo "# cd \$TOOL" >>install-tool.sh
    echo "# symlink template" >>install-tool.sh
    echo "# cd \$SOME_ROOT/bin" >>install-tool.sh
    echo "# ln -s \"\$SOME_ROOT/\$TOOLPATH/\$TOOL/\$TOOL/yourfile\"" \""yourfile\"" >>install-tool.sh
    echo "#---Installation cmd end here---" >>install-tool.sh
    chmod +x install-tool.sh
    echo "#---This file is for uninstall tool in bin dir. In theory you have set them in the install-tool.sh file too---" >uninstall-tool.sh
    echo "#---Uninstall cmd start here---" >>uninstall-tool.sh
    echo "# cd \$SOME_ROOT/bin" >>uninstall-tool.sh
    echo "" >>uninstall-tool.sh
    echo "#---Uninstall cmd end here---" >>uninstall-tool.sh
    chmod +x uninstall-tool.sh
    ls -la
    echo ""
    log "[+] Template creation for $TOOL is finished"
    log "[+] You can now add the installation cmd into $NEWTOOLDIR/$TOOL/install-tool.sh and unstallation cmd into $NEWTOOLDIR/$TOOL/uninstall-tool.sh"
    askCode
}

# check if tool name already exist before add-tool
function checkName() {
    if [ ! -d */$TOOL ]; then
        echo ""
        #echo "Everything good Not the same name"
    else
        echo ""
        log "[-] This tool name is already used."
        log "[*] You can use any other name, just be sure to precise the new name when doing git clone instruction in the install-tool.sh file."
        exit 1
    fi
}

function installTool() {
    cd $TOOLPATH
    if ./install-tool.sh; then
        log "[+] [$TOOL] Install finished in $TOOLPATH dir"
    else
        log "[-] [$TOOL] Install FAILED"
    fi
}

function uninstallTool() {
    cd "$TOOLPATH"
    if [ -f ".installed" ]; then
        if [ -x ./$TOOL/uninstall.sh ]; then
            log "[+] [$TOOL] Removing dependencies with builtin uninstall.sh file."
            ./$TOOL/uninstall.sh
            log "[+] [$TOOL] Continuing... We will remove tool from our project."
        else
            log "[-] [$TOOL] No builtin uninstall.sh file. Continuing... We will remove tool from our project."
        fi
        ### Deleting Symlink with uninstall-tool.sh
        if ./uninstall-tool.sh; then
            log "[+] [$TOOL] Uninstall finished"
        else
            log "[-] [$TOOL] Uninstall FAILED! Probably no uninstall-tool.sh file in $TOOL dir. In most case, this is a normal output"
        fi
        log "[+] [$TOOL] Removing tool dir (not removing others dependencies) and .installed file."
        rm -rf $TOOL
        rm .installed
        log "[+] [$TOOL] Uninstall is completed."
    else
        echo ""
        log "[-] This tool is not installed !"
    fi
}

function infoTool() {
    cd $TOOLPATH
    if [ -f .installed ]; then
        cd $TOOL
        # checking for bat -> https://github.com/sharkdp/bat
        whichBat=$(which bat)
        if [ -x "$whichBat" ]; then
            echo ""
            log "[+] Looks like bat is installed !"
            echo "[*] Do you want to use bat instead of cat ?"
            select yn in "Yes" "No"; do
                case $yn in
                Yes)
                    bat README.md
                    exit 0
                    ;;
                No)
                    cat README.md
                    exit 0
                    ;;
                *)
                    log "[-] Not an option... quitting !"
                    exit 1
                    ;;
                esac
            done
        else
            cat README.md
        fi
    else
        echo ""
        log "[-] This tool is not installed !"
    fi
}

########## End of General Functions  ##########

##########   Listing functions   ##########
function listTools() {
    COUNTER=1
    echo ""
    for t in */*; do
        if [ -f "$t/.installed" ]; then
            myColor="log"
        else
            myColor="echo"
        fi
        [ ! -e "$t/install-tool.sh" ] && continue
        $myColor "[$COUNTER] $t"
        #moving to the next one
        COUNTER=$((COUNTER + 1))
    done
}

function listInstalled() {
    COUNTER=1
    echo ""
    for t in */*; do
        [ ! -e "$t/.installed" ] && continue
        echo "[$COUNTER] $t"
        COUNTER=$((COUNTER + 1))
    done
}

function listCat() {
    #COUNTER=1
    echo ""
    for t in $TOOL/*; do
        if [ -f "$t/.installed" ]; then
            myColor="log"
        else
            myColor="echo"
        fi
        [ ! -e "$t/install-tool.sh" ] && continue
        $myColor "[+] $t"
        #COUNTER=$((COUNTER + 1))
    done
}
########## End of List function  ##########

########## Functions with Actions Cat  ##########
function installCat() {
    for t in $TOOL/*; do
        if [ -x "$t/install-tool.sh" ]; then
            echo ""
            log "[+] Installing $t"
            cd $t
            ./install-tool.sh
            cd $DIR
        else
            log "[-] [$t] No install-tool.sh for this tool !"
        fi
    done
}

function uninstallCat() {
    for t in $TOOL/*; do
        if [ -f $t/.installed ]; then
            echo ""
            log "[*] Start Uninstalling for: $t"
            if [ -f $t/uninstall.sh ]; then
                log "[+] [$t] Removing dependencies with builtin uninstall.sh file."
                cd $t
                ./uninstall.sh
                cd $DIR
                log "[+] [$t] Continuing... We will remove tool from our project."
            else
                log "[-] [$t] No builtin uninstall.sh file. Continuing... We will remove tool from our project."
            fi
            if [ -f $t/uninstall-tool.sh ]; then
                cd $t
                ./uninstall-tool.sh
                cd $DIR
                log "[+] [$t] Uninstall finished"
            else
                log "[-] [$t] Uninstall FAILED! Probably no uninstall-tool.sh file in $t dir. In most case, this is a normal output."
            fi
            temptoolname="$(echo $t | cut -d "/" -f 2)"
            cd $t
            rm -rf $temptoolname
            rm .installed
            cd $DIR
            log "[+] [$t] Uninstall is completed."
        else
            log "[-] [$t] Tool not installed !"
        fi
    done
}
########## End of Functions with Actions Cat  ##########

########## Functions with Actions All  ##########
function checkUpdateAll() {
    for t in */*; do
        if [ -f "$t/.installed" ]; then
            temptoolname="$(echo $t | cut -d "/" -f 2)"
            echo ""
            if [ -d "$t/$temptoolname/.git" ]; then
                log "[*] Checking update for: $temptoolname"
                cd $t/$temptoolname
                if "$CHECKGIT" | grep "Your repo is Behind. You Need to Pull" >/dev/null; then
                    log "[+] [$t] Checking for Update with checkgit."
                    $CHECKGITACTION
                    log "[+] [$TOOL] Continuing... Checking for custom update-tool.sh !"
                    cd ..
                    specialUpdate
                    cd $DIR
                else
                    log "[+] [$t] You are not behind. $temptoolname is up to date !"
                    cd $DIR
                fi
            else
                log "[-] [$t] Not a git repo !"
                log "[+] [$TOOL] Continuing... Checking for custom update-tool.sh !"
                cd $t/$temptoolname
                cd ..
                specialUpdate
                cd $DIR
            fi
        else
            #log "[-] [$t] Tool not installed !"
            echo "[-] [$t] Tool not installed !" >/dev/null
        fi
    done
}

function installAll() {
    for t in */*; do
        if [ -x "$t/install-tool.sh" ]; then
            echo ""
            log "[+] Installing $t"
            cd $t
            ./install-tool.sh
            cd $DIR
        else
            log "[-] [$t] No install-tool.sh for this tool !"
        fi
    done
}
########## End of Functions with Actions All  ##########

########## Complete Uninstall functions  ##########
function uninstallAll() {
    for t in */*; do
        if [ -f $t/.installed ]; then
            echo ""
            temptoolname="$(echo $t | cut -d "/" -f 2)"
            log "[*] Start Uninstalling for: $t"
            if [ -f $t/uninstall.sh ]; then
                log "[+] [$t] Removing dependencies with builtin uninstall.sh file."
                cd $t
                ./uninstall.sh
                cd $DIR
                log "[+] [$t] Continuing... We will remove tool from our project."
            else
                log "[-] [$t] No builtin uninstall.sh file. Continuing... We will remove tool from our project."
            fi
            if [ -f $t/uninstall-tool.sh ]; then
                cd $t
                ./uninstall-tool.sh
                cd $DIR
                log "[+] [$t] Uninstall finished"
            else
                log "[-] [$t] Uninstall FAILED! Probably no uninstall-tool.sh file in $t dir. In most case, this is a normal output."
            fi
            cd $t
            rm -rf $temptoolname
            rm .installed
            cd $DIR
            log "[+] [$t] Uninstall is completed."
        else
            log "[-] [$t] Tool not installed !"
        fi
    done
}

function completeUninstall() {
    log "[+] [$t] Removing all installed tools."
    cd $HOME_PATH
    sed '/Some-tools-start/,/Some-tools-end/d' .zshrc >.zshrc.new
    mv .zshrc .zshrc.backup2
    mv .zshrc.new .zshrc
    cd $DIR
    uninstallAll
    rm -rf bin
    rm -rf __pycache__
}
########## End of Complete Uninstall functions  ##########

case $ACTION in
setup)
    requirePackages
    whichShell
    setUp
    ;;
add-tool)
    checkName
    addTool
    ;;
help)
    usage
    ;;
list)
    listTools
    ;;
list-installed)
    listInstalled
    ;;
list-cat)
    listCat
    ;;
info)
    infoTool
    ;;
install)
    installTool
    ;;
install-cat)
    installCat
    ;;
install-all)
    installAll
    ;;
check-update)
    checkUpdate
    ;;
check-update-all)
    checkUpdateAll
    ;;
uninstall)
    uninstallTool
    ;;
uninstall-cat)
    uninstallCat
    ;;
complete-uninstall)
    completeUninstall
    ;;
self-update)
    log "[+] [$TOOL] Checking Update for Some-Tools"
    $CHECKGITACTION
    ;;
*) ;;

esac
