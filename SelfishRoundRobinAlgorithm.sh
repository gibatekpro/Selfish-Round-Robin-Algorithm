#!/bin/bash

data=$1
newQueuePriorityIncrement=$2
acceptedQueuePriorityIncrement=$3
quanta=$4
processes=()
newQ=()
acceptedQ=()
outputType=1
outputFile="output.txt"

if [[ ! -z $1 ]] && [[ ! -z $newQueuePriorityIncrement ]] && [[ ! -z $acceptedQueuePriorityIncrement ]] && [[ -z $4 ]]; then
    
    if [[ -f "$1" && "$newQueuePriorityIncrement" =~ ^[0-9]+$ && "$acceptedQueuePriorityIncrement" =~ ^[0-9]+$ ]]; then
        
    echo ""
    echo "Right number of parameters entered: 3."
    echo "A default quanta value will be used. quanta = 1"
    echo "$1 data file entered"
    echo ""

    quanta=1

    else
    echo "Invalid number or combination of parameters."
    echo ""
    echo "You need to input at least 3 positional parameters"
    echo "1. The data file"
    echo "2. The new queue priotity increment. It must be an integer."
    echo "3. The accepted queue priority increment. It must be an integer."
    echo "4. (Optional) Quanta. If you don't include quanta, value of 1 will be used"
    echo ""
    echo "Try again. Exiting script..."
    exit 1
    fi

elif [[ ! -z $1 ]] && [[ ! -z $newQueuePriorityIncrement ]] && [[ ! -z $acceptedQueuePriorityIncrement ]] && [[ ! -z $4 ]]; then

    if [[ -f "$1" && "$newQueuePriorityIncrement" =~ ^[0-9]+$ && "$acceptedQueuePriorityIncrement" =~ ^[0-9]+$ &&  $4 =~ ^[0-9]+$  ]]; then
            
    echo ""
    echo "Right number of parameters entered: 4."
    echo "$1 data file entered"
    echo "quanta = $quanta"
    echo ""

    else
    echo "Invalid number or combination of parameters."
    echo ""
    echo "You need to input at least 3 positional parameters"
    echo "1. The data file"
    echo "2. The new queue priotity increment. It must be an integer."
    echo "3. The accepted queue priority increment. It must be an integer."
    echo "4. (Optional) Quanta. If you don't include quanta, value of 1 will be used"
    echo ""
    echo "Try again. Exiting script..."
    exit 1
    fi
else
    echo "Invalid number or combination of parameters."
    echo ""
    echo "You need to input at least 3 positional parameters"
    echo "1. The data file"
    echo "2. The new queue priotity increment"
    echo "3. The accepted queue priority increment"
    echo "4. (Optional) Quanta. If you don't include quanta, value of 1 will be used"
    echo ""
    echo "Try again. Exiting script..."
    exit 1
fi


echo "Data in data file:"

# Read file line by line into the array
while IFS= read -r line || [ -n "$line" ]; do
    # Check if the line is not empty
    if [ -n "$line" ]; then
        processes+=("$line")
        echo "$line"
    fi
done < "$1"


echo "Priority Increment in New_Queue = $newQueuePriorityIncrement and in Accepted_Queue = $acceptedQueuePriorityIncrement"


echo -e "\nSelect an option of how you want your output:"
PS3="Enter a number (1-3): "

select option in "Output to standard output only" "Output to named text file. If file exists, it will be overwritten" "Output to both standard output and named text file"; do
    case $REPLY in
        1)
            echo -e "You selected: Output to standard output only.\n"
            outputType=1
            break
            ;;
        2)
            echo "You selected: Output to named text file (overwrite if exists)."
            echo -e "Output text file name is $outputFile \n"
            outputType=2
            break
            ;;
        3)
            echo "You selected: Output to both standard output and named text file."
            echo -e "Output text file name is $outputFile \n"
            outputType=3
            break
            ;;
        *)
            echo "Invalid selection. Please enter a number between 1 and 3."
            ;;
    esac
done


for i in "${!processes[@]}"; do
    processes[$i]="$(echo "${processes[$i]}" | awk '{print $1","$2","$3",0,-,0"}')"
done


