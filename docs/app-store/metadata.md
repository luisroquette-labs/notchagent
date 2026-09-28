# Mac App Store metadata

Version: 3.5.5
Build: 16
Bundle ID: `br.com.lfrprojects.notchagent.appstore`
Primary category: Developer Tools
Secondary category: Productivity
Price: Free

## URLs

- Marketing: https://notchagent.app
- Support: https://github.com/luisroquette/notchagent/issues
- Privacy: https://github.com/luisroquette/notchagent/blob/master/PRIVACY.md

## Portuguese (Brazil)

Name: `NotchAgent`
Subtitle: `Uso de IA no seu Mac`
Keywords: `Claude,Codex,tokens,cota,custo,limite,produtividade,notch,menu bar,monitor,LLM`

Promotional text:

> Veja Claude e Codex no notch. Antecipe limites, entenda tokens, ritmo e
> custos e mantenha seus dados locais — sem anúncios, rastreamento ou conta.

Description:

> Saiba quanto de IA você está usando antes de atingir o limite. O NotchAgent
> reúne Claude e Codex em um painel nativo no notch e na barra de menus do Mac.
>
> • Acompanhe tokens, sessões, cotas, ritmo e estimativas de custo
> • Compare o uso por modelo e identifique picos ao longo do dia
> • Antecipe limites com histórico e projeções de consumo
> • Consulte o essencial no notch ou abra o dashboard detalhado
> • Monitore contas e conecte o NotchAgent Desk, se quiser
>
> Seus dados continuam no Mac. O acesso às pastas do Claude Code, Claude
> Desktop e Codex é somente leitura e depende da sua autorização. Sem anúncios,
> rastreamento ou conta NotchAgent.
>
> A edição da App Store não executa CLIs externos. As atualizações chegam pela
> própria App Store.

## English (U.S.)

Name: `NotchAgent`
Subtitle: `AI usage on your Mac`
Keywords: `Claude,Codex,tokens,quota,cost,limits,productivity,notch,menu bar,monitor,LLM`

Promotional text:

> See Claude and Codex in your notch. Anticipate limits, understand tokens,
> pace, and costs, and keep your data local — with no ads, tracking, or account.

Description:

> Know how much AI you are using before you hit a limit. NotchAgent brings
> Claude and Codex together in a native dashboard for your Mac's notch and
> menu bar.
>
> • Track tokens, sessions, quotas, pace, and cost estimates
> • Compare usage by model and spot peaks throughout your day
> • Anticipate limits with history and consumption projections
> • Check the essentials in the notch or open the detailed dashboard
> • Optionally monitor accounts and connect NotchAgent Desk
>
> Your data stays on your Mac. Read-only access to Claude Code, Claude Desktop,
> and Codex folders requires your authorization. No ads, tracking, or
> NotchAgent account.
>
> The App Store edition does not run external CLIs. Updates arrive through the
> App Store.

## Review notes

NotchAgent is a menu-bar app (`LSUIElement`) and does not show a Dock icon.
After launch, click its menu-bar item or the top-center notch area.

No account is required. To test local usage, open Settings > Data folders and
choose any of these folders if present: `.claude`, `Claude`, or `.codex`.
The picker validates the folder name and grants read-only access. Empty or
missing folders produce an explicit no-data state and do not block the rest of
the interface.

The build is sandboxed. It does not execute `codex`, `gcloud`, Terminal,
firmware helpers, or launch agents. Paid Anthropic probe requests and Sparkle
updates are disabled in this edition. Optional account monitors, weather,
email, and Desk features are visible and opt-in/configurable in Settings.

NotchAgent Desk hardware is not required for review. If no device is present,
the Desk section remains in a disconnected state.

## App privacy answers

- Data collection: No, the developer does not collect data from this app.
- Tracking: No.
- Third-party advertising: No.
- Analytics: No.
- Privacy manifest: no collected data, no tracking; required-reason API use is
  declared for app preferences and metadata of app/user-selected files.

Reconfirm these answers against the final archived binary before submission.

## Screenshots

Final set: five opaque PNG screenshots at 2880 × 1800 in
`dist/app-store-screenshots-polished/`:

1. Cost and decision dashboard — strongest first benefit.
2. Claude and Codex overview in the notch.
3. Token distribution by model.
4. Usage rhythm throughout the day.
5. Session burn and limit projection.

Do not show API keys, email addresses, file paths, account identifiers, or real
transcript content. App previews are optional.
