#!/usr/bin/env bash

# =============================================================================
# CLI: Watchdog — автопереключение стратегии при сбое доступа к целям
# Мониторит URL-цели из targets.txt и при N сбоях подряд меняет стратегию
# =============================================================================

WATCHDOG_LOG_FILE="$HOME_DIR_PATH/watchdog.log"
WATCHDOG_CHECK_INTERVAL=60
WATCHDOG_FAIL_THRESHOLD=3
WATCHDOG_CONNECT_TIMEOUT=5
WATCHDOG_MAX_TIMEOUT=10

# Цели по умолчанию, если в targets.txt нет URL-целей
WD_DEFAULT_TARGET_NAMES=(YouTube Discord Google)
WD_DEFAULT_TARGET_URLS=("https://www.youtube.com" "https://discord.com" "https://www.google.com")

WD_SERVICE_WAS_ACTIVE=false

# Справка для watchdog
show_watchdog_usage() {
    echo "Usage: $(basename "$0") watchdog"
    echo
    echo "Автопереключение стратегии при сбое доступа к целям."
    echo "Мониторит URL-цели из targets.txt (или встроенные: YouTube, Discord, Google)."
    echo "После $WATCHDOG_FAIL_THRESHOLD сбоев подряд переключается на следующую стратегию."
    echo "Интервал проверки: $WATCHDOG_CHECK_INTERVAL секунд."
    echo "Ctrl+C для остановки."
    echo
    echo "Лог пишется в: $WATCHDOG_LOG_FILE"
}

# -----------------------------------------------------------------------------
# Логирование
# -----------------------------------------------------------------------------

_wd_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$WATCHDOG_LOG_FILE"
}

# -----------------------------------------------------------------------------
# Загрузка целей (только URL-цели из targets.txt)
# -----------------------------------------------------------------------------