if [ "$outputType" -eq 1 ]; then


    echo -n "T    "

    for process in "${processes[@]}"; do
        processName=$(echo "$process" | cut -d ',' -f 1)
        echo -n "$processName    "
    done
    echo ""
    
elif [ "$outputType" -eq 2 ]; then

    echo -n > $outputFile

    echo -n "T    "  >> "$outputFile"
    for process in "${processes[@]}"; do
        processName=$(echo "$process" | cut -d ',' -f 1)
        echo -n "$processName    "
    done >> "$outputFile"
    echo >> "$outputFile"

elif [ "$outputType" -eq 3 ]; then

    echo -n > $outputFile

    echo -n "T    "  >> "$outputFile"
    for process in "${processes[@]}"; do
        processName=$(echo "$process" | cut -d ',' -f 1)
        echo -n "$processName    "
    done >> "$outputFile"
    echo >> "$outputFile"

    echo -n "T    "
    for process in "${processes[@]}"; do
        processName=$(echo "$process" | cut -d ',' -f 1)
        echo -n "$processName    "
    done
    echo ""
fi



startProcess() {

time=0
hasProcess=1

while [ "$hasProcess" -eq 1 ]; do

    findNewProcess "$time"

    removeFinishedProcesses

    performNewQueueOperations

    performAcceptedQueueOperations

    incrementPriorities

    setNewQueueStatusToWaiting


    if [ "$outputType" -eq 1 ]; then

        echo -n "$time"

        for process in "${processes[@]}"; do
            status=$(getProcessStatus "$process")
            echo -n "    $status"
        done

        echo ""
        
    elif [ "$outputType" -eq 2 ]; then

        echo -n "$time" >> "$outputFile"

        for process in "${processes[@]}"; do
            status=$(getProcessStatus "$process")
            echo -n "    $status"
        done >> "$outputFile"

        echo >> "$outputFile"


    elif [ "$outputType" -eq 3 ]; then

        echo -n "$time"

        for process in "${processes[@]}"; do
            status=$(getProcessStatus "$process")
            echo -n "    $status"
        done

        echo ""

        echo -n "$time" >> "$outputFile"

        for process in "${processes[@]}"; do
            status=$(getProcessStatus "$process")
            echo -n "    $status"
        done >> "$outputFile"

        echo >> "$outputFile"

    fi

    
    highestArrivalTime=0
    for process in "${processes[@]}"; do
        arrivalTime=$(getProcessArrivalTime "$process")
        if [ "$highestArrivalTime" -lt "$arrivalTime" ]; then
            highestArrivalTime=$arrivalTime
        fi
    done

    ((time++))

    if [ "$time" -gt "$highestArrivalTime" ] && [ "${#acceptedQ[@]}" -eq 0 ] && [ "${#newQ[@]}" -eq 0 ]; then
        hasProcess=0
    fi

done
}

