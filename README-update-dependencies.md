# Update Package Dependencies Scripts

These scripts are designed to update the `package.json` file created by the ServiceNow SDK with the correct dependencies for development with the custom ServiceNow packages.

## What the scripts do:

1. **Update `@servicenow/glide` dependency** - Changes from the published version to the git repository: `git://github.com/sonisoft-cnanda/servicenow-glide`
2. **Add `sn-sdk-mock` dependency** - Adds the local mock package: `file:../sn-sdk-mock`
3. **Create backup** - Saves the original `package.json` as `package.json.backup`
4. **Optional installation** - Can install the updated dependencies automatically

## Prerequisites:

- **jq** (JSON processor) must be installed:
  - Ubuntu/Debian: `sudo apt-get install jq`
  - macOS: `brew install jq`
  - CentOS/RHEL: `sudo yum install jq`
  - Fedora: `sudo dnf install jq`
  - Windows: `choco install jq` or `scoop install jq`

## Usage:

### Linux/macOS:

```bash
# Navigate to your project directory (where package.json exists)
cd your-project-directory

# Run the script (update only)
./update-package-dependencies.sh

# Run the script with automatic dependency installation
./update-package-dependencies.sh --install
```

### Windows:

```powershell
# Navigate to your project directory (where package.json exists)
cd your-project-directory

# Run the script (update only)
.\update-package-dependencies.ps1

# Run the script with automatic dependency installation
.\update-package-dependencies.ps1 -Install
```

## Example workflow:

1. Run the main setup script (`setup-project.sh`, `setup-project-macos.sh`, or `setup-project.ps1`)
2. Navigate to your project directory: `cd sn-dev-project`
3. Use the ServiceNow SDK to create your app (this creates the initial `package.json`)
4. Run the update script: `./update-package-dependencies.sh --install`
5. Start developing with the correct dependencies!

## What gets updated:

**Before:**
```json
{
  "devDependencies": {
    "@servicenow/sdk": "4.0.0",
    "@servicenow/glide": "26.0.1",
    "eslint": "8.50.0",
    "@servicenow/eslint-plugin-sdk-app-plugin": "4.0.0",
    "typescript": "5.5.4"
  }
}
```

**After:**
```json
{
  "devDependencies": {
    "@servicenow/sdk": "4.0.0",
    "@servicenow/glide": "git://github.com/sonisoft-cnanda/servicenow-glide",
    "eslint": "8.50.0",
    "@servicenow/eslint-plugin-sdk-app-plugin": "4.0.0",
    "typescript": "5.5.4",
    "sn-sdk-mock": "file:../sn-sdk-mock"
  }
}
```

## Safety features:

- **Backup creation**: Original `package.json` is saved as `package.json.backup`
- **Error handling**: Scripts exit gracefully if `package.json` is not found
- **Validation**: Checks for required tools before proceeding
- **Non-destructive**: Can be run multiple times safely

## Troubleshooting:

- **"jq is required"**: Install jq using the commands above
- **"package.json not found"**: Make sure you're in the correct project directory
- **"npm install failed"**: Check that Node.js and npm are properly installed and accessible