_wd_load_targets() {
    local -a keep_names=() keep_urls=()
    local i

    if [[ -f "$AUTOCHECK_TARGETS_FILE" ]]; then
        _ac_parse_targets < "$AUTOCHECK_TARGETS_FILE"
    fi

    for ((i=0; i<${#AC_TARGET_NAMES[@]}; i++)); do
        if [[ -n "${AC_TARGET_URLS[$i]}" ]]; then
            keep_names+=("${AC_TARGET_NAMES[$i]}")
            keep_urls+=("${AC_TARGET_URLS[$i]}")
        fi
    done

    if [[ ${#keep_names[@]} -eq 0 ]]; then
        echo -e "${YELLOW}В targets.txt нет URL-целей, используются встроенные: ${WD_DEFAULT_TARGET_NAMES[*]}${NC}"
        AC_TARGET_NAMES=("${WD_DEFAULT_TARGET_NAMES[@]}")
        AC_TARGET_URLS=("${WD_DEFAULT_TARGET_URLS[@]}")
    else
        AC_TARGET_NAMES=("${keep_names[@]}")
        AC_TARGET_URLS=("${keep_urls[@]}")
    fi
}

# -----------------------------------------------------------------------------
# Проверка доступности
# -----------------------------------------------------------------------------

# HTTP-проверка URL: 0 если сайт отвечает (HTTP 2xx/3xx), 1 иначе
_wd_http_ok() {
    local url="$1" code
    code=$(curl -s -o /dev/null -w '%{http_code}' \
        --connect-timeout "$WATCHDOG_CONNECT_TIMEOUT" \
        --max-time "$WATCHDOG_MAX_TIMEOUT" "$url" 2>/dev/null) || return 1
    [[ "$code" =~ ^[0-9]{3}$ ]] && (( code >= 200 )) && (( code < 400 ))
}

# Проверка всех целей: 0 если все доступны
_wd_check_targets() {
    local all_ok=true i
    for ((i=0; i<${#AC_TARGET_NAMES[@]}; i++)); do
        local name="${AC_TARGET_NAMES[$i]}" url="${AC_TARGET_URLS[$i]}"
        if ! _wd_http_ok "$url"; then
            echo -e "  ${RED}Цель недоступна: ${BOLD}$name${NC}${RED} ($url)${NC}"
            all_ok=false
        fi
    done
    [[ "$all_ok" == true ]]
}

# -----------------------------------------------------------------------------
# Переключение стратегии
# -----------------------------------------------------------------------------

_wd_next_strategy() {
    local -a list=()
    mapfile -t list < <(get_strategies)
    local n=${#list[@]}
    if (( n <= 1 )); then
        echo ""
        return 0
    fi

    local cur="$strategy" found=-1 i
    for ((i=0; i<n; i++)); do
        [[ "${list[$i]}" == "$cur" ]] && { found=$i; break; }
    done

    if (( found < 0 )); then
        echo "${list[0]}"
    else
        echo "${list[$(( (found + 1) % n ))]}"
    fi
}

_wd_switch_strategy() {
    local next old_strategy
    next=$(_wd_next_strategy)
    if [[ -z "$next" ]]; then
        echo -e "${YELLOW}Нет других стратегий для переключения.${NC}"
        _wd_log "Нет других стратегий для переключения"
        return 1
    fi

    echo -e "${YELLOW}Сбой стратегии ${BOLD}$strategy${NC}${YELLOW}, переключение на ${BOLD}$next${NC}${NC}"
    _wd_log "Сбой стратегии $strategy, переключение на $next"

    old_strategy="$strategy"
    strategy="$next"

    # Запуск новой стратегии в под-оболочке, чтобы не потерять управление при ошибке
    if ! ( run_zapret ); then
        echo -e "${RED}Не удалось запустить стратегию $next.${NC}"
        _wd_log "Ошибка запуска стратегии $next"
        strategy="$old_strategy"
        ( run_zapret ) >/dev/null 2>&1 || true
        return 1
    fi

    # Сохраняем новую стратегию в conf.env (без перезапуска сервиса)
    RESTART_SERVICE=false
    update_config "$next" "$interface" "$gamefiltertcp" "$gamefilterudp" "${firewall_backend:-auto}" >/dev/null 2>&1 || true

    echo -e "${GREEN}Стратегия изменена: ${BOLD}$next${NC}"
    _wd_log "Активная стратегия: $next"
    return 0
}

# -----------------------------------------------------------------------------
# Основной цикл
# -----------------------------------------------------------------------------

# Восстановление состояния при остановке
_wd_on_exit() {
    echo ""
    echo -e "${YELLOW}Остановка watchdog...${NC}"
    trap - SIGINT SIGTERM
    _wd_log "Watchdog остановлен"
    stop_zapret >/dev/null 2>&1 || true
    if [[ "$WD_SERVICE_WAS_ACTIVE" == true ]]; then
        echo -e "${YELLOW}Перезапуск сервиса...${NC}"
        start_service >/dev/null 2>&1 || true
    fi
    exit 0
}

watchdog_run() {
    load_config

    # Если сервис активен — останавливаем (watchdog берёт управление на себя)
    local rc=0
    check_service_status >/dev/null 2>&1 || rc=$?
    if [[ $rc -eq 2 ]]; then
        WD_SERVICE_WAS_ACTIVE=true
        echo -e "${YELLOW}Сервис активен, останавливаю его (watchdog возьмёт управление).${NC}"
        stop_service >/dev/null 2>&1 || true
    fi

    stop_zapret >/dev/null 2>&1 || true
    sleep 1

    _wd_load_targets
    echo -e "Цели мониторинга: ${BOLD}${AC_TARGET_NAMES[*]}${NC}"
    echo ""

    if ! ( run_zapret ); then
        show_error "Не удалось запустить zapret со стратегией $strategy"
        _wd_log "Ошибка запуска zapret со стратегией $strategy"
        if [[ "$WD_SERVICE_WAS_ACTIVE" == true ]]; then
            start_service >/dev/null 2>&1 || true
        fi
        return 1
    fi

    echo -e "${GREEN}Запуск watchdog...${NC}"
    echo "  Стратегия: $strategy"
    echo "  Интервал проверки: ${WATCHDOG_CHECK_INTERVAL}с, порог сбоев: ${WATCHDOG_FAIL_THRESHOLD}"
    echo "  Лог: $WATCHDOG_LOG_FILE"
    _wd_log "Watchdog запущен: стратегия=$strategy"

    trap '_wd_on_exit' SIGINT SIGTERM

    local fails=0
    while true; do
        if _wd_check_targets; then
            if (( fails > 0 )); then
                echo "  Проверка пройдена ($(date '+%H:%M:%S'))"
                _wd_log "Проверка пройдена"
            fi
            fails=0
        else
            (( fails++ )) || true
            echo -e "  ${RED}Проверка не пройдена ($(date '+%H:%M:%S')) — сбоев подряд: $fails/${WATCHDOG_FAIL_THRESHOLD}${NC}"
            if (( fails >= WATCHDOG_FAIL_THRESHOLD )); then
                _wd_switch_strategy || true
                fails=0
            fi
        fi
        sleep "$WATCHDOG_CHECK_INTERVAL"
    done
}

# -----------------------------------------------------------------------------
# Главная функция (меню)
# -----------------------------------------------------------------------------

show_watchdog_menu() {
    local restore_errexit=false
    if [[ $- == *e* ]]; then
        restore_errexit=true
    fi
    set +e

    clear
    echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}         Автопереключение стратегии (Watchdog)${NC}"
    echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "Мониторит URL-цели из ${GREEN}targets.txt${NC} (или встроенные: YouTube, Discord, Google)"
    echo -e "После ${BOLD}${WATCHDOG_FAIL_THRESHOLD}${NC} сбоев подряд стратегия автоматически меняется"
    echo -e "Интервал проверки: ${BOLD}${WATCHDOG_CHECK_INTERVAL}${NC} секунд. Ctrl+C для остановки."
    echo ""

    if [[ ! -d "$REPO_DIR" ]]; then
        show_error "Стратегии не найдены. Запустите: ./service.sh download-deps --default"
        return 0
    fi

    if ! check_conf_file; then
        show_error "Конфигурация отсутствует или неполная. Запустите: ./service.sh config edit"
        return 0
    fi

    elevate_cache_credentials >/dev/null 2>&1 || true
    _load_init_backend

    watchdog_run

    if [[ "$restore_errexit" == true ]]; then
        set -e
    fi

    read -p "Нажмите Enter для продолжения..."
    return 0
}

# Обработчик команды watchdog
handle_watchdog_command() {
    case "${1:-}" in
        -h|--help)
            show_watchdog_usage
            ;;
        "")
            show_watchdog_menu
            ;;
        *)
            echo "Unknown watchdog command: $1"
            show_watchdog_usage
            exit 1
            ;;
    esac
}