findNewProcess() {
    local time=$1

    for ((i = 0; i < ${#processes[@]}; i++)); do
        newOrAccepted "$time" "$i"
    done
}

performNewQueueOperations() {
    # Check if newQ is not empty
    if [ ${#newQ[@]} -gt 0 ]; then
        processesToRemove=()
        highestPriority=-2147483648
        processesWithHighestPriority=()

        for currentProcess in "${newQ[@]}"; do
            currentPriority=$(getProcessPriority "$currentProcess")
        
            if [ "$currentPriority" -eq "$highestPriority" ]; then
                processesWithHighestPriority+=("$currentProcess")
            elif [ "$currentPriority" -gt "$highestPriority" ]; then
                highestPriority="$currentPriority"
                processesWithHighestPriority=("$currentProcess")
                processesToRemove=("$currentProcess")
            fi
        done

        if [ ${#acceptedQ[@]} -ne 0 ]; then
            if [ "$(getProcessPriority "${processesWithHighestPriority[0]}")" -eq "$(getProcessPriority "${acceptedQ[0]}")" ]; then
                for process in "${processesWithHighestPriority[@]}"; do
                    performMoveToAcceptedQueue "$process"
                newQ=($(echo "${newQ[@]}" | tr ' ' '\n' | grep -v "$process"))
                done

            fi
        else
            for process in "${processesWithHighestPriority[@]}"; do
                performMoveToAcceptedQueue "$process"
            done

            newQ=($(echo "${newQ[@]}" | tr ' ' '\n' | grep -v "${processesToRemove[@]}"))

        fi
    fi
}

performAcceptedQueueOperations() {
    if [ "${#acceptedQ[@]}" -gt 0 ]; then

        if [ "${#acceptedQ[@]}" -gt 0 ]; then
        firstProcess=${acceptedQ[0]}

        if [ "$(getProcessRunTime "$firstProcess")" -ge "$quanta" ]; then

            if [ "${#acceptedQ[@]}" -eq 1 ]; then
                runTime=$(getProcessRunTime "$firstProcess")
                requiredServiceTime=$(getProcessServiceRequired "$firstProcess")

                ((runTime++))
                ((requiredServiceTime--))

                for ((i = 0; i < ${#processes[@]}; i++)); do
                    if [ "$(getProcessName "${processes[i]}")" == "$(getProcessName "$firstProcess")" ]; then
                        setMainProcessStatus "R" "$i"
                        setMainProcessRunTime "$runTime" "$i"
                        setMainProcessServiceRequired "$requiredServiceTime" "$i"
                    fi
                done

                setAcceptedProcessStatus "R" 0
                setAcceptedProcessRunTime "$runTime" 0
                setAcceptedProcessServiceRequired "$requiredServiceTime" 0
            else

                runTime=0

                for ((i = 0; i < ${#processes[@]}; i++)); do
                    if [ "$(getProcessName "${processes[i]}")" == "$(getProcessName "$firstProcess")" ]; then
                        setMainProcessStatus "W" "$i"
                        setMainProcessRunTime "$runTime" "$i"
                    fi
                done

                setAcceptedProcessStatus "W" 0
                setAcceptedProcessRunTime "$runTime" 0

                processToMove="${acceptedQ[0]}"

                acceptedQ=("${acceptedQ[@]:1}" "$processToMove")

                newRunTime=$(getProcessRunTime "${acceptedQ[0]}")
                newRequiredServiceTime=$(getProcessServiceRequired "${acceptedQ[0]}")

                ((newRunTime++))
                ((newRequiredServiceTime--))

                for ((i = 0; i < ${#processes[@]}; i++)); do
                    if [ "$(getProcessName "${processes[i]}")" == "$(getProcessName "${acceptedQ[0]}")" ]; then
                        setMainProcessStatus "R" "$i"
                        setMainProcessRunTime "$newRunTime" "$i"
                        setMainProcessServiceRequired "$newRequiredServiceTime" "$i"
                    fi
                done

                setAcceptedProcessStatus "R" 0
                setAcceptedProcessRunTime "$newRunTime" 0
                setAcceptedProcessServiceRequired "$newRequiredServiceTime" 0

            fi
        else
            runTime=$(getProcessRunTime "$firstProcess")
            requiredServiceTime=$(getProcessServiceRequired "$firstProcess")

            ((runTime++))
            ((requiredServiceTime--))

            for ((i = 0; i < ${#processes[@]}; i++)); do
                if [ "$(getProcessName "${processes[i]}")" == "$(getProcessName "$firstProcess")" ]; then
                    setMainProcessStatus "R" "$i"
                    setMainProcessRunTime "$runTime" "$i"
                    setMainProcessServiceRequired "$requiredServiceTime" "$i"
                fi
            done

            setAcceptedProcessStatus "R" 0
            setAcceptedProcessRunTime "$runTime" 0
            setAcceptedProcessServiceRequired "$requiredServiceTime" 0

        fi
    fi
    fi
}

incrementPriorities() {
    if [ "${#newQ[@]}" -gt 0 ]; then
        for ((i = 0; i < ${#newQ[@]}; i++)); do
            priority=$(getProcessPriority "${newQ[i]}")
            ((priority += newQueuePriorityIncrement))
            setNewQueueProcessPriority "$priority" "$i"
        done
    fi

    if [ "${#acceptedQ[@]}" -gt 0 ]; then
        for ((i = 0; i < ${#acceptedQ[@]}; i++)); do
            priority=$(getProcessPriority "${acceptedQ[i]}")
            ((priority += acceptedQueuePriorityIncrement))
            setAcceptedProcessPriority "$priority" "$i"
        done
    fi
}

setNewQueueStatusToWaiting() {
    for ((i = 0; i < ${#processes[@]}; i++)); do
        for ((j = 0; j < ${#newQ[@]}; j++)); do
            setNewQueueProcessStatus "W" "$j"

            if [ "$(getProcessName "${processes[i]}")" == "$(getProcessName "${newQ[j]}")" ]; then
                setMainProcessStatus "W" "$i"
            fi
        done
    done

}

newOrAccepted() {
    local time=$1
    local i=$2


    if [ $time -eq $(getProcessArrivalTime "${processes[$i]}") ]; then
        if [ ${#newQ[@]} -eq 0 ] && [ ${#acceptedQ[@]} -eq 0 ]; then
                performMoveToAcceptedQueue "${processes[$i]}"
        else
            
            performMoveToNewQueue "${processes[$i]}"
        fi
    fi
}

performMoveToNewQueue() {
    local process=$1
    newQ+=("$process")
}



performMoveToAcceptedQueue() {
    local process=$1
    acceptedQ+=("$process")
}

removeFinishedProcesses() {
    
    local processesToRemove=()

    for ((i = 0; i < ${#acceptedQ[@]}; i++)); do
        process=${acceptedQ[i]}

        if [ "$(getProcessServiceRequired "$process")" -eq 0 ]; then
            processesToRemove+=("$process")
        fi
    done

    for processToRemove in "${processesToRemove[@]}"; do
        acceptedQ=($(echo "${acceptedQ[@]}" | tr ' ' '\n' | grep -v "$processToRemove"))

    done

    for ((i = 0; i < ${#processes[@]}; i++)); do
        for ((i1 = 0; i1 < ${#processesToRemove[@]}; i1++)); do
            if [ "$(getProcessName "${processes[i]}")" == "$(getProcessName "${processesToRemove[i1]}")" ]; then
                setMainProcessStatus "F" "$i"
            fi
        done
    done

}

getProcessName() {
    local process=$1
    IFS=',' read -ra processDetails <<< "$process"
    echo "${processDetails[0]}"
}

getProcessServiceRequired() {
    local process=$1
    IFS=',' read -ra processDetails <<< "$process"
    echo "${processDetails[1]}"
}

getProcessArrivalTime() {
    local process=$1
    IFS=',' read -ra processDetails <<< "$process"
    echo "${processDetails[2]}"
}

getProcessPriority() {
    process="$1"
    IFS=',' read -ra processDetails <<< "$process"
    echo "${processDetails[3]}"
}

# Returns the status of a process
getProcessStatus() {
    local process=$1
    IFS=',' read -ra processDetails <<< "$process"
    echo "${processDetails[4]}"
}

getProcessRunTime() {
    local process=$1
    IFS=',' read -ra processDetails <<< "$process"
    echo "${processDetails[5]}"
}

setMainProcessServiceRequired() {
    local serviceRequiredTime=$1
    local i=$2

    local currentProcess=${processes[i]}
    local processName=$(getProcessName "$currentProcess")
    local arrivalTime=$(getProcessArrivalTime "$currentProcess")
    local priority=$(getProcessPriority "$currentProcess")
    local status=$(getProcessStatus "$currentProcess")
    local runTime=$(getProcessRunTime "$currentProcess")

    processes[i]=$(IFS=','; echo "$processName,$serviceRequiredTime,$arrivalTime,$priority,$status,$runTime")

}

setMainProcessStatus() {
    local status=$1
    local i=$2

    local currentProcess=${processes[i]}
    local processName=$(getProcessName "$currentProcess")
    local serviceRequired=$(getProcessServiceRequired "$currentProcess")
    local arrivalTime=$(getProcessArrivalTime "$currentProcess")
    local priority=$(getProcessPriority "$currentProcess")
    local runTime=$(getProcessRunTime "$currentProcess")

    processes[i]=$(IFS=','; echo "$processName,$serviceRequired,$arrivalTime,$priority,$status,$runTime")
}

setMainProcessRunTime() {
    local runtime=$1
    local i=$2

    local currentProcess=${processes[i]}
    local processName=$(getProcessName "$currentProcess")
    local serviceRequired=$(getProcessServiceRequired "$currentProcess")
    local arrivalTime=$(getProcessArrivalTime "$currentProcess")
    local priority=$(getProcessPriority "$currentProcess")
    local status=$(getProcessStatus "$currentProcess")

    processes[i]=$(IFS=','; echo "$processName,$serviceRequired,$arrivalTime,$priority,$status,$runtime")

}

setNewQueueProcessPriority() {
    local priority=$1
    local i=$2

    local currentProcess=${newQ[i]}
    local processName=$(getProcessName "$currentProcess")
    local serviceRequired=$(getProcessServiceRequired "$currentProcess")
    local arrivalTime=$(getProcessArrivalTime "$currentProcess")
    local status=$(getProcessStatus "$currentProcess")
    local runTime=$(getProcessRunTime "$currentProcess")

    newQ[i]=$(IFS=','; echo "$processName,$serviceRequired,$arrivalTime,$priority,$status,$runTime")
}

setNewQueueProcessStatus() {
    local status=$1
    local i=$2

    local currentProcess=${newQ[i]}
    local processName=$(getProcessName "$currentProcess")
    local serviceRequired=$(getProcessServiceRequired "$currentProcess")
    local arrivalTime=$(getProcessArrivalTime "$currentProcess")
    local priority=$(getProcessPriority "$currentProcess")
    local runTime=$(getProcessRunTime "$currentProcess")

    newQ[i]=$(IFS=','; echo "$processName,$serviceRequired,$arrivalTime,$priority,$status,$runTime")
}

setAcceptedProcessServiceRequired() {
    local serviceRequiredTime=$1
    local i=$2

    local currentProcess=${acceptedQ[i]}
    local processName=$(getProcessName "$currentProcess")
    local arrivalTime=$(getProcessArrivalTime "$currentProcess")
    local priority=$(getProcessPriority "$currentProcess")
    local status=$(getProcessStatus "$currentProcess")
    local runTime=$(getProcessRunTime "$currentProcess")

    acceptedQ[i]=$(IFS=','; echo "$processName,$serviceRequiredTime,$arrivalTime,$priority,$status,$runTime")
}

setAcceptedProcessPriority() {
    local priority=$1
    local i=$2

    local currentProcess=${acceptedQ[i]}
    local processName=$(getProcessName "$currentProcess")
    local serviceRequired=$(getProcessServiceRequired "$currentProcess")
    local arrivalTime=$(getProcessArrivalTime "$currentProcess")
    local status=$(getProcessStatus "$currentProcess")
    local runTime=$(getProcessRunTime "$currentProcess")

    acceptedQ[i]=$(IFS=','; echo "$processName,$serviceRequired,$arrivalTime,$priority,$status,$runTime")
}

setAcceptedProcessStatus() {
    local status=$1
    local i=$2

    local currentProcess=${acceptedQ[i]}
    local processName=$(getProcessName "$currentProcess")
    local serviceRequired=$(getProcessServiceRequired "$currentProcess")
    local arrivalTime=$(getProcessArrivalTime "$currentProcess")
    local priority=$(getProcessPriority "$currentProcess")
    local runTime=$(getProcessRunTime "$currentProcess")

    acceptedQ[i]=$(IFS=','; echo "$processName,$serviceRequired,$arrivalTime,$priority,$status,$runTime")
}

setAcceptedProcessRunTime() {
    local runtime=$1
    local i=$2

    local currentProcess=${acceptedQ[i]}
    local processName=$(getProcessName "$currentProcess")
    local serviceRequired=$(getProcessServiceRequired "$currentProcess")
    local arrivalTime=$(getProcessArrivalTime "$currentProcess")
    local priority=$(getProcessPriority "$currentProcess")
    local status=$(getProcessStatus "$currentProcess")

    acceptedQ[i]=$(IFS=','; echo "$processName,$serviceRequired,$arrivalTime,$priority,$status,$runtime")
}

startProcess
