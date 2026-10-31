# Mac App Store metadata

Version: 3.7.0
Build: 24
Bundle ID: `br.com.lfrprojects.notchagent.appstore`
Primary category: Developer Tools
Secondary category: Productivity
Price: Free
App Store Connect 3.6.0 draft locale: `pt-BR`; English and Spanish copy below
is prepared locally and is not published as a separate locale.

## URLs

- Marketing: https://notchagent.app
- Support: https://notchagent.app/support
- Privacy: https://notchagent.app/privacy

## Portuguese (Brazil)

Name: `NotchAgent`
Subtitle: `Uso, ritmo e custos de IA`
Keywords: `tokens,cota,custo,limite,produtividade,notch,menu bar,monitor,IA,agentes`

Promotional text:

> Veja tokens, ritmo e custos no notch. Consulte cotas quando disponíveis e mantenha o
> controle sem anúncios, rastreamento ou conta NotchAgent.

Description:

> Acompanhe quanto de IA você está usando. O NotchAgent
> reúne o uso do Claude e do Codex em um painel nativo no notch e na barra de
> menus.
>
> • Acompanhe tokens, sessões, ritmo e estimativas de custo
> • Compare o uso por modelo e identifique picos ao longo do dia
> • Veja cotas do Codex quando a ferramenta fornece esses dados
> • Ative no guia o percentual da cota oficial do Claude Code
> • Consulte o essencial no notch ou abra o dashboard detalhado
> • Monitore contas e conecte o NotchAgent Desk, se quiser
>
> Os dados de uso são processados localmente no dispositivo. O acesso salvo às pastas do
> Claude Code, Claude Desktop e Codex é somente leitura e depende da sua
> autorização. Ao conectar Claude Code, o guia ativa a exportação da cota oficial
> em `.claude/settings.json`, preservando as demais opções. Na primeira abertura,
> o guia mostra a pasta certa para cada
> ferramenta e confirma quando encontra sessões. É preciso já ter usado uma
> dessas ferramentas neste computador para ver dados locais; contas de API são
> opcionais e configuradas à parte. Recursos online opcionais e seus destinos estão descritos na
> política de privacidade. Sem anúncios, rastreamento ou conta NotchAgent.
> A cota oficial do Claude Code aparece depois da próxima resposta do Claude Code,
> quando a conta fornece essa informação. O app não estima percentuais a partir de tokens.
>
> A edição da App Store não executa CLIs externos. As atualizações chegam pela
> própria App Store.
>
> NotchAgent é independente e não é afiliado aos provedores monitorados.

## English (U.S.)

Name: `NotchAgent`
Subtitle: `AI usage, pace, and costs`
Keywords: `tokens,quota,cost,limits,productivity,notch,menu bar,monitor,AI,agents`

Promotional text:

> See tokens, pace, and costs in the notch. Check quotas when available and stay
> in control with no ads, tracking, or NotchAgent account.

Description:

> See how much AI you are using. NotchAgent brings
> Claude and Codex usage together in a native dashboard for the notch and menu
> bar.
>
> • Track tokens, sessions, pace, and cost estimates
> • Compare usage by model and spot peaks throughout your day
> • See Codex quotas when the tool provides that data
> • Enable Claude Code's official quota percentage in guided setup
> • Check the essentials in the notch or open the detailed dashboard
> • Optionally monitor accounts and connect NotchAgent Desk
>
> Usage data is processed locally on the device. Saved read-only access to Claude Code,
> Claude Desktop, and Codex folders requires your authorization. Connecting Claude Code
> enables official quota export in `.claude/settings.json` while preserving your other options. Guided
> first-launch setup takes you to each folder and confirms when it finds
> sessions. You need to have used one of these tools on this computer to see
> local data; API accounts are optional and configured separately. Optional online
> features and their destinations are described in the privacy policy.
> No ads, tracking, or NotchAgent account.
> Claude Code's official quota appears after its next response when the account
> provides this data. The app does not infer quota percentages from tokens.
>
> The App Store edition does not run external CLIs. Updates arrive through the
> App Store.
>
> NotchAgent is independent and is not affiliated with the monitored providers.

## Review notes

NotchAgent is a menu-bar app (`LSUIElement`) and does not show a Dock icon.
After launch, click its menu-bar item or the top-center notch area.

