. "$LIB_DIR/core.sh"
. "$LIB_DIR/help.sh"

moveToStacksPath
getStacks

echo "${txtBold}${txtGreen}> Found $NUM_STACKS Stack(s):${colorReset}"

storeIFS
envOutput=""

for stackName in $STACK_LIST; do
  INDEX_COUNT=$((INDEX_COUNT+1))
  envOutput="$envOutput\n    ${txtGrey}($INDEX_COUNT)${colorReset} $stackName"
done

restoreIFS

echo "$envOutput"
echo ""