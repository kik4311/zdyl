<div align="center">

# zdyl

### Plug-and-Play адаптер для обхода замедления YouTube и Discord на Linux

Адаптер для стратегий [Flowseal/zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube) и [zapret](https://github.com/bol-van/zapret) от bol-van.

[![GitHub stars](https://img.shields.io/github/stars/kik4311/zdyl?style=social)](https://github.com/kik4311/zdyl/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/kik4311/zdyl?style=social)](https://github.com/kik4311/zdyl/network/members)
[![GitHub release](https://img.shields.io/github/v/release/kik4311/zdyl?style=social)](https://github.com/kik4311/zdyl/releases)

</div>

---

## Что это такое

Если YouTube и Discord замедлены вашим провайдером — zapret (nfqws) обходит это с помощью подмены пакетов. Но готовые стратегии пишутся для Windows (`.bat`), а ручная настройка на Linux — боль.

**zdyl** — это адаптер, который:

- берёт готовые стратегии [Flowseal](https://github.com/Flowseal/zapret-discord-youtube) и автоматически адаптирует их под Linux
- скачивает собранный бинарник `nfqws` из [zapret](https://github.com/bol-van/zapret)
- ставит всё как системный сервис под вашу init-систему
- сам подбирает рабочую стратегию (автопроверка) и переключает её при сбоях (watchdog)

## Возможности

- **Простая установка** — одна команда скачивает nfqws и стратегии
- **Автопроверка конфигураций** — аналог Run Tests: подбирает лучшую стратегию под ваши цели
- **Watchdog** — при 3 сбоях подряд автоматически переключает стратегию
- **Встроенное обновление** — проверка и установка новых версий nfqws и стратегий
- **GameFilter** — поддержка игровых стратегий (TCP/UDP)
- **Firewall** — nftables и iptables (автоопределение)
- **Init-системы** — systemd, OpenRC, runit, s6, dinit
- **Режимы ipset** — Any / Loaded / None
- **Меню приложений** — запуск через ярлык в GUI

---

## Требования

- **Linux** с `nftables` или `iptables`
- Архитектура: **x86_64, ARM, MIPS** и другие (определяется автоматически)
- Утилиты: `git`, `curl`, `tar`, `gcc`/`cc` (для некоторых стратегий)

> **Работа без пароля:** `./service.sh setup-permissions` — настроит NOPASSWD для nft/nfqws

---

## Установка

### Быстрый запуск (без сервиса)

```bash
git clone https://github.com/kik4311/zdyl.git
cd zdyl

./service.sh download-deps --default   # скачать nfqws и стратегии
./service.sh run                       # запустить вручную, проверить работу
```

### Полная установка (с автозапуском)

```bash
git clone https://github.com/kik4311/zdyl.git
cd zdyl

./service.sh download-deps --default   # скачать nfqws и стратегии
./service.sh setup-permissions         # настроить работу без пароля (рекомендуется)
./service.sh service install           # создать и запустить сервис автозапуска
./service.sh desktop install           # ярлык в меню приложений (опционально)
```

При установке сервиса скрипт проверит `conf.env` (при необходимости запросит параметры) и создаст сервис под вашу init-систему.

---

## Удаление

```bash
./service.sh service remove      # остановить и удалить сервис
./service.sh desktop remove      # удалить ярлык
./service.sh setup-permissions remove   # убрать настройки NOPASSWD
rm -rf zdyl                      # удалить каталог проекта
```

---

## Как это работает

Адаптер загружает стратегии из [Flowseal/zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube) — готовые `.bat`-конфигурации для `nfqws` (бинарник из [zapret](https://github.com/bol-van/zapret)). Стратегии автоматически адаптируются под Linux (переименование, замена путей) и запускаются через `nfqws`.

**Структура каталога:**

```
zdyl/
├── service.sh              # главный скрипт (CLI)
├── conf.env                # конфигурация
├── targets.txt             # цели для autocheck/watchdog
├── nfqws                   # бинарник zapret
├── zapret-latest/          # стратегии из Flowseal (обновляются через download-deps)
├── custom-strategies/      # собственные стратегии (всегда в списке)
├── user-lists/             # пользовательские списки (белый/чёрный список)
└── src/
    ├── cli/                # команды CLI (config, service, run, ...)
    ├── lib/                # общие библиотеки (firewall, ipswitch, ...)
    └── firewall-backends/  # бэкенды nftables / iptables
```

---

## Конфигурация (`conf.env`)

Файл создаётся автоматически при первом запуске или вручную:

```bash
strategy=general.bat        # стратегия из списка
interface=any               # сетевой интерфейс (any, enp0s3, eth0, ...)
gamefiltertcp=false         # GameFilter TCP (для игр)
gamefilterudp=false         # GameFilter UDP (для игр)
firewall_backend=auto       # auto | nftables | iptables
```

Управление конфигурацией:

```bash
./service.sh config show                        # показать текущую конфигурацию
./service.sh config edit                        # интерактивное редактирование
./service.sh config set general.bat             # установить стратегию
./service.sh config set general.bat enp0s3      # стратегия + интерфейс
./service.sh config set general.bat enp0s3 -gt -gu   # + GameFilter
./service.sh config set discord -fb iptables    # + бэкенд файрвола
./service.sh config set discord -n              # без перезапуска сервиса
```

---

## Использование

### Интерактивное меню

```bash
./service.sh
```

| № | Действие |
|---|----------|
| 1 | Запустить (без установки сервиса) |
| 2 | Управление сервисом |
| 3 | Изменить конфигурацию |
| 4 | Управление зависимостями |
| 5 | Управление ярлыком на рабочем столе |
| 6 | Настроить работу без пароля |
| 7 | Сменить режим ipset |
| 8 | Автопроверка конфигураций |
| 9 | Автопереключение при сбое (watchdog) |
| 10 | Проверить обновления |
| 0 | Выход |

### Запуск вручную

```bash
./service.sh run                                    # интерактивный выбор параметров
./service.sh run --config conf.env                  # из конфигурационного файла
./service.sh run -s general.bat -i enp0s3           # прямые параметры
./service.sh run -s general.bat -i enp0s3 -gt -gu   # с GameFilter
./service.sh run -fb iptables                       # принудительный бэкенд
```

### Стратегии

```bash
./service.sh strategy list    # показать доступные стратегии
```

Свои стратегии кладите в `custom-strategies/` — они появятся в списке автоматически.

### Обновление зависимостей

```bash
./service.sh download-deps                # интерактивный выбор версий
./service.sh download-deps --default      # рекомендованные версии
./service.sh download-deps -z v72.9 -s main   # конкретные версии
```

### Проверка обновлений

```bash
./service.sh update --check   # только проверить наличие обновлений
./service.sh update           # проверить и установить
./service.sh update --yes     # установить без подтверждения
```

### Прочие команды

```bash
./service.sh kill                        # остановить nfqws и очистить правила firewall
./service.sh setup-permissions           # NOPASSWD для nft/nfqws
./service.sh setup-permissions status    # показать текущие настройки
./service.sh setup-permissions remove    # убрать настройки
./service.sh --help                      # полная справка
```

---

## Режимы ipset

Пункт 7 в меню (или `conf.env`) управляет режимом списков:

| Режим | Что делает |
|-------|------------|
| **Loaded** | Все списки загружены: и свои (ipset), и внешние (list-*) |
| **Any** | nfqws обрабатывает весь трафик (без ограничения списками) |
| **None** | Только внешние списки, свои отключены |

Переключение идёт по кругу: **Loaded → None → Any → Loaded**. При переключении списки автоматически сохраняются в бекап и восстанавливаются.

> На время автопроверки ipset переключается в режим **Any** и в конце автоматически восстанавливается.

---

## Автопроверка конфигураций (Run Tests)

Аналог утилиты **Run Tests** из Flowseal/zapret-discord-youtube.

```bash
./service.sh autocheck
```

Алгоритм:
1. Перебирает все стратегии из `custom-strategies/` и `zapret-latest/`
2. Проверяет каждую против целей из `targets.txt`
   - **URL-цели**: HTTP/1.1, TLS 1.2, TLS 1.3
   - **PING-цели**: проверка ping
3. Показывает результаты (OK/ERR/UNSUP) и определяет лучшую стратегию
4. Предлагает сохранить её в `conf.env`
5. Сохраняет отчёт в `auto_check_results.txt`

`targets.txt` создаётся автоматически при первом запуске (Discord, YouTube, Google, Cloudflare, DNS). Формат:

```
DiscordMain = "https://discord.com"
CloudflareDNS1111 = "PING:1.1.1.1"
```

Можно проверять все конфигурации или выбранные: `1,3,5-10`.

---

## Watchdog (автопереключение при сбое)

Следит за доступностью целей и автоматически меняет стратегию при сбоях.

```bash
./service.sh watchdog
```

Как работает:
1. Запускает zapret со стратегией из `conf.env`
2. Периодически проверяет доступность URL-целей из `targets.txt` (если их нет — встроенные: YouTube, Discord, Google)
3. После **3 сбоев подряд** переключается на следующую стратегию и сохраняет её в `conf.env`
4. Интервал проверки — 60 секунд

При остановке (Ctrl+C) zapret останавливается, а активный сервис перезапускается с новой стратегией. Лог — `watchdog.log`.

---

## Автозагрузка (системный сервис)

```bash
./service.sh service install   # установить и запустить сервис
```

Управление:

```bash
./service.sh service status     # статус
./service.sh service start      # запустить
./service.sh service stop       # остановить
./service.sh service restart    # перезапустить
./service.sh service remove     # удалить сервис
```

<details>
<summary>systemd</summary>

```bash
systemctl status zapret_discord_youtube.service
journalctl -u zapret_discord_youtube.service
```

</details>

<details>
<summary>OpenRC</summary>

```bash
rc-service zapret_discord_youtube status
rc-service zapret_discord_youtube logs
```

</details>

<details>
<summary>runit</summary>

```bash
sv status zapret_discord_youtube
tail -f /var/log/zapret_discord_youtube/current
```

</details>

<details>
<summary>s6</summary>

```bash
s6-svstat /var/service/zapret_discord_youtube
tail -f /var/log/zapret_discord_youtube/current
```

</details>

<details>
<summary>dinit</summary>

```bash
dinitctl status zapret_discord_youtube
dinitctl log zapret_discord_youtube
```

</details>

---

## Ярлык в меню приложений

```bash
./service.sh desktop install    # создать ярлык
./service.sh desktop remove     # удалить ярлык
```

После установки zapret можно запускать из меню приложений (категория «Сеть»).

---

## О версиях

По умолчанию используются:
- **nfqws**: v72.9 (рекомендованная, задана в `src/lib/constants.sh` как `ZAPRET_RECOMMENDED_VERSION`)
- **Стратегии**: последний коммит Flowseal (задан в `src/lib/constants.sh` как `MAIN_REPO_REV`)

Сменить версии можно через `download-deps` или командой `update`.

> Если текущая версия не работает — попробуйте [стабильные релизы](https://github.com/kik4311/zdyl/releases) или другие стратегии.

---

## Устранение неполадок

**Ничего не работает после установки сервиса**

```bash
./service.sh service status     # посмотреть статус
./service.sh run                # запустить вручную — так видны ошибки
```

**Не удаётся переключить режим ipset обратно из Any**

Бекап списков создаётся автоматически при каждом переключении. Если бекап потерян (например, после `download-deps`), просто повторите цикл: переключитесь в None и обратно, либо переустановите стратегии:

```bash
./service.sh download-deps --default
```

**Сервис требует пароль при перезапуске**

```bash
./service.sh setup-permissions
```

**Стратегия не работает (YouTube/Discord не открываются)**

1. Запустите автопроверку — она подберёт рабочую стратегию:
   ```bash
   ./service.sh autocheck
   ```
2. Если ничего не подошло — проверьте [Issues](https://github.com/Flowseal/zapret-discord-youtube/issues) и [Discussions](https://github.com/Flowseal/zapret-discord-youtube/discussions) репозитория стратегий: проблема может уже обсуждаться
3. Попробуйте более свежую/старую версию nfqws: `./service.sh download-deps -z <версия>`

**nftables не находится**

Проверьте, что установлен и запущен nftables, либо принудительно укажите бэкенд:

```bash
./service.sh config set discord -fb iptables
```

---

## Поддержка и помощь

> [!IMPORTANT]
> Это **адаптер**! Он не гарантирует, что стратегии разблокируют всё.

**В [Issues](https://github.com/kik4311/zdyl/issues) пишите:**
- Ошибки в работе скрипта адаптера
- Предложения по функциям

**В [Discussions](https://github.com/kik4311/zdyl/discussions):**
- Не работает YouTube/Discord (после проверки Flowseal)
- Поиск рабочих стратегий, обмен опытом

**Pull Request приветствуются!**

---

## Контрибьюторы

<div align="center">

**Спасибо всем, кто улучшает проект!**

<a href="https://github.com/kik4311/zdyl/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=kik4311/zdyl" alt="Contributors" />
</a>

</div>

---

<div align="center">

[![Star History Chart](https://api.star-history.com/svg?repos=kik4311/zdyl&type=Date)](https://star-history.com/#kik4311/zdyl&Date)

</div>