# Mac App Store metadata

Version: 3.5.5
Build: 13
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
Subtitle: `Uso de IA, claro no notch`
Keywords: `IA,Claude,Codex,tokens,cotas,custos,produtividade,notch,menu bar,desenvolvedor`

Promotional text:

> Acompanhe tokens, cotas, ritmo e custos de IA em uma interface nativa que
> vive discretamente no notch e na barra de menus do Mac.

Description:

> NotchAgent transforma o notch do Mac em um painel local de uso de IA.
> Autorize suas pastas do Claude Code, Claude Desktop e Codex para visualizar
> atividade, consumo de tokens, janelas de cota, ritmo e estimativas de custo.
>
> • Processamento local e acesso somente leitura às pastas escolhidas
> • Painel compacto no notch e visão detalhada sob demanda
> • Alertas de limite, histórico e projeções de consumo
> • Monitoramento opcional de contas e serviços configurados por você
> • Integração opcional com NotchAgent Desk por rede local ou USB
>
> Sem anúncios, rastreamento ou conta NotchAgent. A edição da App Store não
> executa CLIs externos, não usa Sparkle e recebe atualizações pela App Store.

## English (U.S.)

Name: `NotchAgent`
Subtitle: `AI usage at a glance`
Keywords: `AI,Claude,Codex,tokens,quota,costs,productivity,notch,menu bar,developer`

Promotional text:

> Track AI tokens, quota, pace, and cost in a native interface that stays out
> of the way in your Mac's notch and menu bar.

Description:

> NotchAgent turns your Mac's notch into a local AI usage dashboard. Grant
> read-only access to your Claude Code, Claude Desktop, and Codex folders to
> see activity, token usage, quota windows, pace, and cost estimates.
>
> • Local processing with read-only access to folders you choose
> • Compact notch status and an on-demand detailed dashboard
> • Limit alerts, history, and usage projections
> • Optional monitoring for accounts and services you configure
> • Optional NotchAgent Desk integration over local network or USB
>
> No ads, tracking, or NotchAgent account. The App Store edition does not run
> external CLIs, does not use Sparkle, and receives updates from the App Store.

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

Prepare at least one, preferably five, opaque PNG screenshots at 2880 × 1800:

1. Expanded notch dashboard with Claude and Codex cards.
2. Session rhythm and model breakdown.
3. Spending and subscription dashboard.
4. Read-only folder authorization in Settings.
5. Compact notch state and a quota alert.

Do not show API keys, email addresses, file paths, account identifiers, or real
transcript content. App previews are optional.
