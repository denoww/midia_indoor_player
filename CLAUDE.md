# midia_indoor_player

App Node.js/CoffeeScript que exibe vídeos/imagens em TVs (sinalização indoor). Lê grade do ERP `seucondominio`, baixa mídia de S3 pra disco local, serve via Express na porta `:4001`, Chrome Kiosk na TV abre `http://localhost:4001?tvId=<id>`.

## Arquitetura — dual-mode

O **mesmo código** roda em dois lugares:

1. **TV (local-mode)** — Pi/PC com Chrome Kiosk. PM2 roda `server.coffee` em `localhost:4001`. `.env` tem `TV_ID=<n>` definido. Player se identifica como aquela TV específica.
2. **Cloud relay (multi-TV)** — EC2 `i-0c566e7d2cab061a0` (us-east-1d). PM2 roda o mesmo `server.coffee`, **sem `TV_ID` no `.env`**, expondo via ALB `seucondominio-web` (https:4002 + http:4001 → :4001). Atende as ~30 TVs que rodam só Chrome (sem player local) apontando pra esse host. Cache em `/var/lib/midia_indoor_player/public/<tv_id>/{videos,images,feeds}/` (~4GB).

Spike de egress 17-20h vem majoritariamente do cloud relay — TVs reiniciam, perdem cache do browser, re-baixam tudo da nuvem. Ver seção "Cache invalidation" abaixo.

## Deploy

**Não há CI/CD funcional** — os workflows `11_prod_build_image.yml` e `12_prod_restart_server.yml` estão **100% comentados**. Só `13_prod_ligar_load_balance.yml` é ativo, e ele apenas reanexa a EC2 ao ALB (não toca em código). Push em `master` não deploya nada.

### Cloud relay (i-0c566e7d2cab061a0)

Após push em `master`, deploy manual via **SSM** (sem precisar de chave SSH):

```bash
CMD=$(aws ssm send-command \
  --instance-ids i-0c566e7d2cab061a0 \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["cd /var/lib/midia_indoor_player && sudo -u ubuntu git pull && sudo -u ubuntu /home/ubuntu/.npm-global/bin/pm2 restart MIDIAINDOOR"]' \
  --query 'Command.CommandId' --output text)
sleep 8 && aws ssm get-command-invocation --instance-id i-0c566e7d2cab061a0 --command-id $CMD \
  --query '{Status:Status,Out:StandardOutputContent,Err:StandardErrorContent}' --output json
```

PM2 está no path do user `ubuntu` (`/home/ubuntu/.npm-global/bin/pm2`), não no PATH do root.

Alternativa (SSH se tiver a key `portaria_staging_ssh_pem_key`): `ssh ubuntu@52.55.231.172 "cd /var/lib/midia_indoor_player && git pull && pm2 restart MIDIAINDOOR"`.

### TVs com player local

Não há mecanismo automático. `tasks/update_daily.sh` e `tasks/update_repository.sh` estão comentados. Cada TV continua congelada na versão que estava quando rodou `tasks/install.sh`. Mudanças backwards-compatible (campos novos no payload do ERP, novos formatos de filename) **não quebram** TVs antigas — só não se beneficiam.

> Quando precisar atualizar TV local, SSH na TV → `cd /var/lib/midia_indoor_player; git pull; pm2 restart MIDIAINDOOR`. Sem automação.

## Egress / banda

Instância é multi-tenant (`scCameras,midia_indoor_player,socket-server-seucondominio,quickchart,erp_staging`) — `NetworkOut` do CloudWatch agrega todos. Baseline ~80 GB/dia, picos 200-800 GB/dia em dias de mass-restart de TVs. Custo us-east-1: $0.09/GB egress.

```bash
# Volume diário dos últimos 7 dias
aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name NetworkOut \
  --dimensions Name=InstanceId,Value=i-0c566e7d2cab061a0 \
  --start-time $(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 86400 --statistics Sum --query 'sort_by(Datapoints,&Timestamp)[*].[Timestamp,Sum]' --output text
```

## Cache invalidation — versionamento por filename

Vídeos baixados do S3 ficam em `public/<tvId>/videos/<midia_id>-v<anexo_updated_at>.<ext>`. O sufixo `-v<unix_ts>` vem do ERP (`Publicidade::Midia::Arquivo#to_frontend_obj` retorna `versao_cache: anexo_updated_at.to_i`).

Quando o admin re-uploada um arquivo, `anexo_updated_at` muda → próxima `grade.json` chega com filename novo → cloud server baixa a versão nova do S3, browser da TV vê URL nova e busca fresh. Arquivo antigo fica órfão no disco até cleanup manual.

`web.coffee` aplica `Cache-Control: max-age=31536000, immutable` apenas em arquivos cujo nome match `^.+-v\d+\.(mp4|webm|webp|jpg|jpeg|png|gif)$`. Arquivos sem versão (TVs antigas / payloads antigos do ERP) caem no `revalidateCache` (max-age=0) — backwards-compat preservado.

## Comandos úteis

| O que | Como |
|---|---|
| Logs PM2 do cloud | `aws ssm send-command ... --parameters 'commands=["tail -200 /home/ubuntu/.pm2/logs/MIDIAINDOOR-out.log"]'` |
| Tamanho do cache | `du -sh /var/lib/midia_indoor_player/public/` |
| Listar TVs ativas no relay | `ls /var/lib/midia_indoor_player/public/` (cada subdir = TV_ID) |
| Restart só | `sudo -u ubuntu /home/ubuntu/.npm-global/bin/pm2 restart MIDIAINDOOR` |

## Armadilhas

- **Log PM2 cresce sem rotação** — `MIDIAINDOOR-out.log` tem 6+GB e enche disco. Implementar `pm2 install pm2-logrotate` ou cron de truncate.
- **`restart.js` é arquivo vazio (0 bytes)** — não confiar nele.
- **Workflows 11/12 comentados** — push em master NÃO redeploy. Tem que SSM manual. Se for ativar CI, lembre que o `13` (load balance) é o único acionado pelo `10`.
