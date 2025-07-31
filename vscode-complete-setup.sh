#!/usr/bin/env bash
# ====================================================================
#  VS Code Complete Setup - Main Installer
#  VERSION: 2.1.0
#  AUTHOR: ROKHANZ
#  FOCUS: VS Code Extension Installation + Uninstall + Configuration
#  FILE: vscode-complete-setup.sh
# ====================================================================

set -uo pipefail  # Removed -e flag to prevent early exit on non-zero returns

# Global shopping cart system
declare -a GLOBAL_CART=()

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'
GRAY='\033[0;37m'; WHITE='\033[1;37m'; ORANGE='\033[0;33m'; NC='\033[0m'

# Disable colors if needed
[[ ! -t 1 || "${TERM:-}" == "dumb" || -n "${NO_COLOR:-}" ]] && {
    RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' GRAY='' WHITE='' ORANGE='' NC=''
}

# ============================================================================
# GLOBAL EXTENSION DETECTION SYSTEM
# ============================================================================

# Global variables for extension detection
declare -a INSTALLED_EXTENSIONS=()
declare -A INSTALLED_BY_CATEGORY=()

# Auto detect and cache installed extensions
detect_installed_extensions() {
    echo -e "${CYAN}🔍 Detecting installed extensions...${NC}"

    # Clear previous cache
    INSTALLED_EXTENSIONS=()
    # Clear associative array properly
    for key in "${!INSTALLED_BY_CATEGORY[@]}"; do
        unset "INSTALLED_BY_CATEGORY[$key]"
    done

    # Get installed extensions
    local installed_raw
    installed_raw=$(code --list-extensions 2>/dev/null) || {
        echo -e "${YELLOW}⚠️ Could not detect VS Code or extensions${NC}"
        return 1
    }

    if [[ -z "$installed_raw" ]]; then
        echo -e "${YELLOW}⚠️ No extensions installed${NC}"
        return 0
    fi

    # Cache installed extensions
    while IFS= read -r ext; do
        # Skip empty lines and header lines
        if [[ -n "$ext" && "$ext" != "Extensions installed on"* && "$ext" != *":"* ]]; then
            INSTALLED_EXTENSIONS+=("$ext")
        fi
    done <<< "$installed_raw"

    # Simplified categorization - just count extensions
    echo -e "${GREEN}✅ Found ${#INSTALLED_EXTENSIONS[@]} installed extensions${NC}"

    # Set a simple category for all extensions (for compatibility)
    INSTALLED_BY_CATEGORY[all]="${INSTALLED_EXTENSIONS[*]}"

    return 0
}

