. "$LIB_DIR/core.sh"

moveToStacksPath

if [ -z "$1" ]; then
    errorAndExit "Usage: hlrunner logs <stack>" 1
fi

composeOperation $1 logs