No account is required. First-launch setup opens automatically when no folder
is authorized; click Connect for Codex or Claude Code and choose the suggested
`.codex` or `.claude` folder. Claude Desktop is optional. Each row separately
checks for readable session records. An empty or missing sessions folder shows
a specific message and Choose another folder; it does not block the app. The
same guide can be reopened from Settings or a provider card.
Connecting Claude Code adds a static `statusLine` command to the user-selected
`.claude/settings.json`. If a custom status line exists, the app asks before
replacing that one setting and preserves all other settings. Claude Code then
writes its official `rate_limits` subset to `.claude/.notchagent-quota.json` after
a response. The app itself does not run a CLI, read credentials, or make quota API
calls. If the person keeps their custom status line, the app leaves it intact.
To quit this menu-bar app, use the highlighted Encerrar/Quit button in the
notch panel or the Encerrar NotchAgent/Quit NotchAgent button in the menu-bar item.

The build is sandboxed. It does not execute `codex`, `gcloud`, Terminal,
firmware helpers, or launch agents. Paid Anthropic probe requests, Resend email
delivery, and Sparkle updates are absent from this edition. Weather starts
disabled and makes network requests only after the user enables it. Privacy and
support links are available in Settings.
Claude Code's official subscription quota is unavailable from local transcripts;
the app reads the official status-line export when configured. It never fabricates
a quota percentage from tokens. Codex quota data is shown only when present in
its session records.

NotchAgent Desk hardware is not required for review. If no device is present,
the Desk section remains in a disconnected state.

NotchAgent is independent and is not affiliated with the monitored providers.

## What's new in 3.7.0

Portuguese (Brazil):

> Agora o NotchAgent reconhece contas sem o limite de 5 horas: em vez de
> estimar uma sessão que não existe mais, ele mostra o uso semanal como medida
> principal e avisa com clareza que o seu plano não tem limite de 5 horas.
> Contas que ainda têm o limite de 5 horas continuam funcionando igual.

English (U.S.):

> NotchAgent now recognizes accounts without the 5-hour limit. Instead of
> estimating a session that no longer exists, it shows weekly usage as the
> main gauge and clearly notes that your plan has no 5-hour limit. Accounts
> that still have the 5-hour limit are unchanged.

Spanish:

> NotchAgent ahora reconoce las cuentas sin el límite de 5 horas. En lugar de
> estimar una sesión que ya no existe, muestra el uso semanal como medida
> principal y avisa con claridad que tu plan no tiene límite de 5 horas. Las
> cuentas que aún tienen el límite de 5 horas no cambian.

## What's new in 3.6.0

Portuguese (Brazil):

> A configuração inicial agora mostra quais pastas do Claude e do Codex
> autorizar. Cada conexão confirma se encontrou sessões e explica como corrigir
> pastas vazias ou incorretas. O guia também pode ser reaberto em Ajustes.
> O botão Encerrar agora aparece claramente no painel e na barra de menus.
> Ative a cota oficial do Claude Code pelo próprio guia, sem Terminal ou chave de API.

English (U.S.):

> Guided setup now shows which Claude and Codex folders to authorize. Each
> connection confirms whether sessions were found and explains how to fix an
> empty or incorrect folder. You can reopen the guide from Settings.
> Quit is now clearly available in the panel and menu bar.
> Enable Claude Code's official quota in the guide, without Terminal or an API key.

Spanish:

> La configuración guiada muestra qué carpetas de Claude y Codex autorizar.
> Cada conexión confirma si encontró sesiones y explica cómo corregir una
> carpeta vacía o incorrecta. Puedes volver a abrir la guía desde Ajustes.
> El botón para cerrar la app ahora está visible en el panel y la barra de menús.
> Activa la cuota oficial de Claude Code desde la guía, sin Terminal ni clave de API.

## App privacy answers

- Data collection: No, the developer does not collect data from this app.
- Tracking: No.
- Third-party advertising: No.
- Analytics: No.
- Privacy manifest: no collected data, no tracking; required-reason API use is
  declared for app preferences and metadata of app/user-selected files.

Reconfirm these answers against the final archived binary before submission.

## Screenshots

Final set: four opaque PNG screenshots at 2880 × 1800 in
`dist/app-store-screenshots-v17/`:

1. Claude and Codex overview with complete local data.
2. Session burn and limit projection.
3. Usage rhythm throughout the day.
4. Local token distribution by model.

Do not upload `05-dashboard.png`; it is retained only as a rejected comparison.
Do not show API keys, email addresses, file paths, account identifiers, or real
transcript content. App previews are optional.
