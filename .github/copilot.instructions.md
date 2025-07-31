# Project Context and Coding Guidelines

## Language Selection

- Always select the most suitable programming language for each feature or requirement, based on efficiency, reliability, ecosystem support, and the project's needs.
- Do not force the use of a single language for all modules—choose contextually.

## Code Structure & Logic

- Avoid overlapping or redundant logic and functions throughout the entire project.
- If a main menu and submenus are implemented, always ensure users can return to the previous menu from any submenu.
- Prevent duplication of logic or functions, especially with different names but identical functionality. If duplicates are found, consolidate them into a single, clearly-named function and remove the redundant versions.
- Avoid code that is hard to maintain or abandoned unique logic.

## Keyboard Shortcut Consistency

- Always ensure that the `Ctrl+A` (`editor.action.selectAll`) shortcut in VSCode remains active for "Select All" functionality in the editor.
- If an extension or custom keybinding attempts to override or use `Ctrl+A` for another command, **reassign that extension's shortcut to a different key combination** (such as `Ctrl+Alt+A`, `Ctrl+Shift+A`, etc.).
- When modifying or generating `keybindings.json`, always check that `"key": "ctrl+a"` is mapped to `"command": "editor.action.selectAll"` with `"when": "editorTextFocus"`.
- Never disable or remove the default `Ctrl+A` select all shortcut in the editor.

## Naming Conventions

- Use consistent, clear, and meaningful naming conventions for all functions and logic.
- Variable and function names can be in Indonesian, English, or a mix, as long as they are clear, unambiguous, and consistent across the codebase.

## Documentation & Comments

- Every function must include brief documentation or comments explaining its purpose and usage.
- Always perform spellcheck for all comments, documentation, and identifiers to ensure correct spelling and clarity.

## Ambiguous Requests & Research

- If a user request is ambiguous, always ask for clarification or confirmation before generating code.
- If stuck or incomplete, perform further research using up-to-date web sources or clearly state any limitations.

## Code Quality

- Ensure the code is readable, maintainable, and understandable for other developers.
- Refactor code whenever possible to improve clarity, efficiency, and maintainability.
- Follow best practices and conventions of the chosen language for each file or module.

## ShellCheck Warning Handling Guidelines

To ensure Bash scripts are robust, maintainable, and ShellCheck-clean, always follow these rules to prevent common warnings:

- For every small or major update to the main script, always run all types of ShellCheck and wait patiently for the output before proceeding.
- For any ShellCheck warning (of any SC code), never use tricks or fake fixes to suppress or bypass the warning; always address each warning by genuinely applying best practices or removing the root cause.

- Always check and fix any ShellCheck warnings, especially:
  - SC2162: Use `read -r` for user input
  - SC2155: Declare and assign variables separately
  - SC2184: Quote all arguments to `unset`
  - SC2034: Remove unused variables or export if needed
  - SC2317: Ensure no unreachable/dead code

## Bash Scripting Best Practices

Bash Scripting Best Practices (ShellCheck)
Always use read -r for any user input in Bash scripts to avoid ShellCheck SC2162 warnings and ensure correct handling of backslashes.

Never use read -p -r or read -p ... -r.
If a prompt is needed, always use echo -ne "Prompt: " first, then read -r variable.
Example:

```bash
echo -ne "Enter your name: "
read -r name
Or, for shells that support it, use:
```

```bash
read -r -p "Enter your name: " name
```

But never reverse the order of options.

### SC2155: Declare and assign separately to avoid masking return values

Declare local variables and assign values in separate lines within functions; never combine with local var=$(...).

```bash
local my_var
my_var="$(some_command)"
```

### SC2184: Quote arguments to unset so they're not glob expanded

Always quote all arguments to unset to prevent unintended filename expansion.

```bash
unset "$var1" "$var2"
```

### SC2034: Unused variable

Remove variables that are not used, or export if needed externally.

```bash
# Remove unused:
# my_var="value"
# Or, if needed outside:
export my_var="value"
```

### SC2317: Unreachable code (dead code)

Make sure every function defined is called at least once. Remove or demonstrate usage of functions to avoid dead code warnings.

```bash
# Example usage:
get_category_display_name "ai"
```

## ShellCheck Warning Handling Guidelines

Always check and fix any ShellCheck warnings, especially:

- SC2162: Use read -r
- SC2155: Declare and assign separately
- SC2184: Quote all arguments to unset
- SC2034: No unused variables
- SC2317: No unreachable/dead code
