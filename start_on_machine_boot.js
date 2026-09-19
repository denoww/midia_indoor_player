// ⚠️ DESCONTINUADO (19/09/2026) — modo de instalação Linux/Raspberry Pi /
// Orange Pi. Sem manutenção real desde 2023, sem evidência de nenhum device
// vivo em produção hoje. O parque atual roda no app Android `corpflix`
// (repo denoww/corpflix) ou, como frota legada ainda viva, em Windows via
// Chrome kiosk (ver README § "Config windows" — esse SIM continua em uso,
// ~30 TVs, e o Chrome dele se autoatualiza sozinho, sem ação necessária).
// Contexto completo: ROADMAP_dependencias_criticas.md item #26 (repo
// seucondominio).

// startup on boot (da lib auto-launch)
var AutoLaunch, autoLauncher;

AutoLaunch = require('auto-launch');

projectPath = process.cwd();

autoLauncher = new AutoLaunch({
  name: 'midia_indoor_player',
  path: projectPath+'/tasks/init.sh'
});

autoLauncher.enable();

autoLauncher.isEnabled().then(function(isEnabled) {
  if (isEnabled) {
    return;
  }
  autoLauncher.enable();
}).catch(function(err) {
  throw err;
});

console.log('Criado startup em ~/.config/autostart/init.sh.desktop')
