console.log("-----------------------------------------------------------------");
console.log("Abrindo player...");
console.log("-----------------------------------------------------------------");

require('coffeescript').register();
require('./env');
shell = require("child_process").exec;

fullscreen = ENV.fullscreen == 'true' || ENV.fullscreen == true

url = "http://localhost:4001?tvId="+ENV.TV_ID
if(fullscreen){
  cmd = "chromium-browser -kiosk "+url
}else{
  cmd = "chromium-browser "+url
}

shell(cmd);
console.log("-----------------------------------------------------------------");

