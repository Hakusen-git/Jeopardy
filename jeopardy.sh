#!/bin/bash
# A simple program that simulates a game called jeopardy 
# Author: Wayne Yao

#initial set up, create neccessary folders and files
mkdir temps &> /dev/null

mkdir winnings &> /dev/null

if [ ! "$(ls -A temps)" ]; then
  cp -r categories/* temps
fi

if [ ! -f winnings/winnings ]
then
  touch winnings/winnings
  count=0 #variable for winning
  echo "$count" > winnings/winnings
else
  count=($(cat winnings/winnings))
  if [ -z $count ];
  then
    count=0
    echo $count > winnings/winnings
  fi
fi

# an array storing all categories names
declare -a cateNum
index=1

# function for displaying question board
function board {
    completed=0
    echo "=====Question Board====="
    for file in temps/* ; do
        cateNum[${index}]=$file
        
        echo "===($index) $(basename ${cateNum[$index]})==="
        lines=($(wc -l < ${file})) &> /dev/null
        if [ "${lines}" -eq "0" ]; 
        then
            echo "(complete)"
            completed=$(($completed + 1))
            index=$(($index + 1))

        else while IFS=, read -ra arr; do
                echo ${arr[0]}
             done < ${file}
        index=$(($index + 1))
        fi
    done
    index=$(($index - 1))
    if [ $index -eq $completed ]; then
      completed=-1
    fi
    index=1
}

# function for displaying menu
function menu {
  echo -e "\n"
  echo "=============================================================="
    echo "Welcome to Jeopardy!"
    echo "=============================================================="
    echo "Please select from one of the following options: "
    echo "     (p)rint question board"
    echo "     (a)sk a question"
    echo "     (v)iew current winnings"
    echo "     (r)eset game"
    echo "     e(x)it"
    read -p "Enter a selection [p/a/v/r/x] : " VAL
}

# reset function, clear all temp files back to initial state
function reset {
    
    rm temps/*

    cp -r categories/* temps

    count=0

    echo $count > winnings/winnings

}

# A while loop for the main functions
while true ; do

  menu

# According to users inputs, decide which function to run
case $VAL in
  [pP])
    board
    read -s -p "Press Any Key to continue"
    ;;
  [aA])
    board

    if [ ! "$completed" -eq "-1" ]; then

    read -p "Please enter a category number : " CATEGORIES

    read -p "Please enter the score you want to get from the question : " SCORE

    SCORE=$(echo $SCORE | grep -o -E '[0-9]+')

    # After reading inputs, check if inputs are usable

    CATEGORIES=${cateNum[$CATEGORIES]}

    while [ ! -f "${CATEGORIES}" ]
    do
      read -p "Category does not exist!! Please enter another category number : " CATEGORIES
      CATEGORIES=${cateNum[$CATEGORIES]}
    done

    numOfLines=($(wc -l < ${CATEGORIES})) &> /dev/null
        
    while [ "${numOfLines[0]}" -eq "0" ]
    do
    	read -p "This category is completed! Please enter another category number : " CATEGORIES
    	CATEGORIES=${cateNum[$CATEGORIES]}
    	while [ ! -f "${CATEGORIES}" ]
    	do
    	read -p "Category does not exist!! Please enter another category number : " CATEGORIES
    	CATEGORIES=${cateNum[$CATEGORIES]}
    	done
    	
    	numOfLines=($(wc -l < ${CATEGORIES})) &> /dev/null
    done

    question=$(grep -w "${SCORE}" ${CATEGORIES})
            
    while [ -z "$question" ]
            do
            	read -p "invalid question!! Please enter a new score : " SCORE
            	question=$(grep -w "${SCORE}" ${CATEGORIES})
    done

    # After exception checking, start to get questions, answers and points from the temp files.
            
    IFS=','
    read -a strarr<<<"$question"
    echo ${strarr[1]}
    echo ${strarr[1]} | festival --tts
    read -p "Press input answer : " ANSWER
    # trim and lowercase input and answer
    ANSWER="${ANSWER,,}"
    strarr[2]="${strarr[2],,}"
    ANSWER="${ANSWER// }"
    strarr[2]="${strarr[2]// }"

    # Start comparing answer, then do further function
    if [ "$ANSWER" = "${strarr[2]}" ];
    then
         echo "Correct!"
         count=$(($count + ${strarr[0]}))
         echo $count > winnings/winnings
         
    else
         echo "Wrong Answer!! The correct answer is : "
         echo ${strarr[2]}
         echo ${strarr[2]} | festival --tts
         count=$(($count - ${strarr[0]}))
         echo $count > winnings/winnings
    fi

    # delete the question line from temp file so it won't be displayed again       
    sed -i "/${strarr[0]}/d" ${CATEGORIES}

    else

    echo "All questions are completed, please reset the game"
    
    fi
    read -s -p "This question is finished! Press Any Key to continue"
    ;;
  [vV])
    echo "The current winning is : ${count}"
    
    read -s -p "Press Any Key to continue"
    ;;
  [rR])
    reset
    read -s -p "Game is reset! Press Any Key to continue"
    
    ;;
  [xX])
    echo "Exit Game"
    exit
    ;;
esac


done