# Show installed extensions summary
show_installed_summary() {
    if [[ ${#INSTALLED_EXTENSIONS[@]} -eq 0 ]]; then
        echo -e "${YELLOW}📋 No extensions installed${NC}"
        return 0
    fi

    echo -e "${CYAN}📋 Installed Extensions Summary (${#INSTALLED_EXTENSIONS[@]} total):${NC}"

    for category in "${!INSTALLED_BY_CATEGORY[@]}"; do
        local category_name
        category_name=$(get_category_display_name "$category")
        local ext_count
        ext_count=$(echo "${INSTALLED_BY_CATEGORY[$category]}" | wc -w)
        echo -e "${BLUE}  ${category_name}: ${YELLOW}$ext_count extensions${NC}"
    done
}

# Check if specific extension is installed
is_extension_installed() {
    local ext="$1"
    for installed_ext in "${INSTALLED_EXTENSIONS[@]}"; do
        if [[ "$installed_ext" == "$ext" ]]; then
            return 0
        fi
    done
    return 1
}

# Get extension category
get_extension_category() {
    local ext_id="$1"
    # AI Extensions
    if [[ "$ext_id" =~ ^(github\.copilot|github\.copilot-chat|tabnine\.tabnine-vscode|codeium\.codeium|visualstudioexptteam\.vscodeintellicode|amazonwebservices\.aws-toolkit-vscode|continue\.continue|rubberduck\.rubberduck-vscode|sourcery\.sourcery|codiga\.vscode-plugin|mintlify\.document|openai\.openai-api|anthropic\.claude|ollama\.ollama|coderush\.coderush)$ ]]; then
        echo "ai"
    # JavaScript/TypeScript/Node.js
    elif [[ "$ext_id" =~ ^(ms-vscode\.vscode-typescript-next|esbenp\.prettier-vscode|dbaeumer\.vscode-eslint|christian-kohler\.npm-intellisense|christian-kohler\.path-intellisense|xabikos\.javascriptsnippets|ms-vscode\.vscode-node-azure-pack|ms-vscode\.vscode-js-debug|bradlc\.vscode-tailwindcss)$ ]]; then
        echo "javascript"
    # Python
    elif [[ "$ext_id" =~ ^(ms-python\.python|ms-python\.autopep8|ms-python\.black-formatter|ms-python\.pylint|ms-python\.isort|ms-python\.debugpy|njpwerner\.autodocstring|ms-toolsai\.jupyter)$ ]]; then
        echo "python"
    # Themes
    elif [[ "$ext_id" =~ ^(dracula-theme\.theme-dracula|ms-vscode\.theme-onedarkpro|monokai\.theme-monokai-pro-vscode|wesbos\.theme-cobalt2|equinusocio\.vsc-material-theme|akamud\.vscode-theme-onedark|sdras\.night-owl|sainnhe\.gruvbox-material|sainnhe\.everforest|johnpapa\.winteriscoming|ms-vscode\.theme-tomorrowkit)$ ]]; then
        echo "themes"
    # Other Languages (Rust, Go, C#, Java, etc.)
    elif [[ "$ext_id" =~ ^(rust-lang\.rust-analyzer|golang\.go|ms-dotnettools\.csharp|ms-vscode\.cpptools|redhat\.java|vscjava\.vscode-java-pack|ms-vscode\.powershell|mads-hartmann\.bash-ide-vscode|foxundermoon\.shell-format|timonwong\.shellcheck|remisa\.shellman|mkhl\.shfmt|shakram02\.bash-beautify|rogalmic\.bash-debug|jetmartin\.bats|bmalehorn\.shell-syntax-improved|jeff-hykin\.better-shellscript-syntax|tetradresearch\.vscode-h2o|dart-code\.dart-code|dart-code\.flutter|ms-vscode\.cmake-tools)$ ]]; then
        echo "languages"
    # Productivity
    elif [[ "$ext_id" =~ ^(ms-vscode\.vscode-icons|pkief\.material-icon-theme|vscode-icons-team\.vscode-icons|usernamehw\.errorlens|streetsidesoftware\.code-spell-checker|aaron-bond\.better-comments|formulahendry\.auto-rename-tag|ms-vscode\.live-server|ritwickdey\.liveserver|formulahendry\.code-runner|ms-vscode-remote\.remote-ssh|ms-vscode\.remote-explorer|gruntfuggly\.todo-tree|alefragnani\.bookmarks)$ ]]; then
        echo "productivity"
    # Git & Version Control
    elif [[ "$ext_id" =~ ^(eamodio\.gitlens|mhutchie\.git-graph|donjayamanne\.githistory|waderyan\.gitblame|felipecaputo\.git-project-manager|huizhou\.githd|codezombiech\.gitignore|github\.vscode-pull-request-github)$ ]]; then
        echo "git"
    else
        echo "other"
    fi
}

# Show available extensions in database
show_available_extensions() {
    echo -e "${CYAN}📚 Available Extensions Database:${NC}"
    echo ""

    local current_category=""
    for ext_id in "${!EXTENSION_INFO[@]}"; do
        local info="${EXTENSION_INFO[$ext_id]}"
        local ext_name
        local ext_desc
        local category
        ext_name=$(echo "$info" | cut -d'|' -f1)
        ext_desc=$(echo "$info" | cut -d'|' -f2)
        category=$(get_extension_category "$ext_id")
        local category_display
        category_display=$(get_category_display_name "$category")

        if [[ "$category" != "$current_category" ]]; then
            echo -e "${BLUE}🔸 $category_display${NC}"
            current_category="$category"
        fi

        local status_indicator=""
        if is_extension_installed "$ext_id"; then
            status_indicator="${GREEN}✅${NC}"
        else
            status_indicator="${GRAY}⭕${NC}"
        fi

        echo -e "  $status_indicator ${YELLOW}$ext_name${NC} - ${GRAY}$ext_desc${NC}"
    done

    echo ""
    echo -e "${CYAN}Legend: ${GREEN}✅ Installed${NC} | ${GRAY}⭕ Not Installed${NC}"
}

# Extension database dengan informasi lengkap - COMPREHENSIVE LIST
declare -A EXTENSION_INFO=(
    # AI Extensions
    ["github.copilot"]="GitHub Copilot|AI assistant untuk coding|github.copilot|Memberikan code completion, suggestions, dan generate code otomatis menggunakan AI"
    ["github.copilot-chat"]="GitHub Copilot Chat|Chat AI untuk bantuan coding|github.copilot-chat|Chat interface untuk bertanya dan mendapat bantuan coding dari AI"
    ["tabnine.tabnine-vscode"]="Tabnine AI|AI code completion|tabnine.tabnine-vscode|AI-powered autocomplete yang memprediksi code berdasarkan konteks"
    ["codeium.codeium"]="Codeium AI|Free AI coding assistant|codeium.codeium|AI coding assistant gratis dengan fitur autocomplete dan chat"
    ["visualstudioexptteam.vscodeintellicode"]="IntelliCode|AI-assisted development|visualstudioexptteam.vscodeintellicode|AI yang memberikan smart suggestions berdasarkan best practices"
    ["amazonwebservices.aws-toolkit-vscode"]="AWS Toolkit|AWS development tools|amazonwebservices.aws-toolkit-vscode|Tools lengkap untuk develop, deploy, dan debug aplikasi AWS"
    ["continue.continue"]="Continue|AI code assistant|continue.continue|Open source AI code assistant dengan support untuk multiple LLMs"
    ["rubberduck.rubberduck-vscode"]="Rubber Duck|AI debugging assistant|rubberduck.rubberduck-vscode|AI assistant untuk debugging, code explanation, dan generate tests"
    ["sourcery.sourcery"]="Sourcery|AI code reviewer|sourcery.sourcery|AI-powered code reviewer yang memberikan suggestions untuk improve code quality"
    ["codiga.vscode-plugin"]="Codiga|AI code analysis|codiga.vscode-plugin|AI-powered static code analysis dengan real-time security dan quality checks"
    ["mintlify.document"]="Mintlify Doc Writer|AI docstring generator|mintlify.document|Generate documentation dan docstrings otomatis menggunakan AI"
    ["openai.openai-api"]="OpenAI API|OpenAI integration|openai.openai-api|Integration dengan OpenAI APIs untuk AI-powered development"
    ["huggingface.huggingface-vscode"]="Hugging Face|AI model integration|huggingface.huggingface-vscode|Integration dengan Hugging Face models untuk ML development"
    ["aicommits.aicommits"]="AI Commits|AI commit messages|aicommits.aicommits|Generate commit messages otomatis menggunakan AI berdasarkan code changes"
    ["blackboxapp.blackbox"]="Blackbox AI|AI code search|blackboxapp.blackbox|AI-powered code search dan autocomplete dari millions of code repos"
    ["phind.phind"]="Phind|AI search for developers|phind.phind|AI-powered search engine khusus untuk developers dengan code examples"

    # Language Extensions - JavaScript/Node.js
    ["ms-vscode.vscode-typescript-next"]="TypeScript|TypeScript language support|ms-vscode.vscode-typescript-next|Support lengkap untuk TypeScript dengan IntelliSense dan debugging"
    ["bradlc.vscode-tailwindcss"]="Tailwind CSS|Tailwind CSS IntelliSense|bradlc.vscode-tailwindcss|Autocomplete, syntax highlighting, dan preview untuk Tailwind CSS"
    ["esbenp.prettier-vscode"]="Prettier|Code formatter|esbenp.prettier-vscode|Automatic code formatter untuk berbagai bahasa pemrograman"
    ["dbaeumer.vscode-eslint"]="ESLint|JavaScript linter|dbaeumer.vscode-eslint|Linting dan fixing otomatis untuk JavaScript/TypeScript code quality"
    ["ms-vscode.vscode-json"]="JSON Language|JSON language support|ms-vscode.vscode-json|Syntax highlighting, validation, dan formatting untuk file JSON"
    ["christian-kohler.npm-intellisense"]="npm Intellisense|npm modules autocomplete|christian-kohler.npm-intellisense|Autocomplete untuk import npm modules dalam JavaScript/TypeScript"
    ["christian-kohler.path-intellisense"]="Path Intellisense|File path autocomplete|christian-kohler.path-intellisense|Autocomplete untuk file paths dalam import statements"
    ["xabikos.javascriptsnippets"]="JavaScript Snippets|JavaScript code snippets|xabikos.javascriptsnippets|Collection of useful JavaScript ES6 code snippets"
    ["ms-vscode.vscode-node-azure-pack"]="Node.js Azure Pack|Node.js tools for Azure|ms-vscode.vscode-node-azure-pack|Bundle tools untuk develop Node.js applications di Azure"
    ["ms-vscode.vscode-js-debug"]="JavaScript Debugger|JavaScript debugging|ms-vscode.vscode-js-debug|Advanced debugging untuk JavaScript dan Node.js applications"

    # Language Extensions - Python
    ["ms-python.python"]="Python|Python language support|ms-python.python|Support lengkap untuk Python dengan IntelliSense, debugging, dan testing"
    ["ms-python.black-formatter"]="Black Formatter|Python code formatter|ms-python.black-formatter|Code formatter Python yang uncompromising dan konsisten"
    ["ms-python.flake8"]="Flake8|Python linter|ms-python.flake8|Python linter untuk style guide enforcement dan error detection"
    ["ms-python.pylint"]="Pylint|Python static code analysis|ms-python.pylint|Static code analysis untuk Python dengan quality checks"
    ["ms-python.autopep8"]="autopep8|Python code formatter|ms-python.autopep8|Automatically formats Python code berdasarkan PEP 8 style guide"
    ["ms-python.isort"]="isort|Python import sorter|ms-python.isort|Automatically sort dan organize Python imports"
    ["ms-python.debugpy"]="Python Debugger|Python debugging|ms-python.debugpy|Advanced debugger untuk Python applications"
    ["njpwerner.autodocstring"]="autoDocstring|Python docstring generator|njpwerner.autodocstring|Generate docstrings otomatis untuk Python functions dan classes"
    ["ms-toolsai.jupyter"]="Jupyter|Jupyter notebook support|ms-toolsai.jupyter|Support lengkap untuk Jupyter notebooks dalam VS Code"

    # Language Extensions - Web Development
    ["formulahendry.auto-close-tag"]="Auto Close Tag|Auto close HTML tags|formulahendry.auto-close-tag|Automatically add closing tags untuk HTML dan XML"
    ["formulahendry.auto-rename-tag"]="Auto Rename Tag|Auto rename paired HTML tags|formulahendry.auto-rename-tag|Automatically rename paired HTML/XML tags secara sinkron"
    ["ms-vscode.live-server"]="Live Server|Live reload for web development|ms-vscode.live-server|Launch local development server dengan live reload"
    ["ritwickdey.liveserver"]="Live Server (Alt)|Launch local development server|ritwickdey.liveserver|Alternative live server dengan fitur preview real-time"
    ["ecmel.vscode-html-css"]="HTML CSS Support|CSS support for HTML|ecmel.vscode-html-css|Enhance HTML dengan CSS class dan ID suggestions"
    ["pranaygp.vscode-css-peek"]="CSS Peek|Go to CSS definition|pranaygp.vscode-css-peek|Peek dan go to CSS definitions dari HTML files"
    ["zignd.html-css-class-completion"]="HTML CSS Class Completion|CSS class autocomplete|zignd.html-css-class-completion|Intelligent CSS class name completion untuk HTML"

    # Language Extensions - Other Languages
    ["rust-lang.rust-analyzer"]="Rust Analyzer|Rust language support|rust-lang.rust-analyzer|Official Rust language server dengan IntelliSense dan debugging"
    ["golang.go"]="Go|Go language support|golang.go|Comprehensive support untuk Go programming language"
    ["ms-dotnettools.csharp"]="C#|C# language support|ms-dotnettools.csharp|Full support untuk C# development dengan .NET framework"
    ["ms-vscode.cpptools"]="C/C++|C/C++ language support|ms-vscode.cpptools|IntelliSense, debugging, dan code browsing untuk C/C++"
    ["redhat.java"]="Java|Java language support|redhat.java|Language support untuk Java development"
    ["vscjava.vscode-java-pack"]="Java Extension Pack|Complete Java development|vscjava.vscode-java-pack|Bundle lengkap extensions untuk Java development"
    ["ms-vscode.powershell"]="PowerShell|PowerShell language support|ms-vscode.powershell|Rich PowerShell language support dan scripting"
    ["mads-hartmann.bash-ide-vscode"]="Bash IDE|Bash/Shell scripting IDE|mads-hartmann.bash-ide-vscode|Complete IDE support untuk Bash scripting dengan IntelliSense"
    ["foxundermoon.shell-format"]="Shell Format|Shell script formatter|foxundermoon.shell-format|Format dan beautify shell scripts dengan proper indentation"
    ["timonwong.shellcheck"]="ShellCheck|Shell script linter|timonwong.shellcheck|Advanced linting untuk shell scripts menggunakan ShellCheck"
    ["remisa.shellman"]="Shellman|Bash scripting snippets|remisa.shellman|Comprehensive Bash scripting snippets dan documentation"
    ["mkhl.shfmt"]="shfmt|Shell script formatter|mkhl.shfmt|Format shell scripts dengan shfmt tool"
    ["shakram02.bash-beautify"]="Bash Beautify|Bash script beautifier|shakram02.bash-beautify|Beautify dan format Bash scripts dengan proper indentation"
    ["rogalmic.bash-debug"]="Bash Debug|Bash debugger|rogalmic.bash-debug|Debug Bash scripts dengan breakpoints dan step-through debugging"
    ["jetmartin.bats"]="Bats|Bash testing framework|jetmartin.bats|Support untuk Bats (Bash Automated Testing System)"
    ["bmalehorn.shell-syntax-improved"]="Shell Syntax|Enhanced shell syntax|bmalehorn.shell-syntax-improved|Improved syntax highlighting untuk shell scripts"
    ["jeff-hykin.better-shellscript-syntax"]="Better Shell Syntax|Advanced shell syntax|jeff-hykin.better-shellscript-syntax|Superior syntax highlighting dan parsing untuk shell scripts"
    ["tetradresearch.vscode-h2o"]="H2O|Terminal enhancement|tetradresearch.vscode-h2o|Advanced terminal dan shell integration tools"
    ["ms-vscode.vscode-json"]="JSON Language|JSON support|ms-vscode.vscode-json|Enhanced JSON language support untuk konfigurasi files"
    ["dart-code.dart-code"]="Dart|Dart language support|dart-code.dart-code|Support untuk Dart programming language"
    ["dart-code.flutter"]="Flutter|Flutter development|dart-code.flutter|Complete Flutter development tools dan debugging"
    ["ms-vscode.cmake-tools"]="CMake Tools|CMake support|ms-vscode.cmake-tools|CMake language support dan build system integration"

    # Editor Tools - Code Execution & Testing
    ["formulahendry.code-runner"]="Code Runner|Run code in multiple languages|formulahendry.code-runner|Run code snippets atau files dalam berbagai bahasa programming"
    ["hbenl.vscode-test-explorer"]="Test Explorer|Unified test explorer|hbenl.vscode-test-explorer|Unified interface untuk run dan debug tests dari berbagai frameworks"
    ["ms-vscode.test-adapter-converter"]="Test Adapter Converter|Convert test frameworks|ms-vscode.test-adapter-converter|Convert test adapters untuk kompatibilitas dengan Test Explorer"
    ["orta.vscode-jest"]="Jest|JavaScript testing framework|orta.vscode-jest|Support lengkap untuk Jest testing framework dengan snapshot"
    ["ms-python.python-unittest"]="Python Unittest|Python unit testing|ms-python.python-unittest|Support untuk Python unit testing dan test discovery"

    # Editor Tools - Error & Quality
    ["usernamehw.errorlens"]="Error Lens|Highlight errors inline|usernamehw.errorlens|Highlight errors dan warnings langsung di editor secara inline"
    ["streetsidesoftware.code-spell-checker"]="Code Spell Checker|Spelling checker|streetsidesoftware.code-spell-checker|Spell checker untuk code comments, strings, dan documentation"
    ["ms-vscode.hexeditor"]="Hex Editor|Binary file editor|ms-vscode.hexeditor|Editor untuk binary files dalam format hexadecimal"
    ["adpyke.codesnap"]="CodeSnap|Take beautiful code screenshots|adpyke.codesnap|Generate beautiful screenshots dari code dengan syntax highlighting"

    # Editor Tools - Productivity
    ["ms-vscode.remote-containers"]="Dev Containers|Development in containers|ms-vscode.remote-containers|Develop dalam Docker containers dengan full VS Code experience"
    ["ms-vscode-remote.remote-ssh"]="Remote SSH|SSH remote development|ms-vscode-remote.remote-ssh|Edit files dan run commands di remote servers via SSH"
    ["ms-vscode.remote-repositories"]="Remote Repositories|GitHub remote repositories|ms-vscode.remote-repositories|Browse dan edit GitHub repositories langsung tanpa clone"
    ["alefragnani.bookmarks"]="Bookmarks|Mark lines and jump to them|alefragnani.bookmarks|Mark lines dalam code dan navigate dengan mudah"
    ["alefragnani.project-manager"]="Project Manager|Switch between projects|alefragnani.project-manager|Manage dan switch between multiple projects dengan mudah"
    ["gruntfuggly.todo-tree"]="Todo Tree|Show TODO comments in tree|gruntfuggly.todo-tree|Show TODO, FIXME, dan other comments dalam tree view"
    ["aaron-bond.better-comments"]="Better Comments|Improve comment visibility|aaron-bond.better-comments|Colored comments berdasarkan kategori (TODO, WARNING, dll)"

    # File & Data Formats
    ["redhat.vscode-yaml"]="YAML|YAML language support|redhat.vscode-yaml|Comprehensive YAML language support dengan validation dan schema"
    ["dotjoshjohnson.xml"]="XML Tools|XML formatting and tools|dotjoshjohnson.xml|XML formatting, minifying, dan XPath evaluation tools"
    ["ms-vscode.vscode-json"]="JSON Language|JSON language support|ms-vscode.vscode-json|JSON syntax highlighting, validation, dan schema support"
    ["janisdd.vscode-edit-csv"]="Edit CSV|CSV file editor|janisdd.vscode-edit-csv|Advanced CSV editor dengan table view dan data manipulation"
    ["mechatroner.rainbow-csv"]="Rainbow CSV|CSV file colorizer|mechatroner.rainbow-csv|Highlight CSV columns dengan colors untuk readability"
    ["ms-vscode.vscode-markdown"]="Markdown|Markdown language support|ms-vscode.vscode-markdown|Basic Markdown language support dan preview"
    ["yzhang.markdown-all-in-one"]="Markdown All in One|Complete markdown support|yzhang.markdown-all-in-one|Comprehensive Markdown support dengan shortcuts, TOC, dan preview"
    ["davidanson.vscode-markdownlint"]="Markdown Lint|Markdown linter|davidanson.vscode-markdownlint|Markdown linter untuk style consistency dan best practices"

    # Git & Version Control
    ["eamodio.gitlens"]="GitLens|Supercharge Git capabilities|eamodio.gitlens|Advanced Git features dengan blame, history, dan repository insights"
    ["github.vscode-pull-request-github"]="GitHub Pull Requests|GitHub integration|github.vscode-pull-request-github|Manage GitHub pull requests dan issues dari VS Code"
    ["github.vscode-github-actions"]="GitHub Actions|GitHub Actions support|github.vscode-github-actions|Manage dan monitor GitHub Actions workflows"
    ["donjayamanne.git-extension-pack"]="Git Extension Pack|Complete Git toolset|donjayamanne.git-extension-pack|Bundle extensions untuk comprehensive Git workflow"
    ["mhutchie.git-graph"]="Git Graph|View Git repository graph|mhutchie.git-graph|Visual Git repository graph dengan branch dan commit history"
    ["github.remotehub"]="Remote Repositories|Browse GitHub repositories|github.remotehub|Browse dan edit GitHub repositories langsung dalam VS Code"

    # Docker & DevOps
    ["ms-azuretools.vscode-docker"]="Docker|Docker support|ms-azuretools.vscode-docker|Comprehensive Docker support dengan container management dan debugging"
    ["ms-kubernetes-tools.vscode-kubernetes-tools"]="Kubernetes|Kubernetes support|ms-kubernetes-tools.vscode-kubernetes-tools|Kubernetes cluster management, YAML editing, dan deployment tools"
    ["hashicorp.terraform"]="Terraform|Terraform support|hashicorp.terraform|HashiCorp Terraform language support dengan syntax highlighting dan validation"
    ["redhat.vscode-commons"]="Commons|Common tools for development|redhat.vscode-commons|Common utilities dan dependencies untuk Red Hat extensions"

    # Themes - Dark
    ["dracula-theme.theme-dracula"]="Dracula Theme|Popular dark theme|dracula-theme.theme-dracula|Popular dark theme dengan color palette yang eye-friendly"
    ["zhuangtongfa.material-theme"]="Material Theme|Material design theme|zhuangtongfa.material-theme|Google Material Design inspired theme dengan variants"
    ["ms-vscode.theme-onedarkpro"]="One Dark Pro|Professional dark theme|ms-vscode.theme-onedarkpro|Professional dark theme based on Atom's One Dark"
    ["github.github-vscode-theme"]="GitHub Theme|Official GitHub theme|github.github-vscode-theme|Official GitHub theme dengan light dan dark variants"
    ["monokai.theme-monokai-pro-vscode"]="Monokai Pro|Professional Monokai theme|monokai.theme-monokai-pro-vscode|Premium Monokai theme dengan color filters dan customization"
    ["johnpapa.vscode-peacock"]="Peacock|Workspace color customizer|johnpapa.vscode-peacock|Customize VS Code workspace colors untuk multi-project development"

    # Themes - Light
    ["ms-vscode.theme-tomorrow-and-tomorrow-night"]="Tomorrow Theme|Tomorrow light/dark theme|ms-vscode.theme-tomorrow-and-tomorrow-night|Clean theme dengan light dan dark variants"
    ["pkief.material-icon-theme"]="Material Icon Theme|Material design icons|pkief.material-icon-theme|Material Design inspired file dan folder icons"
    ["vscode-icons-team.vscode-icons"]="vscode-icons|File icon theme|vscode-icons-team.vscode-icons|Comprehensive file icon theme dengan support untuk many file types"

    # Keybindings & Emulation
    ["ms-vscode.sublime-keybindings"]="Sublime Keybindings|Sublime Text keybindings|ms-vscode.sublime-keybindings|Port Sublime Text keyboard shortcuts ke VS Code"
    ["ms-vscode.atom-keybindings"]="Atom Keybindings|Atom editor keybindings|ms-vscode.atom-keybindings|Atom editor keyboard shortcuts compatibility"
    ["vscodevim.vim"]="Vim|Vim emulation|vscodevim.vim|Vim keybindings dan commands emulation dalam VS Code"
    ["ms-vscode.notepadplusplus-keybindings"]="Notepad++ Keybindings|Notepad++ keybindings|ms-vscode.notepadplusplus-keybindings|Notepad++ keyboard shortcuts compatibility"

    # REST API & HTTP
    ["humao.rest-client"]="REST Client|HTTP request client|humao.rest-client|Send HTTP requests dan view responses langsung dalam VS Code"
    ["rangav.vscode-thunder-client"]="Thunder Client|Lightweight REST client|rangav.vscode-thunder-client|Lightweight REST API client dengan GUI interface"
    ["ms-vscode.vscode-httpyac"]="httpYac|HTTP request runner|ms-vscode.vscode-httpyac|Advanced HTTP client dengan scripting capabilities"

    # Database
    ["ms-mssql.mssql"]="SQL Server|SQL Server support|ms-mssql.mssql|Microsoft SQL Server connection, querying, dan management tools"
    ["oracle.oracledevtools"]="Oracle Developer Tools|Oracle database tools|oracle.oracledevtools|Oracle database development tools dan SQL support"
    ["ms-ossdata.vscode-postgresql"]="PostgreSQL|PostgreSQL support|ms-ossdata.vscode-postgresql|PostgreSQL database connection dan query tools"
    ["mongodb.mongodb-vscode"]="MongoDB|MongoDB support|mongodb.mongodb-vscode|MongoDB database explorer, querying, dan management"

    # Snippets & Templates
    ["ms-vscode.vscode-snippet"]="Snippet|Code snippet manager|ms-vscode.vscode-snippet|Advanced code snippet management dan creation tools"
    ["formulahendry.auto-complete-tag"]="Auto Complete Tag|HTML tag completion|formulahendry.auto-complete-tag|Auto completion untuk HTML tags dengan intelligent suggestions"
    ["bradlc.vscode-tailwindcss"]="Tailwind CSS IntelliSense|Tailwind CSS support|bradlc.vscode-tailwindcss|Autocomplete, syntax highlighting, dan preview untuk Tailwind CSS"
    ["steoates.autoimport-es6-ts"]="Auto Import ES6/TS|Auto import for ES6/TypeScript|steoates.autoimport-es6-ts|Automatically import ES6/TypeScript modules saat typing"
)

# Predefined extensions for default installation - COMPREHENSIVE
DEFAULT_EXTENSIONS=(
    # AI Essentials
    "github.copilot" "github.copilot-chat" "tabnine.tabnine-vscode" "codeium.codeium"

    # JavaScript/Node.js Essentials
    "ms-vscode.vscode-typescript-next" "esbenp.prettier-vscode" "dbaeumer.vscode-eslint"
    "christian-kohler.npm-intellisense" "christian-kohler.path-intellisense"

    # Python Essentials
    "ms-python.python" "ms-python.black-formatter" "ms-python.flake8"

    # Editor Tools
    "formulahendry.code-runner" "usernamehw.errorlens" "ms-vscode.vscode-json"
    "formulahendry.auto-close-tag" "formulahendry.auto-rename-tag"

    # Git & Version Control
    "eamodio.gitlens" "github.vscode-pull-request-github"

    # Themes & Icons
    "dracula-theme.theme-dracula" "pkief.material-icon-theme"

    # Productivity
    "alefragnani.bookmarks" "gruntfuggly.todo-tree"

    # Keybindings
    "ms-vscode.sublime-keybindings"
)

# Extension categories for interactive mode - EXPANDED
declare -A CATEGORIES=(
    [ai]="github.copilot github.copilot-chat tabnine.tabnine-vscode codeium.codeium visualstudioexptteam.vscodeintellicode amazonwebservices.aws-toolkit-vscode continue.continue rubberduck.rubberduck-vscode sourcery.sourcery codiga.vscode-plugin mintlify.document openai.openai-api huggingface.huggingface-vscode aicommits.aicommits blackboxapp.blackbox phind.phind"

    [javascript]="ms-vscode.vscode-typescript-next esbenp.prettier-vscode dbaeumer.vscode-eslint christian-kohler.npm-intellisense christian-kohler.path-intellisense xabikos.javascriptsnippets ms-vscode.vscode-node-azure-pack ms-vscode.vscode-js-debug bradlc.vscode-tailwindcss"

    [python]="ms-python.python ms-python.black-formatter ms-python.flake8 ms-python.pylint ms-python.autopep8 ms-python.isort ms-python.debugpy njpwerner.autodocstring ms-toolsai.jupyter"

    [webdev]="formulahendry.auto-close-tag formulahendry.auto-rename-tag ms-vscode.live-server ritwickdey.liveserver ecmel.vscode-html-css pranaygp.vscode-css-peek zignd.html-css-class-completion bradlc.vscode-tailwindcss"

    [languages]="rust-lang.rust-analyzer golang.go ms-dotnettools.csharp ms-vscode.cpptools redhat.java vscjava.vscode-java-pack ms-vscode.powershell mads-hartmann.bash-ide-vscode foxundermoon.shell-format timonwong.shellcheck remisa.shellman mkhl.shfmt shakram02.bash-beautify rogalmic.bash-debug jetmartin.bats bmalehorn.shell-syntax-improved jeff-hykin.better-shellscript-syntax tetradresearch.vscode-h2o dart-code.dart-code dart-code.flutter ms-vscode.cmake-tools"

    [editor]="formulahendry.code-runner usernamehw.errorlens streetsidesoftware.code-spell-checker ms-vscode.hexeditor adpyke.codesnap hbenl.vscode-test-explorer ms-vscode.test-adapter-converter orta.vscode-jest"

    [remote]="ms-vscode.remote-containers ms-vscode-remote.remote-ssh ms-vscode.remote-repositories alefragnani.bookmarks alefragnani.project-manager"

    [productivity]="gruntfuggly.todo-tree aaron-bond.better-comments alefragnani.bookmarks alefragnani.project-manager ms-vscode.remote-repositories"

    [files]="redhat.vscode-yaml dotjoshjohnson.xml ms-vscode.vscode-json janisdd.vscode-edit-csv mechatroner.rainbow-csv ms-vscode.vscode-markdown yzhang.markdown-all-in-one davidanson.vscode-markdownlint"

    [git]="eamodio.gitlens github.vscode-pull-request-github github.vscode-github-actions donjayamanne.git-extension-pack mhutchie.git-graph github.remotehub"

    [devops]="ms-azuretools.vscode-docker ms-kubernetes-tools.vscode-kubernetes-tools hashicorp.terraform redhat.vscode-commons"

    [themes]="dracula-theme.theme-dracula zhuangtongfa.material-theme ms-vscode.theme-onedarkpro github.github-vscode-theme monokai.theme-monokai-pro-vscode johnpapa.vscode-peacock ms-vscode.theme-tomorrow-and-tomorrow-night"

    [icons]="pkief.material-icon-theme vscode-icons-team.vscode-icons"

    [keybindings]="ms-vscode.sublime-keybindings ms-vscode.atom-keybindings vscodevim.vim ms-vscode.notepadplusplus-keybindings"

    [api]="humao.rest-client rangav.vscode-thunder-client ms-vscode.vscode-httpyac"

    [database]="ms-mssql.mssql oracle.oracledevtools ms-ossdata.vscode-postgresql mongodb.mongodb-vscode"

    [snippets]="ms-vscode.vscode-snippet formulahendry.auto-complete-tag steoates.autoimport-es6-ts"
)

# Display extension info with colors
show_extension_info() {
    local ext_id="$1"
    local info="${EXTENSION_INFO[$ext_id]:-}"

    if [[ -n "$info" ]]; then
        IFS='|' read -r name desc package function_desc <<< "$info"
        echo -e "  ${BLUE}📦 ${name}${NC}"
        echo -e "  ${GRAY}   Package: ${package}${NC}"
        echo -e "  ${CYAN}   Deskripsi: ${desc}${NC}"
        if [[ -n "$function_desc" ]]; then
            echo -e "  ${CYAN}   Fungsi: ${function_desc}${NC}"
        fi
    else
        echo -e "  ${YELLOW}📦 $ext_id${NC}"
        echo -e "  ${GRAY}   Package: $ext_id${NC}"
        echo -e "  ${CYAN}   Deskripsi: Extension standar${NC}"
        echo -e "  ${CYAN}   Fungsi: Extension dengan fitur standar${NC}"
    fi
}

# ============================================================================
# GLOBAL SHOPPING CART SYSTEM
# ============================================================================

# Add extension to global cart (avoid duplicates)
add_to_cart() {
    local ext="$1"
    # Check if already in cart
    for item in "${GLOBAL_CART[@]}"; do
        if [[ "$item" == "$ext" ]]; then
            return 1  # Already exists
        fi
    done
    GLOBAL_CART+=("$ext")
    return 0
}

# Remove extension from global cart
remove_from_cart() {
    local ext="$1"
    local new_cart=()
    for item in "${GLOBAL_CART[@]}"; do
        if [[ "$item" != "$ext" ]]; then
            new_cart+=("$item")
        fi
    done
    GLOBAL_CART=("${new_cart[@]}")
}

# Clear global cart
clear_cart() {
    GLOBAL_CART=()
}

# Show cart contents
show_cart() {
    if [[ ${#GLOBAL_CART[@]} -eq 0 ]]; then
        echo -e "${GRAY}🛒 Cart is empty${NC}"
        return 0
    fi

    echo -e "${CYAN}🛒 Current Cart (${#GLOBAL_CART[@]} items):${NC}"
    local i=1
    for ext in "${GLOBAL_CART[@]}"; do
        echo -e "${BLUE}$i. ${YELLOW}$ext${NC}"
        ((i++))
    done
}

# Add category to cart
# Show extension detailed info
show_extension_detailed_info() {
    local ext_id="$1"
    local info="${EXTENSION_INFO[$ext_id]:-}"

    if [[ -n "$info" ]]; then
        IFS='|' read -ra PARTS <<< "$info"
        local ext_name="${PARTS[0]:-$ext_id}"
        local ext_desc="${PARTS[1]:-No description}"
        local ext_function="${PARTS[3]:-No detailed function info}"

        echo -e "${BLUE}📦 Extension: ${CYAN}$ext_name${NC}"
        echo -e "${YELLOW}🔹 Description: ${GRAY}$ext_desc${NC}"
        echo -e "${GREEN}⚙️  Function: ${WHITE}$ext_function${NC}"
    else
        echo -e "${BLUE}📦 Extension: ${CYAN}$ext_id${NC}"
        echo -e "${YELLOW}🔹 Description: ${GRAY}No information available${NC}"
    fi
}

# Add individual extensions from category to cart
add_individual_extensions_to_cart() {
    local category="$1"
    local category_extensions="${CATEGORIES[$category]}"
    local category_name
    category_name=$(get_category_display_name "$category")

    if [[ -z "$category_extensions" ]]; then
        echo -e "${RED}❌ Category tidak ditemukan: $category${NC}"
        return 1
    fi

    IFS=' ' read -ra ext_array <<< "$category_extensions"

    while true; do
        clear
        echo -e "${PURPLE}🎯 Individual Extension Selection - ${category_name}${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        # Show extensions in this category with detailed info
        local i=1
        declare -A ext_map
        for ext in "${ext_array[@]}"; do
            local status_indicator=""
            if is_extension_installed "$ext"; then
                status_indicator="${GREEN}✅ Installed${NC}"
            else
                # Check if in cart
                local in_cart=false
                for cart_item in "${GLOBAL_CART[@]}"; do
                    if [[ "$cart_item" == "$ext" ]]; then
                        in_cart=true
                        break
                    fi
                done
                if [[ "$in_cart" == true ]]; then
                    status_indicator="${YELLOW}🛒 In Cart${NC}"
                else
                    status_indicator="${GRAY}⭕ Available${NC}"
                fi
            fi

            echo -e "${BLUE}$i.${NC} $status_indicator"
            show_extension_detailed_info "$ext"
            echo ""
            ext_map[$i]="$ext"
            ((i++))
        done

        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}Selection Options:${NC}"
        echo -e "${BLUE}• ${CYAN}Enter extension number(s)${NC} (e.g., 1, 3, 5-7, or 'all')"
        echo -e "${YELLOW}• ${CYAN}'done'${NC} - Finish selection and return to cart"
        echo -e "${RED}• ${CYAN}'back'${NC} - Return to category selection"
        echo ""

        echo -ne "${GREEN}Your selection: ${NC}"
        read -r selection

        case "$selection" in
            "done")
                return 0
                ;;
            "back")
                return 1
                ;;
            "all")
                local added_count=0
                for ext in "${ext_array[@]}"; do
                    if add_to_cart "$ext"; then
                        ((added_count++))
                    fi
                done
                if [[ $added_count -gt 0 ]]; then
                    echo -e "${GREEN}✅ Added $added_count extensions to cart${NC}"
                else
                    echo -e "${YELLOW}⚠️ All extensions already in cart${NC}"
                fi
                echo -ne "${CYAN}Press Enter to continue...${NC}"
                read -r
                ;;
            *)
                # Parse individual numbers and ranges
                local added_count=0
                IFS=',' read -ra SELECTIONS <<< "$selection"
                for sel in "${SELECTIONS[@]}"; do
                    sel=$(echo "$sel" | xargs) # trim whitespace
                    if [[ "$sel" =~ ^[0-9]+$ ]]; then
                        # Single number
                        if [[ -n "${ext_map[$sel]:-}" ]]; then
                            if add_to_cart "${ext_map[$sel]}"; then
                                ((added_count++))
                                echo -e "${GREEN}✅ Added ${ext_map[$sel]} to cart${NC}"
                            else
                                echo -e "${YELLOW}⚠️ ${ext_map[$sel]} already in cart${NC}"
                            fi
                        else
                            echo -e "${RED}❌ Invalid selection: $sel${NC}"
                        fi
                    elif [[ "$sel" =~ ^[0-9]+-[0-9]+$ ]]; then
                        # Range (e.g., 3-5)
                        local start_num="${sel%-*}"
                        local end_num="${sel#*-}"
                        for ((j=start_num; j<=end_num; j++)); do
                            if [[ -n "${ext_map[$j]:-}" ]]; then
                                if add_to_cart "${ext_map[$j]}"; then
                                    ((added_count++))
                                    echo -e "${GREEN}✅ Added ${ext_map[$j]} to cart${NC}"
                                else
                                    echo -e "${YELLOW}⚠️ ${ext_map[$j]} already in cart${NC}"
                                fi
                            fi
                        done
                    else
                        echo -e "${RED}❌ Invalid selection format: $sel${NC}"
                    fi
                done

                if [[ $added_count -gt 0 ]]; then
                    echo -e "${GREEN}🎉 Total added: $added_count extensions${NC}"
                fi
                echo -ne "${CYAN}Press Enter to continue...${NC}"
                read -r
                ;;
        esac
    done
}

add_category_to_cart() {
    local category="$1"
    local category_extensions="${CATEGORIES[$category]}"

    if [[ -z "$category_extensions" ]]; then
        echo -e "${RED}❌ Category tidak ditemukan: $category${NC}"
        return 1
    fi

    IFS=' ' read -ra ext_array <<< "$category_extensions"
    local added_count=0

    for ext in "${ext_array[@]}"; do
        if add_to_cart "$ext"; then
            ((added_count++))
        fi
    done

    if [[ $added_count -gt 0 ]]; then
        local category_name
        category_name=$(get_category_display_name "$category")
        echo -e "${GREEN}✅ Added $added_count extensions from $category_name to cart${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️ All extensions from this category already in cart${NC}"
        return 1
    fi
}

# Execute cart operations (install or uninstall)
execute_cart() {
    local operation="$1"  # "install" or "uninstall"

    if [[ ${#GLOBAL_CART[@]} -eq 0 ]]; then
        echo -e "${YELLOW}⚠️ Cart is empty${NC}"
        return 0
    fi

    echo -e "${CYAN}🛒 Ready to $operation ${#GLOBAL_CART[@]} extensions:${NC}"
    show_cart
    echo ""

    echo -ne "${GREEN}Continue with $operation? (y/N): ${NC}"
    read -r confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}❌ Operation cancelled${NC}"
        return 0
    fi

    echo -e "${YELLOW}🔄 Starting $operation process...${NC}\n"
    local success_count=0
    local total_count=${#GLOBAL_CART[@]}

    for ext in "${GLOBAL_CART[@]}"; do
        echo -e "${BLUE}${operation^}ing:${NC}"
        show_extension_info "$ext"

        if [[ "$operation" == "install" ]]; then
            if code --install-extension "$ext" --force &>/dev/null; then
                echo -e "${GREEN}  ✅ Successfully installed${NC}"
                ((success_count++))
            else
                echo -e "${RED}  ❌ Failed to install${NC}"
            fi
        elif [[ "$operation" == "uninstall" ]]; then
            if code --uninstall-extension "$ext" &>/dev/null; then
                echo -e "${GREEN}  ✅ Successfully uninstalled${NC}"
                remove_extension_config "$ext"
                ((success_count++))
            else
                echo -e "${RED}  ❌ Failed to uninstall${NC}"
            fi
        fi
        echo ""
    done

    echo -e "${GREEN}🎉 $operation completed: $success_count/$total_count successful${NC}"
    clear_cart
    echo -ne "${CYAN}Press Enter to continue...${NC}"
    read -r
}

# Interactive cart management
manage_cart() {
    local operation="$1"  # "install" or "uninstall"

    while true; do
        clear
        echo -e "${PURPLE}🛒 Shopping Cart Manager - ${operation^}${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        show_cart
        echo ""

        echo -e "${GREEN}Cart Actions:${NC}"
        echo -e "${BLUE}a. 📦 ${CYAN}Add category to cart${NC}"
        echo -e "${YELLOW}r. 🗑️  ${PURPLE}Remove item from cart${NC}"
        echo -e "${RED}c. 🧹 ${GRAY}Clear entire cart${NC}"
        echo -e "${GREEN}e. 🚀 ${YELLOW}Execute $operation${NC}"
        echo -e "${GRAY}back. 🔙 ${CYAN}Back to menu${NC}"
        echo ""

        echo -ne "${GREEN}Choose action: ${NC}"
        read -r action

        case "$action" in
            a)
                echo -e "${CYAN}Available categories:${NC}"
                local i=1
                declare -A category_map
                for category in "${!CATEGORIES[@]}"; do
                    local category_name
                    category_name=$(get_category_display_name "$category")
                    echo -e "${BLUE}$i. ${CYAN}$category_name${NC}"
                    category_map[$i]="$category"
                    ((i++))
                done
                echo ""

                echo -e "${CYAN}📋 Selection Mode:${NC}"
                echo -e "${GREEN}1. ${YELLOW}Add entire category${NC} (all extensions in category)"
                echo -e "${BLUE}2. ${PURPLE}Select individual extensions${NC} (pick specific extensions)"
                echo -e "${GRAY}0. ${RED}Cancel${NC}"
                echo ""

                echo -ne "${GREEN}Choose selection mode (0-2): ${NC}"
                read -r mode_choice

                case "$mode_choice" in
                    1)
                        echo -ne "${YELLOW}Enter category number: ${NC}"
                        read -r cat_num
                        if [[ -n "${category_map[$cat_num]:-}" ]]; then
                            add_category_to_cart "${category_map[$cat_num]}"
                        else
                            echo -e "${RED}❌ Invalid category number${NC}"
                        fi
                        ;;
                    2)
                        echo -ne "${YELLOW}Enter category number: ${NC}"
                        read -r cat_num
                        if [[ -n "${category_map[$cat_num]:-}" ]]; then
                            add_individual_extensions_to_cart "${category_map[$cat_num]}"
                        else
                            echo -e "${RED}❌ Invalid category number${NC}"
                        fi
                        ;;
                    0)
                        echo -e "${YELLOW}Selection cancelled${NC}"
                        ;;
                    *)
                        echo -e "${RED}❌ Invalid selection mode${NC}"
                        ;;
                esac
                ;;
            r)
                if [[ ${#GLOBAL_CART[@]} -eq 0 ]]; then
                    echo -e "${YELLOW}⚠️ Cart is empty${NC}"
                else
                    show_cart
                    echo ""
                    echo -ne "${YELLOW}Enter item number to remove: ${NC}"
                    read -r item_num

                    if [[ $item_num =~ ^[0-9]+$ ]] && [[ $item_num -ge 1 ]] && [[ $item_num -le ${#GLOBAL_CART[@]} ]]; then
                        local removed_item="${GLOBAL_CART[$((item_num-1))]}"
                        remove_from_cart "$removed_item"
                        echo -e "${GREEN}✅ Removed $removed_item from cart${NC}"
                    else
                        echo -e "${RED}❌ Invalid item number${NC}"
                    fi
                fi
                ;;
            c)
                if [[ ${#GLOBAL_CART[@]} -gt 0 ]]; then
                    echo -ne "${RED}Clear entire cart? (y/N): ${NC}"
                    read -r confirm_clear
                    if [[ "$confirm_clear" =~ ^[Yy]$ ]]; then
                        clear_cart
                        echo -e "${GREEN}✅ Cart cleared${NC}"
                    fi
                else
                    echo -e "${YELLOW}⚠️ Cart is already empty${NC}"
                fi
                ;;
            e)
                execute_cart "$operation"
                return 0
                ;;
            back)
                return 0
                ;;
            *)
                echo -e "${RED}❌ Invalid action${NC}"
                ;;
        esac

        echo -ne "${CYAN}Press Enter to continue...${NC}"
        read -r
    done
}

# Get user settings path with options
get_settings_path() {
    echo -e "${PURPLE}📁 Pilih lokasi settings.json:${NC}"
    echo -e "${GREEN}1) ${CYAN}User Global${NC} (~/.config/Code/User/settings.json)"
    echo -e "${BLUE}2) ${YELLOW}Workspace Current${NC} ($(pwd)/.vscode/settings.json)"
    echo -e "${PURPLE}3) ${GRAY}Custom Path${NC} (masukkan path manual)"
    echo -e "${GRAY}0) ${RED}Cancel/Back${NC} (batalkan dan kembali)"
    echo ""

    while true; do
        echo -ne "${GREEN}Pilih lokasi settings (0-3): ${NC}"
        read -r choice
        case $choice in
            1)
                local settings_dir="$HOME/.config/Code/User"
                mkdir -p "$settings_dir"
                echo "$settings_dir/settings.json"
                return 0
                ;;
            2)
                local settings_dir
                settings_dir="$(pwd)/.vscode"
                mkdir -p "$settings_dir"
                echo "$settings_dir/settings.json"
                return 0
                ;;
            3)
                echo -ne "${YELLOW}Masukkan path lengkap settings.json: ${NC}"
                read -r custom_path
                if [[ -n "$custom_path" ]]; then
                    local custom_dir
                    custom_dir="$(dirname "$custom_path")"
                    mkdir -p "$custom_dir"
                    echo "$custom_path"
                    return 0
                else
                    echo -e "${RED}❌ Path tidak boleh kosong${NC}"
                fi
                ;;
            0)
                echo -e "${YELLOW}❌ Operation cancelled${NC}"
                return 1
                ;;
            *)
                echo -e "${RED}❌ Pilihan tidak valid. Masukkan 0, 1, 2, atau 3${NC}"
                ;;
        esac
    done
}

