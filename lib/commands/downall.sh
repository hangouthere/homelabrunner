. "$LIB_DIR/core.sh"

moveToStacksPath
getStacks

echo "> Stopping $NUM_STACKS Stacks..."

iterateStacksForSingleOp down "Stopping"