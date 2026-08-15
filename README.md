<div align="center">

# Zapret Discord YouTube Linux

### Plug-and-Play адаптер для обхода замедления YouTube и Discord на Linux

Адаптер для стратегий [Flowseal/zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube) и [zapret](https://github.com/bol-van/zapret) от bol-van.

[![GitHub stars](https://img.shields.io/github/stars/kik4311/zapret-discord-youtube-linux?style=social)](https://github.com/kik4311/zapret-discord-youtube-linux/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/kik4311/zapret-discord-youtube-linux?style=social)](https://github.com/kik4311/zapret-discord-youtube-linux/network/members)
[![GitHub release](https://img.shields.io/github/v/release/kik4311/zapret-discord-youtube-linux?style=social)](https://github.com/kik4311/zapret-discord-youtube-linux/releases)

</div>

---

## Возможности

- **Простая установка** — одна команда скачивает nfqws и стратегии
- **Автопроверка конфигураций** — подбирает лучшую стратегию для ваших целей
- **Watchdog** — при сбоях автоматически переключает стратегию
- **Встроенное обновление** — проверка и установка новых версий nfqws и стратегий
- **GameFilter** — поддержка игровых стратегий
- **Firewall** — nftables и iptables
- **Init-системы** — systemd, OpenRC, runit, s6, dinit
- **Меню приложений** — запуск через ярлык в GUI

---

## Требования

- **Linux** с `nftables` или `iptables`
- Архитектура: **x86_64, ARM, MIPS** и другие (определяется автоматически)
- Утилиты: `git`, `curl`, `tar`, `gcc`/`cc` (для некоторых стратегий)

> **Работа без пароля:** `./service.sh setup-permissions` — настроит NOPASSWD для nft/nfqws

---

## Быстрый старт

```bash
git clone https://github.com/kik4311/zapret-discord-youtube-linux.git
cd zapret-discord-youtube-linux

./service.sh download-deps --default
./service.sh
```

Скрипт покажет интерактивное меню: запуск, управление сервисом, настройка.

---

## Как это работает

Адаптер загружает стратегии из [Flowseal/zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube) — готовые `.bat`-конфигурации для `nfqws` (бинарник из [zapret](https://github.com/bol-van/zapret)). Стратегии автоматически адаптируются под Linux (переименование, замена путей) и запускаются через `nfqws`.

**Структура каталога:**
- `zapret-latest/` — стратегии, загруженные из Flowseal (обновляются через `download-deps`)
- `custom-strategies/` — собственные стратегии (всегда в списке)
- `nfqws` — бинарник zapret
- `conf.env` — конфигурация

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
./service.sh config show                # показать текущую конфигурацию
./service.sh config edit                # интерактивное редактирование
./service.sh config set general.bat     # установить стратегию
./service.sh config set general.bat enp0s3 -gt -gu   # стратегия + интерфейс + GameFilter
./service.sh config set discord -n      # без перезапуска сервиса
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

### Запуск zapret

```bash
./service.sh run                              # интерактивный выбор параметров
./service.sh run --config conf.env            # из конфигурационного файла
./service.sh run -s general.bat -i enp0s3     # прямые параметры
./service.sh run -s general.bat -i enp0s3 -gt -gu   # с GameFilter
```

### Стратегии

```bash
./service.sh strategy list    # показать доступные стратегии
```

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

> На время проверки ipset переключается в режим `Any` и восстанавливается в конце.

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

Скрипт проверяет `conf.env` (при необходимости запросит параметры) и создаёт сервис под вашу init-систему.

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

## Прочие команды

```bash
./service.sh kill              # остановить nfqws и очистить правила firewall
./service.sh setup-permissions # настроить NOPASSWD для nft/nfqws
./service.sh --help            # полная справка
```

---

## О версиях

По умолчанию используются:
- **nfqws**: v72.9 (рекомендованная, задана в `src/lib/constants.sh` как `ZAPRET_RECOMMENDED_VERSION`)
- **Стратегии**: последний коммит Flowseal (задан в `src/lib/constants.sh` как `MAIN_REPO_REV`)

Сменить версии можно через `download-deps` или командой `update`.

> Если текущая версия не работает — попробуйте [стабильные релизы](https://github.com/kik4311/zapret-discord-youtube-linux/releases) или другие стратегии.

---

## Поддержка и помощь

> [!IMPORTANT]
> Это **адаптер**! Он не гарантирует, что стратегии разблокируют всё.

**Сначала проверьте:**
1. [Issues](https://github.com/Flowseal/zapret-discord-youtube/issues) и [Discussions](https://github.com/Flowseal/zapret-discord-youtube/discussions) репозитория стратегий — проблема может уже обсуждаться
2. Воспользуйтесь [автопроверкой конфигураций](#автопроверка-конфигураций-run-tests) — она подберёт рабочую стратегию

**В [Issues](https://github.com/kik4311/zapret-discord-youtube-linux/issues) пишите:**
- Ошибки в работе скрипта адаптера
- Предложения по функциям

**В [Discussions](https://github.com/kik4311/zapret-discord-youtube-linux/discussions):**
- Не работает YouTube/Discord (после проверки Flowseal)
- Поиск рабочих стратегий, обмен опытом

**Pull Request приветствуются!**

---

## Контрибьюторы

<div align="center">

**Спасибо всем, кто улучшает проект!**

<a href="https://github.com/kik4311/zapret-discord-youtube-linux/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=kik4311/zapret-discord-youtube-linux" alt="Contributors" />
</a>

</div>

---

<div align="center">

[![Star History Chart](https://api.star-history.com/svg?repos=kik4311/zapret-discord-youtube-linux&type=Date)](https://star-history.com/#kik4311/zapret-discord-youtube-linux&Date)

</div>
