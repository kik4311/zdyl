#!/usr/bin/env bash

# =============================================================================
# CLI: Проверка и установка обновлений (nfqws + стратегии)
# =============================================================================

# Файл, в котором хранится последняя установленная версия зависимостей
UPDATE_STATUS_FILE="$HOME_DIR_PATH/.deps-versions"

# Глобальные переменные для check_for_updates
UPDATE_NFQWS_CUR=""
UPDATE_NFQWS_NEW=""
UPDATE_NFQWS_UPDATE=false
UPDATE_STRAT_CUR=""
UPDATE_STRAT_NEW=""
UPDATE_STRAT_UPDATE=false

# Справка для update
show_update_usage() {
    echo "Usage: $(basename "$0") update [options]"
    echo
    echo "Проверяет наличие обновлений nfqws и стратегий и устанавливает их."
    echo
    echo "Options:"
    echo "    -c, --check   Только проверить наличие обновлений (без установки)"
    echo "    -y, --yes     Установить обновления без подтверждения"
    echo "    -h, --help    Показать справку"
    echo
    echo "Examples:"
    echo "    $(basename "$0") update            # Проверить и предложить обновление"
    echo "    $(basename "$0") update --check    # Только проверить"
    echo "    $(basename "$0") update --yes      # Обновить без вопросов"
}

# -----------------------------------------------------------------------------
# Определение текущих установленных версий
# -----------------------------------------------------------------------------

# Установленная версия nfqws (из бинарника, затем из .deps-versions, затем из константы)
# Бинарник — источник правды: .deps-versions может устареть при сбое обновления
_installed_nfqws_version() {
    local fv bv
    if [[ -x "$NFQWS_PATH" ]]; then
        bv=$("$NFQWS_PATH" --version 2>/dev/null | grep -oP 'v\K[0-9][0-9.]*' | head -n1)
        [[ -n "$bv" ]] && { echo "$bv"; return 0; }
    fi
    if [[ -f "$UPDATE_STATUS_FILE" ]]; then
        fv=$(grep -m1 '^nfqws=' "$UPDATE_STATUS_FILE" | cut -d= -f2-)
        [[ -n "$fv" ]] && { echo "$fv"; return 0; }
    fi
    echo "${ZAPRET_RECOMMENDED_VERSION#v}"
}

# Установленная версия стратегий (из .deps-versions, затем из константы)
_installed_strategy_version() {
    local sv
    if [[ -f "$UPDATE_STATUS_FILE" ]]; then
        sv=$(grep -m1 '^strategy=' "$UPDATE_STATUS_FILE" | cut -d= -f2-)
        [[ -n "$sv" ]] && { echo "$sv"; return 0; }
    fi
    echo "$MAIN_REPO_REV"
}

# -----------------------------------------------------------------------------
# Определение последних версий (из GitHub)
# -----------------------------------------------------------------------------

# Последний релиз nfqws (тег без 'v')
_latest_nfqws_version() {
    local tag
    tag=$(resolve_zapret_version "latest" 2>/dev/null) || return 1
    echo "${tag#v}"
}

# Последний коммит ветки main/master репозитория стратегий
_latest_strategy_version() {
    local sha
    sha=$(git ls-remote "$REPO_URL" refs/heads/main 2>/dev/null | awk '{print $1}')
    [[ -z "$sha" ]] && sha=$(git ls-remote "$REPO_URL" refs/heads/master 2>/dev/null | awk '{print $1}')
    [[ -z "$sha" ]] && return 1
    echo "$sha"
}

# Сравнение версий: $1 > $2
_version_gt() {
    [[ "$1" != "$2" ]] && [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n1)" == "$1" ]]
}

# -----------------------------------------------------------------------------
# Проверка обновлений
# -----------------------------------------------------------------------------

check_for_updates() {
    UPDATE_NFQWS_CUR="$(_installed_nfqws_version)"
    UPDATE_STRAT_CUR="$(_installed_strategy_version)"

    echo "Проверка обновлений..."
    echo ""

    # nfqws
    UPDATE_NFQWS_UPDATE=false
    if ! UPDATE_NFQWS_NEW="$(_latest_nfqws_version)"; then
        echo -e "${RED}Не удалось проверить последнюю версию nfqws (нет сети?).${NC}"
        UPDATE_NFQWS_NEW=""
    elif _version_gt "$UPDATE_NFQWS_NEW" "$UPDATE_NFQWS_CUR"; then
        UPDATE_NFQWS_UPDATE=true
    fi

    # стратегии
    UPDATE_STRAT_UPDATE=false
    if ! UPDATE_STRAT_NEW="$(_latest_strategy_version)"; then
        echo -e "${RED}Не удалось проверить последний коммит стратегий (нет сети?).${NC}"
        UPDATE_STRAT_NEW=""
    elif [[ "$UPDATE_STRAT_NEW" != "$UPDATE_STRAT_CUR" ]]; then
        UPDATE_STRAT_UPDATE=true
    fi
}

