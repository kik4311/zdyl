#!/usr/bin/env bash

# =============================================================================
# CLI: Обновление стратегий (проверка коммита и скачивание при изменениях)
# =============================================================================

UPDATE_STATUS_FILE="$HOME_DIR_PATH/.deps-versions"
REPO_URL="https://github.com/Flowseal/zapret-discord-youtube.git"

show_update_usage() {
    echo "Usage: $(basename "$0") update [options]"
    echo
    echo "Проверяет наличие обновлений стратегий и устанавливает их."
    echo
    echo "Options:"
    echo "    -c, --check   Только проверить наличие обновлений"
    echo "    -y, --yes     Установить обновления без подтверждения"
    echo "    -h, --help    Показать справку"
    echo
    echo "Examples:"
    echo "    $(basename "$0") update          # Проверить и предложить обновление"
    echo "    $(basename "$0") update --check  # Только проверить"
    echo "    $(basename "$0") update --yes    # Обновить без вопросов"
}

# Текущий коммит стратегий
_installed_strategy_version() {
    if [[ -f "$UPDATE_STATUS_FILE" ]]; then
        grep -m1 '^strategy=' "$UPDATE_STATUS_FILE" | cut -d= -f2-
    else
        echo "$MAIN_REPO_REV"
    fi
}

# Последний коммит в main/master
_latest_strategy_version() {
    local sha
    sha=$(git ls-remote "$REPO_URL" refs/heads/main 2>/dev/null | awk '{print $1}')
    [[ -z "$sha" ]] && sha=$(git ls-remote "$REPO_URL" refs/heads/master 2>/dev/null | awk '{print $1}')
    echo "$sha"
}

# Сохранить версию
_persist_version() {
    echo "strategy=$1" > "$UPDATE_STATUS_FILE"
}

# Показать статус обновлений
check_updates() {
    local cur new
    cur=$(_installed_strategy_version)
    new=$(_latest_strategy_version)

    [[ -z "$new" ]] && { echo "Ошибка: не удалось получить версию из GitHub"; return 1; }

    echo "Текущий коммит:  ${cur:0:12}"
    echo "Доступный коммит: ${new:0:12}"

    if [[ "$cur" == "$new" ]]; then
        echo "Обновлений нет."
        return 0
    else
        echo "Есть обновления."
        return 1
    fi
}

# Установить обновления
apply_updates() {
    local cur new
    cur=$(_installed_strategy_version)
    new=$(_latest_strategy_version)

    [[ -z "$new" ]] && { echo "Ошибка: не удалось получить версию"; return 1; }

    if [[ "$cur" == "$new" ]]; then
        echo "Уже актуально."
        return 0
    fi

    echo "Скачивание стратегий (коммит ${new:0:12})..."
    INTERACTIVE_MODE=false
    setup_repository "$new" && _persist_version "$new" && {
        echo "Стратегии обновлены."
        return 0
    } || {
        echo "Ошибка при обновлении."
        return 1
    }
}

handle_update_command() {
    local mode="interactive"

    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--check) mode="check"; shift ;;
            -y|--yes)   mode="yes"; shift ;;
            -h|--help)  show_update_usage; return 0 ;;
            *)          echo "Неизвестная опция: $1"; show_update_usage; return 1 ;;
        esac
    done

    case $mode in
        check) check_updates ;;
        yes)   apply_updates ;;
        *)     check_updates || { echo; read -p "Установить обновления? [y/N]: " ans; [[ "$ans" =~ ^[Yy]$ ]] && apply_updates; } ;;
    esac
}