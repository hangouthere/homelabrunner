. "$LIB_DIR/core.sh"
TEMPLATE_DIR="$DATA_DIR/templates"
moveToStacksPath

if [ -z "$1" ]; then
    errorAndExit "Usage: hlrunner init <name>" 1
fi

stackName=$1
stackPath="$HLR_STACKS_PATH_FULL/$stackName"

if [ -d "$stackPath" ]; then
    errorAndExit "Error: Stack '$stackName' already exists at $stackPath" 52
fi

echo "Creating stack: $stackName"

mkdir -p "$stackPath"

if [ -f "$TEMPLATE_DIR/compose.yaml" ]; then
    cp "$TEMPLATE_DIR/compose.yaml" "$stackPath/compose.yaml"
    echo "  - created compose.yaml"
else
    errorAndExit "Error: Template compose.yaml not found" 53
fi

if [ -f "$TEMPLATE_DIR/.env" ]; then
    cp "$TEMPLATE_DIR/.env" "$stackPath/.env"
    cp "$TEMPLATE_DIR/.env" "$stackPath/.env-example"
    echo "  - created .env"
    echo "  - created .env-example"
else
    errorAndExit "Error: Template .env not found" 53
fi

echo ""
echo "${txtGreen}Stack '$stackName' created successfully!${colorReset}"
echo "  Location: $stackPath"
echo ""
echo "Next steps:"
echo "  cd $stackPath"
echo "  # edit .env if needed"
echo "  hlrunner up $stackName"