# Display ASCII banner header
print_banner() {
    clear
    echo -e "${CYAN}"
    echo "██████╗  ██████╗ ██╗  ██╗██╗  ██╗ █████╗ ███╗   ██╗███████╗"
    echo "██╔══██╗██╔═══██╗██║ ██╔╝██║  ██║██╔══██╗████╗  ██║╚══███╔╝"
    echo "██████╔╝██║   ██║█████╔╝ ███████║███████║██╔██╗ ██║  ███╔╝"
    echo "██╔══██╗██║   ██║██╔═██╗ ██╔══██║██╔══██║██║╚██╗██║ ███╔╝"
    echo "██║  ██║╚██████╔╝██║  ██╗██║  ██║██║  ██║██║ ╚████║███████╗"
    echo "╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝"
    echo -e "${NC}"
    echo -e "${PURPLE}VS Code Complete Setup - by ROKHANZ${NC}"
    echo ""
}

# Centralized dependency check & install
check_and_install() {
    local cmd="$1"
    local pkg="${2:-$1}"

    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${YELLOW}⏳ Installing missing dependency: $pkg${NC}"
        if command -v apt &>/dev/null; then
            sudo apt update && sudo apt install -y "$pkg"
        elif command -v yum &>/dev/null; then
            sudo yum install -y "$pkg"
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y "$pkg"
        elif command -v pacman &>/dev/null; then
            sudo pacman -Sy --noconfirm "$pkg"
        else
            echo -e "${RED}❌ Tidak ada package manager yang dikenali. Install $pkg manual!${NC}"
            return 1
        fi
    fi

    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${RED}❌ $cmd masih tidak ditemukan. Silakan install manual.${NC}"
        return 1
    fi
    return 0
}

# Check if VS Code CLI is available
check_vscode() {
    command -v code &>/dev/null || {
        echo -e "${RED}❌ VS Code CLI tidak ditemukan${NC}"
        return 1
    }
}

# Validate environment
validate_environment() {
    local issues=0

    [[ -z "${TERM:-}" ]] && {
        export TERM=xterm-256color
        echo -e "${YELLOW}⚠️ TERM not set, forced to xterm-256color${NC}"
    }
    [[ -z "${BASH_VERSION:-}" ]] && {
        echo -e "${RED}❌ Script butuh Bash!${NC}"
        ((issues++))
    }
    if [[ ! -w "/tmp" ]]; then
        echo -e "${RED}❌ No write permission to /tmp${NC}"
        ((issues++))
    fi

    if [[ $issues -eq 0 ]]; then
        echo -e "${GREEN}✅ Environment OK${NC}"
        return 0
    else
        echo -e "${RED}❌ Environment tidak layak ($issues masalah)${NC}"
        return 1
    fi
}

