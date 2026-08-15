<div align="center">

# 🎧 Zapret Discord YouTube Linux 📺

### Plug-And-Play адаптер для обхода замедления YouTube на Linux

На базе стратегий [Flowseal](https://github.com/Flowseal/zapret-discord-youtube) и [zapret](https://github.com/bol-van/zapret) от bol-van

**Проверено на:**
Ubuntu 24.04 • Debian 12 • Arch Linux • Gentoo Linux

[![GitHub stars](https://img.shields.io/github/stars/kik4311/zapret-discord-youtube-linux?style=social)](https://github.com/kik4311/zapret-discord-youtube-linux/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/kik4311/zapret-discord-youtube-linux?style=social)](https://github.com/kik4311/zapret-discord-youtube-linux/network/members)

</div>

---

<div align="center">

[Быстрый старт](#быстрый-старт) • [Использование](#использование) • [Автозагрузка](#автозагрузка) • [Поддержка](#поддержка-и-помощь)


</div>

## Быстрый старт

```bash
git clone https://github.com/kik4311/zapret-discord-youtube-linux.git
cd zapret-discord-youtube-linux

./service.sh download-deps --default
./service.sh
```

Скрипт интерактивно предложит выбрать действие: запуск, управление сервисом или настройку конфигурации.

> 💡 **Работа без пароля:** `./service.sh setup-permissions` — настроит NOPASSWD для nft/nfqws

> 💡 Что-то не работает? Сначала прочитайте раздел [Поддержка и помощь](#поддержка-и-помощь)

---

**Требования:**
- Работает только с **nftables**
- Поддерживаемые архитектуры: **x86_64, ARM, MIPS, и др** (автоматическое определение)

---

## О версиях

Адаптер по умолчанию использует:
- **nfqws**: v72.9 (рекомендованная версия, прописана в `src/lib/constants.sh` как `ZAPRET_RECOMMENDED_VERSION`)
- **Стратегии**: [коммит ef19845a801e4e743f7bdfdbd58f9745c6adbd60](https://github.com/Flowseal/zapret-discord-youtube/commit/ef19845a801e4e743f7bdfdbd58f9745c6adbd60) (прописан в `src/lib/constants.sh` как `MAIN_REPO_REV`)

Вы можете изменить версии:
- Интерактивно: `./service.sh download-deps` (выбор из доступных версий)
- Напрямую: `./service.sh download-deps -z v72.9 -s main`
- В коде: отредактируйте константы в `src/lib/constants.sh`

Если текущая версия не работает, попробуйте [стабильные релизы](https://github.com/kik4311/zapret-discord-youtube-linux/releases).

**Сторонние проекты:**
- [Версия от Snowy-Fluffy](https://github.com/Snowy-Fluffy/zapret.installer)

---

# Использование

## Интерактивный режим

```bash
./service.sh
```

Меню предлагает:
1. **Запустить** — интерактивный выбор интерфейса, gamefilter и стратегии, запуск в текущем терминале
2. **Управление сервисом** — установка/удаление/перезапуск системного сервиса
3. **Изменить конфигурацию** — редактирование `conf.env`

## Конфигурация (conf.env)

Создайте файл `conf.env`:

```bash
strategy=general.bat
interface=enp0s3
gamefiltertcp=true
gamefiterudp=true
```

## Управление через CLI

### Основные команды

```bash
./service.sh --help  # показать справку по командам
```

### Управление зависимостями

```bash
# Скачать nfqws и стратегии (интерактивный выбор версий)
./service.sh download-deps

# Скачать рекомендованные версии (неинтерактивно)
./service.sh download-deps --default

# Скачать конкретные версии
./service.sh download-deps -z v72.9 -s main

# Показать доступные стратегии
./service.sh strategy list

# Проверить наличие обновлений nfqws и стратегий
./service.sh update --check

# Проверить и установить обновления
./service.sh update

# Установить обновления без подтверждения
./service.sh update --yes
```

### Запуск zapret

```bash
# Интерактивный режим (запрос параметров)
./service.sh run

# Загрузка из конфигурационного файла
./service.sh run --config conf.env

# Прямые параметры
./service.sh run -s general.bat -i enp0s3
./service.sh run -s general.bat -i enp0s3 -gt -gu  # с gamefiltertcp и gamefilterudp
```

### Управление системным сервисом

```bash
# Интерактивное меню управления сервисом
./service.sh service

# Установить и запустить сервис
./service.sh service install

# Показать статус
./service.sh service status

# Запустить/остановить/перезапустить
./service.sh service start
./service.sh service stop
./service.sh service restart

# Удалить сервис
./service.sh service remove
```

### Управление конфигурацией

```bash
# Показать текущую конфигурацию
./service.sh config show

# Интерактивное редактирование
./service.sh config edit

# Установить конфигурацию напрямую
./service.sh config set general.bat
./service.sh config set general.bat enp0s3 -gt -gu  # с gamefiltertcp и gamefilterudp
./service.sh config set discord -n             # без перезапуска сервиса
```

### Создание ярлыка в меню приложений

```bash
# Создать ярлык в меню приложений (для GUI запуска)
./service.sh desktop install

# Удалить ярлык из меню приложений
./service.sh desktop remove
```

После установки ярлыка вы сможете запустить zapret из меню приложений вашей системы (категория "Сеть" или "Система").

### Утилиты

```bash
# Остановить nfqws и очистить nftables
./service.sh kill
```

---

## Автопроверка конфигураций (Run Tests)

Аналог утилиты **Run Tests** из [Flowseal/zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube).

```bash
./service.sh autocheck
```

Или через интерактивное меню:
```bash
./service.sh
# -> выбрать "8. Автопроверка конфигураций"
```

Скрипт автоматически:
1. Перебирает все стратегии (из `/custom-strategies` и `/zapret-latest`)
2. Проверяет каждую против списка целей из `targets.txt`
   - **URL-цели**: проверки HTTP (HTTP/1.1), TLS 1.2 и TLS 1.3
   - **PING-цели**: проверка ping
3. Показывает результаты по каждой цели и аналитику (OK/ERR/UNSUP)
4. Определяет лучшую стратегию и предлагает сохранить её в `conf.env`
5. Сохраняет результаты в `auto_check_results.txt`

Файл `targets.txt` создаётся автоматически при первом запуске (Discord, YouTube, Google, Cloudflare и публичные DNS). Формат:

```
DiscordMain = "https://discord.com"
CloudflareDNS1111 = "PING:1.1.1.1"
```

Можно тестировать все конфигурации или выбранные (номера, диапазоны: `1,3,5-10`).

> На время проверки ipset переключается в режим `Any` и восстанавливается в конце. Если сервис zapret был активен — он перезапустится после проверки.


---

## Автопереключение при сбое (Watchdog)

Следит за доступностью целей и при сбоях автоматически меняет стратегию:

```bash
./service.sh watchdog
```

Или через интерактивное меню:
```bash
./service.sh
# -> выбрать "9. Автопереключение при сбое (watchdog)"
```

Как работает:
1. Запускает zapret со стратегией из `conf.env`
2. Периодически проверяет доступность **URL-целей** из `targets.txt` (если их нет — встроенные: YouTube, Discord, Google)
3. После **3 сбоев подряд** переключается на следующую стратегию и сохраняет её в `conf.env`
4. Интервал проверки — 60 секунд, порог сбоев — 3 (меняются в `src/cli/watchdog.sh`)

При остановке (Ctrl+C) zapret останавливается, а если сервис был активен — перезапускается с новой стратегией.

Лог пишется в `watchdog.log`.

> Настройки `watchdog.log` и `.deps-versions` — это служебные файлы, они игнорируются git.


---

## Автозагрузка (системный сервис)

```bash
# Через CLI
./service.sh service install

# Или через интерактивное меню
./service.sh
# -> выбрать "2. Управление сервисом" -> "1. Установить и запустить сервис"
```

Скрипт:
- Проверяет `conf.env` (если пустой — запросит параметры интерактивно)
- Создаёт сервис для автозапуска (поддерживает systemd, OpenRC, runit, s6, dinit)
- Использует значения из `conf.env`

<details>
<summary>Для systemd систем</summary>

Просмотреть статус сервиса можно командой:

```bash
systemctl status zapret_discord_youtube.service
```

Посмотреть логи сервиса:

```bash
journalctl -u zapret_discord_youtube.service
```

</details>

<details>
<summary>Для OpenRC систем</summary>

Просмотреть статус сервиса можно командой:

```bash
rc-service zapret_discord_youtube status
```

Посмотреть логи сервиса:

```bash
rc-service zapret_discord_youtube logs
```

</details>

<details>
<summary>Для runit систем</summary>

Просмотреть статус сервиса можно командой:

```bash
sv status zapret_discord_youtube
```

Посмотреть логи сервиса:

```bash
tail -f /var/log/zapret_discord_youtube/current
```

</details>

<details>
<summary>Для s6 систем</summary>

Просмотреть статус сервиса можно командой:

```bash
s6-svstat /var/service/zapret_discord_youtube
```

Посмотреть логи сервиса:

```bash
tail -f /var/log/zapret_discord_youtube/current
```

</details>

<details>
<summary>Для dinit систем</summary>

Просмотреть статус сервиса можно командой:

```bash
dinitctl status zapret_discord_youtube
```

Посмотреть логи сервиса:

```bash
dinitctl log zapret_discord_youtube
```

</details>

---

## Поддержка и помощь

> [!IMPORTANT]
> Это АДАПТЕР! Не гарантирует, что стратегии разблокируют всё.

### Если ничего не работает

**Прежде чем создавать Issue или Discussion:**

1. Посмотрите [Issues в репозитории со стратегиями](https://github.com/Flowseal/zapret-discord-youtube/issues) — возможно, проблема уже обсуждается там
2. Попробуйте другие стратегии или воспользуйтесь [автопроверкой конфигураций](#автопроверка-конфигураций-run-tests)
3. Проверьте [Discussions](https://github.com/Flowseal/zapret-discord-youtube/discussions) — там обсуждают рабочие решения

### Когда создавать Issue/Discussion у меня

**Когда писать в [Issues](https://github.com/kik4311/zapret-discord-youtube-linux/issues):**
- Ошибки в работе **скрипта адаптера**
- Вопросы по работе **скрипта адаптера**
- Предложение добавить стратегию в custom-strategies

**Когда писать в [Discussions](https://github.com/kik4311/zapret-discord-youtube-linux/discussions):**
- Не работает YouTube или другой сайт (после проверки репозитория Flowseal)
- Поиск рабочих стратегий
- Обмен опытом

**Pull Request приветствуются** (например, поддержка iptables)

---

## Контрибьюторы

<div align="center">

**Спасибо всем, кто улучшает проект!** 🎉

<a href="https://github.com/kik4311/zapret-discord-youtube-linux/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=kik4311/zapret-discord-youtube-linux" alt="Contributors" />
</a>

Хотите видеть здесь свое имя? Сделайте [Pull Request](https://github.com/kik4311/zapret-discord-youtube-linux/pulls)!

</div>

---

<div align="center">

[![Star History Chart](https://api.star-history.com/svg?repos=kik4311/zapret-discord-youtube-linux&type=Date)](https://star-history.com/#kik4311/zapret-discord-youtube-linux&Date)

</div>
