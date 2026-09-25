# launchctl.user.envVariables.PATH not applied when restarts mac

```bash
>darwin switch
>launchctl getenv PATH
/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
# fresh restart of mac, literally.
>launchctl getenv PATH

# WTF?
```

# Launching app via clicking does not follow the PATH set by launchctl.user.envVariables.PATH

```bash
>darwin switch
>launchctl getenv PATH
/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
>open -a Sioyek
>ps eww -p $(pgrep sioyek) | tr ' ' '\n' | grep '^PATH='
PATH=/Users/95hyouka/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/Users/95hyouka/.nix-profile/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/opt/podman/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
# close sioyek and open it by clicking its icon in the Dock
>launchctl getenv PATH
/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
>ps eww -p $(pgrep sioyek) | tr ' ' '\n' | grep '^PATH='
PATH=/usr/bin:/bin:/usr/sbin:/sbin
# WTF?
```

```bash
❯ ps eww -p $(pgrep Find)
  PID   TT  STAT      TIME COMMAND
  640   ??  S      0:03.42 /System/Library/CoreServices/Finder.app/Contents/MacOS/Finder
  779   ??  Ss     0:00.10 /System/Applications/FindMy.app/Contents/PlugIns/FindMyWidgetPeople.appex/Contents/MacOS/FindMyWidgetPeople -LaunchArguments eyJzZXJ2aWNlTmFtZSI6ImNvbS5hcHBsZS5maW5kbXkuRmluZE15V2lkZ2V0UGVvcGxlIiwiZW5oYW5jZWRTZWN1cml0eSI6ZmFsc2UsInR5cGUiOjF9
  795   ??  Ss     0:00.05 /System/Applications/FindMy.app/Contents/PlugIns/FindMyWidgetItems.appex/Contents/MacOS/FindMyWidgetItems -LaunchArguments eyJzZXJ2aWNlTmFtZSI6ImNvbS5hcHBsZS5maW5kbXkuRmluZE15V2lkZ2V0SXRlbXMiLCJlbmhhbmNlZFNlY3VyaXR5IjpmYWxzZSwidHlwZSI6MX0=
 1042   ??  Ss     0:00.02 /System/Library/PrivateFrameworks/FindMyMac.framework/Resources/FindMyMacd

~
❯ ps eww -p $(pgrep Dock)
  PID   TT  STAT      TIME COMMAND
  565   ??  Ss     0:00.02 /System/Library/DriverExtensions/com.apple.DriverKit-IOUserDockChannelSerial.dext/com.apple.DriverKit-IOUserDockChannelSerial com.apple.IOUserDockChannelSerial 0x100000c6e com.apple.DriverKit-IOUserDockChannelSerial
  636   ??  S      0:02.32 /System/Library/CoreServices/Dock.app/Contents/MacOS/Dock
  978   ??  Ss     0:01.33 /System/Library/CoreServices/Dock.app/Contents/XPCServices/DockHelper.xpc/Contents/MacOS/DockHelper
```
---

# 진단 (2026-09-25)

## 한 줄 요약

`launchd.user.envVariables`는 nix-darwin에서 **`launchctl setenv` 한 줄**로 구현된다.
`setenv`는 (1) 재부팅하면 날아가고 (2) 부팅 시점엔 애초에 엉뚱한 도메인에 꽂힌다.

## 근거

nix-darwin이 실제로 만들어내는 코드 — 플리스트도 뭐도 아니고 그냥 명령 한 줄:

```bash
❯ grep -n 'launchctl setenv' /run/current-system/activate
2472:sudo --user=95hyouka -- launchctl setenv PATH '/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin'
```

### 1번 증상: 재부팅하면 사라진다

`launchctl setenv`는 launchd 도메인의 **인메모리** 상태만 바꾼다. 로그아웃/재부팅이면 끝.

부팅 때 다시 세팅될 것 같지만 안 된다. activate 스크립트는 부팅 시
`org.nixos.activate-system` LaunchDaemon이 실행하는데, 데몬의 bootstrap port는
**system 도메인**이다. `sudo --user=...`는 bootstrap port를 바꾸지 않으므로
`launchctl setenv`는 `gui/501`이 아니라 system 도메인에 값을 넣는다.
그래서 로그인 후 터미널에서 `launchctl getenv PATH`를 하면 비어 있다.

```bash
❯ cat /run/current-system/Library/LaunchDaemons/org.nixos.activate-system.plist
  <key>RunAtLoad</key><true/>   # root, system 도메인
```

### 2번 증상: 클릭해서 띄운 앱의 PATH가 다르다

`gui/501`에 PATH가 없으면 launchd는 자기 내장 기본값 `_PATH_STDPATH`를 준다:

