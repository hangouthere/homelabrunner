. "$LIB_DIR/core.sh"

moveToStacksPath
getStacks

echo "> Upgrading $NUM_STACKS Stacks..."

storeIFS

for stackName in $STACK_LIST; do
    INDEX_COUNT=$((INDEX_COUNT+1))
    echo $INDEX_COUNT - Upgrading $stackName...
    restoreIFS

    upgradeStack $stackName

    storeIFS

    if [ ! "$INDEX_COUNT" -eq "$NUM_STACKS" ]; then
        echo =======================================================
    fi
done

restoreIFS