# Install default extensions (non-interactive)
install_default_extensions() {
    echo -e "${GREEN}🚀 Installing Default Extensions${NC}"
    echo "────────────────────────────────────"

    check_vscode || return 1

    local total=${#DEFAULT_EXTENSIONS[@]} current=0 failed=0

    for ext in "${DEFAULT_EXTENSIONS[@]}"; do
        ((current++))
        echo -e "${YELLOW}[$current/$total]${NC} Installing extension:"
        show_extension_info "$ext"

        if code --install-extension "$ext" --force &>/dev/null; then
            echo -e "${GREEN}  ✅ Berhasil diinstall${NC}\n"
        else
            echo -e "${RED}  ❌ Gagal diinstall${NC}\n"; ((failed++))
        fi
    done

    # Auto-overwrite settings.json
    create_default_settings

    echo -e "${GREEN}🎉 Selesai: $((total-failed))/$total berhasil diinstall${NC}"
    echo -ne "Tekan Enter..."
    read -r
}

# Interactive extension installation with global cart
interactive_install() {
    clear_cart  # Clear any previous cart contents
    manage_cart "install"
}


# Create default settings.json with clear path selection
create_default_settings() {
    echo -e "${CYAN}🛠️ Create Default VS Code Settings${NC}"
    echo -e "${GRAY}This will create optimized settings.json based on installed extensions${NC}"
    echo ""

    # Auto detect extensions first
    detect_installed_extensions
    echo ""

    echo -e "${YELLOW}📁 Choose settings location:${NC}"
    echo -e "${GREEN}1. ${CYAN}User Global Settings${NC}"
    echo -e "   ${GRAY}→ ~/.config/Code/User/settings.json (affects all VS Code projects)${NC}"
    echo -e "${BLUE}2. ${PURPLE}Current Workspace Settings${NC}"
    echo -e "   ${GRAY}→ $(pwd)/.vscode/settings.json (affects only this project)${NC}"
    echo -e "${YELLOW}3. ${GRAY}Custom Path${NC}"
    echo -e "   ${GRAY}→ Specify custom location for settings.json${NC}"
    echo -e "${RED}0. ${GRAY}Cancel/Back${NC} (return to settings menu)"
    echo ""

    local settings_file
    echo -ne "${GREEN}Select location (0-3): ${NC}"
    read -r location_choice

    case $location_choice in
        1)
            settings_file="$HOME/.config/Code/User/settings.json"
            mkdir -p "$(dirname "$settings_file")"
            echo -e "${GREEN}� Selected: User Global Settings${NC}"
            ;;
        2)
            settings_file="$(pwd)/.vscode/settings.json"
            mkdir -p "$(dirname "$settings_file")"
            echo -e "${BLUE}📍 Selected: Workspace Settings${NC}"
            ;;
        3)
            echo -ne "${YELLOW}Enter full path for settings.json: ${NC}"
            read -r custom_path
            if [[ -n "$custom_path" ]]; then
                settings_file="$custom_path"
                mkdir -p "$(dirname "$settings_file")"
                echo -e "${PURPLE}📍 Selected: Custom Path${NC}"
            else
                echo -e "${RED}❌ Path cannot be empty${NC}"
                echo -ne "${CYAN}Press Enter to continue...${NC}"
                read -r
                return 1
            fi
            ;;
        0)
            echo -e "${YELLOW}❌ Operation cancelled${NC}"
            return 0
            ;;
        *)
            echo -e "${RED}❌ Invalid selection${NC}"
            echo -ne "${CYAN}Press Enter to continue...${NC}"
            read -r
            return 1
            ;;
    esac

    echo -e "${CYAN}💾 Target file: $settings_file${NC}"

    # Check if file exists and warn about overwrite
    if [[ -f "$settings_file" ]]; then
        echo -e "${YELLOW}⚠️ Settings file already exists and will be overwritten${NC}"
        echo -ne "${RED}Continue with overwrite? (y/N): ${NC}"
        read -r confirm_overwrite
        if [[ ! "$confirm_overwrite" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}❌ Operation cancelled${NC}"
            echo -ne "${CYAN}Press Enter to continue...${NC}"
            read -r
            return 0
        fi
    fi

    # Smart configuration based on installed extensions
    echo -e "\n${CYAN}🔧 Analyzing installed extensions for optimal configuration...${NC}"

    # Auto-detect formatters and tools
    local python_formatter="black"
    local js_formatter="prettier"
    local theme="Dark+ (default dark)"
    local icon_theme="material-icon-theme"

    # Python formatter detection
    if is_extension_installed "ms-python.black-formatter" && is_extension_installed "ms-python.autopep8"; then
        echo -e "${CYAN}🐍 Multiple Python formatters detected:${NC}"
        echo -e "${GREEN}1. ${YELLOW}Black${NC} (recommended, modern)"
        echo -e "${BLUE}2. ${PURPLE}autopep8${NC} (traditional, PEP8 focused)"
        echo -ne "${GREEN}Choose Python formatter (1-2) [1]: ${NC}"
        read -r py_choice
        case ${py_choice:-1} in
            2) python_formatter="autopep8" ;;
            *) python_formatter="black" ;;
        esac
    elif is_extension_installed "ms-python.autopep8"; then
        python_formatter="autopep8"
    fi

    # JavaScript formatter detection
    if ! is_extension_installed "esbenp.prettier-vscode"; then
        js_formatter="none"
    fi

    # Theme detection
    if is_extension_installed "dracula-theme.theme-dracula" && is_extension_installed "ms-vscode.theme-onedarkpro"; then
        echo -e "${CYAN}🎨 Multiple themes detected:${NC}"
        echo -e "${PURPLE}1. ${YELLOW}Dracula${NC} (popular, high contrast)"
        echo -e "${BLUE}2. ${GREEN}One Dark Pro${NC} (modern, Atom-inspired)"
        echo -e "${GRAY}3. ${CYAN}Default Dark+${NC} (VS Code default)"
        echo -ne "${GREEN}Choose color theme (1-3) [1]: ${NC}"
        read -r theme_choice
        case ${theme_choice:-1} in
            1) theme="Dracula" ;;
            2) theme="One Dark Pro" ;;
            *) theme="Dark+ (default dark)" ;;
        esac
    elif is_extension_installed "dracula-theme.theme-dracula"; then
        theme="Dracula"
    elif is_extension_installed "ms-vscode.theme-onedarkpro"; then
        theme="One Dark Pro"
    fi

    # Icon theme detection
    if is_extension_installed "pkief.material-icon-theme" && is_extension_installed "vscode-icons-team.vscode-icons"; then
        echo -e "${CYAN}📂 Multiple icon themes detected:${NC}"
        echo -e "${BLUE}1. ${YELLOW}Material Icon Theme${NC} (clean, material design)"
        echo -e "${GREEN}2. ${PURPLE}vscode-icons${NC} (comprehensive, detailed)"
        echo -ne "${GREEN}Choose icon theme (1-2) [1]: ${NC}"
        read -r icon_choice
        case ${icon_choice:-1} in
            2) icon_theme="vscode-icons" ;;
            *) icon_theme="material-icon-theme" ;;
        esac
    elif is_extension_installed "vscode-icons-team.vscode-icons"; then
        icon_theme="vscode-icons"
    fi


    # Generate dynamic settings content based on installed extensions
    echo -e "${CYAN}🔧 Generating dynamic configuration based on installed extensions...${NC}"

    # Start building settings JSON dynamically
    local settings_content="{"
    # shellcheck disable=SC2034  # Variable used by reference in add_*_settings functions
    local is_first_section=true  # Controls JSON comma formatting, modified by reference

    # Always include base editor settings
    add_base_settings settings_content is_first_section

    # Add theme settings if themes are detected
    add_theme_settings settings_content is_first_section "$theme" "$icon_theme"

    # Add extension-specific configurations based on what's installed
    local configured_extensions=()

    # Check each installed extension and add its configuration
    for ext in "${INSTALLED_EXTENSIONS[@]}"; do
        case "$ext" in
            # Python Extensions
            "ms-python.python"|"ms-python.black-formatter"|"ms-python.autopep8"|"ms-python.flake8"|"ms-python.pylint")
                if ! array_contains "python" "${configured_extensions[@]}"; then
                    add_python_settings settings_content is_first_section "$python_formatter"
                    configured_extensions+=("python")
                    echo -e "${GREEN}  ✓ Added Python configuration${NC}"
                fi
                ;;

            # JavaScript/TypeScript Extensions
            "esbenp.prettier-vscode"|"ms-vscode.vscode-typescript-next"|"ms-vscode.vscode-json")
                if ! array_contains "javascript" "${configured_extensions[@]}"; then
                    add_javascript_settings settings_content is_first_section "$js_formatter"
                    configured_extensions+=("javascript")
                    echo -e "${GREEN}  ✓ Added JavaScript/TypeScript configuration${NC}"
                fi
                ;;

            # Bash/Shell Extensions
            "mads-hartmann.bash-ide-vscode"|"foxundermoon.shell-format"|"timonwong.shellcheck"|"bmalehorn.shell-syntax-improved")
                if ! array_contains "bash" "${configured_extensions[@]}"; then
                    add_bash_settings settings_content is_first_section
                    configured_extensions+=("bash")
                    echo -e "${GREEN}  ✓ Added Bash/Shell configuration${NC}"
                fi
                ;;

            # Git Extensions
            "eamodio.gitlens"|"donjayamanne.githistory"|"github.vscode-pull-request-github")
                if ! array_contains "git" "${configured_extensions[@]}"; then
                    add_git_settings settings_content is_first_section
                    configured_extensions+=("git")
                    echo -e "${GREEN}  ✓ Added Git configuration${NC}"
                fi
                ;;

            # Error Lens
            "usernamehw.errorlens")
                add_errorlens_settings settings_content is_first_section
                echo -e "${GREEN}  ✓ Added Error Lens configuration${NC}"
                ;;

            # Todo Tree
            "gruntfuggly.todo-tree")
                add_todotree_settings settings_content is_first_section
                echo -e "${GREEN}  ✓ Added Todo Tree configuration${NC}"
                ;;

            # Docker Extensions
            "ms-azuretools.vscode-docker"|"ms-vscode-remote.remote-containers")
                if ! array_contains "docker" "${configured_extensions[@]}"; then
                    add_docker_settings settings_content is_first_section
                    configured_extensions+=("docker")
                    echo -e "${GREEN}  ✓ Added Docker configuration${NC}"
                fi
                ;;

            # C/C++ Extensions
            "ms-vscode.cpptools"|"ms-vscode.cmake-tools")
                if ! array_contains "cpp" "${configured_extensions[@]}"; then
                    add_cpp_settings settings_content is_first_section
                    configured_extensions+=("cpp")
                    echo -e "${GREEN}  ✓ Added C/C++ configuration${NC}"
                fi
                ;;

            # Rust Extensions
            "rust-lang.rust-analyzer")
                add_rust_settings settings_content is_first_section
                echo -e "${GREEN}  ✓ Added Rust configuration${NC}"
                ;;

            # Go Extensions
            "golang.go")
                add_go_settings settings_content is_first_section
                echo -e "${GREEN}  ✓ Added Go configuration${NC}"
                ;;

            # Java Extensions
            "redhat.java"|"vscjava.vscode-java-pack")
                if ! array_contains "java" "${configured_extensions[@]}"; then
                    add_java_settings settings_content is_first_section
                    configured_extensions+=("java")
                    echo -e "${GREEN}  ✓ Added Java configuration${NC}"
                fi
                ;;

            # Markdown Extensions
            "yzhang.markdown-all-in-one"|"shd101wyy.markdown-preview-enhanced")
                if ! array_contains "markdown" "${configured_extensions[@]}"; then
                    add_markdown_settings settings_content is_first_section
                    configured_extensions+=("markdown")
                    echo -e "${GREEN}  ✓ Added Markdown configuration${NC}"
                fi
                ;;
        esac
    done

    # Close the JSON object
    settings_content="${settings_content%,}
}"

    # Write the dynamic settings to file
    echo "$settings_content" > "$settings_file"

    # Create secure keybindings.json in the same directory
    local keybindings_file
    if [[ "$settings_file" == *"User/settings.json" ]]; then
        keybindings_file="${settings_file%/*}/keybindings.json"
    elif [[ "$settings_file" == *".vscode/settings.json" ]]; then
        keybindings_file="${settings_file%/*}/keybindings.json"
    else
        # Custom path - place keybindings.json in same directory
        keybindings_file="${settings_file%/*}/keybindings.json"
    fi

    # Create secure keybindings configuration
    create_secure_keybindings "$keybindings_file"

    # Check for extension conflicts
    check_extension_keybinding_conflicts

    echo -e "\n${GREEN}✅ Dynamic Settings.json successfully created/updated!${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📍 Location: $settings_file${NC}"
    echo -e "${CYAN}🔐 Keybindings: $keybindings_file${NC}"
    echo -e "${BLUE}🎨 Theme: $theme${NC}"
    echo -e "${BLUE}📂 Icons: $icon_theme${NC}"
    echo -e "${GREEN}⌨️  Ctrl+A: Secured for 'Select All' (editor.action.selectAll)${NC}"

    if array_contains "python" "${configured_extensions[@]}"; then
        echo -e "${BLUE}🐍 Python: $python_formatter formatter configured${NC}"
    fi

    if array_contains "javascript" "${configured_extensions[@]}"; then
        echo -e "${BLUE}📜 JavaScript: $js_formatter formatter configured${NC}"
    fi

    echo -e "\n${YELLOW}📦 Configured Extension Categories:${NC}"
    if [[ ${#configured_extensions[@]} -gt 0 ]]; then
        for category in "${configured_extensions[@]}"; do
            case "$category" in
                python) echo -e "${GREEN}  ✓ ${BLUE}🐍 Python Development Environment${NC}" ;;
                javascript) echo -e "${GREEN}  ✓ ${YELLOW}📜 JavaScript/TypeScript Environment${NC}" ;;
                bash) echo -e "${GREEN}  ✓ ${CYAN}💻 Bash/Shell Development Environment${NC}" ;;
                git) echo -e "${GREEN}  ✓ ${PURPLE}📊 Git & Version Control${NC}" ;;
                docker) echo -e "${GREEN}  ✓ ${BLUE}🐳 Docker & Container Tools${NC}" ;;
                cpp) echo -e "${GREEN}  ✓ ${RED}� C/C++ Development Environment${NC}" ;;
                java) echo -e "${GREEN}  ✓ ${YELLOW}☕ Java Development Environment${NC}" ;;
                rust) echo -e "${GREEN}  ✓ ${ORANGE}🦀 Rust Development Environment${NC}" ;;
                go) echo -e "${GREEN}  ✓ ${CYAN}🐹 Go Development Environment${NC}" ;;
                markdown) echo -e "${GREEN}  ✓ ${GRAY}📝 Markdown Authoring Environment${NC}" ;;
            esac
        done
    else
        echo -e "${YELLOW}  ⚠️ Only base editor configuration applied${NC}"
        echo -e "${GRAY}    (No specific extensions detected for advanced configuration)${NC}"
    fi

    # Show individual extension configurations
    local has_individual=false
    for ext in "${INSTALLED_EXTENSIONS[@]}"; do
        case "$ext" in
            "usernamehw.errorlens")
                if ! $has_individual; then
                    echo -e "\n${CYAN}🔧 Individual Extension Configurations:${NC}"
                    has_individual=true
                fi
                echo -e "${GREEN}  ✓ ${RED}🔍 Error Lens - Enhanced error visualization${NC}"
                ;;
            "gruntfuggly.todo-tree")
                if ! $has_individual; then
                    echo -e "\n${CYAN}🔧 Individual Extension Configurations:${NC}"
                    has_individual=true
                fi
                echo -e "${GREEN}  ✓ ${YELLOW}📋 Todo Tree - TODO/FIXME tracking${NC}"
                ;;
        esac
    done

    echo -e "\n${GREEN}💡 Tips:${NC}"
    echo -e "${YELLOW}  • Restart VS Code for optimal performance${NC}"
    echo -e "${YELLOW}  • Only extensions you have installed are configured${NC}"
    echo -e "${YELLOW}  • Settings are dynamically generated based on your setup${NC}"
    echo -e "${GREEN}  • Ctrl+A is protected - always works as 'Select All' in editor${NC}"
    echo -e "${BLUE}  • Keybindings.json overrides any conflicting extension shortcuts${NC}"

    echo -ne "${CYAN}Press Enter to continue...${NC}"
    read -r
}

# Remove extension config from settings.json
remove_extension_config() {
    local ext="$1"
    # Simple implementation - could be enhanced with jq
    echo "🔧 Membersihkan konfigurasi untuk: $ext"
}

# Extension category cache
declare -A CATEGORY_CACHE=()

# Detect extension category
detect_extension_category() {
    local ext_id="$1"

    # Check cache first
    if [[ -n "${CATEGORY_CACHE[$ext_id]:-}" ]]; then
        echo "${CATEGORY_CACHE[$ext_id]}"
        return 0
    fi

    # Check each category to find which one contains this extension
    for category in "${!CATEGORIES[@]}"; do
        local category_extensions=" ${CATEGORIES[$category]} "
        if [[ "$category_extensions" == *" ${ext_id} "* ]]; then
            CATEGORY_CACHE[$ext_id]="$category"
            echo "$category"
            return 0
        fi
    done

    # If not found in predefined categories, return "other"
    CATEGORY_CACHE[$ext_id]="other"
    echo "other"
}

# Get category display name
get_category_display_name() {
    local category="$1"
    case $category in
        ai) echo "🤖 AI Extensions" ;;
        javascript) echo "📜 JavaScript/TypeScript" ;;
        python) echo "🐍 Python" ;;
        webdev) echo "🌐 Web Development" ;;
        languages) echo "🗣️  Other Languages" ;;
        editor) echo "⚙️  Editor Tools" ;;
        remote) echo "🔗 Remote Development" ;;
        productivity) echo "🚀 Productivity Tools" ;;
        files) echo "📁 File Formats" ;;
        git) echo "📊 Git & Version Control" ;;
        devops) echo "🐳 Docker & DevOps" ;;
        themes) echo "🎨 Themes" ;;
        icons) echo "📂 Icon Themes" ;;
        keybindings) echo "⌨️  Keybindings" ;;
        api) echo "🌐 API & REST Tools" ;;
        database) echo "🗄️  Database Tools" ;;
        snippets) echo "📝 Snippets & Templates" ;;
        other) echo "📦 Other Extensions" ;;
        *) echo "📦 Unknown Category" ;;
    esac
}

# Helper function to check if array contains element
array_contains() {
    local element="$1"
    shift
    local array=("$@")
    for item in "${array[@]}"; do
        [[ "$item" == "$element" ]] && return 0
    done
    return 1
}

# Add base editor settings
add_base_settings() {
    local -n settings_ref=$1
    local -n first_ref=$2

    if [[ "$first_ref" == true ]]; then
        first_ref=false
    else
        settings_ref+=","
    fi

    settings_ref+='
    "editor.fontSize": 14,
    "editor.fontFamily": "'\''Fira Code'\'', '\''JetBrains Mono'\'', '\''Cascadia Code'\'', '\''SF Mono'\'', Consolas",
    "editor.fontLigatures": true,
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "editor.formatOnSave": true,
    "editor.formatOnPaste": true,
    "editor.wordWrap": "on",
    "editor.lineNumbers": "on",
    "editor.renderWhitespace": "boundary",
    "editor.bracketPairColorization.enabled": true,
    "editor.guides.bracketPairs": true,
    "editor.minimap.enabled": true,
    "editor.scrollBeyondLastLine": false,
    "editor.cursorBlinking": "smooth",
    "editor.cursorSmoothCaretAnimation": "on",

    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000,
    "files.trimTrailingWhitespace": true,
    "files.insertFinalNewline": true,
    "files.exclude": {
        "**/node_modules": true,
        "**/.git": true,
        "**/.DS_Store": true,
        "**/Thumbs.db": true
    },

    "terminal.integrated.fontSize": 13,
    "terminal.integrated.fontFamily": "'\''Fira Code'\'', '\''JetBrains Mono'\'', monospace",
    "terminal.integrated.cursorBlinking": true,
    "terminal.integrated.cursorStyle": "line",

    "extensions.autoUpdate": true,
    "extensions.autoCheckUpdates": true'
}

# Add theme settings
add_theme_settings() {
    local -n settings_ref=$1
    local -n first_ref=$2
    local theme="$3"
    local icon_theme="$4"

    if [[ "$first_ref" == true ]]; then
        first_ref=false
    else
        settings_ref+=","
    fi

    settings_ref+='
    "workbench.colorTheme": "'"$theme"'",
    "workbench.iconTheme": "'"$icon_theme"'",
    "workbench.startupEditor": "welcomePage",
    "workbench.editor.enablePreview": false'
}

# Add Python extension settings
add_python_settings() {
    local -n settings_ref=$1
    local -n first_ref=$2
    local formatter="$3"

    if [[ "$first_ref" == true ]]; then
        first_ref=false
    else
        settings_ref+=","
    fi

    settings_ref+='
    "python.defaultInterpreterPath": "/usr/bin/python3",
    "python.formatting.provider": "'"$formatter"'",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "python.linting.flake8Enabled": true,
    "python.analysis.autoImportCompletions": true,
    "python.analysis.completeFunctionParens": true,
    "[python]": {
        "editor.defaultFormatter": "ms-python.'"$formatter"'-formatter",
        "editor.tabSize": 4,
        "editor.insertSpaces": true
    }'
}

# Add JavaScript/TypeScript settings
add_javascript_settings() {
    local -n settings_ref=$1
    local -n first_ref=$2
    local formatter="$3"

    if [[ "$first_ref" == true ]]; then
        first_ref=false
    else
        settings_ref+=","
    fi

    settings_ref+='
    "typescript.suggest.autoImports": true,
    "typescript.updateImportsOnFileMove.enabled": "always",
    "javascript.suggest.autoImports": true,
    "javascript.updateImportsOnFileMove.enabled": "always",
    "emmet.includeLanguages": {
        "javascript": "javascriptreact",
        "typescript": "typescriptreact"
    }'

    if [[ "$formatter" != "none" ]]; then
        settings_ref+=',
    "[javascript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[typescript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[json]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[html]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[css]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    }'
    fi
}

