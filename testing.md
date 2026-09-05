# 설정 테스트 방법

이 repo의 설정이 "제대로 로드/적용되는지" 확인하는 방법을 비용 순으로 정리.
아래로 갈수록 충실도는 높아지고 비용도 커진다. **0~3단계로 대부분 잡힌다.**

| 단계 | 방법 | 비용 | 잡히는 것 |
|---|---|---|---|
| 0 | eval (`nix flake check`) | 초 단위 | 문법·옵션명·타입·assertion |
| 1 | build (`darwin-rebuild build`) | 분 단위 | 실제 빌드 실패 |
| 2 | 산출물 grep (`result/activate`) | 초 단위 | 의도 → 실제 명령 번역 |
| 3 | `darwin-rebuild check` | 초 단위 | 활성화 전처리 검사 |
| 4 | activate 스크립트 assert 테스트 | 초 단위 | 특정 설정의 회귀 |
| 5 | macOS VM | 수 시간 + 수십 GB | 부트스트랩 전체 |

---

## 0단계 — eval

> ⚠️ **주의: 맨손 `nix flake check`는 원래 아무것도 검증하지 않았다.**
> Nix는 `darwinConfigurations` / `homeConfigurations`를 인식하지 못해서
> "출력이 존재하는지"만 보고 **평가조차 하지 않고** 통과시킨다 (0.9초).

그래서 `flake-outputs/devShell/output.nix`에서 두 config를 `checks`로 다시 노출해 뒀다
(커밋 `45e8f5d`). 지금은 이렇게 나온다:

```
$ nix flake check -L
checking derivation checks.aarch64-darwin.home-95hyouka...
checking derivation checks.aarch64-darwin.darwin-95hyoukas-MacBook-Air...
running 2 flake checks...
all checks passed!                                        → 9.9s
```

devshell 메뉴에도 넣어 뒀다 (커밋 `30a7394`):

```
$ check      # = nix build "$PRJ_ROOT#checks.aarch64-darwin.{darwin-*,home-*}"
```

수동으로 평가만 하고 싶으면:

```bash
nix eval --raw .#darwinConfigurations.\"95hyoukas-MacBook-Air\".config.system.build.toplevel.drvPath   # 4.4s
nix eval --raw .#homeConfigurations.\"95hyouka\".activationPackage.drvPath                             # 3.4s
```

옵션 값이 실제로 어떻게 병합됐는지 직접 볼 수도 있다:

```bash
nix eval .#darwinConfigurations.\"95hyoukas-MacBook-Air\".config.system.defaults.finder --json
# {"AppleShowAllExtensions":true,"AppleShowAllFiles":true,"CreateDesktop":null,...}
```

### 다른 아키텍처 머신에서 (예: x86_64 리눅스 CI)

`--arch` / `--system` 같은 플래그는 **없다.** `nix flake check`의 고유 옵션은
`--all-systems`와 `--no-build` 둘뿐이다. 대신 전역 설정 `system`을 덮어쓰면 된다:

```bash
nix flake check --no-build --option system aarch64-darwin   # 리눅스에서 darwin만 체크
nix flake check --all-systems --no-build                    # 양쪽 다 (4.2s)
```

- `system`은 필터가 아니라 "이 머신이 무슨 시스템인지" 선언하는 설정이므로,
  **`--no-build`를 빼면 리눅스에서 darwin 클로저를 빌드하려다 실패한다.** eval 전용.
- darwin이 아닌 머신에서 평가가 가능한 이유는 이 config에 IFD가 없기 때문.
  확인 방법: `nix eval ... --option allow-import-from-derivation false` → 통과.
  (`aerospace/.aerospace.toml`의 `fromTOML`은 IFD가 아니라 순수 파일 읽기)
- 리눅스에서는 **평가까지만** 가능. 실제 빌드는 aarch64-darwin 러너 필요
  (GitHub Actions `macos-14` / `macos-15`가 arm64).
- `--no-build`라도 flake input은 전부 fetch한다. 실측: nixpkgs 333M,
  homebrew-core 44M, homebrew-cask 31M.

---

## 1단계 — 빌드만 (시스템 무변경)

```bash
darwin-rebuild build --flake .#95hyoukas-MacBook-Air   # ./result 생성
home-manager build --flake .#95hyouka
nix store diff-closures /run/current-system ./result   # 뭐가 바뀌는지 diff
```

`nvd diff /run/current-system ./result`도 좋다.

---

## 2단계 — 산출물 grep

**"설정이 제대로 로드됐나"에 대한 가장 직접적인 답.** `result/activate`가 전부 말해준다.

```bash
grep -n 'defaults write' result/activate    # AppleShowAllFiles, screencapture target 등
grep -n 'duti' result/activate              # postActivation (실기기에선 activate:2566)
cat $(nix eval --raw .#darwinConfigurations.\"95hyoukas-MacBook-Air\".config.homebrew.brewfile)
```

Brewfile은 cask 21개 + masApps 2개가 정상 생성됨을 확인했다.
cask 이름 오타/rename(brew에서 흔한 breakage)은 설치 없이 검증 가능:

```bash
brew info --cask <name>
```

적용 후 실제 반영 확인:

```bash
defaults read com.apple.screencapture target     # → clipboard
defaults read com.apple.finder AppleShowAllFiles
duti -d com.adobe.pdf                            # → info.sioyek.sioyek
```

---

## 3단계 — `darwin-rebuild check` (실기기, 비파괴)

`darwin-rebuild`에는 `nixos-rebuild test` 같은 게 **없다.**
서브커맨드는 `edit | switch | activate | build | check | changelog`.

`check`는 `checkActivation=1`을 걸고 activate를 실행한다. activate 스크립트 2596줄 중
**809줄에서 `exit 0`** — 즉 전처리 검사만 돌고 mutation 직전에 빠져나온다.

