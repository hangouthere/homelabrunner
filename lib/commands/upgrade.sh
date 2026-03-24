. "$LIB_DIR/core.sh"

moveToStacksPath

if [ -z "$1" ]; then
    errorAndExit "Usage: hlrunner upgrade <stack>" 1
fi

upgradeStack $1