# Вывод статуса версий
_print_update_status() {
    echo -e "${BOLD}Текущие версии:${NC}"
    echo -e "  nfqws:     ${CYAN}${UPDATE_NFQWS_CUR}${NC}"
    echo -e "  стратегии: ${CYAN}${UPDATE_STRAT_CUR:0:12}${NC}"

    echo ""
    echo -e "${BOLD}Доступные версии:${NC}"
    if [[ "$UPDATE_NFQWS_UPDATE" == true ]]; then
        echo -e "  nfqws:     ${GREEN}${UPDATE_NFQWS_NEW}${NC} (доступно обновление)"
    elif [[ -n "$UPDATE_NFQWS_NEW" ]]; then
        echo -e "  nfqws:     ${UPDATE_NFQWS_NEW} (актуально)"
    else
        echo -e "  nfqws:     неизвестно"
    fi

    if [[ "$UPDATE_STRAT_UPDATE" == true ]]; then
        echo -e "  стратегии: ${GREEN}${UPDATE_STRAT_NEW:0:12}${NC} (доступно обновление)"
    elif [[ -n "$UPDATE_STRAT_NEW" ]]; then
        echo -e "  стратегии: ${UPDATE_STRAT_NEW:0:12} (актуально)"
    else
        echo -e "  стратегии: неизвестно"
    fi
}

# -----------------------------------------------------------------------------
# Установка обновлений
# -----------------------------------------------------------------------------

# Сохранить установленные версии в .deps-versions
_persist_deps_versions() {
    local nfqws_v="${1:-}" strat_v="${2:-}"
    {
        [[ -n "$nfqws_v" ]] && echo "nfqws=$nfqws_v"
        [[ -n "$strat_v" ]] && echo "strategy=$strat_v"
    } > "$UPDATE_STATUS_FILE"
}

apply_updates() {
    local do_nfqws=false do_strat=false
    [[ "$UPDATE_NFQWS_UPDATE" == true ]] && do_nfqws=true
    [[ "$UPDATE_STRAT_UPDATE" == true ]] && do_strat=true

    if ! $do_nfqws && ! $do_strat; then
        echo "Всё актуально."
        return 0
    fi

    elevate_cache_credentials >/dev/null 2>&1 || true

    if $do_nfqws; then
        echo ""
        echo "Обновление nfqws до версии $UPDATE_NFQWS_NEW..."
        download_nfqws "$UPDATE_NFQWS_NEW"
    fi

    if $do_strat; then
        echo ""
        echo "Обновление стратегий до коммита $UPDATE_STRAT_NEW..."
        INTERACTIVE_MODE=false
        setup_repository "$UPDATE_STRAT_NEW"
    fi

    _persist_deps_versions "${UPDATE_NFQWS_NEW:-$UPDATE_NFQWS_CUR}" "${UPDATE_STRAT_NEW:-$UPDATE_STRAT_CUR}"

    # Если сервис активен — перезапускаем, чтобы применить обновления
    _load_init_backend
    local rc=0
    check_service_status >/dev/null 2>&1 || rc=$?
    if [[ $rc -eq 2 ]]; then
        echo ""
        echo "Сервис активен, перезапуск для применения обновлений..."
        restart_service
    fi

    echo ""
    echo -e "${GREEN}Обновление завершено.${NC}"
}

# -----------------------------------------------------------------------------
# Обработчик команды update
# -----------------------------------------------------------------------------

handle_update_command() {
    local mode="interactive"

    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--check)
                mode="check"
                shift
                ;;
            -y|--yes)
                mode="yes"
                shift
                ;;
            -h|--help)
                show_update_usage
                return 0
                ;;
            *)
                echo "Unknown update option: $1"
                show_update_usage
                return 1
                ;;
        esac
    done

    check_for_updates || return 1
    _print_update_status

    case "$mode" in
        check)
            if [[ "$UPDATE_NFQWS_UPDATE" == true || "$UPDATE_STRAT_UPDATE" == true ]]; then
                return 1
            fi
            return 0
            ;;
        yes)
            apply_updates
            ;;
        *)
            if [[ "$UPDATE_NFQWS_UPDATE" == true || "$UPDATE_STRAT_UPDATE" == true ]]; then
                echo ""
                read -p "Установить обновления? [y/N]: " answer
                if [[ "$answer" =~ ^[Yy]$ ]]; then
                    apply_updates
                else
                    echo "Отменено."
                fi
            else
                echo ""
                echo "Всё актуально."
            fi
            ;;
    esac
}
