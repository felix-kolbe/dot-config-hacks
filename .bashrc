#!/bin/bash
# by FXKE

# Make bash append rather than overwrite the history on disk
shopt -s histappend


##### paths

export PATH=~/bin/:$PATH
export PATH=$PATH:"/c/Users/${USER}/AppData/Local/Beyond Compare 4"


##### short aliases

#### GUI tools

alias tgit=TortoiseGitProc
alias notepad++='"C:/Program Files (x86)/Notepad++/notepad++.exe"'
alias npp=notepad++
alias meld='"C:\Program Files (x86)\Meld\Meld.exe"'

#### CLI tools

alias colordiff="diff --color"
alias l >/dev/null 2>&1 || alias l='ls -CF'
alias ll >/dev/null 2>&1 || alias ll="ls -goh"



##### cd commands

alias cd_wireshark="cd c:\\\Users\\\${USER}\\\AppData\\\Roaming\\\Wireshark"
#alias cd_wiki="cd '/c/Users/xxx/yyy/.wiki/'"
#alias cd_lmc="cd c:/Users/xxx/lmc_src/ && black"




##### generic helper functions

#### finder

alias findkeeps="find . -name '*.keep'"
alias findkeepsdelete="find . -name '*.keep' -print -delete"

alias find-commented-lines="find . -name '*.c' | xargs grep --color -Hn \"^ *//\""


#alias find_empty_directories_recursively_1_remove="find . -empty -type d | xargs  rmdir -v --ignore-fail-on-non-empty"
#alias find_empty_directories_recursively_1_remove-interactive="find . -empty -type d | xargs --interactive  rmdir -v --ignore-fail-on-non-empty"
#alias find_empty_directories_recursively_2_remove="find . -empty -type d -print -delete"
#alias find_empty_directories_recursively_3_remove="find . -depth -exec rmdir -v {} \;"

#alias find_empty_directories_recursively="find . -wholename "'.git*"'-prune -o -type d -empty -print"
#alias find_empty_directories_recursively_remove="find . -wholename "'.git*"'-prune -o -type d -empty -exec rmdir -v {} \;"

alias find_empty_directories_recursively="find ./* -depth -not -path '*.git*' -type d -empty -print"
alias find_empty_directories_recursively_remove="find ./* -depth -not -path '*.git*' -type d -empty -exec rmdir -v {} \;"
alias find_empty_directories_recursively_remove_document="find ./* -depth -not -path '*.git*' -type d -empty -exec rmdir -v {} \;  > __empty_dirs_removed && wc -l __empty_dirs_removed"


#### highlighter

alias highlight_less="less -p"

function highlight() {
  grep --color -E "$1|\$"
}

# https://github.com/kepkin/dev-shell-essentials/blob/master/highlight.sh
function highlight_col() {
	declare -A fg_color_map
	fg_color_map[black]=30
	fg_color_map[red]=31
	fg_color_map[green]=32
	fg_color_map[yellow]=33
	fg_color_map[blue]=34
	fg_color_map[magenta]=35
	fg_color_map[cyan]=36

	fg_c=$(echo -e "\e[1;${fg_color_map[$1]}m")
	c_rs=$'\e[0m'
	sed -u s"/$2/$fg_c\0$c_rs/g"
}





###### specific make/build helpers
# mostly for future inspiration

alias mad="make all BUILDCFG=dbg"
alias mid="make install BUILDCFG=dbg"
alias mcd="make clean BUILDCFG=dbg"

alias mdd="rm -vrf _dbg_*"
alias mrd="mdd && mad"

function make_sub_directories_mad()
{
  dirs=(*/)
  for dir in "${dirs[@]}"; do
    pushd $dir  &&  mad
    popd  ||  return
  done
}

alias madl="mad 2>&1 | tee output_make_all_dbg.log"

function do-task () { mv -v "$1" "$1".do && sleep 5 && tail -f "$1".log; }




##### git-related

# to disable, these must _not_ be exported at all or exported as empty! ("..=EOL")
export GIT_PS1_SHOWCOLORHINTS=
export GIT_PS1_SHOWDIRTYSTATE=
export GIT_PS1_SHOWSTASHSTATE=
export GIT_PS1_SHOWUNTRACKEDFILES=
export GIT_PS1_SHOWUPSTREAM=
# keeping above block to easily copy it into a running shell