```
/usr/bin:/bin:/usr/sbin:/sbin
```

...클릭해서 띄운 sioyek이 갖고 있던 바로 그 값이다. 즉 이건 "Dock이 특별해서"가
아니라 **그 시점 `gui/501`에 PATH가 없었기 때문**이다. 확인:

```bash
❯ ls -l /var/db/com.apple.xpc.launchd/config/
total 0                       # 비어 있음 -> user 도메인 PATH 오버라이드 없음
```

그리고 `setenv`가 살아있는 동안에는 Launch Services로 띄운 앱도 값을 제대로 받는다
(Finder로 sioyek 실행해서 확인함 — 도메인의 PATH도, 방금 넣은 테스트 변수도 다 들어왔다):

```bash
❯ launchctl setenv PROBEVAR probe-set-at-14-07
❯ osascript -e 'tell application "Finder" to open POSIX file ".../sioyek.app"'
❯ ps eww -p $(pgrep -x sioyek) | tr ' ' '\n' | grep -E '^(PATH|PROBEVAR)='
PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
PROBEVAR=probe-set-at-14-07
```

한편 `open -a`가 셸의 PATH를 그대로 물려준 건 정상이다. `open`은 호출자의 환경을
Launch Services에 같이 넘긴다. 그래서 터미널에서 띄운 앱과 클릭해서 띄운 앱이
원래부터 다른 PATH를 갖는다 — 이건 버그가 아니라 사양.

## 고친 방법 (sioyek 전용)

launchd에는 "이 앱에만" 환경변수를 주는 기능이 없다. user 도메인은 통째로 하나다
(`launchctl config user path`도 도메인 전체에 걸린다). 그래서 앱 쪽에서 해결한다.

sioyek은 Qt 앱이라 nixpkgs의 `wrapQtAppsHook`이 이미 번들 안을 이렇게 만들어 둔다:

```bash
❯ ls -la .../sioyek.app/Contents/MacOS/
-r-xr-xr-x  7700416  .sioyek-wrapped   # 진짜 바이너리
-r-xr-xr-x    50656  sioyek            # makeBinaryWrapper (Mach-O), QT_PLUGIN_PATH 설정 후 exec
```

여기에 `qtWrapperArgs`로 PATH를 얹는다. **래퍼 레이어가 늘지 않고**, 실행 바이너리가
번들 안에 그대로 있으므로 Dock 아이콘 / 기본 앱 연결도 안 깨진다.

```nix
qtWrapperArgs =
  (old.qtWrapperArgs or [])
  ++ ["--prefix PATH : ${sioyekPath}"];
```

`--set`이 아니라 `--prefix`인 이유: 런처가 준 PATH를 꼬리로 남겨서 `/usr/bin` 등이 살아있게.

### 검증

Dock 실행과 똑같이 `_PATH_STDPATH`만 주고 띄워봤다:

```bash
❯ env -i PATH=/usr/bin:/bin:/usr/sbin:/sbin HOME=$HOME .../Contents/MacOS/sioyek &
❯ ps eww -p $(pgrep -x sioyek) | tr ' ' '\n' | grep '^PATH='
PATH=/Users/95hyouka/.local/bin:/Users/95hyouka/.nix-profile/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/opt/podman/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
```

Dock / Finder / `open` / aerospace / 셸 직접 실행 — 실행 경로와 무관하게 동일하게 걸린다.

### 안 쓰기로 한 것

- `launchd.user.envVariables` — 위 진단대로 재부팅을 못 견딘다. 제거함.
- `launchctl config user path` — 재부팅은 견디지만 user 도메인 **전체**에 걸린다.
  Apple 자체 user agent들까지 nix 바이너리를 먼저 보게 되므로 쓰지 않기로 함.
- `Info.plist`의 `LSEnvironment` — Launch Services로 띄울 때만 먹고
  `lsregister` 캐시를 타서 덜 결정적이다.

### 남은 사실

글로벌 설정을 걷어냈으므로, **sioyek 외 다른 GUI 앱**은 여전히 재부팅 후
`/usr/bin:/bin:/usr/sbin:/sbin`만 받는다. 나중에 다른 앱도 같은 문제를 겪으면
그 앱에도 같은 래퍼 방식을 적용하면 된다.

### 부수 효과

`sioyekPath`에 `/Users/95hyouka/...`가 하드코딩되므로 sioyek 파생이 사용자 전용이 된다
(makeBinaryWrapper는 값을 리터럴로 굽기 때문에 `$HOME` 확장이 안 된다).
1인 머신이라 괜찮지만, 공유할 설정이면 홈 경로 두 줄은 빼는 게 맞다.
