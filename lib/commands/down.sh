. "$LIB_DIR/core.sh"

moveToStacksPath

if [ -z "$1" ]; then
    errorAndExit "Usage: hlrunner down <stack>" 1
fi

composeOperation $1 down