. "$LIB_DIR/core.sh"

moveToStacksPath
getStacks

echo "> Pulling $NUM_STACKS Stacks..."

iterateStacksForSingleOp pull "Pulling"