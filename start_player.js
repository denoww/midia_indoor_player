console.log("-----------------------------------------------------------------");
require('coffeescript').register();
require('./env');

if(!ENV.TV_ID){
  console.log("ENV.TV_ID vazio, portanto não vai abrir o player");
  return
}else {

  console.log("Abrindo player...");

  require('coffeescript').register();
  shell = require("child_process").exec;

  fullscreen = ENV.fullscreen == 'true' || ENV.fullscreen == true

  url = "http://localhost:"+ENV.HTTP_PORT+"?tvId="+ENV.TV_ID
  if(fullscreen){
    cmd = "chromium-browser -kiosk "+url
  }else{
    cmd = "chromium-browser "+url
  }

  shell(cmd);
}
console.log("-----------------------------------------------------------------");