# Add Bash/Shell settings
add_bash_settings() {
    local -n settings_ref=$1
    local -n first_ref=$2

    if [[ "$first_ref" == true ]]; then
        first_ref=false
    else
        settings_ref+=","
    fi

    settings_ref+='
    "bashIde.enableSourceErrorLinting": true,
    "bashIde.includeAllWorkspaceSymbols": true,
    "bashIde.shellcheckPath": "/usr/bin/shellcheck",
    "bashIde.explainshellEndpoint": "https://explainshell.com/explain",
    "shellcheck.enable": true,
    "shellcheck.executablePath": "/usr/bin/shellcheck",
    "shellcheck.run": "onSave",
    "shellcheck.exclude": ["SC1091"],
    "shellformat.useEditorConfig": true,
    "shellformat.flag": "-i 4 -bn -ci -sr -kp",
    "[shellscript]": {
        "editor.defaultFormatter": "foxundermoon.shell-format",
        "editor.tabSize": 4,
        "editor.insertSpaces": true,
        "editor.detectIndentation": false
    },
    "[bash]": {
        "editor.defaultFormatter": "foxundermoon.shell-format",
        "editor.tabSize": 4,
        "editor.insertSpaces": true
    },
    "files.associations": {
        "*.sh": "shellscript",
        "*.bash": "shellscript",
        "*.bashrc": "shellscript",
        "*.bash_profile": "shellscript",
        "*.bash_aliases": "shellscript",
        "*.zsh": "shellscript",
        "*.zshrc": "shellscript",
        ".env*": "shellscript"
    }'
}

# Add Git settings
add_git_settings() {
    local -n settings_ref=$1
    local -n first_ref=$2

    if [[ "$first_ref" == true ]]; then
        first_ref=false
    else
        settings_ref+=","
    fi

    settings_ref+='
    "git.enableSmartCommit": true,
    "git.confirmSync": false,
    "git.autofetch": true,
    "gitlens.codeLens.enabled": false,
    "gitlens.currentLine.enabled": false,
    "gitlens.hovers.enabled": true,
    "gitlens.blame.compact": false'
}

# Add Error Lens settings
add_errorlens_settings() {
    local -n settings_ref=$1
    local -n first_ref=$2

    if [[ "$first_ref" == true ]]; then
        first_ref=false
    else
        settings_ref+=","
    fi

    settings_ref+='
    "errorLens.enabledDiagnosticLevels": ["error", "warning"],
    "errorLens.gutterIconsEnabled": true,
    "errorLens.followCursor": "allLines"'
}

# Add Todo Tree settings
add_todotree_settings() {
    local -n settings_ref=$1
    local -n first_ref=$2

    if [[ "$first_ref" == true ]]; then
        first_ref=false
    else
        settings_ref+=","
    fi

    settings_ref+='
    "todo-tree.general.tags": ["BUG", "HACK", "FIXME", "TODO", "XXX", "[ ]", "[x]"],
    "todo-tree.regex.regex": "(//|#|<!--|;|/\\*|^|^\\s*(-|\\*|>|))\\s*(BUG|HACK|FIXME|TODO|XXX|\\[ \\]|\\[x\\])",
    "todo-tree.highlights.enabled": true'
}

# Add Docker settings
add_docker_settings() {
    local -n settings_ref=$1
    local -n first_ref=$2

    if [[ "$first_ref" == true ]]; then
        first_ref=false
    else
        settings_ref+=","
    fi

    settings_ref+='
    "docker.enableDockerComposeLanguageService": true,
    "docker.showStartPage": false,
    "[dockerfile]": {
        "editor.defaultFormatter": "ms-azuretools.vscode-docker"
    }'
}

# Add C/C++ settings
add_cpp_settings() {
    local -n settings_ref=$1
    local -n first_ref=$2

    if [[ "$first_ref" == true ]]; then
        first_ref=false
    else
        settings_ref+=","
    fi

    settings_ref+='
    "C_Cpp.default.cStandard": "c17",
    "C_Cpp.default.cppStandard": "c++17",
    "C_Cpp.default.intelliSenseMode": "gcc-x64",
    "[c]": {
        "editor.defaultFormatter": "ms-vscode.cpptools"
    },
    "[cpp]": {
        "editor.defaultFormatter": "ms-vscode.cpptools"
    }'
}

# Add Rust settings
add_rust_settings() {
    local -n settings_ref=$1
    local -n first_ref=$2

    if [[ "$first_ref" == true ]]; then
        first_ref=false
    else
        settings_ref+=","
    fi

    settings_ref+='
    "rust-analyzer.checkOnSave.command": "cargo check",
    "rust-analyzer.cargo.loadOutDirsFromCheck": true,
    "[rust]": {
        "editor.defaultFormatter": "rust-lang.rust-analyzer",
        "editor.formatOnSave": true
    }'
}

# Add Go settings
add_go_settings() {
    local -n settings_ref=$1
    local -n first_ref=$2

    if [[ "$first_ref" == true ]]; then
        first_ref=false
    else
        settings_ref+=","
    fi

    settings_ref+='
    "go.formatTool": "goimports",
    "go.lintTool": "golint",
    "go.vetOnSave": "package",
    "[go]": {
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
            "source.organizeImports": true
        }
    }'
}

# Add Java settings
add_java_settings() {
    local -n settings_ref=$1
    local -n first_ref=$2

    if [[ "$first_ref" == true ]]; then
        first_ref=false
    else
        settings_ref+=","
    fi

    settings_ref+='
    "java.configuration.updateBuildConfiguration": "automatic",
    "java.compile.nullAnalysis.mode": "automatic",
    "[java]": {
        "editor.defaultFormatter": "redhat.java",
        "editor.tabSize": 4
    }'
}

# Add Markdown settings
add_markdown_settings() {
    local -n settings_ref=$1
    local -n first_ref=$2

    if [[ "$first_ref" == true ]]; then
        first_ref=false
    else
        settings_ref+=","
    fi

    settings_ref+='
    "markdown.preview.breaks": true,
    "markdown.preview.linkify": true,
    "[markdown]": {
        "editor.defaultFormatter": "yzhang.markdown-all-in-one",
        "editor.wordWrap": "on",
        "editor.quickSuggestions": {
            "comments": "off",
            "strings": "off",
            "other": "off"
        }
    }'
}

# Create secure keybindings.json to ensure Ctrl+A is always "Select All"
create_secure_keybindings() {
    local keybindings_file="$1"
    local settings_dir
    settings_dir="$(dirname "$keybindings_file")"

    # Ensure directory exists
    mkdir -p "$settings_dir"

    echo -e "${CYAN}🔐 Creating secure keybindings configuration...${NC}"
    echo -e "${YELLOW}📋 Ensuring Ctrl+A is reserved for 'Select All' in editor${NC}"

    # Create keybindings.json with secure Ctrl+A mapping
    cat > "$keybindings_file" << 'EOF'
[
    {
        "key": "ctrl+a",
        "command": "editor.action.selectAll",
        "when": "editorTextFocus"
    },
    {
        "key": "ctrl+a",
        "command": "editor.action.selectAll",
        "when": "editorFocus && !editorReadonly"
    },
    {
        "key": "ctrl+a",
        "command": "editor.action.selectAll",
        "when": "editorFocus"
    },
    {
        "key": "ctrl+a",
        "command": "list.selectAll",
        "when": "listFocus && !editorFocus"
    },
    {
        "key": "ctrl+a",
        "command": "workbench.action.terminal.selectAll",
        "when": "terminalFocus"
    }
]
EOF

    echo -e "${GREEN}✅ Secure keybindings created: $keybindings_file${NC}"
    echo -e "${BLUE}🔒 Ctrl+A protection applied:${NC}"
    echo -e "${YELLOW}   • Editor text focus: editor.action.selectAll${NC}"
    echo -e "${YELLOW}   • List focus: list.selectAll${NC}"
    echo -e "${YELLOW}   • Terminal focus: workbench.action.terminal.selectAll${NC}"
}

# Check and fix conflicting keybindings from extensions
check_extension_keybinding_conflicts() {
    echo -e "\n${CYAN}🔍 Checking for potential Ctrl+A conflicts from extensions...${NC}"

    # Common extensions that might override Ctrl+A
    local potential_conflicts=(
        "ms-vscode.sublime-keybindings"
        "ms-vscode.atom-keybindings"
        "vscodevim.vim"
        "ms-vscode.notepadplusplus-keybindings"
    )
    local conflicts_found=false

    for ext in "${potential_conflicts[@]}"; do
        if is_extension_installed "$ext"; then
            echo -e "${YELLOW}⚠️  Extension detected: $ext${NC}"
            case "$ext" in
                "ms-vscode.sublime-keybindings")
                    echo -e "${BLUE}   → Sublime Text extensions may override Ctrl+A${NC}"
                    conflicts_found=true
                    ;;
                "ms-vscode.atom-keybindings")
                    echo -e "${BLUE}   → Atom keybindings may override Ctrl+A${NC}"
                    conflicts_found=true
                    ;;
                "vscodevim.vim")
                    echo -e "${BLUE}   → Vim extension may override Ctrl+A${NC}"
                    conflicts_found=true
                    ;;
                "ms-vscode.notepadplusplus-keybindings")
                    echo -e "${BLUE}   → Notepad++ keybindings may override Ctrl+A${NC}"
                    conflicts_found=true
                    ;;
            esac
        fi
    done

    if [[ "$conflicts_found" == true ]]; then
        echo -e "\n${GREEN}💡 Solution applied:${NC}"
        echo -e "${CYAN}   Our keybindings.json will override extension conflicts${NC}"
        echo -e "${CYAN}   Ctrl+A will remain mapped to 'Select All' in editor${NC}"
    else
        echo -e "${GREEN}✅ No conflicting keybinding extensions detected${NC}"
    fi
}

# Uninstall all extensions
uninstall_all_extensions() {
    local installed="$1"
    echo -e "${YELLOW}⚠️ Uninstalling SEMUA extensions...${NC}\n"
    local count=0
    while IFS= read -r ext; do
        ((count++))
        echo -e "${BLUE}[$count] Uninstalling:${NC}"
        show_extension_info "$ext"
        if code --uninstall-extension "$ext" &>/dev/null; then
            echo -e "${GREEN}  ✅ Berhasil diuninstall${NC}\n"
        else
            echo -e "${RED}  ❌ Gagal diuninstall${NC}\n"
        fi
    done <<< "$installed"
    echo -e "${GREEN}🎉 Selesai uninstall semua extensions${NC}"
    echo -ne "${CYAN}Tekan Enter untuk melanjutkan...${NC}"
    read -r
}

# Uninstall extensions from specific category
uninstall_category_extensions() {
    local category="$1"
    local category_name="$2"
    local extensions="$3"

    clear
    echo -e "${RED}🗑️ Uninstall ${category_name}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Convert extensions string to array
    IFS=' ' read -ra ext_array <<< "$extensions"

    # Display extensions in this category
    local i=1
    declare -A ext_map
    for ext in "${ext_array[@]}"; do
        echo -e "${BLUE}$i. ${CYAN}$ext${NC}"
        show_extension_info "$ext"
        echo ""
        ext_map[$i]="$ext"
        ((i++))
    done

    echo -e "${RED}0. 🗑️  ${YELLOW}Uninstall SEMUA dari kategori ini${NC}"
    echo -e "${GRAY}back. 🔙 ${CYAN}Kembali ke Kategori${NC}"
    echo ""

    while true; do
        echo -ne "${GREEN}Pilih extension untuk uninstall (0/1-$((i-1))/back): ${NC}"
        read -r choice

        case "$choice" in
            0)
                echo -e "${YELLOW}⚠️ Uninstalling semua extensions dari ${category_name}...${NC}\n"
                local count=0
                for ext in "${ext_array[@]}"; do
                    ((count++))
                    echo -e "${BLUE}[$count/${#ext_array[@]}] Uninstalling:${NC}"
                    show_extension_info "$ext"
                    if code --uninstall-extension "$ext" &>/dev/null; then
                        echo -e "${GREEN}  ✅ Berhasil diuninstall${NC}\n"
                        remove_extension_config "$ext"
                    else
                        echo -e "${RED}  ❌ Gagal diuninstall${NC}\n"
                    fi
                done
                echo -e "${GREEN}🎉 Selesai uninstall ${category_name}${NC}"
                echo -ne "${CYAN}Tekan Enter untuk melanjutkan...${NC}"
                read -r
                return 0
                ;;
            back)
                return 0
                ;;
            *)
                if [[ $choice =~ ^[0-9]+$ ]] && [[ -n "${ext_map[$choice]:-}" ]]; then
                    local ext="${ext_map[$choice]}"
                    echo -e "${YELLOW}Uninstalling:${NC}"
                    show_extension_info "$ext"
                    if code --uninstall-extension "$ext" &>/dev/null; then
                        echo -e "${GREEN}✅ $ext berhasil diuninstall${NC}"
                        remove_extension_config "$ext"
                        # Remove from current list
                        unset "ext_map[$choice]"
                        # Check if category is empty
                        local remaining=0
                        for _ in "${!ext_map[@]}"; do
                            ((remaining++))
                        done
                        if [[ $remaining -eq 0 ]]; then
                            echo -e "${GREEN}🎉 Semua extensions dari ${category_name} telah diuninstall${NC}"
                            echo -ne "${CYAN}Tekan Enter untuk melanjutkan...${NC}"
                            read -r
                            return 0
                        fi
                    else
                        echo -e "${RED}❌ Gagal uninstall $ext${NC}"
                    fi
                    echo ""
                else
                    echo -e "${RED}❌ Pilihan tidak valid${NC}"
                fi
                ;;
        esac
    done
}

# Interactive uninstall with global shopping cart
interactive_uninstall() {
    # Check if there are installed extensions
    local installed_extensions
    installed_extensions=$(code --list-extensions 2>/dev/null)

    if [[ -z "$installed_extensions" ]]; then
        echo -e "${YELLOW}⚠️ Tidak ada extensions yang terinstall${NC}"
        echo -ne "${CYAN}Tekan Enter untuk melanjutkan...${NC}"
        read -r
        return 0
    fi

    # Filter global categories to only show categories with installed extensions
    declare -A available_categories
    while IFS= read -r ext; do
        local category
        category=$(detect_extension_category "$ext")
        if [[ -n "${CATEGORIES[$category]:-}" ]]; then
            if [[ -z "${available_categories[$category]:-}" ]]; then
                available_categories[$category]="$ext"
            else
                available_categories[$category]+=" $ext"
            fi
        else
            # Handle "other" category
            if [[ -z "${available_categories[other]:-}" ]]; then
                available_categories[other]="$ext"
            else
                available_categories[other]+=" $ext"
            fi
        fi
    done <<< "$installed_extensions"

    # Temporarily update CATEGORIES with only installed extensions
    local original_categories=()
    for category in "${!CATEGORIES[@]}"; do
        original_categories+=("$category:${CATEGORIES[$category]}")
    done

    # Clear CATEGORIES and populate only with installed extensions
    for category in "${!CATEGORIES[@]}"; do
        unset "CATEGORIES[$category]"
    done

    for category in "${!available_categories[@]}"; do
        CATEGORIES[$category]="${available_categories[$category]}"
    done

    clear_cart
    manage_cart "uninstall"

    # Restore original categories
    for category in "${!CATEGORIES[@]}"; do
        unset "CATEGORIES[$category]"
    done

    for entry in "${original_categories[@]}"; do
        local category="${entry%%:*}"
        local extensions="${entry#*:}"
        CATEGORIES[$category]="$extensions"
    done
}

# Auto-detect and uninstall extensions by category
detect_and_uninstall() {
    clear
    echo -e "${RED}🗑️ Uninstall Extensions${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Sub-menu for uninstall options
    echo -e "${GREEN}Uninstall Options:${NC}"
    echo -e "${BLUE}1. 🛒 ${CYAN}Interactive Uninstall (Shopping Cart)${NC}"
    echo -e "${YELLOW}2. 📂 ${PURPLE}Category-based Uninstall${NC}"
    echo -e "${GRAY}3. 🔙 ${CYAN}Back to Main Menu${NC}"
    echo ""

    echo -ne "${GREEN}Choose uninstall mode (1-3): ${NC}"
    read -r mode_choice

    case $mode_choice in
        1) interactive_uninstall ;;
        2) category_based_uninstall ;;
        3) return 0 ;;
        *)
            echo -e "${RED}❌ Invalid choice${NC}"
            echo -ne "${CYAN}Press Enter to continue...${NC}"
            read -r
            detect_and_uninstall
            ;;
    esac
}

# Category-based uninstall (original functionality)
category_based_uninstall() {
    clear
    echo -e "${RED}📂 Category-based Uninstall${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    check_vscode || return 1

    # Get installed extensions
    local installed
    installed=$(code --list-extensions 2>/dev/null) || {
        echo "❌ Gagal mendapatkan daftar extensions"
        return 1
    }

    [[ -z "$installed" ]] && {
        echo -e "${YELLOW}ℹ️ Tidak ada extension yang terinstall${NC}"
        echo -ne "${CYAN}Tekan Enter untuk melanjutkan...${NC}"
        read -r
        return 0
    }

    # Group extensions by category
    declare -A categorized_extensions
    local -a other_extensions=()

    while IFS= read -r ext; do
        local category
        category=$(detect_extension_category "$ext")
        if [[ "$category" == "other" ]]; then
            other_extensions+=("$ext")
        else
            if [[ -z "${categorized_extensions[$category]:-}" ]]; then
                categorized_extensions[$category]="$ext"
            else
                categorized_extensions[$category]+=" $ext"
            fi
        fi
    done <<< "$installed"

    # Display menu
    while true; do
        clear
        echo -e "${RED}� Uninstall by Category${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        local menu_counter=1
        declare -A menu_map

        # Show categories with extensions
        for category in "${!categorized_extensions[@]}"; do
            local category_name
            category_name=$(get_category_display_name "$category")
            local ext_count
            ext_count=$(echo "${categorized_extensions[$category]}" | wc -w)
            echo -e "${BLUE}$menu_counter. ${category_name} ${GRAY}(${ext_count} extensions)${NC}"
            menu_map[$menu_counter]="$category"
            ((menu_counter++))
        done

        # Show other extensions if any
        if [[ ${#other_extensions[@]} -gt 0 ]]; then
            echo -e "${BLUE}$menu_counter. 📦 Other Extensions ${GRAY}(${#other_extensions[@]} extensions)${NC}"
            menu_map[$menu_counter]="other"
            ((menu_counter++))
        fi

        echo ""
        echo -e "${RED}$menu_counter. 🗑️  ${YELLOW}Uninstall SEMUA Extensions${NC}"
        menu_map[$menu_counter]="all"
        ((menu_counter++))

        echo -e "${GRAY}$menu_counter. 🔙 ${CYAN}Kembali ke Menu Utama${NC}"
        menu_map[$menu_counter]="back"
        echo ""

        echo -ne "${GREEN}Pilih kategori untuk uninstall (1-$menu_counter): ${NC}"
        read -r choice

        if [[ -n "${menu_map[$choice]:-}" ]]; then
            local selected_category="${menu_map[$choice]}"

            case "$selected_category" in
                "all")
                    uninstall_all_extensions "$installed"
                    return 0
                    ;;
                "back")
                    return 0
                    ;;
                "other")
                    uninstall_category_extensions "other" "📦 Other Extensions" "${other_extensions[*]}"
                    ;;
                *)
                    local category_name
                    category_name=$(get_category_display_name "$selected_category")
                    uninstall_category_extensions "$selected_category" "$category_name" "${categorized_extensions[$selected_category]}"
                    ;;
            esac
        else
            echo -e "${RED}❌ Pilihan tidak valid${NC}"
            echo -ne "${CYAN}Tekan Enter untuk melanjutkan...${NC}"
            read -r
        fi
    done
}

