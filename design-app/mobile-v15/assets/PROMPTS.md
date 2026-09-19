# Imagens e identidade — Radar V15

## Procedência

Duas ilustrações raster geradas do zero com a ferramenta integrada de geração
de imagens, sem imagens de referência, sem assets de outros protótipos e sem
tratamento posterior do conteúdo. Não são fotos de produtos do catálogo.

O logo, os ícones de interface, estados vetoriais e animações SVG são desenhos
nativos em código, separados das ilustrações raster. PNGs do ícone são exports
dos SVGs locais por renderização do navegador, não novas gerações.

## Descoberta

Arquivo: [illustrations/descoberta.png](illustrations/descoberta.png).
Uso: acesso ao aplicativo e apresentação da identidade.

Brief enviado:

> Use case: stylized-concept. Asset type: mobile app sign-in editorial illustration, square raster artwork. Create a brand-new premium crafted still life for Radar, a Brazilian app for discovering and tracking store prices, cashback and reward points. No reference images. Subject: one sculptural orange-red price ticket, thick matte ceramic with a single circular punched hole, leaning against a large frosted smoked-glass magnifying lens; beside it a small stack of two cream circular reward tokens, completely blank. A tiny terracotta sphere and one slim graphite horizontal price strip on the ground complete an intentional asymmetric composition. Objects tactile, finely grained ceramic, charcoal translucent glass, subtle paperlike ground. Art-directed studio product photography blended with clean 3D illustration, mature refined approachable, sculptural not cute. Warm pale off-white background #f5f3ef, soft directional daylight, real contact shadows, color palette burnt orange #c24f26 and soft apricot, charcoal #29282b and ivory. Objects centered within the middle 65% of the square, generous plain margins for cropping. No text, no currency symbols, no numbers, no logos, no lettering, no phone frame, no UI, no gradients in background, no teal, blue or purple. Excellent smooth edges and realistic light, premium shopping discovery identity. 1024 square.

## Acompanhamento

Arquivo: [illustrations/acompanhamentos.png](illustrations/acompanhamentos.png).
Uso: lista pessoal vazia e convite opcional para receber avisos.

Brief enviado:

> Use case: stylized-concept. Asset type: single square editorial illustration for the empty saved-watchlist screen of Radar, a mobile price tracking and shopping rewards app. Create a new tactile premium still life, completely new composition, no references. A softly rounded graphite desk tray contains one cream sculptural blank price tag, with a subtle orange-red loop through its punched round hole. A small burnt-orange ceramic bell beside the tray represents future price alerts. Three objects only, carefully composed with generous quiet negative space occupying top third. Matte ceramics, fine paper grain and satin charcoal finish; warm white seamless background #f5f3ef with soft studio light and realistic contact shadow. Main palette terracotta #c24f26, warm ivory, graphite #29282b. Sophisticated approachable editorial product photography/3D, no cartoon faces, no cute mascots. No text, currency symbols, letters, numbers, logo, UI, phone frame or watermark. Entire isolated still life fits inside middle 60 percent with very generous margins. Square 1024.

## Vetores e exports

| Arquivo | Uso |
|---|---|
| `brand/symbol.svg` | Símbolo para superfícies claras. |
| `brand/symbol-dark.svg` | Símbolo para superfícies escuras. |
| `brand/wordmark.svg` | Assinatura horizontal; texto usa Manrope, incluída em fonts. |
| `brand/app-icon.svg` | Prévia com cantos arredondados. |
| `brand/app-icon-{48,192,512,1024}.png` | Exports raster da prévia. |
| `brand/ios-icon.svg`, `brand/ios-icon-1024.png` | Arte quadrada para máscara da plataforma. |
| `brand/android-background.svg` | Cor sólida da camada de fundo. |
| `brand/android-foreground.svg` | Símbolo com margem interna para ícone adaptativo. |
| `brand/notification.svg` | Silhueta monocromática para notificação. |
| `illustrations/no-results.svg` | Busca sem resultados. |
| `illustrations/offline.svg` | Indisponibilidade. |
| `motion/abertura.svg` | Composição animada, independente do navegador do app. |
| `motion/confirmacao.svg` | Traço animado de confirmação. |

Os SVGs Android são fontes visuais, não XML VectorDrawable pronto para Gradle.
A integração futura deve gerar recursos nativos e conferir máscaras no aparelho.
Os PNGs podem ser regenerados por `node review/export-assets.mjs`, com o servidor
e o Chrome de revisão descritos no README.

Manrope veio do repositório público Google Fonts, família `ofl/manrope`.
A licença original acompanha a fonte em [fonts/OFL.txt](fonts/OFL.txt).
