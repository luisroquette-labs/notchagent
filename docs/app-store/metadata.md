# Mac App Store metadata

Version: 3.5.5
Build: 22
Bundle ID: `br.com.lfrprojects.notchagent.appstore`
Primary category: Developer Tools
Secondary category: Productivity
Price: Free

## URLs

- Marketing: https://notchagent.app
- Support: https://notchagent.app/support
- Privacy: https://notchagent.app/privacy

## Portuguese (Brazil)

Name: `NotchAgent`
Subtitle: `Cotas, ritmo e custos de IA`
Keywords: `tokens,cota,custo,limite,produtividade,notch,menu bar,monitor,IA,agentes`

Promotional text:

> Veja cotas, tokens, ritmo e custos no notch. Antecipe limites e mantenha o
> controle sem anúncios, rastreamento ou conta NotchAgent.

Description:

> Saiba quanto de IA você está usando antes de atingir o limite. O NotchAgent
> reúne o uso do Claude e do Codex em um painel nativo no notch e na barra de
> menus.
>
> • Acompanhe tokens, sessões, cotas, ritmo e estimativas de custo
> • Compare o uso por modelo e identifique picos ao longo do dia
> • Antecipe limites com histórico e projeções de consumo
> • Consulte o essencial no notch ou abra o dashboard detalhado
> • Monitore contas e conecte o NotchAgent Desk, se quiser
>
> Os dados de uso são processados localmente no dispositivo. O acesso às pastas do
> Claude Code, Claude Desktop e Codex é somente leitura e depende da sua
> autorização. Recursos online opcionais e seus destinos estão descritos na
> política de privacidade. Sem anúncios, rastreamento ou conta NotchAgent.
>
> A edição da App Store não executa CLIs externos. As atualizações chegam pela
> própria App Store.
>
> NotchAgent é independente e não é afiliado aos provedores monitorados.

## English (U.S.)

Name: `NotchAgent`
Subtitle: `AI quotas, pace, and costs`
Keywords: `tokens,quota,cost,limits,productivity,notch,menu bar,monitor,AI,agents`

Promotional text:

> See quotas, tokens, pace, and costs in the notch. Anticipate limits and stay
> in control with no ads, tracking, or NotchAgent account.

Description:

> Know how much AI you are using before you hit a limit. NotchAgent brings
> Claude and Codex usage together in a native dashboard for the notch and menu
> bar.
>
> • Track tokens, sessions, quotas, pace, and cost estimates
> • Compare usage by model and spot peaks throughout your day
> • Anticipate limits with history and consumption projections
> • Check the essentials in the notch or open the detailed dashboard
> • Optionally monitor accounts and connect NotchAgent Desk
>
> Usage data is processed locally on the device. Read-only access to Claude Code,
> Claude Desktop, and Codex folders requires your authorization. Optional
> online features and their destinations are described in the privacy policy.
> No ads, tracking, or NotchAgent account.
>
> The App Store edition does not run external CLIs. Updates arrive through the
> App Store.
>
> NotchAgent is independent and is not affiliated with the monitored providers.

## Review notes

NotchAgent is a menu-bar app (`LSUIElement`) and does not show a Dock icon.
After launch, click its menu-bar item or the top-center notch area.

No account is required. To test local usage, open Settings > Data folders and
choose a `.claude`, `Claude`, or `.codex` folder if present. The picker validates
the folder name and grants read-only access. Empty or missing folders produce a
no-data state and do not block the rest of the interface.

The build is sandboxed. It does not execute `codex`, `gcloud`, Terminal,
firmware helpers, or launch agents. Paid Anthropic probe requests, Resend email
delivery, and Sparkle updates are absent from this edition. Weather starts
disabled and makes network requests only after the user enables it. Privacy and
support links are available in Settings.

NotchAgent Desk hardware is not required for review. If no device is present,
the Desk section remains in a disconnected state.

NotchAgent is independent and is not affiliated with the monitored providers.

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
