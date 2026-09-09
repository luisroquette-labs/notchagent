# Handoff — troca de Claude Code pra Codex, 09/09/2026

Sessão anterior ficou sem crédito no meio de um brainstorm. Nada foi
perdido: trabalho concluído está commitado em branch; o brainstorm em
andamento está documentado em detalhe. Leia este arquivo primeiro.

## Linha do tempo desta sessão (resumida)

1. Usuário plugou a NotchAgent Desk (ESP32-S3) no Mac, tela sem dados.
2. Causa raiz real, achada só depois de muita investigação: firmware físico
   roda `1.0.0-alpha.1` (dogfooding), e o app rejeitava qualquer versão de
   firmware com sufixo de pre-release por causa de um regex estrito
   (`wholeMatch` em `N.N.N`). **Corrigido, testado, commitado.**
3. No caminho, mais 3 problemas reais foram achados e corrigidos (não eram
   o pedido original, mas bloqueavam a validação):
   - Watchdog de crash-recovery (`SMAppService.agent`) usava `open -b` como
     proxy — o launchd rastreava o processo errado. Trocado pra
     `BundleProgram`.
   - Registrar esse watchdog sem desregistrar o login item antigo
     (`SMAppService.mainApp`) duplicava o lançamento a cada login. Corrigido.
   - SDK .NET do protocolo (`NotchAgent-Desk/sdk/dotnet`) tinha
     `DeskProtocolContract.Minor` travado em `1` enquanto o protocolo real
     é `1.3`. Corrigido no outro repo.
4. Nesse mesmo mergulho, foi criada do zero uma bridge USB da Desk pro
   Windows (não existia nenhum código lá — só o codec do protocolo, nunca
   plugado no app).
5. Usuário perguntou sobre a Desk funcionar "só na bateria" — depois de
   esclarecer (via perguntas diretas) que o pedido real é "sem cabo, Mac
   ligado na rede local", entrei no fluxo `superpowers:brainstorming` pra
   desenhar isso. **Parado no meio da apresentação da Seção 1 (arquitetura
   geral) quando os créditos acabaram.**

## Estado do código — tudo commitado, nada perdido

**Repo `NotchAgent`** (`/Users/luisroquette/Projects/NotchAgent`)
Branch: `feat/desk-watchdog-windows-bridge-and-firmware-regex-fix`
Commit: `4610f11`
Base: `master` (branch criada a partir dele, master não foi tocado)

O que tem nesse commit:
- Fix do regex de firmware (`NotchAgentDeskBridge.swift`) + teste de
  regressão que reproduz o bug antes do fix.
- `DeskWatchdog.swift` (crash-recovery) + fix do `BundleProgram` + fix do
  double-login-item em `SystemIntegration.swift`.
- `DeskOnboardingDecision.swift` (lógica pura extraída, testável) +
  notificação com botão de 1 toque em vez de abrir Settings sozinho.
- `Scripts/make-app.sh` atualizado pra empacotar o LaunchAgent no bundle
  (senão o watchdog nunca ia junto no app final).
- Bridge Windows completa do zero (`windows/NotchAgent.Windows/Desk/`):
  handshake, reconexão, filtro VID/PID via WMI, snapshot factory (só NOW
  real — BURN/RHYTHM/MODELS vazios, gap pré-existente do Windows, não
  novo), janela de consentimento Avalonia, seam `IDeskPort`/`FakeDeskPort`
  pra testar sem hardware.

Testes: `swift test` → **584/584 verde** (era 579 antes desta sessão).
`.NET` (`windows/NotchAgent.Windows.Tests`) → **10/10 verde**.

**Repo `NotchAgent-Desk`** (`/Users/luisroquette/Projects/NotchAgent-Desk`)
Branch: `fix/dotnet-protocol-minor-version-drift`
Commit: `bca8a5b`
Base: `main`

Fix do `DeskProtocolContract.Minor` (1→3) + teste de regressão.
`.NET` (`sdk/dotnet/NotchAgent.Desk.Protocol.Tests`) → **4/4 verde**.

**Nada foi dado push.** Branches só existem localmente. PRs não foram
abertos — decisão explícita de não commitar/dar push sem pedido do
usuário; ele só pediu pra continuar, ainda não pediu merge.

## Pendências reais (não são bugs, são verificações que faltam)

1. **Teste de crash ao vivo do watchdog ficou inconclusivo.** `sfltool
   dumpbtm` mostra o job `enabled`, mas `launchctl print`/`kickstart`
   reportam "not found" — pode precisar de um logout/login real pra o
   launchd assumir o processo. Não confirmado. Peça pro usuário fazer:
   `kill -9 $(pgrep -x NotchAgent)` → deve voltar sozinho; depois clicar
   "Sair" no menu → não deve voltar. Se não voltar depois de um
   logout/login de verdade, é bug real, investigar de novo.
2. **App instalado em `/Applications/NotchAgent.app` já tem o fix** (foi
   rebuilded e reinstalado ao vivo durante a sessão) — mas o binário ali
   não é o mesmo que está no commit até você rodar
   `./Scripts/make-app.sh` de novo a partir da branch acima, caso precise
   reconstruir.
3. **Windows: só compile-verified**, nunca rodou em hardware físico
   (limitação antiga do projeto, documentada, não nova).
4. **Cross-repo dependency**: `windows/NotchAgent.Windows/Desk/Protocol/DeskFrameCodec.cs`
   foi vendorado (copiado) do repo `NotchAgent-Desk` em vez de referência
   de projeto cross-repo (que quebrava CI). Precisa virar pacote NuGet de
   verdade eventualmente — está marcado com comentário `ponytail:` no
   próprio arquivo.

## Brainstorm em andamento — Desk sem cabo (WiFi)

Spec parcial, com todas as decisões já travadas nas perguntas ao usuário,
e a lista exata do que falta desenhar:
`docs/superpowers/specs/2026-09-09-desk-wifi-autonomy-design.md`

**Não implementar nada disso ainda** — o usuário só viu e não confirmou a
Seção 1 (arquitetura). Retome perguntando se a Seção 1 está certa, depois
siga pras seções 2–7 listadas no arquivo, uma de cada vez, seguindo o
fluxo da skill `superpowers:brainstorming` (pergunta → design → doc → plano
via `superpowers:writing-plans`).

## Instrução direta pro Codex (ou pra você, se for outra sessão Claude)

1. Leia este arquivo inteiro primeiro.
2. Leia `docs/superpowers/specs/2026-09-09-desk-wifi-autonomy-design.md`.
3. Rode `swift test` e `dotnet test` (paths de dotnet-8 dev em
   `~/Library/Application Support/NotchAgent/dotnet-8`) pra confirmar que
   nada quebrou desde o commit `4610f11` antes de continuar.
4. Retome o brainstorm exatamente de onde parou: confirme a Seção 1 com o
   usuário, depois desenhe as seções 2–7 na ordem listada no spec.
5. Memória do projeto já tem os achados técnicos registrados —
   `project-notchagent` (busque por essa memória se tiver acesso ao
   sistema de memória; se não tiver, este arquivo + o spec cobrem o
   essencial).
