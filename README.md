# ServiceNow SDK Project Setup

This repository contains scripts and tools to set up a complete ServiceNow development environment with custom dependencies and mocking capabilities.

## 🚀 Quick Start

The setup process involves three main steps:

1. **Run the setup script** to create your development environment
2. **Use ServiceNow SDK** to create your application
3. **Update dependencies** to use custom packages

## 📋 Prerequisites

### Required Software

- **Git** - For cloning repositories
- **Node.js** - Will be installed via nodenv
- **jq** (JSON processor) - Required for dependency updates
  - Ubuntu/Debian: `sudo apt-get install jq`
  - macOS: `brew install jq`
  - CentOS/RHEL: `sudo yum install jq`
  - Fedora: `sudo dnf install jq`
  - Windows: `choco install jq` or `scoop install jq`

### Platform-Specific Requirements

#### Linux
- Build tools (automatically installed by script)
- curl

#### macOS
- Xcode Command Line Tools (automatically installed by script)
- Homebrew (automatically installed by script)

#### Windows
- PowerShell 5.0 or later
- Git for Windows (recommended)

## 🛠️ Setup Scripts

Choose the appropriate script for your platform:

### Linux
```bash
./src/setup-project.sh
```

### macOS
```bash
./src/setup-project-macos.sh
```

### Windows
```powershell
.\src\setup-project.ps1
```

### Script Options

All scripts support the following options:

```bash
# Set custom project name
./src/setup-project.sh --name my-custom-project

# Show help
./src/setup-project.sh --help
```

## 📁 What the Setup Scripts Do

1. **Clone Required Repositories**
   - `sn-sdk-mock` - Mocking framework for ServiceNow development
   - `servicenow-glide` - Custom Glide API package

2. **Install Node.js Environment Manager**
   - **Linux/macOS**: Installs nodenv
   - **Windows**: Installs nodenv-win

3. **Create Project Structure**
   ```
   sn-dev-project/
   ├── .node-version (22.16.0)
   ├── .eslintrc.js (macOS only)
   ├── .gitignore (macOS only)
   ├── tsconfig.json
   ├── src/
   └── test/
   ```

4. **Verify npm Installation**
   - Ensures npm is available in the project's Node.js environment
   - Installs npm if missing

## 🎯 Complete Workflow

### Step 1: Run Setup Script

```bash
# Linux/macOS
./src/setup-project.sh

# Windows
.\src\setup-project.ps1
```

### Step 2: Navigate to Project Directory

```bash
cd sn-dev-project
```

### Step 3: Install Node.js Version

```bash
# Install the specified Node.js version
nodenv install 22.16.0

# Set it as the local version for this project
nodenv local 22.16.0
```

### Step 4: Create ServiceNow Application

Use the ServiceNow SDK to create your application:

```bash
# This will create the initial package.json
now-sdk create app
```

Follow the interactive prompts to configure your application.

### Step 5: Update Dependencies

After the ServiceNow SDK creates your `package.json`, update it with the custom dependencies:

```bash
# Linux/macOS
./src/update-package-dependencies.sh --install

# Windows
.\src\update-package-dependencies.ps1 -Install
```

This script will:
- Update `@servicenow/glide` to use the custom git repository
- Add `sn-sdk-mock` as a local dependency
- Install the updated dependencies

## 🔧 Why Custom Dependencies?

### Custom servicenow-glide Package

The setup scripts replace the official `@servicenow/glide` package with a custom version from our git repository. Here's why:

#### The Multi-Application Challenge

When building multiple ServiceNow applications that interact with each other, the standard TypeScript approach becomes cumbersome. The official ServiceNow documentation shows how to add custom type definitions using `declare module`, but this requires duplicating the same declarations across every application.

For example, if you define custom types like this:

```typescript
declare module '@servicenow/glide/sn_app_api' {
    class AppStoreAPI {
        static canUpgradeAnyStoreApp(): boolean
    }
}
```

You need to duplicate this declaration in each application to use those types, making it difficult to scale across multiple applications.