# actual config used (enable locally as per system specs)
export GIT_PS1_SHOWCOLORHINTS=1
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM=1


alias g="git"
alias qgit="git"

alias fetchlb="git fetch  &&  git lb"
alias fetchllb="git fetch local  &&  git lb"

alias git_gc_in_all_subdir_repos="find . -type f -name .git -okdir git gc \;"


# show stash by index given via parameter
git_stash_show()
{
  git show "stash@{$1}"
}

git-diff-file-changes()
{
  echo "Overall changes:" && git diff --name-status | wc -l
  echo "Modified:" && git diff --name-status --diff-filter=M | wc -l
  echo "Deleted:" && git diff --name-status --diff-filter=D | wc -l
  echo "Added:" && git diff --name-status --diff-filter=A | wc -l
  echo "Remaining:" && git diff --name-status --diff-filter=mda | wc -l
}


gitdiff()
{
  echo "diff --color $3 $4 $5 <(git show $1) <(git show $2)"
  diff --color $3 $4 $5 <(git show $1) <(git show $2)
}

# in some environments above <( ) piping is not working
gitdiff_nopiping()
{
  echo "diff --color $3 $4 $5 <(git show $1) <(git show $2)"
  git show $1  >  tmp_gitdifftemp_1
  git show $2  >  tmp_gitdifftemp_2
  diff --color $3 $4 $5 tmp_gitdifftemp_1 tmp_gitdifftemp_2
  rm tmp_gitdifftemp_1 tmp_gitdifftemp_2
}