```bash
sudo darwin-rebuild check --flake .#95hyoukas-MacBook-Air   # root 필요
```

잡히는 것:

- macOS 버전 하한
- `system.primaryUser`(95hyouka) 실존 여부
- Homebrew 설치 여부 / Determinate 충돌 감지
- `/etc` 파일 충돌 (nix-darwin이 덮어쓸 파일들의 sha256 검사)
- App Management 권한 (TCC)

**defaults / homebrew / duti는 실행되지 않는다.**

---

## 4단계 — activate 스크립트 assert 테스트 (VM 없이)

nix-darwin 소스에 `release.nix:15 makeTest` + `tests/` 45개가 있다.
방식은 VM이 아니라 **`runCommand` 샌드박스에서 생성된 `activate` 스크립트 텍스트를 assert**하는 것.

예: `tests/system-defaults-write.nix`는 fixture 문자열이 `${config.out}/activate` 안에
포함되어 있는지 python으로 확인한다.

같은 패턴을 이 repo의 `checks`에 붙이면 초 단위로 회귀 테스트가 된다:

- sioyek이 정말 pdf 기본앱으로 설정되는가
- `screencapture target=clipboard`가 `defaults write`로 나오는가
- Brewfile에 특정 cask가 들어있는가

---

## 5단계 — macOS VM

### 가능하다

- 호스트: Apple Silicon / macOS 26.5.1, 여유 디스크 438GB
- pinned nixpkgs에 `tart 2.36.0`, `utm 4.7.5` 있음. VirtualBuddy도 무료 대안
- Virtualization.framework로 게스트 macOS 26 가능 (게스트 ≤ 호스트 버전)
- Apple 라이선스: 호스트당 macOS VM 2개까지

### VM에서 맞춰야 할 전제

- **사용자명 `95hyouka` 계정을 VM에 만들어야 한다.** `system.primaryUser`와
  HM의 `home.homeDirectory = /Users/95hyouka`가 하드코딩이라, 없으면 activation이
  809줄(3단계 검사) 이전에서 죽는다.
- **hostName은 상관없다.** `--flake .#95hyoukas-MacBook-Air`로 attr을 명시하므로
  VM 호스트명이 달라도 된다.
- **agenix 개인키**(`publicKeys.nix`의 lyra95 ed25519 대응 비밀키)를 VM에 넣어야
  `github_ed25519.age` 복호화가 되고 HM activation이 끝까지 간다.

### VM으로 테스트 못 하는 것

| 항목 | 이유 |
|---|---|
| `masApps` (KakaoTalk, Line) | macOS 15+ 게스트에서 Apple ID 로그인은 되지만 **Mac App Store 로그인은 여전히 불가** (VZ 플랫폼 제약) |
| `touchIdAuth` (sudo) | VM에 Secure Enclave/Touch ID 없음. pam 파일 생성 자체는 검증 가능 |
| steam / parsec / unity-hub | GPU·드라이버 의존 |
| duti 기본앱 | LaunchServices는 돌지만 결과가 실기기와 다를 수 있음 |

### 비용

IPSW ~15GB + VM 디스크 + `brew bundle`이 cask 21개를 전부 새로 받음(수십 GB).
1회 풀 리허설에 몇 시간.

> **결론: 반복 회귀 테스트용으로는 과하다.**
> "새 맥에 처음부터 부트스트랩" 시나리오를 1회 리허설하는 용도로만 가치가 있다.

---

## VM보다 실용적일 수 있는 대안

### 1. 세대 롤백 (지금도 이미 쓰고 있는 방법)

`/nix/var/nix/profiles/`에 세대가 쌓여 있다. 실기기에서 그냥 switch하고 문제 생기면:

```bash
sudo darwin-rebuild --rollback
sudo darwin-rebuild --switch-generation 54
darwin-rebuild --list-generations
```

`/etc` 변경까지 되돌리려면 미리 `tmutil localsnapshot`.

### 2. 외장 SSD 부팅 설치본

Apple Silicon은 외장 볼륨 부팅이 된다. App Store·Touch ID까지 포함한 **풀 충실도**
테스트가 되고, VM보다 오히려 현실적이다.

### 3. CI

GitHub Actions에서 0~1단계는 가능. 단:

- macOS runner는 **중첩 가상화 불가** → CI 안에서 VM은 불가능
- runner 유저명이 `runner`라 `switch`는 profile 하드코딩 때문에 불가
- x86_64 리눅스 러너는 0단계(eval)까지만 (위 "다른 아키텍처 머신에서" 참고)

---

## 추천 순서

가성비 순:

1. `check` (devshell 메뉴) — 0·1단계
2. `nix store diff-closures /run/current-system ./result` — 뭐가 바뀌는지
3. `sudo darwin-rebuild check --flake .#...` — 활성화 실패 사전 차단
4. 필요하면 activate 스크립트 assert 테스트 (4단계)
5. VM은 "새 맥 세팅 리허설"이 목적일 때만

## 참고 링크

- [Using iCloud with macOS virtual machines — Apple Developer](https://developer.apple.com/documentation/virtualization/using-icloud-with-macos-virtual-machines)
- [Use iCloud on a virtual machine — Apple Support](https://support.apple.com/en-us/120468)
- [Signing into Apple Account on macOS VMs — Parallels Docs](https://docs.parallels.com/pdfm-ug-26/parallels-desktop-for-mac-26-users-guide/advanced-topics/using-other-operating-systems-on-your-mac/running-macos-virtual-machines/signing-into-apple-account-on-macos-virtual-machines)
- [Sequoia, virtualisation and Apple ID — Eclectic Light](https://eclecticlight.co/2024/07/12/sequoia-virtualisation-and-apple-id/)
