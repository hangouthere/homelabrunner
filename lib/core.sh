_LIB_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$LIB_DIR/colors.sh"

HLR_STACKS_PATH_FULL=""
STACK_LIST=""
NUM_STACKS=0
INDEX_COUNT=0

getStackPath() {
    local _outval=$1
    local stackName=$2
    local stackDir=$HLR_STACKS_PATH_FULL/$stackName

    composeFile=""
    for f in compose.yaml compose.yml docker-compose.yaml docker-compose.yml; do
        if [ -f "$stackDir/$f" ]; then
            composeFile="$stackDir/$f"
            break
        fi
    done

    if [ -z "$composeFile" ]; then
        eval "$_outval="
        return 1
    fi

    eval "$_outval=\$composeFile"
}

checkStack() {
    local stackPath=$1
    if [ ! -f "$stackPath" ]; then
        errorAndExit "Error: Stack does not exist - $stackPath" 50
    fi
}

composeOperation() {
    local stackName=$1
    local operation=$2

    if [ "up" = "$operation" ]; then
        operation="up -d"
    fi

    if [ "logs" = "$operation" ]; then
        operation="logs -f --tail=100"
    fi

    if [ "build" = "$operation" ]; then
        operation="build --pull"
    fi

    local composeFile
    getStackPath composeFile "$stackName" || errorAndExit "Error: Stack '$stackName' has no compose file" 50

    local stackDir
    stackDir=$(dirname "$composeFile")
    local composeFileName
    composeFileName=$(basename "$composeFile")

    checkStack "$composeFile"

    (
        cd "$stackDir"
        docker compose -f "$composeFileName" $operation
    )
}

hasBuildContext() {
    local stackName=$1
    local composeFilePath
    getStackPath composeFilePath "$stackName" || return 1

    grep -q "build:" "$composeFilePath"
}

upgradeStack() {
    local stackName=$1

    if hasBuildContext "$stackName"; then
        echo "Building (with pull) for $stackName..."
        composeOperation $stackName build
    else
        echo "Pulling latest images for $stackName..."
        composeOperation $stackName pull
    fi

    echo ""
    echo "Stopping $stackName..."
    composeOperation $stackName down
    echo ""
    echo "Starting $stackName..."
    composeOperation $stackName up
}

moveToStacksPath() {
    HLR_STACKS_PATH=${HLR_STACKS_PATH:-$(pwd)}
    HLR_STACKS_PATH_FULL="$(dirname $HLR_STACKS_PATH)/$(basename $HLR_STACKS_PATH)"
    HLR_STACKS_PATH_FULL=$(realpath $HLR_STACKS_PATH_FULL)

    if [ ! -d "$HLR_STACKS_PATH_FULL" ]; then
        errorAndExit "Error: Stacks path does not exist - $HLR_STACKS_PATH_FULL" 51
    fi

    cd $HLR_STACKS_PATH_FULL

    echo "${txtYellow}Searching: $HLR_STACKS_PATH_FULL${colorReset}\n"
}

getStacks() {
    STACK_LIST=""
    for dir in "$HLR_STACKS_PATH_FULL"/*/; do
        [ -d "$dir" ] || continue
        name=$(basename "$dir")
        for f in compose.yaml compose.yml docker-compose.yaml docker-compose.yml; do
            if [ -f "$dir$f" ]; then
                echo "$name"
                break
            fi
        done
    done | sort > /tmp/stacks_sorted

    STACK_LIST=$(cat /tmp/stacks_sorted)
    rm -f /tmp/stacks_sorted

    NUM_STACKS=$(echo "$STACK_LIST" | grep -c . || echo 0)

    if [ -z "$STACK_LIST" ]; then
        errorAndExit "No Stacks Found!\nEnsure you run this command where your stack directories reside, or set HLR_STACKS_PATH to the path where they reside." 98
    fi
}

iterateStacksForSingleOp() {
    operation=$1
    actionLabel=$2

    storeIFS

    for stackName in $STACK_LIST; do
        INDEX_COUNT=$((INDEX_COUNT+1))
        echo $INDEX_COUNT - $actionLabel $stackName...

        restoreIFS
        composeOperation $stackName $operation
        storeIFS

        if [ ! "$INDEX_COUNT" -eq "$NUM_STACKS" ]; then
            echo =======================================================
        fi
    done

    restoreIFS
}

storeIFS() {
    OLDIFS=$IFS
    IFS='
'
}

restoreIFS() {
    IFS=$OLDIFS
}

errorAndExit() {
    errMsg=$1
    exitCode=$2

    echo "${txtRed}$errMsg${colorReset}"
    exit $exitCode
}