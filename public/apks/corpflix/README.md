# Canal de distribuição — Corpflix

Diretório que serve o APK do app Corpflix para o parque de Android TVs em
condomínios via HTTP estático do `midia_indoor_player`.

## Por que existe

As TVs do parque rodam **sem conta Google logada** (decisão deliberada — ver
`CLAUDE.md` do repo `corpflix`), então a Play Store não consegue atualizar
nada nelas. Antes deste canal, a única forma de atualizar era ADB local —
inviável para o parque Brasil-todo (cada condomínio em uma rede diferente).

Aqui ficam:

1. `update.json` — manifesto consultado pelo updater dentro do app. Contém
   `versionCode`, URL do APK, SHA-256, percentual de rollout.
2. `corpflix-X.Y.ZZ.apk` — o binário em si (não versionado no Git, ver
   `.gitignore` da raiz). Subido via `scp` pelo script de deploy do
   `corpflix`.

## URL pública

```
https://<host-do-midia-indoor>/apks/corpflix/update.json
https://<host-do-midia-indoor>/apks/corpflix/corpflix-<versionName>.apk
```

A pasta `public/` é servida como estática pelo Express
(`app/servers/web.coffee`, linha do `app.use express.static('../../public/')`)
com `Cache-Control: public, max-age=0, must-revalidate` — bom para o JSON,
seguro para o APK (que muda de nome a cada release).

## Como publicar uma release

No repo `corpflix`:

```bash
./scripts/upload_apk_to_midia.sh
```

O script:

1. Faz build release do APK.
2. Calcula SHA-256.
3. `scp` do APK para `/var/lib/midia_indoor_player/public/apks/corpflix/`
   em todas as EC2s com tag `midia_indoor_player`.
4. Reescreve `update.json` (commit + push neste repo, depois `git pull` na EC2).

## Esquema do `update.json`

| Campo | Tipo | Função |
|---|---|---|
| `versionCode` | int | Comparado com `BuildConfig.VERSION_CODE` do app. Maior = update disponível. |
| `versionName` | string | Apenas display ("3.2.10"). |
| `url` | string | URL absoluta do APK. |
| `sha256` | string | Hash hex lowercase do APK. App valida antes de instalar. |
| `minVersionCode` | int | Versão mínima que pode receber este update. Para força usuários muito antigos a passar por uma release intermediária. |
| `rolloutPercent` | int (0–100) | Canário. App calcula `hash(deviceId) % 100 < rolloutPercent` e só atualiza se passar. |
| `releaseNotes` | string | Texto livre, opcional, para logs. |
| `publishedAt` | ISO 8601 | Timestamp da publicação, opcional. |

## Convivência com Play Store

A Play Store **continua sendo** um canal válido — o app permanece publicado
lá para alguns modelos de TV mais "limpos" e para testadores. O canal
`midia_indoor` é o **canal de produção do parque sideloaded**.
