# NotchAgent Privacy Policy

Effective date: September 28, 2026

NotchAgent is a local-first macOS application. Luis Roquette, the developer,
does not operate a NotchAgent analytics, advertising, account, or telemetry
server and does not collect personal data through the app.

## Data kept on your Mac

NotchAgent stores app preferences, usage snapshots, spending entries, and
sanitized diagnostic logs in its app container. Claude Code, Claude Desktop,
and Codex transcript folders are read only after you select them in the macOS
file picker. Access is saved as a security-scoped bookmark and can be revoked
in Settings. Transcript contents are processed locally and are not sent to the
developer.

API credentials you enter are stored in the macOS Keychain. NotchAgent does
not include analytics or advertising SDKs and does not track you across apps
or websites.

## Network connections you control

Features that use the network connect directly from your Mac to the service
needed for that feature:

- Weather uses Open-Meteo and, when no city is selected, ipwho.is for a
  one-time approximate location lookup.
- Currency conversion uses the Banco Central do Brasil PTAX service. Provider
  status uses the public Claude status endpoint. Service logos may load from
  Logo.dev.
- Optional account monitors connect to the provider you choose, such as
  Anthropic, OpenAI, Google, X, xAI, ElevenLabs, Firecrawl, DeepSeek,
  OpenRouter, TwitterAPI.io, Twilio, or HeyGen. Their own privacy policies
  apply to data processed by those services.
- Optional restore emails send the recipient address and notification content
  to Resend using the API key you provide. This feature is off by default.
- NotchAgent Desk communicates with a paired device on your local network or
  over USB/serial only after you enable the relevant feature.

The Mac App Store edition never runs a paid AI quota probe. Network features
can be disabled in Settings.

## Retention and deletion

The developer has no NotchAgent server copy to retain or delete. Remove local
data by revoking folder access, removing configured accounts, or deleting the
app and its container from your Mac. Data held by a third-party service is
controlled by that service's policy and account tools.

## Contact

For privacy or support requests, open a public issue without sensitive data at
<https://github.com/luisroquette-labs/notchagent/issues>. Do not post credentials,
API keys, transcript contents, or other sensitive information in an issue.

Policy URL for App Store Connect:
<https://github.com/luisroquette-labs/notchagent/blob/master/PRIVACY.md>