gitdiff_multi()
(
  # replace second argument by HEAD if not given
  if [ $# -lt 2 ]; then
    branch2=$(git rev-parse --abbrev-ref --default HEAD $2)
  else
    branch2=$2
  fi

  echo Comparing $1 and $branch2:
  git show --summary --pretty=oneline $1 $branch2

  # gitdiff $1 $2 > /dev/null
  #echo "diff --color $3 $4 $5 <(git show $1) <(git show $2)"
  diff -I "commit ......." -I "index ......." --color --brief $3 $4 $5 <(git show $1) <(git show $branch2) #> /dev/null
  diffstatus=$?

  if [[ $diffstatus -eq 1 ]]
  then
    echo Initially different! Continuing until equal.
    gitdiff_multi_until_equal $(git rev-parse --verify --short $1^) $(git rev-parse --verify --short $branch2^) $3 $4 $5
  elif [[ $diffstatus -eq 0 ]]
  then
    echo Initially equal! Continuing until different.
    gitdiff_multi_until_different $(git rev-parse --verify --short $1^) $(git rev-parse --verify --short $branch2^) $3 $4 $5
  else
    echo Diff returned error! Abort.
  fi

  #git l -1 $1 $2
  #git show --summary --pretty=oneline $1 $2
)

gitdiff_multi_until_equal()
(
  # replace second argument by HEAD if not given
  if [ $# -lt 2 ]; then
    branch2=$(git rev-parse --abbrev-ref --default HEAD $2)
  else
    branch2=$2
  fi

  echo Comparing $1 and $branch2:
  git show --summary --pretty=oneline $1 $branch2

  diff -I "commit ......." -I "index ......." --color --brief $3 $4 $5 <(git show $1) <(git show $branch2)  #> /dev/null
  diffstatus=$?

  if [[ $diffstatus -eq 1 ]]
  then
    echo Different.
    gitdiff_multi_until_equal $(git rev-parse --verify --short $1^) $(git rev-parse --verify --short $branch2^) $3 $4 $5
  elif [[ $diffstatus -eq 0 ]]
  then
    echo Equal!
  else
    echo Diff returned error! Abort.
  fi
)

gitdiff_multi_until_different()
(
  # replace second argument by HEAD if not given
  if [ $# -lt 2 ]; then
    branch2=$(git rev-parse --abbrev-ref --default HEAD $2)
  else
    branch2=$2
  fi

  echo Comparing $1 and $branch2:
  git show --summary --pretty=oneline $1 $branch2

  diff -I 'commit .......' -I 'index .......' --color $3 $4 $5 <(git show $1) <(git show $branch2)  #> /dev/null
  diffstatus=$?

  if [[ $diffstatus -eq 1 ]]
  then
#    diff -I 'commit .......' -I 'index .......' --color $3 $4 $5 <(git show $1) <(git show $branch2)
#    echo Different! Diff shown above. Stopping.
    echo "diff -I 'commit .......' -I 'index .......' --color $3 $4 $5 <(git show $1) <(git show $branch2)"
    echo Different! Call diff with above command. Stopping.
  elif [[ $diffstatus -eq 0 ]]
  then

    if [[ $(git rev-parse --verify --short $1) = $(git rev-parse --verify --short $branch2) ]]
    then
      echo Identical hashes! Parents will never be different. Stop.
    else
      echo Equal.
      gitdiff_multi_until_different $(git rev-parse --verify --short $1^) $(git rev-parse --verify --short $branch2^) $3 $4 $5
    fi

  else
    echo Diff returned error! Abort.
  fi
)

# deprecated?
git_branch_update()
{
  git checkout "$1" && git pull --rebase "$2"
  return ${PIPESTATUS[0]}
}

alias git_update_branches_from_list="git_update_branches \$(cat updatelist)"

git_update_branches()
{
  for branch in "$@"
  do
    echo "$branch"
  done

  for branch in "$@"
  do
    echo "--------------------------------------------------------------------"
    git branch -lvv  $branch  | grep --color behind
    rv=$?
    # Exit status is 0 if any line is selected, 1 otherwise;
    if [ $rv -eq 0 ]; then
      #read -p "Update branch '$branch'? Enter or Ctrl-C: " -sr  choice
      #echo  # new line (use with -n 1)
      git checkout $branch && git pull
      rv=$?
      if [ $rv -ne 0 ]; then
        echo "Error updating branch '$branch' -> Abort!"
        return $?
      fi
    else
      echo "Skipping up-to-date or invalid branch '$branch'"
    fi

  #  read -p "Update branch '$branch'? Put yn: " -sr  choice
  #  #echo  # new line (use with -n 1)
  #  case "$choice" in
  #    y|Y )
  #    echo "yes"
  #    git checkout $branch && git pull
  #    if [ $? -ne 0 ]; then
  #      echo "Error -> Abort!"
  #      return $?
  #    fi
  #    ;;
  #    * ) echo "Aborting";;
  #  esac
  done

  echo "List of branches still being behind their upstream:"
  git branch -lvv | grep --color behind
}



git_show_recursive_upstream_status()
{
#  echo "--------------------------------------------------------------------"
  #branch=$(git symbolic-ref --short $1)
  branch=$(git rev-parse --abbrev-ref --default HEAD $1)

#  echo "Argument $1 -> Branch '$branch'"
  #upstream=$(git rev-parse --symbolic-full-name $branch@{upstream})
  upstream=$(git rev-parse --abbrev-ref "$branch@{upstream}")
  rv=$?
  if [ $rv -eq 0 ]; then
#    echo "Branch '$branch' has upstream '$upstream'."
    git branch -lvv  --color $branch  | grep --color -e 'behind' -e ''
    rv=$?
    if [ $rv -eq 0 ]; then
    git_show_recursive_upstream_status $upstream
    fi
  else
#    echo "Branch '$branch' has no (valid) upstream: ($upstream) - Exiting."
    git branch -lvv  --color $branch  | grep --color -e 'behind' -e ''
  fi
  return 0
}


git_show_recursive_branch_dependencies()
{
#  echo "--------------------------------------------------------------------"
  #branch=$(git symbolic-ref --short $1)
  branch=$(git rev-parse --abbrev-ref --default HEAD $1)
#  echo "Argument $1 -> Branch '$branch'"
  git branch -lvv  | grep --color '\['$branch
  rv=$?
  if [ $rv -eq 0 ]; then
    git for-each-ref --format='%(upstream:short) < %(refname:short)' refs/heads | grep :$branch
    for downstream in $(git for-each-ref --format='%(refname:short):%(upstream:short)' refs/heads | grep :$branch | sed "s/\(.\+\):.\+/\1/")
    do
#      echo Down: $2 $downstream
      git_show_recursive_branch_dependencies $downstream ". $2"
    done
#  else
#    echo "Branch '$branch' has no dependent branches."
  fi
  return 0
}


alias git_update_recursive_branch_dependencies_prompt_from_master="git sw master && git_update_recursive_branch_dependencies_prompt"

git_update_recursive_branch_dependencies_prompt()
{
#  echo "--------------------------------------------------------------------"
  #branch=$(git symbolic-ref --short $1)
  branch=$(git rev-parse --abbrev-ref --default HEAD $1)
#  echo "Argument $1 -> Branch '$branch'"
  git branch -lvv  | grep --color '\['$branch
  rv=$?
  if [ $rv -eq 0 ]; then
#    git for-each-ref --format='%(upstream:short) < %(refname:short)' refs/heads | grep $branch
    for downstream in $(git for-each-ref --format='%(refname:short):%(upstream:short)' refs/heads | grep :$branch | sed "s/\(.\+\):.\+/\1/")
    do
      echo Check: $2 $downstream

      git branch -lvv $downstream | grep --color ' behind '
      rv=$?
      if [ $rv -ne 0 ]; then
        echo "Branch '$downstream' is up to date."
      else
        git l -55 "$downstream@{U}" $downstream
        # TODO: Add last fetch head to list command to make full downstream path print (if this works) in case of too much new in upstream

        read -p "Update branch '$downstream'? Put, w/o Enter, y/u|n/s|q (for yes/update|no/skip|quit): " -sr -n 1 choice
        #echo  # new line (use with -n 1)
        case "$choice" in
          y|u )
            echo "Updating " $downstream
            git checkout $downstream && git pull #--dry-run
            rv=$?
            if [ $rv -ne 0 ]; then
              echo "Error: '$rv' -> Abort!"
              return $rv
            fi
            ;;
          n|s )
            echo "Skipping" $downstream
            ;;
          q )
            echo "Quitting."
            return 0
            ;;
          * )
            echo "Aborting!"
            return 1
            ;;
        esac
      fi
    done

    echo "--------------------------------------------------------------------"

    for downstream in $(git for-each-ref --format='%(refname:short):%(upstream:short)' refs/heads | grep :$branch | sed "s/\(.\+\):.\+/\1/")
    do
      echo Down: $2 $downstream
      git_update_recursive_branch_dependencies_prompt $downstream ". $2"
      rv=$?
      if [ $rv -ne 0 ]; then
        echo "Error '$rv' in recursive call -> Abort."
        return $rv
      fi
    done

  else
    echo "Branch '$branch' has no dependent branches."
  fi

  # print final list only if we are the initial call, not recursive
  if [ $# -lt 2 ]; then
    echo "List of branches still being behind their upstream:"
    git branch -lvv | grep --color behind
  fi

  return 0
}

  #  read -p "Update branch '$branch'? Put yn: " -sr  choice
  #  #echo  # new line (use with -n 1)
  #  case "$choice" in
  #    y|Y )
  #    echo "yes"
  #    git checkout $branch && git pull
  #    if [ $? -ne 0 ]; then
  #      echo "Error -> Abort!"
  #      return $?
  #    fi
  #    ;;
  #    * ) echo "Aborting";;
  #  esac