# Search extensions with marketplace-style functionality
search_extensions() {
    local search_term=""
    local search_results=()
    local installed_extensions=()

    # Get currently installed extensions
    if command -v code >/dev/null 2>&1; then
        mapfile -t installed_extensions < <(code --list-extensions 2>/dev/null || true)
    fi

    while true; do
        clear
        print_banner
        echo -e "\n${PURPLE}🔍 Search Extensions${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

        if [[ -n "$search_term" ]]; then
            echo -e "${GREEN}📋 Search Results for: ${YELLOW}'$search_term'${NC}"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

            # Search through extensions
            search_results=()
            local result_count=0

            for ext_id in "${!EXTENSION_INFO[@]}"; do
                local ext_data="${EXTENSION_INFO[$ext_id]}"
                local ext_name
                local ext_desc
                ext_name=$(echo "$ext_data" | cut -d'|' -f1)
                ext_desc=$(echo "$ext_data" | cut -d'|' -f2)

                # Case-insensitive search in ID, name, and description
                if [[ "${ext_id,,}" == *"${search_term,,}"* ]] || \
                   [[ "${ext_name,,}" == *"${search_term,,}"* ]] || \
                   [[ "${ext_desc,,}" == *"${search_term,,}"* ]]; then
                    search_results+=("$ext_id")
                    ((result_count++))
                fi
            done

            if [[ $result_count -eq 0 ]]; then
                echo -e "${RED}❌ No extensions found matching '$search_term'${NC}"
                echo -e "${GRAY}💡 Try different keywords or check spelling${NC}"
            else
                echo -e "${GREEN}✅ Found $result_count extension(s)${NC}"
                echo ""

                # Display search results with numbered list
                local index=1
                for ext_id in "${search_results[@]}"; do
                    local ext_data="${EXTENSION_INFO[$ext_id]}"
                    local ext_name
                    local ext_desc
                    local category
                    local category_display
                    ext_name=$(echo "$ext_data" | cut -d'|' -f1)
                    ext_desc=$(echo "$ext_data" | cut -d'|' -f2)
                    category=$(get_extension_category "$ext_id")
                    category_display=$(get_category_display_name "$category")

                    # Check if extension is installed
                    local status_icon="⬜"
                    local status_text="${GRAY}Not Installed${NC}"

                    if printf '%s\n' "${installed_extensions[@]}" | grep -q "^$ext_id$"; then
                        status_icon="✅"
                        status_text="${GREEN}Installed${NC}"
                    fi

                    echo -e "${YELLOW}$index. ${CYAN}$ext_name${NC}"
                    echo -e "   ${BLUE}ID:${NC} $ext_id"
                    echo -e "   ${PURPLE}Category:${NC} $category_display"
                    echo -e "   ${GREEN}Description:${NC} $ext_desc"
                    echo -e "   ${YELLOW}Status:${NC} $status_icon $status_text"
                    echo ""
                    ((index++))
                done

                echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "${GREEN}Actions:${NC}"
                echo -e "${YELLOW}• Enter number (1-$result_count) to manage extension${NC}"
                echo -e "${BLUE}• Type 'install <number>' to install specific extension${NC}"
                echo -e "${RED}• Type 'uninstall <number>' to uninstall specific extension${NC}"
                echo -e "${PURPLE}• Type 'info <number>' for detailed information${NC}"
            fi
        else
            echo -e "${GREEN}🔍 Extension Search${NC}"
            echo -e "${GRAY}Search through all available extensions by name, ID, or description${NC}"
            echo ""
            echo -e "${CYAN}💡 Tips:${NC}"
            echo -e "${YELLOW}• Use keywords like: python, javascript, git, theme, etc.${NC}"
            echo -e "${YELLOW}• Search is case-insensitive${NC}"
            echo -e "${YELLOW}• Partial matches are supported${NC}"
        fi

        echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}Search Options:${NC}"
        echo -e "${YELLOW}1. 🔍 ${CYAN}New Search${NC}"
        echo -e "${BLUE}2. 📂 ${YELLOW}Browse by Category${NC}"
        echo -e "${PURPLE}3. ⭐ ${GREEN}Show Popular Extensions${NC}"
        echo -e "${GRAY}4. 🔙 ${CYAN}Back to Main Menu${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

        echo -ne "${GREEN}Enter choice or search term: ${NC}"
        read -r input

        case "$input" in
            1|"new"|"search")
                echo -ne "${CYAN}🔍 Enter search term: ${NC}"
                read -r search_term
                ;;
            2|"category"|"browse")
                search_by_category
                # No prompt needed - search_by_category handles its own prompts
                ;;
            3|"popular"|"show")
                show_popular_extensions
                # No prompt needed - show_popular_extensions handles its own prompts
                ;;
            4|"back"|"menu"|"exit"|"quit")
                return
                ;;
            install\ *)
                local num="${input#install }"
                if [[ "$num" =~ ^[0-9]+$ ]] && [[ $num -ge 1 ]] && [[ $num -le ${#search_results[@]} ]]; then
                    local ext_id="${search_results[$((num-1))]}"
                    install_single_extension "$ext_id"
                    echo -ne "${CYAN}Press Enter to continue...${NC}"
                    read -r
                else
                    echo -e "${RED}❌ Invalid extension number${NC}"
                    echo -ne "${CYAN}Press Enter to continue...${NC}"
                    read -r
                fi
                ;;
            uninstall\ *)
                local num="${input#uninstall }"
                if [[ "$num" =~ ^[0-9]+$ ]] && [[ $num -ge 1 ]] && [[ $num -le ${#search_results[@]} ]]; then
                    local ext_id="${search_results[$((num-1))]}"
                    uninstall_single_extension "$ext_id"
                    echo -ne "${CYAN}Press Enter to continue...${NC}"
                    read -r
                else
                    echo -e "${RED}❌ Invalid extension number${NC}"
                    echo -ne "${CYAN}Press Enter to continue...${NC}"
                    read -r
                fi
                ;;
            info\ *)
                local num="${input#info }"
                if [[ "$num" =~ ^[0-9]+$ ]] && [[ $num -ge 1 ]] && [[ $num -le ${#search_results[@]} ]]; then
                    local ext_id="${search_results[$((num-1))]}"
                    show_extension_info "$ext_id"
                    echo -ne "${CYAN}Press Enter to continue...${NC}"
                    read -r
                else
                    echo -e "${RED}❌ Invalid extension number${NC}"
                    echo -ne "${CYAN}Press Enter to continue...${NC}"
                    read -r
                fi
                ;;
            [0-9]*)
                if [[ "$input" =~ ^[0-9]+$ ]] && [[ $input -ge 1 ]] && [[ $input -le ${#search_results[@]} ]]; then
                    local ext_id="${search_results[$((input-1))]}"
                    manage_single_extension "$ext_id"
                    # No prompt needed - manage_single_extension handles its own flow
                else
                    echo -e "${RED}❌ Invalid extension number${NC}"
                    echo -ne "${CYAN}Press Enter to continue...${NC}"
                    read -r
                fi
                ;;
            *)
                if [[ -n "$input" ]]; then
                    search_term="$input"
                fi
                ;;
        esac
    done
}

# Helper function to manage single extension
manage_single_extension() {
    local ext_id="$1"
    local ext_data="${EXTENSION_INFO[$ext_id]}"
    local ext_name
    local is_installed=false
    ext_name=$(echo "$ext_data" | cut -d'|' -f1)

    # Check if extension is installed
    if command -v code >/dev/null 2>&1; then
        if code --list-extensions 2>/dev/null | grep -q "^$ext_id$"; then
            is_installed=true
        fi
    fi

    clear
    show_extension_info "$ext_id"

    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Available Actions:${NC}"

    if [[ "$is_installed" == true ]]; then
        echo -e "${RED}1. 🗑️ ${YELLOW}Uninstall Extension${NC}"
        echo -e "${BLUE}2. 🔄 ${PURPLE}Reinstall Extension${NC}"
    else
        echo -e "${GREEN}1. 📦 ${CYAN}Install Extension${NC}"
    fi

    echo -e "${GRAY}3. 🔙 ${CYAN}Back to Search${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    echo -ne "${GREEN}Choose action (1-3): ${NC}"
    read -r action

    case "$action" in
        1)
            if [[ "$is_installed" == true ]]; then
                uninstall_single_extension "$ext_id"
            else
                install_single_extension "$ext_id"
            fi
            echo -ne "${CYAN}Press Enter to continue...${NC}"
            read -r
            ;;
        2)
            if [[ "$is_installed" == true ]]; then
                echo -e "${YELLOW}🔄 Reinstalling $ext_name...${NC}"
                uninstall_single_extension "$ext_id"
                install_single_extension "$ext_id"
                echo -ne "${CYAN}Press Enter to continue...${NC}"
                read -r
            fi
            ;;
        3|*)
            return
            ;;
    esac
}

# Helper function to show detailed extension information
show_extension_info() {
    local ext_id="$1"
    local ext_data="${EXTENSION_INFO[$ext_id]}"
    local ext_name
    local ext_desc
    local category
    local category_display
    local is_installed=false
    ext_name=$(echo "$ext_data" | cut -d'|' -f1)
    ext_desc=$(echo "$ext_data" | cut -d'|' -f2)
    category=$(get_extension_category "$ext_id")
    category_display=$(get_category_display_name "$category")

    # Check if extension is installed
    if command -v code >/dev/null 2>&1; then
        if code --list-extensions 2>/dev/null | grep -q "^$ext_id$"; then
            is_installed=true
        fi
    fi

    echo -e "\n${PURPLE}📋 Extension Details${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Name:${NC} $ext_name"
    echo -e "${BLUE}ID:${NC} $ext_id"
    echo -e "${PURPLE}Category:${NC} $category_display"
    echo -e "${GREEN}Description:${NC} $ext_desc"

    if [[ "$is_installed" == true ]]; then
        echo -e "${YELLOW}Status:${NC} ✅ ${GREEN}Installed${NC}"
    else
        echo -e "${YELLOW}Status:${NC} ⬜ ${GRAY}Not Installed${NC}"
    fi
}

# Helper function to install single extension
install_single_extension() {
    local ext_id="$1"
    local ext_data="${EXTENSION_INFO[$ext_id]}"
    local ext_name
    ext_name=$(echo "$ext_data" | cut -d'|' -f1)

    echo -e "\n${GREEN}📦 Installing: $ext_name${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if command -v code >/dev/null 2>&1; then
        if code --install-extension "$ext_id" --force; then
            echo -e "${GREEN}✅ Successfully installed: $ext_name${NC}"
        else
            echo -e "${RED}❌ Failed to install: $ext_name${NC}"
        fi
    else
        echo -e "${RED}❌ VS Code CLI not found${NC}"
    fi
}

# Helper function to uninstall single extension
uninstall_single_extension() {
    local ext_id="$1"
    local ext_data="${EXTENSION_INFO[$ext_id]}"
    local ext_name
    ext_name=$(echo "$ext_data" | cut -d'|' -f1)

    echo -e "\n${RED}🗑️ Uninstalling: $ext_name${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if command -v code >/dev/null 2>&1; then
        if code --uninstall-extension "$ext_id"; then
            echo -e "${GREEN}✅ Successfully uninstalled: $ext_name${NC}"
        else
            echo -e "${RED}❌ Failed to uninstall: $ext_name${NC}"
        fi
    else
        echo -e "${RED}❌ VS Code CLI not found${NC}"
    fi
}

# Helper function to search by category
search_by_category() {
    while true; do
        clear
        print_banner
        echo -e "\n${PURPLE}📂 Browse Extensions by Category${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

        echo -e "${GREEN}Available Categories:${NC}"
        echo -e "${YELLOW}1. 🤖 ${CYAN}AI & Machine Learning${NC}"
        echo -e "${BLUE}2. 💻 ${YELLOW}JavaScript & Node.js${NC}"
        echo -e "${GREEN}3. 🐍 ${PURPLE}Python Development${NC}"
        echo -e "${PURPLE}4. 🌐 ${BLUE}Web Development${NC}"
        echo -e "${CYAN}5. 🔤 ${GREEN}Other Languages${NC}"
        echo -e "${YELLOW}6. ✏️ ${RED}Editor Enhancements${NC}"
        echo -e "${BLUE}7. 🎨 ${PURPLE}Themes & UI${NC}"
        echo -e "${GREEN}8. 🔧 ${CYAN}DevOps & Tools${NC}"
        echo -e "${PURPLE}9. 📊 ${YELLOW}Data & Database${NC}"
        echo -e "${GRAY}10. 🔙 ${CYAN}Back to Search${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

        echo -ne "${GREEN}Choose category (1-10): ${NC}"
        read -r choice

        local category=""
        case "$choice" in
            1) category="ai" ;;
            2) category="javascript" ;;
            3) category="python" ;;
            4) category="webdev" ;;
            5) category="languages" ;;
            6) category="editor" ;;
            7) category="themes" ;;
            8) category="devops" ;;
            9) category="data" ;;
            10|"back") return ;;
            *)
                echo -e "${RED}❌ Invalid choice${NC}"
                continue
                ;;
        esac

        if [[ -n "$category" ]]; then
            show_category_extensions "$category"
        fi
    done
}

# Helper function to show extensions in a category
show_category_extensions() {
    local target_category="$1"
    local category_display
    local extensions_in_category=()
    local installed_extensions=()
    category_display=$(get_category_display_name "$target_category")

    # Get currently installed extensions
    if command -v code >/dev/null 2>&1; then
        mapfile -t installed_extensions < <(code --list-extensions 2>/dev/null || true)
    fi

    # Find extensions in this category
    for ext_id in "${!EXTENSION_INFO[@]}"; do
        local ext_category
        ext_category=$(get_extension_category "$ext_id")
        if [[ "$ext_category" == "$target_category" ]]; then
            extensions_in_category+=("$ext_id")
        fi
    done

    clear
    print_banner
    echo -e "\n${PURPLE}📂 $category_display Extensions${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if [[ ${#extensions_in_category[@]} -eq 0 ]]; then
        echo -e "${RED}❌ No extensions found in this category${NC}"
    else
        echo -e "${GREEN}✅ Found ${#extensions_in_category[@]} extension(s)${NC}"
        echo ""

        local index=1
        for ext_id in "${extensions_in_category[@]}"; do
            local ext_data="${EXTENSION_INFO[$ext_id]}"
            local ext_name
            local ext_desc
            ext_name=$(echo "$ext_data" | cut -d'|' -f1)
            ext_desc=$(echo "$ext_data" | cut -d'|' -f2)

            # Check if extension is installed
            local status_icon="⬜"
            local status_text="${GRAY}Not Installed${NC}"

            if printf '%s\n' "${installed_extensions[@]}" | grep -q "^$ext_id$"; then
                status_icon="✅"
                status_text="${GREEN}Installed${NC}"
            fi

            echo -e "${YELLOW}$index. ${CYAN}$ext_name${NC}"
            echo -e "   ${BLUE}ID:${NC} $ext_id"
            echo -e "   ${GREEN}Description:${NC} $ext_desc"
            echo -e "   ${YELLOW}Status:${NC} $status_icon $status_text"
            echo ""
            ((index++))
        done

        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}Actions:${NC}"
        echo -e "${YELLOW}• Enter number (1-${#extensions_in_category[@]}) to manage extension${NC}"
        echo -e "${BLUE}• Type 'install all' to install all extensions in category${NC}"
        echo -e "${RED}• Type 'uninstall all' to uninstall all extensions in category${NC}"
    fi

    echo -e "${GRAY}• Type 'back' to return to category selection${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    echo -ne "${GREEN}Enter choice: ${NC}"
    read -r input

    case "$input" in
        "install all")
            echo -e "\n${GREEN}📦 Installing all extensions in $category_display...${NC}"
            for ext_id in "${extensions_in_category[@]}"; do
                install_single_extension "$ext_id"
            done
            ;;
        "uninstall all")
            echo -e "\n${RED}🗑️ Uninstalling all extensions in $category_display...${NC}"
            for ext_id in "${extensions_in_category[@]}"; do
                uninstall_single_extension "$ext_id"
            done
            ;;
        "back")
            return
            ;;
        [0-9]*)
            if [[ "$input" =~ ^[0-9]+$ ]] && [[ $input -ge 1 ]] && [[ $input -le ${#extensions_in_category[@]} ]]; then
                local ext_id="${extensions_in_category[$((input-1))]}"
                manage_single_extension "$ext_id"
            else
                echo -e "${RED}❌ Invalid extension number${NC}"
            fi
            ;;
        *)
            echo -e "${RED}❌ Invalid choice${NC}"
            ;;
    esac

    if [[ "$input" != "back" ]]; then
        echo -ne "${CYAN}Press Enter to continue...${NC}"
        read -r
    fi
}

# Helper function to show popular extensions
show_popular_extensions() {
    local popular_extensions=(
        "ms-python.python"
        "ms-vscode.vscode-typescript-next"
        "esbenp.prettier-vscode"
        "bradlc.vscode-tailwindcss"
        "ms-vscode.vscode-json"
        "github.copilot"
        "ms-python.black-formatter"
        "ms-python.isort"
        "formulahendry.auto-rename-tag"
        "ms-python.flake8"
    )

    clear
    print_banner
    echo -e "\n${PURPLE}⭐ Popular Extensions${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Top 10 Most Popular Extensions:${NC}"
    echo ""

    local installed_extensions=()
    if command -v code >/dev/null 2>&1; then
        mapfile -t installed_extensions < <(code --list-extensions 2>/dev/null || true)
    fi

    local index=1
    for ext_id in "${popular_extensions[@]}"; do
        if [[ -n "${EXTENSION_INFO[$ext_id]}" ]]; then
            local ext_data="${EXTENSION_INFO[$ext_id]}"
            local ext_name
            local ext_desc
            local category
            local category_display
            ext_name=$(echo "$ext_data" | cut -d'|' -f1)
            ext_desc=$(echo "$ext_data" | cut -d'|' -f2)
            category=$(get_extension_category "$ext_id")
            category_display=$(get_category_display_name "$category")

            # Check if extension is installed
            local status_icon="⬜"
            local status_text="${GRAY}Not Installed${NC}"

            if printf '%s\n' "${installed_extensions[@]}" | grep -q "^$ext_id$"; then
                status_icon="✅"
                status_text="${GREEN}Installed${NC}"
            fi

            echo -e "${YELLOW}$index. ${CYAN}$ext_name${NC}"
            echo -e "   ${BLUE}ID:${NC} $ext_id"
            echo -e "   ${PURPLE}Category:${NC} $category_display"
            echo -e "   ${GREEN}Description:${NC} $ext_desc"
            echo -e "   ${YELLOW}Status:${NC} $status_icon $status_text"
            echo ""
            ((index++))
        fi
    done

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Actions:${NC}"
    echo -e "${YELLOW}• Enter number (1-10) to manage extension${NC}"
    echo -e "${BLUE}• Type 'install all' to install all popular extensions${NC}"
    echo -e "${GRAY}• Type 'back' to return to search menu${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    echo -ne "${GREEN}Enter choice: ${NC}"
    read -r input

    case "$input" in
        "install all")
            echo -e "\n${GREEN}📦 Installing all popular extensions...${NC}"
            for ext_id in "${popular_extensions[@]}"; do
                if [[ -n "${EXTENSION_INFO[$ext_id]}" ]]; then
                    install_single_extension "$ext_id"
                fi
            done
            ;;
        "back")
            return
            ;;
        [0-9]*)
            if [[ "$input" =~ ^[0-9]+$ ]] && [[ $input -ge 1 ]] && [[ $input -le ${#popular_extensions[@]} ]]; then
                local ext_id="${popular_extensions[$((input-1))]}"
                if [[ -n "${EXTENSION_INFO[$ext_id]}" ]]; then
                    manage_single_extension "$ext_id"
                else
                    echo -e "${RED}❌ Extension not found in database${NC}"
                fi
            else
                echo -e "${RED}❌ Invalid extension number${NC}"
            fi
            ;;
        *)
            echo -e "${RED}❌ Invalid choice${NC}"
            ;;
    esac

    if [[ "$input" != "back" ]]; then
        echo -ne "${CYAN}Press Enter to continue...${NC}"
        read -r
    fi
}

# Edit/manage settings.json
manage_settings() {
    while true; do
        clear
        echo -e "${PURPLE}⚙️ Manage Settings.json${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

        # Auto detect extensions for context
        detect_installed_extensions
        echo ""

        echo -e "${GREEN}Settings Management Options:${NC}"
        echo -e "${GREEN}1. ⚙️ ${CYAN}Create/Overwrite Default Settings${NC}"
        echo -e "   ${GRAY}→ Buat settings.json baru dengan konfigurasi optimal${NC}"
        echo -e "${BLUE}2. ✏️ ${YELLOW}Edit Existing Settings${NC}"
        echo -e "   ${GRAY}→ Buka settings.json yang ada untuk diedit manual${NC}"
        echo -e "${PURPLE}3. 👁️ ${GREEN}View Current Settings${NC}"
        echo -e "   ${GRAY}→ Tampilkan isi settings.json saat ini${NC}"
        echo -e "${YELLOW}4. 💾 ${BLUE}Backup Current Settings${NC}"
        echo -e "   ${GRAY}→ Buat backup dari settings.json yang ada${NC}"
        echo -e "${CYAN}5. 📊 ${PURPLE}Show Extension Info${NC}"
        echo -e "   ${GRAY}→ Tampilkan ringkasan extensions yang terinstall${NC}"
        echo -e "${PURPLE}6. 🔧 ${YELLOW}Advanced Configuration${NC}"
        echo -e "   ${GRAY}→ Konfigurasi lanjutan untuk extensions dan themes${NC}"
        echo -e "${GRAY}7. 🔙 ${CYAN}Kembali ke Menu Utama${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        echo -ne "${GREEN}Pilih opsi (1-7): ${NC}"
        read -r choice

        case $choice in
            1)
                echo -e "\n${GREEN}🛠️ Create/Overwrite Default Settings${NC}"
                echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                create_default_settings
                ;;
            2)
                echo -e "\n${BLUE}✏️ Edit Existing Settings${NC}"
                echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                edit_settings_file
                ;;
            3)
                echo -e "\n${PURPLE}�️ View Current Settings${NC}"
                echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                view_settings_file
                ;;
            4)
                echo -e "\n${YELLOW}💾 Backup Current Settings${NC}"
                echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                backup_settings_file
                ;;
            5)
                clear
                echo -e "${CYAN}📊 Extension Information${NC}"
                echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                show_installed_summary
                echo -ne "${CYAN}Tekan Enter untuk melanjutkan...${NC}"
                read -r
                ;;
            6)
                echo -e "\n${PURPLE}🔧 Advanced Configuration${NC}"
                echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                show_advanced_config_menu
                ;;
            7)
                return 0
                ;;
            *)
                echo -e "${RED}❌ Pilihan tidak valid${NC}"
                echo -ne "${CYAN}Tekan Enter untuk melanjutkan...${NC}"
                read -r
                ;;
        esac
    done
}