#### The Solution

Our custom `servicenow-glide` package provides:

- **Centralized type definitions** - Define custom types once in a shared library
- **Cross-application consistency** - Use the same types across all your ServiceNow applications
- **Reduced maintenance** - Update types in one place instead of multiple applications
- **Enhanced scalability** - Easily add new custom APIs and share them across projects

### sn-sdk-mock Package

The `sn-sdk-mock` package provides:

- **Local development testing** - Mock ServiceNow APIs for offline development
- **Unit testing support** - Test your code without a ServiceNow instance
- **API simulation** - Simulate ServiceNow behavior for development and testing

### Step 6: Start Developing!

You're now ready to develop with:
- Custom Glide API packages
- Mocking capabilities for testing
- Proper TypeScript configuration
- ESLint setup (macOS)

## 📦 Project Structure After Setup

```
your-workspace/
├── sn-dev-project/           # Your ServiceNow application
│   ├── .node-version
│   ├── package.json          # Updated with custom dependencies
│   ├── tsconfig.json
│   ├── src/
│   └── test/
├── sn-sdk-mock/             # Mocking framework
├── servicenow-glide/        # Custom Glide API package
└── setup scripts
```

## 🔧 Available Scripts

### Setup Scripts

| Script | Platform | Description |
|--------|----------|-------------|
| `setup-project.sh` | Linux | Full environment setup for Linux |
| `setup-project-macos.sh` | macOS | Enhanced setup with additional tools |
| `setup-project.ps1` | Windows | PowerShell setup script |

### Update Scripts

| Script | Platform | Description |
|--------|----------|-------------|
| `update-package-dependencies.sh` | Linux/macOS | Updates package.json dependencies |
| `update-package-dependencies.ps1` | Windows | PowerShell dependency updater |

## 🎛️ Configuration

### Node.js Version

The scripts use Node.js version `22.16.0` by default. To change this:

1. Edit the `NODE_VERSION` variable in the setup scripts
2. Update the `.node-version` file in your project

### Project Name

Default project name is `sn-dev-project`. Change it with:

```bash
./src/setup-project.sh --name my-project-name
```

## 🧪 Testing Your Setup

After completing the setup, verify everything works:

```bash
cd sn-dev-project

# Check Node.js version
node --version  # Should show v22.16.0

# Check npm version
npm --version

# Verify dependencies
npm list @servicenow/glide
npm list sn-sdk-mock
```

## 🐛 Troubleshooting

### Common Issues

#### "jq is required"
Install jq using the platform-specific commands listed in Prerequisites.

#### "package.json not found"
Make sure you're in the correct project directory when running the update script.

#### "Node.js is not available"
Ensure nodenv is properly installed and the Node.js version is set:
```bash
nodenv install 22.16.0
nodenv local 22.16.0
```

#### "npm install failed"
Check that Node.js and npm are properly installed and accessible in your project directory.

#### Permission Issues (Linux/macOS)
Make scripts executable:
```bash
chmod +x src/setup-project.sh
chmod +x src/update-package-dependencies.sh
```

### Getting Help

Run any script with `--help` to see available options:

```bash
./src/setup-project.sh --help
./src/update-package-dependencies.sh --help
```

## 🔄 Updating Dependencies

The `update-package-dependencies` scripts can be run multiple times safely. They:

- Create backups of your `package.json`
- Only update the specific dependencies needed
- Preserve all other package.json settings

## 📚 Additional Resources

- [ServiceNow SDK Documentation](https://developer.servicenow.com/dev.do#!/reference/api/vancouver/now-sdk)
- [ServiceNow Development Guide](https://developer.servicenow.com/dev.do)
- [TypeScript Documentation](https://www.typescriptlang.org/docs/)

## 🤝 Contributing

If you find issues or have improvements:

1. Check the existing issues
2. Create a new issue with detailed information
3. Submit a pull request with your changes

## 📄 License

This project is licensed under the same terms as the ServiceNow SDK.
