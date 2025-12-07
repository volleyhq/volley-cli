# Contributing to Volley CLI

Thank you for your interest in contributing to Volley CLI! We welcome contributions from the community.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue with:
- A clear description of the problem
- Steps to reproduce the issue
- Expected vs actual behavior
- Your operating system and version
- Volley CLI version (`volley --version`)

### Suggesting Features

We'd love to hear your ideas! Please open an issue with:
- A clear description of the feature
- Use case or problem it solves
- Any examples or mockups (if applicable)

### Code Contributions

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
   - Follow Go best practices and conventions
   - Add tests for new functionality
   - Update documentation as needed
4. **Test your changes**
   ```bash
   make test
   ```
5. **Commit your changes**
   - Write clear, descriptive commit messages
   - Reference issue numbers if applicable
6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```
7. **Open a Pull Request**
   - Provide a clear description of your changes
   - Reference any related issues
   - Ensure all tests pass

## Development Setup

### Prerequisites

- Go 1.21 or later
- Make (for build commands)

### Building

```bash
# Build for your platform
make build

# Build for all platforms
make release

# Run tests
make test
```

### Code Style

- Follow Go standard formatting (`go fmt`)
- Use `golangci-lint` for linting (if configured)
- Write clear, self-documenting code
- Add comments for exported functions and types

## Questions?

If you have questions about contributing, feel free to:
- Open an issue with the `question` label
- Check our [documentation](https://docs.volleyhooks.com)
- Visit [volleyhooks.com](https://volleyhooks.com)

Thank you for contributing to Volley CLI! 🎉