# Dedicated function to edit settings file
edit_settings_file() {
    echo -e "${CYAN}Available settings locations:${NC}"
    echo -e "${GREEN}1. ${YELLOW}User Global Settings${NC} (~/.config/Code/User/settings.json)"
    echo -e "${BLUE}2. ${PURPLE}Current Workspace Settings${NC} ($(pwd)/.vscode/settings.json)"
    echo -e "${GRAY}3. ${CYAN}Custom Path${NC} (specify manually)"
    echo -e "${RED}0. ${GRAY}Cancel/Back${NC} (return to settings menu)"
    echo ""

    echo -ne "${GREEN}Select settings location (0-3): ${NC}"
    read -r location_choice

    local settings_file
    case $location_choice in
        1)
            settings_file="$HOME/.config/Code/User/settings.json"
            echo -e "${GREEN}📍 Selected: User Global Settings${NC}"
            ;;
        2)
            settings_file="$(pwd)/.vscode/settings.json"
            echo -e "${BLUE}📍 Selected: Workspace Settings${NC}"
            ;;
        3)
            echo -ne "${YELLOW}Enter full path to settings.json: ${NC}"
            read -r custom_path
            if [[ -n "$custom_path" ]]; then
                settings_file="$custom_path"
                echo -e "${PURPLE}📍 Selected: Custom Path${NC}"
            else
                echo -e "${RED}❌ Path cannot be empty${NC}"
                echo -ne "${CYAN}Press Enter to continue...${NC}"
                read -r
                return 1
            fi
            ;;
        0)
            echo -e "${YELLOW}❌ Operation cancelled${NC}"
            return 0
            ;;
        *)
            echo -e "${RED}❌ Invalid selection${NC}"
            echo -ne "${CYAN}Press Enter to continue...${NC}"
            read -r
            return 1
            ;;
    esac

    if [[ -f "$settings_file" ]]; then
        echo -e "${BLUE}📝 Opening settings.json for editing...${NC}"
        echo -e "${GRAY}File: $settings_file${NC}"

        if command -v code &>/dev/null; then
            echo -e "${GREEN}🚀 Opening in VS Code...${NC}"
            code "$settings_file"
        elif command -v nano &>/dev/null; then
            echo -e "${YELLOW}📝 Opening in nano...${NC}"
            nano "$settings_file"
        elif command -v vim &>/dev/null; then
            echo -e "${PURPLE}🖥️ Opening in vim...${NC}"
            vim "$settings_file"
        else
            echo -e "${RED}❌ No suitable editor found${NC}"
            echo -e "${YELLOW}💡 Please install: code, nano, or vim${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ Settings file not found: $settings_file${NC}"
        echo -e "${CYAN}💡 Create it first using option 1 (Create Default Settings)${NC}"
    fi

    echo -ne "${CYAN}Press Enter to continue...${NC}"
    read -r
}

# Dedicated function to view settings file
view_settings_file() {
    echo -e "${CYAN}Available settings locations:${NC}"
    echo -e "${GREEN}1. ${YELLOW}User Global Settings${NC} (~/.config/Code/User/settings.json)"
    echo -e "${BLUE}2. ${PURPLE}Current Workspace Settings${NC} ($(pwd)/.vscode/settings.json)"
    echo -e "${GRAY}3. ${CYAN}Custom Path${NC} (specify manually)"
    echo -e "${RED}0. ${GRAY}Cancel/Back${NC} (return to settings menu)"
    echo ""

    echo -ne "${GREEN}Select settings location to view (0-3): ${NC}"
    read -r location_choice

    local settings_file
    case $location_choice in
        1)
            settings_file="$HOME/.config/Code/User/settings.json"
            echo -e "${GREEN}📍 Viewing: User Global Settings${NC}"
            ;;
        2)
            settings_file="$(pwd)/.vscode/settings.json"
            echo -e "${BLUE}📍 Viewing: Workspace Settings${NC}"
            ;;
        3)
            echo -ne "${YELLOW}Enter full path to settings.json: ${NC}"
            read -r custom_path
            if [[ -n "$custom_path" ]]; then
                settings_file="$custom_path"
                echo -e "${PURPLE}📍 Viewing: Custom Path${NC}"
            else
                echo -e "${RED}❌ Path cannot be empty${NC}"
                echo -ne "${CYAN}Press Enter to continue...${NC}"
                read -r
                return 1
            fi
            ;;
        0)
            echo -e "${YELLOW}❌ Operation cancelled${NC}"
            return 0
            ;;
        *)
            echo -e "${RED}❌ Invalid selection${NC}"
            echo -ne "${CYAN}Press Enter to continue...${NC}"
            read -r
            return 1
            ;;
    esac

    if [[ -f "$settings_file" ]]; then
        echo -e "\n${CYAN}📄 Contents of: $settings_file${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        cat "$settings_file"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

        # Show file info
        local file_size
        file_size=$(wc -c < "$settings_file")
        local mod_time
        mod_time=$(stat -c %y "$settings_file" 2>/dev/null || stat -f %Sm "$settings_file" 2>/dev/null)
        echo -e "${GRAY}📊 File size: $file_size bytes | Modified: $mod_time${NC}"
    else
        echo -e "${YELLOW}⚠️ Settings file not found: $settings_file${NC}"
        echo -e "${CYAN}💡 Create it first using option 1 (Create Default Settings)${NC}"
    fi

    echo -ne "${CYAN}Press Enter to continue...${NC}"
    read -r
}

# Dedicated function to backup settings file
backup_settings_file() {
    echo -e "${CYAN}Available settings locations to backup:${NC}"
    echo -e "${GREEN}1. ${YELLOW}User Global Settings${NC} (~/.config/Code/User/settings.json)"
    echo -e "${BLUE}2. ${PURPLE}Current Workspace Settings${NC} ($(pwd)/.vscode/settings.json)"
    echo -e "${GRAY}3. ${CYAN}Custom Path${NC} (specify manually)"
    echo -e "${PURPLE}4. ${GREEN}Backup All Found Settings${NC} (automatic detection)"
    echo -e "${RED}0. ${GRAY}Cancel/Back${NC} (return to settings menu)"
    echo ""

    echo -ne "${GREEN}Select settings to backup (0-4): ${NC}"
    read -r backup_choice

    case $backup_choice in
        1)
            local settings_file="$HOME/.config/Code/User/settings.json"
            backup_single_settings_file "$settings_file" "User Global"
            ;;
        2)
            local settings_file
            settings_file="$(pwd)/.vscode/settings.json"
            backup_single_settings_file "$settings_file" "Workspace"
            ;;
        3)
            echo -ne "${YELLOW}Enter full path to settings.json: ${NC}"
            read -r custom_path
            if [[ -n "$custom_path" ]]; then
                backup_single_settings_file "$custom_path" "Custom"
            else
                echo -e "${RED}❌ Path cannot be empty${NC}"
                echo -ne "${CYAN}Press Enter to continue...${NC}"
                read -r
                return 1
            fi
            ;;
        4)
            echo -e "${PURPLE}🔍 Auto-detecting settings files...${NC}"
            local backup_count=0

            # Backup user global settings
            if [[ -f "$HOME/.config/Code/User/settings.json" ]]; then
                backup_single_settings_file "$HOME/.config/Code/User/settings.json" "User Global"
                ((backup_count++))
            fi

            # Backup workspace settings
            if [[ -f "$(pwd)/.vscode/settings.json" ]]; then
                backup_single_settings_file "$(pwd)/.vscode/settings.json" "Workspace"
                ((backup_count++))
            fi

            if [[ $backup_count -eq 0 ]]; then
                echo -e "${YELLOW}⚠️ No settings files found to backup${NC}"
            else
                echo -e "${GREEN}✅ Backed up $backup_count settings files${NC}"
            fi
            ;;
        0)
            echo -e "${YELLOW}❌ Operation cancelled${NC}"
            return 0
            ;;
        *)
            echo -e "${RED}❌ Invalid selection${NC}"
            echo -ne "${CYAN}Press Enter to continue...${NC}"
            read -r
            return 1
            ;;
    esac

    echo -ne "${CYAN}Press Enter to continue...${NC}"
    read -r
}

# Helper function to backup a single settings file
backup_single_settings_file() {
    local settings_file="$1"
    local description="$2"

    if [[ -f "$settings_file" ]]; then
        local backup_file
        backup_file="${settings_file}.backup.$(date +%Y%m%d_%H%M%S)"

        if cp "$settings_file" "$backup_file"; then
            echo -e "${GREEN}✅ $description settings backed up successfully${NC}"
            echo -e "${CYAN}📁 Backup location: $backup_file${NC}"

            # Show backup info
            local file_size
            file_size=$(wc -c < "$backup_file")
            echo -e "${GRAY}📊 Backup size: $file_size bytes${NC}"
        else
            echo -e "${RED}❌ Failed to backup $description settings${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ $description settings file not found: $settings_file${NC}"
    fi
}

# Advanced Configuration Menu (merged from companion script)
show_advanced_config_menu() {
    while true; do
        clear
        print_banner
        echo -e "\n${PURPLE}🔧 Advanced Configuration Menu${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${GREEN}1. ⚙️ ${CYAN}Auto Configure All Extensions${NC}"
        echo -e "   ${GRAY}→ Konfigurasi otomatis semua extensions yang terinstall${NC}"
        echo -e "${BLUE}2. 🎨 ${YELLOW}Configure Themes & Colors${NC}"
        echo -e "   ${GRAY}→ Pengaturan tema, warna, dan tampilan VS Code${NC}"
        echo -e "${PURPLE}3. 📝 ${GREEN}Configure Formatters${NC}"
        echo -e "   ${GRAY}→ Pengaturan code formatters untuk berbagai bahasa${NC}"
        echo -e "${YELLOW}4. 🔧 ${BLUE}Configure Language Support${NC}"
        echo -e "   ${GRAY}→ Konfigurasi khusus untuk bahasa pemrograman${NC}"
        echo -e "${CYAN}5. 📊 ${PURPLE}View Current Configuration${NC}"
        echo -e "   ${GRAY}→ Tampilkan konfigurasi extension saat ini${NC}"
        echo -e "${RED}0. 🔙 ${GRAY}Back to Settings Menu${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        echo -ne "${GREEN}Pilih opsi (0-5): ${NC}"
        read -r choice

        case $choice in
            1)
                interactive_auto_configure_all
                ;;
            2)
                interactive_configure_themes
                ;;
            3)
                interactive_configure_formatters
                ;;
            4)
                interactive_configure_languages
                ;;
            5)
                view_current_configuration_detailed
                ;;
            0)
                echo -e "${YELLOW}❌ Operation cancelled${NC}"
                return 0
                ;;
            *)
                echo -e "${RED}❌ Pilihan tidak valid, silakan coba lagi${NC}"
                echo -ne "${CYAN}Tekan Enter untuk melanjutkan...${NC}"
                read -r
                ;;
        esac
    done
}

# Interactive Auto Configure All Extensions
interactive_auto_configure_all() {
    clear
    echo -e "${GREEN}⚙️ Interactive Auto Configure All Extensions${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Auto detect extensions first
    detect_installed_extensions
    local ext_count=${#INSTALLED_EXTENSIONS[@]}

    if [[ $ext_count -eq 0 ]]; then
        echo -e "${YELLOW}⚠️ No extensions found to configure${NC}"
        echo -e "${GRAY}Install some extensions first using the main menu${NC}"
        echo -ne "${CYAN}Press Enter to continue...${NC}"
        read -r
        return
    fi

    echo -e "${BLUE}📦 Found $ext_count installed extensions${NC}"
    echo -e "${YELLOW}🔧 Choose configuration options:${NC}"
    echo ""

    # Configuration options
    echo -e "${GREEN}1. 🚀 ${CYAN}Quick Configure (recommended settings)${NC}"
    echo -e "${BLUE}2. 🎯 ${YELLOW}Custom Configure (choose per extension)${NC}"
    echo -e "${PURPLE}3. 📋 ${GREEN}Preview Configuration (see what will be configured)${NC}"
    echo -e "${RED}0. 🔙 ${GRAY}Back to Advanced Menu${NC}"
    echo ""

    echo -ne "${GREEN}Select option (0-3): ${NC}"
    read -r config_choice

    case $config_choice in
        1)
            # Quick configure with recommended settings
            echo -e "\n${CYAN}🚀 Quick Configuration with Recommended Settings${NC}"
            echo -e "${GRAY}This will apply optimal settings for all detected extensions${NC}"
            echo ""
            echo -ne "${YELLOW}Continue with quick configuration? (y/N): ${NC}"
            read -r confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                perform_quick_configuration
            else
                echo -e "${YELLOW}❌ Configuration cancelled${NC}"
            fi
            ;;
        2)
            # Custom configure per extension category
            interactive_custom_configuration
            ;;
        3)
            # Preview what will be configured
            preview_configuration_changes
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}❌ Invalid selection${NC}"
            ;;
    esac

    echo -ne "${CYAN}Press Enter to continue...${NC}"
    read -r
}