git_rename_branch_update_local_branch_tracking_prompt()
{
  if [ $# -eq 1 ]; then
    oldname=$1
    newname=dev/felix/$1
  elif [ $# -eq 2 ]; then
    oldname=$1
    newname=$2
  else
    echo "Not enough arguments! Usage: f <oldname> <newname>"
    return
  fi

  echo "Old branch name: $oldname"
  git branch --list -v "$oldname"

  read -p "Rename branch '$oldname' to '$newname'? Put, w/o Enter, y/r|n|q (for yes/rename|no|quit): " -sr -n 1 choice
  echo  # new line (use with -n 1)
  case "$choice" in
    y|r )
      git branch --move -v $oldname $newname
      echo $?
#      rv=$?
#      if [ $rv -ne 0 ]; then
#        echo "Error: $rv -> Abort!"
#        return $rv
#      fi
      ;;
    n|s )
      echo "Skipping"
      ;;
    q )
      echo "Quitting."
      return 0
      ;;
    * )
      echo "Aborting!"
      return 1
      ;;
  esac


  for branch in $(git for-each-ref --format='%(refname:short) <<%(upstream:short)>>' refs/heads/ | grep "<<$1>>" | cut -d " " -f 1); do
    echo "This branch was tracking the old branch: $branch"
    git branch -l -vv $branch


    read -p "Update branch '$branch' to track '$newname'? Put, w/o Enter, y/u|n/s|q (for yes/update|no/skip|quit): " -sr -n 1 choice
    echo  # new line (use with -n 1)
    case "$choice" in
      y|u )
        echo "Updating " $branch
        git branch --set-upstream-to=$newname $branch
        rv=$?
        if [ $rv -ne 0 ]; then
          echo "Error: $rv -> Abort!"
          return $rv
        fi
        ;;
      n|s )
        echo "Skipping $branch"
        ;;
      q )
        echo "Quitting."
        return 0
        ;;
      * )
        echo "Aborting!"
        return 1
        ;;
    esac

  done
}