# Interactive Configure Themes
interactive_configure_themes() {
    clear
    echo -e "${BLUE}🎨 Interactive Theme Configuration${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Detect installed themes
    local themes=()
    local theme_names=()
    local theme_descriptions=()

    if is_extension_installed "dracula-theme.theme-dracula"; then
        themes+=("Dracula")
        theme_names+=("Dracula Theme")
        theme_descriptions+=("Popular dark theme with high contrast")
    fi

    if is_extension_installed "ms-vscode.theme-onedarkpro"; then
        themes+=("One Dark Pro")
        theme_names+=("One Dark Pro")
        theme_descriptions+=("Atom-inspired dark theme")
    fi

    # Always include default themes
    themes+=("Dark+ (default dark)" "Light+ (default light)")
    theme_names+=("Dark+ Default" "Light+ Default")
    theme_descriptions+=("VS Code default dark theme" "VS Code default light theme")

    echo -e "${YELLOW}🌈 Available Themes:${NC}"
    echo ""

    local i=1
    for theme in "${themes[@]}"; do
        local name="${theme_names[$((i-1))]}"
        local desc="${theme_descriptions[$((i-1))]}"
        echo -e "${GREEN}$i. ${CYAN}$name${NC}"
        echo -e "   ${GRAY}→ $desc${NC}"
        ((i++))
    done

    echo -e "${RED}0. 🔙 ${GRAY}Back to Advanced Menu${NC}"
    echo ""

    echo -ne "${GREEN}Select theme (0-$((${#themes[@]})): ${NC}"
    read -r theme_choice

    if [[ "$theme_choice" =~ ^[1-9][0-9]*$ ]] && [[ $theme_choice -le ${#themes[@]} ]]; then
        local selected_theme="${themes[$((theme_choice-1))]}"
        local selected_name="${theme_names[$((theme_choice-1))]}"

        echo -e "\n${BLUE}🎨 Selected: $selected_name${NC}"
        echo -ne "${YELLOW}Apply this theme to settings? (y/N): ${NC}"
        read -r confirm

        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            apply_theme_configuration "$selected_theme"
        else
            echo -e "${YELLOW}❌ Theme change cancelled${NC}"
        fi
    elif [[ "$theme_choice" == "0" ]]; then
        return
    else
        echo -e "${RED}❌ Invalid selection${NC}"
    fi

    echo -ne "${CYAN}Press Enter to continue...${NC}"
    read -r
}

# Interactive Configure Languages (simplified implementation)
interactive_configure_languages() {
    clear
    echo -e "${YELLOW}🔧 Interactive Language Configuration${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Detect installed language extensions
    local languages_available=false

    echo -e "${BLUE}💻 Available Language Configurations:${NC}"
    echo ""

    # Python
    if is_extension_installed "ms-python.python"; then
        languages_available=true
        echo -e "${GREEN}1. 🐍 ${BLUE}Python Development${NC}"
        echo -e "   ${GRAY}→ Interpreter, linting, debugging, testing${NC}"
    fi

    # JavaScript/TypeScript
    if is_extension_installed "ms-vscode.vscode-typescript-next" || is_extension_installed "esbenp.prettier-vscode"; then
        languages_available=true
        echo -e "${GREEN}2. 📜 ${YELLOW}JavaScript/TypeScript${NC}"
        echo -e "   ${GRAY}→ Auto imports, IntelliSense, debugging${NC}"
    fi

    # Bash/Shell
    if is_extension_installed "mads-hartmann.bash-ide-vscode"; then
        languages_available=true
        echo -e "${GREEN}3. 💻 ${CYAN}Bash/Shell Development${NC}"
        echo -e "   ${GRAY}→ ShellCheck, formatting, syntax highlighting${NC}"
    fi

    if ! $languages_available; then
        echo -e "${YELLOW}⚠️ No language extensions detected${NC}"
        echo -e "${GRAY}Install language extensions first from the main menu${NC}"
        echo -ne "${CYAN}Press Enter to continue...${NC}"
        read -r
        return
    fi

    echo -e "${GREEN}4. ⚙️ ${PURPLE}Configure All Languages${NC}"
    echo -e "   ${GRAY}→ Apply optimal settings for all detected languages${NC}"
    echo -e "${RED}0. 🔙 ${GRAY}Back to Advanced Menu${NC}"
    echo ""

    echo -ne "${GREEN}Select language (0-4): ${NC}"
    read -r lang_choice

    case $lang_choice in
        1|2|3|4)
            echo -e "\n${CYAN}🔧 This will create optimized settings for selected language${NC}"
            echo -ne "${YELLOW}Continue with language configuration? (y/N): ${NC}"
            read -r confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                create_default_settings
                echo -e "${GREEN}✅ Language configuration applied!${NC}"
            else
                echo -e "${YELLOW}❌ Configuration cancelled${NC}"
            fi
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}❌ Invalid selection${NC}"
            ;;
    esac

    echo -ne "${CYAN}Press Enter to continue...${NC}"
    read -r
}

# Interactive Configure Formatters (simplified implementation)
interactive_configure_formatters() {
    clear
    echo -e "${PURPLE}📝 Interactive Formatter Configuration${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Detect installed formatters
    local formatters_available=false

    echo -e "${YELLOW}🔧 Available Formatters Configuration:${NC}"
    echo ""

    # Python formatters
    if is_extension_installed "ms-python.python"; then
        formatters_available=true
        echo -e "${GREEN}1. 🐍 ${BLUE}Python Formatters${NC}"
        echo -e "   ${GRAY}→ Configure Black, autopep8, yapf${NC}"
    fi

    # JavaScript/TypeScript formatters
    if is_extension_installed "esbenp.prettier-vscode"; then
        formatters_available=true
        echo -e "${GREEN}2. 📜 ${YELLOW}JavaScript/TypeScript Formatters${NC}"
        echo -e "   ${GRAY}→ Configure Prettier, ESLint${NC}"
    fi

    # Bash/Shell formatters
    if is_extension_installed "foxundermoon.shell-format"; then
        formatters_available=true
        echo -e "${GREEN}3. 💻 ${CYAN}Bash/Shell Formatters${NC}"
        echo -e "   ${GRAY}→ Configure shell formatting options${NC}"
    fi

    if ! $formatters_available; then
        echo -e "${YELLOW}⚠️ No formatter extensions detected${NC}"
        echo -e "${GRAY}Install formatter extensions first (like Prettier, Black, etc.)${NC}"
        echo -ne "${CYAN}Press Enter to continue...${NC}"
        read -r
        return
    fi

    echo -e "${GREEN}4. ⚙️ ${ORANGE}Configure All Formatters${NC}"
    echo -e "   ${GRAY}→ Apply optimal settings for all detected formatters${NC}"
    echo -e "${RED}0. 🔙 ${GRAY}Back to Advanced Menu${NC}"
    echo ""

    echo -ne "${GREEN}Select formatter category (0-4): ${NC}"
    read -r formatter_choice

    case $formatter_choice in
        1)
            echo -e "\n${GREEN}🐍 Configuring Python Formatters${NC}"
            echo -ne "${YELLOW}Continue with Python formatter configuration? (y/N): ${NC}"
            read -r confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                configure_python_formatters
                echo -e "${GREEN}✅ Python formatter configuration applied!${NC}"
            else
                echo -e "${YELLOW}❌ Configuration cancelled${NC}"
            fi
            ;;
        2)
            echo -e "\n${BLUE}� Configuring JavaScript/TypeScript Formatters${NC}"
            echo -ne "${YELLOW}Continue with JS/TS formatter configuration? (y/N): ${NC}"
            read -r confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                configure_js_formatters
                echo -e "${GREEN}✅ JavaScript/TypeScript formatter configuration applied!${NC}"
            else
                echo -e "${YELLOW}❌ Configuration cancelled${NC}"
            fi
            ;;
        3)
            echo -e "\n${CYAN}💻 Configuring Bash/Shell Formatters${NC}"
            echo -ne "${YELLOW}Continue with Shell formatter configuration? (y/N): ${NC}"
            read -r confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                configure_shell_formatters
                echo -e "${GREEN}✅ Shell formatter configuration applied!${NC}"
            else
                echo -e "${YELLOW}❌ Configuration cancelled${NC}"
            fi
            ;;
        4)
            echo -e "\n${PURPLE}⚙️ Configuring All Formatters${NC}"
            echo -ne "${YELLOW}Continue with all formatters configuration? (y/N): ${NC}"
            read -r confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                # Configure all detected formatters with specific settings
                echo -e "${CYAN}🔧 Applying formatter-specific configurations...${NC}"

                # Configure Python formatters if available
                if is_extension_installed "ms-python.python"; then
                    echo -e "${GREEN}🐍 Configuring Python formatters...${NC}"
                    configure_python_formatters
                fi

                # Configure JavaScript/TypeScript formatters if available
                if is_extension_installed "esbenp.prettier-vscode"; then
                    echo -e "${BLUE}📜 Configuring JavaScript/TypeScript formatters...${NC}"
                    configure_js_formatters
                fi

                # Configure Shell formatters if available
                if is_extension_installed "foxundermoon.shell-format"; then
                    echo -e "${CYAN}💻 Configuring Shell formatters...${NC}"
                    configure_shell_formatters
                fi

                echo -e "${GREEN}✅ All formatters configuration applied!${NC}"
            else
                echo -e "${YELLOW}❌ Configuration cancelled${NC}"
            fi
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}❌ Invalid selection${NC}"
            ;;
    esac

    echo -ne "${CYAN}Press Enter to continue...${NC}"
    read -r
}

# View Current Configuration Detailed
view_current_configuration_detailed() {
    clear
    echo -e "${CYAN}📊 Detailed Current Configuration${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Detect extensions and settings
    detect_installed_extensions
    local ext_count=${#INSTALLED_EXTENSIONS[@]}

    echo -e "${BLUE}📦 Extension Analysis:${NC}"
    echo -e "${YELLOW}  Total Extensions: $ext_count${NC}"
    echo ""

    if [[ $ext_count -gt 0 ]]; then
        echo -e "${GREEN}🔍 Detailed Extension Breakdown:${NC}"
        show_installed_summary
        echo ""

        # Check for existing settings
        local user_settings
        local workspace_settings
        user_settings="$HOME/.config/Code/User/settings.json"
        workspace_settings="$(pwd)/.vscode/settings.json"

        echo -e "${PURPLE}⚙️ Settings Files Status:${NC}"

        if [[ -f "$user_settings" ]]; then
            local user_size
            user_size=$(wc -c < "$user_settings" 2>/dev/null || echo "0")
            echo -e "${GREEN}  ✓ User Settings: ${CYAN}$user_settings${NC} (${user_size} bytes)"
        else
            echo -e "${YELLOW}  ⚠ User Settings: Not found${NC}"
        fi

        if [[ -f "$workspace_settings" ]]; then
            local workspace_size
            workspace_size=$(wc -c < "$workspace_settings" 2>/dev/null || echo "0")
            echo -e "${GREEN}  ✓ Workspace Settings: ${CYAN}$workspace_settings${NC} (${workspace_size} bytes)"
        else
            echo -e "${YELLOW}  ⚠ Workspace Settings: Not found${NC}"
        fi

        echo ""
        echo -e "${BLUE}🎯 Quick Actions:${NC}"
        echo -e "${GREEN}1. 🔧 ${CYAN}Generate New Dynamic Settings${NC}"
        echo -e "${PURPLE}2. 📄 ${YELLOW}View Settings Content${NC}"
        echo -e "${GREEN}3. 💾 ${WHITE}Backup Current Settings${NC}"
        echo -e "${RED}0. 🔙 ${GRAY}Back to Advanced Menu${NC}"
        echo ""

        echo -ne "${GREEN}Select action (0-3): ${NC}"
        read -r action_choice

        case $action_choice in
            1)
                echo -e "\n${CYAN}🔧 This will generate new dynamic settings based on your installed extensions${NC}"
                echo -ne "${YELLOW}Continue? (y/N): ${NC}"
                read -r confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    create_default_settings
                fi
                ;;
            2)
                if [[ -f "$user_settings" ]]; then
                    echo -e "\n${BLUE}📄 User Settings Content:${NC}"
                    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                    head -20 "$user_settings" 2>/dev/null || echo "Cannot read file"
                    echo -e "${GRAY}... (showing first 20 lines)${NC}"
                else
                    echo -e "${YELLOW}⚠️ No user settings file found${NC}"
                fi
                ;;
            3)
                backup_settings_file
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}❌ Invalid selection${NC}"
                ;;
        esac

    else
        echo -e "${YELLOW}⚠️ No extensions installed${NC}"
        echo -e "${GRAY}Use the main menu to install extensions first${NC}"
    fi

    echo -ne "${CYAN}Press Enter to continue...${NC}"
    read -r
}

# Helper functions for interactive configuration
perform_quick_configuration() {
    echo -e "\n${CYAN}🚀 Performing Quick Configuration...${NC}"
    create_default_settings
    echo -e "${GREEN}✅ Quick configuration completed!${NC}"
}

interactive_custom_configuration() {
    echo -e "\n${BLUE}🎯 Custom Configuration${NC}"
    echo -e "${GRAY}This will allow you to choose specific settings per extension category${NC}"
    echo -e "${YELLOW}💡 Feature coming soon - using default configuration for now${NC}"
    create_default_settings
}

preview_configuration_changes() {
    echo -e "\n${PURPLE}📋 Configuration Preview${NC}"
    echo -e "${GRAY}Showing what would be configured...${NC}"
    echo ""

    detect_installed_extensions
    local configured_extensions=()

    echo -e "${BLUE}🔧 Extensions to be configured:${NC}"
    for ext in "${INSTALLED_EXTENSIONS[@]}"; do
        case "$ext" in
            "ms-python.python"|"ms-python.black-formatter"|"ms-python.autopep8")
                if ! array_contains "python" "${configured_extensions[@]}"; then
                    echo -e "${GREEN}  ✓ Python Development Environment${NC}"
                    configured_extensions+=("python")
                fi
                ;;
            "esbenp.prettier-vscode"|"ms-vscode.vscode-typescript-next")
                if ! array_contains "javascript" "${configured_extensions[@]}"; then
                    echo -e "${GREEN}  ✓ JavaScript/TypeScript Environment${NC}"
                    configured_extensions+=("javascript")
                fi
                ;;
            "mads-hartmann.bash-ide-vscode"|"foxundermoon.shell-format")
                if ! array_contains "bash" "${configured_extensions[@]}"; then
                    echo -e "${GREEN}  ✓ Bash/Shell Development Environment${NC}"
                    configured_extensions+=("bash")
                fi
                ;;
        esac
    done

    if [[ ${#configured_extensions[@]} -eq 0 ]]; then
        echo -e "${YELLOW}  ⚠️ Only base editor configuration will be applied${NC}"
    fi

    echo ""
    echo -ne "${YELLOW}Apply these configurations? (y/N): ${NC}"
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        create_default_settings
    else
        echo -e "${YELLOW}❌ Configuration cancelled${NC}"
    fi
}

apply_theme_configuration() {
    local theme="$1"
    echo -e "\n${BLUE}🎨 Applying theme: $theme${NC}"

    # Create a minimal theme-only settings update
    local user_settings="$HOME/.config/Code/User/settings.json"
    mkdir -p "$(dirname "$user_settings")"

    # Simple theme application
    if [[ -f "$user_settings" ]]; then
        # If settings exist, we should properly merge, but for now just inform user
        echo -e "${YELLOW}⚠️ Settings file exists. For full theme application, use 'Create/Overwrite Default Settings' option${NC}"
        echo -e "${GRAY}This will preserve your existing settings and apply the theme properly${NC}"
    else
        # Create minimal settings with theme
        cat > "$user_settings" << EOF
{
    "workbench.colorTheme": "$theme"
}
EOF
        echo -e "${GREEN}✅ Theme applied successfully!${NC}"
        echo -e "${CYAN}📍 Settings saved to: $user_settings${NC}"
    fi
}

# Main menu
main_menu() {
    while true; do
        print_banner
        echo -e "\n${GREEN}🎯 Menu Utama VS Code Complete Setup${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${YELLOW}1. 📦 ${GREEN}Install Extensions${NC}"
        echo -e "${RED}2. 🗑️  ${YELLOW}Uninstall Extensions${NC}"
        echo -e "${PURPLE}3. 🔍 ${CYAN}Search Extensions${NC}"
        echo -e "${BLUE}4. 🔧 ${PURPLE}Manage Settings.json${NC}"
        echo -e "${GRAY}5. 🚪 ${RED}Exit${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

        echo -ne "${GREEN}Pilih opsi (1-5): ${NC}"
        read -r choice

        case $choice in
            1)
                echo -e "\n${CYAN}📦 Mode Instalasi:${NC}"
                echo -e "${GREEN}1. 🤖 ${YELLOW}Default (otomatis)${NC}"
                echo -e "${BLUE}2. 🎨 ${PURPLE}Interactive${NC}"
                echo -e "${GRAY}3. 🔙 ${CYAN}Kembali ke Menu Utama${NC}"
                echo -ne "${YELLOW}Pilih mode (1-3): ${NC}"
                read -r mode
                case $mode in
                    1) install_default_extensions ;;
                    2) interactive_install ;;
                    3) continue ;; # Kembali ke main menu
                    *) echo -e "${RED}❌ Mode tidak valid${NC}" ;;
                esac
                ;;
            2) detect_and_uninstall ;;
            3) search_extensions ;;
            4) manage_settings ;;
            5)
                echo -e "${PURPLE}👋 Terima kasih telah menggunakan VS Code Complete Setup!${NC}"
                echo -e "${CYAN}🎯 Setup development environment Anda sudah siap.${NC}"
                echo -e "${YELLOW}💡 Jangan lupa restart VS Code untuk perubahan optimal.${NC}"
                echo ""
                echo -e "${GREEN}🌟 Jika bermanfaat, silahkan kunjungi dan beri star:${NC}"
                echo -e "${BLUE}🔗 https://github.com/rokhanz${NC}"
                echo ""
                exit 0
                ;;
            *) echo -e "${RED}❌ Pilihan tidak valid, silakan coba lagi${NC}" ;;
        esac
    done
}

# Configure Python formatters specifically
configure_python_formatters() {
    echo -e "${GREEN}🐍 Configuring Python formatters...${NC}"
    local settings_file="$HOME/.config/Code/User/settings.json"
    mkdir -p "$(dirname "$settings_file")"

    # Create Python-specific settings
    cat > "$settings_file" << 'EOF'
{
    "python.defaultInterpreterPath": "/usr/bin/python3",
    "python.formatting.provider": "black",
    "python.formatting.blackArgs": ["--line-length=88"],
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": false,
    "python.linting.flake8Enabled": true,
    "python.linting.flake8Args": ["--max-line-length=88"],
    "[python]": {
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
            "source.organizeImports": true
        }
    }
}
EOF
    echo -e "${CYAN}📍 Python settings saved to: $settings_file${NC}"
}

# Configure JavaScript/TypeScript formatters specifically
configure_js_formatters() {
    echo -e "${BLUE}📜 Configuring JavaScript/TypeScript formatters...${NC}"
    local settings_file="$HOME/.config/Code/User/settings.json"
    mkdir -p "$(dirname "$settings_file")"

    # Create JS/TS-specific settings
    cat > "$settings_file" << 'EOF'
{
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "prettier.semi": true,
    "prettier.singleQuote": true,
    "prettier.tabWidth": 2,
    "prettier.trailingComma": "es5",
    "[javascript]": {
        "editor.formatOnSave": true,
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[typescript]": {
        "editor.formatOnSave": true,
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[json]": {
        "editor.formatOnSave": true,
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    }
}
EOF
    echo -e "${CYAN}📍 JavaScript/TypeScript settings saved to: $settings_file${NC}"
}

# Configure Shell formatters specifically
configure_shell_formatters() {
    echo -e "${CYAN}💻 Configuring Shell formatters...${NC}"
    local settings_file="$HOME/.config/Code/User/settings.json"
    mkdir -p "$(dirname "$settings_file")"

    # Create Shell-specific settings
    cat > "$settings_file" << 'EOF'
{
    "shellformat.useEditorConfig": true,
    "shellformat.effectLanguages": [
        "shellscript",
        "dockerfile",
        "dotenv",
        "hosts",
        "jvmoptions",
        "ignore",
        "gitignore",
        "spring-boot-properties",
        "ahocorasick",
        "bash"
    ],
    "[shellscript]": {
        "editor.formatOnSave": true,
        "editor.defaultFormatter": "foxundermoon.shell-format"
    },
    "shellcheck.enable": true,
    "shellcheck.run": "onSave"
}
EOF
    echo -e "${CYAN}📍 Shell settings saved to: $settings_file${NC}"
}

# Main execution - only run if script is executed directly, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    validate_environment
    dependencies=(code)
    for dep in "${dependencies[@]}"; do
        check_and_install "$dep"
    done

    main_menu
fi