# to backup all branches as a tag with optional prefix given as paramter
# (only used once during migration)
git_tag_all_branches()
{
  _prefix=$1
  for branch in $(git for-each-ref --format='%(refname:short)' refs/heads/); do
    echo $branch
    git tag ${_prefix}$branch $branch
  done

  git tag -l
}





##### coloring


# generally set brighter foreground
echo -ne '\e]10;#EFEFEF\a' #  foreground


# colors:
# echo -ne '\e]4;0;#000000\a' # black
# echo -ne '\e]4;1;#BF0000\a' # red
# echo -ne '\e]4;2;#00BF00\a' # green
# echo -ne '\e]4;3;#BFBF00\a' # yellow
# echo -ne '\e]4;4;#0000BF\a' # blue
# echo -ne '\e]4;5;#BF00BF\a' # magenta
# echo -ne '\e]4;6;#00BFBF\a' # cyan
# echo -ne '\e]4;7;#BFBFBF\a' # white (light grey really)
# echo -ne '\e]4;8;#404040\a' # bold black (i.e. dark grey)
# echo -ne '\e]4;9;#FF4040\a' # bold red
# echo -ne '\e]4;10;#40FF40\a' # bold green
# echo -ne '\e]4;11;#FFFF40\a' # bold yellow
# echo -ne '\e]4;12;#6060FF\a' # bold blue
# echo -ne '\e]4;13;#FF40FF\a' # bold magenta
# echo -ne '\e]4;14;#40FFFF\a' # bold cyan
# echo -ne '\e]4;15;#FFFFFF\a' # bold white
# elements:
# echo -ne '\e]10;#BFBFBF\a' #  foreground
# echo -ne '\e]11;#401000\a' #  background
# echo -ne '\e]12;#00FF00\a' #  cursor


alias black=setcolors_local
function setcolors_local() {
    echo -ne '\e]10;#EEEEEE\a' #  foreground
    echo -ne '\e]11;#000000\a' #  background
    echo -ne '\e]12;#EEEEEE\a' #  cursor
}

alias red=setcolors_dev01
function setcolors_dev01() {
    echo -ne '\e]10;#FFFFFF\a' #  foreground
    echo -ne '\e]11;#300000\a' #  background
    echo -ne '\e]12;#00FFBB\a' #  cursor
}
alias blue=setcolors_sideshow
function setcolors_sideshow() {
    echo -ne '\e]10;#DDDDDD\a' #  foreground
    echo -ne '\e]11;#001040\a' #  background
    echo -ne '\e]12;#FF5050\a' #  cursor
}
alias green=setcolors_testrig
function setcolors_testrig() {
    echo -ne '\e]10;#FFEFEF\a' #  foreground
    echo -ne '\e]11;#003000\a' #  background
    echo -ne '\e]12;#FF2000\a' #  cursor
}

alias violet=setcolors_acm
function setcolors_acm() {
    echo -ne '\e]10;#FFFFFF\a' #  foreground
    echo -ne '\e]11;#331029\a' #  background
    echo -ne '\e]12;#33EEAE\a' #  cursor
}
