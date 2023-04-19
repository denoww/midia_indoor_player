// Generated by CoffeeScript 2.5.1
(function() {
  // Sentry.init
  //   dsn: 'https://ac78f87fac094b808180f86ad8867f61@sentry.io/1519364'
  //   integrations: [new Sentry.Integrations.Vue({Vue, attachProps: true})]

  // Sentry.configureScope (scope)->
  //   scope.setUser id: "TV_ID_#{process.env.TV_ID}_FRONTEND"

  // alert('2')
  var data, onLoaded, relogio, restartPlayerSeNecessario;

  data = {
    body: void 0,
    loaded: false,
    loading: true,
    indexConteudoSuperior: 0,
    indexConteudoMensagem: 0,
    listaConteudoSuperior: [],
    listaConteudoMensagem: [],
    online: true,
    grade: {
      data: {
        cor: 'black',
        layout: 'layout-2',
        weather: {}
      }
    }
  };

  onLoaded = function() {
    vm.loaded || (vm.loaded = gradeObj.loaded && feedsObj.loaded);
    if (vm.loaded) {
      vm.loading = false;
    }
    timelineConteudoSuperior.init();
    return timelineConteudoMensagem.init();
  };

  this.checkTv = function() {
    var error, success;
    success = (resp) => {
      data = resp.data;
      // console.log data
      return restartPlayerSeNecessario(data);
    };
    error = (resp) => {
      return console.log(resp);
    };
    return Vue.http.get('/check_tv').then(success, error);
  };

  this.gradeObj = {
    tentar: 10,
    tentativas: 0,
    get: function(onSuccess, onError) {
      var error, success;
      if (this.loading) {
        return;
      }
      this.loading = true;
      success = (resp) => {
        this.loading = false;
        this.tentativas = 0;
        this.handle(resp.data);
        if (typeof onSuccess === "function") {
          onSuccess();
        }
        this.mountWeatherData();
        this.loaded = true;
        return onLoaded();
      };
      error = (resp) => {
        this.loading = false;
        onLoaded();
        console.error('Grade:', resp);
        this.tentativas++;
        if (this.tentativas > this.tentar) {
          console.error('Grade: Não foi possível comunicar com o servidor!');
          return;
        }
        this.tentarNovamenteEm = 1000 * this.tentativas;
        console.warn(`Grade: Tentando em ${this.tentarNovamenteEm / 1000} segundos`);
        setTimeout((function() {
          return gradeObj.get();
        }), this.tentarNovamenteEm);
        return typeof onError === "function" ? onError() : void 0;
      };
      Vue.http.get('/grade').then(success, error);
    },
    handle: function(data) {
      vm.grade.data = this.data = data;
    },
    mountWeatherData: function() {
      var base, dataHoje, dia, mes;
      (base = vm.grade.data).weather || (base.weather = {});
      if (!(vm.grade.data.weather.proximos_dias || []).length) {
        return;
      }
      dataHoje = new Date();
      dia = `${dataHoje.getDate()}`.rjust(2, '0');
      mes = `${dataHoje.getMonth() + 1}`.rjust(2, '0');
      dataHoje = `${dia}/${mes}`;
      dia = vm.grade.data.weather.proximos_dias[0];
      if (dia.data === dataHoje) {
        dia = vm.grade.data.weather.proximos_dias.shift();
        vm.grade.data.weather.max = dia.max;
        vm.grade.data.weather.min = dia.min;
      }
      vm.grade.data.weather.proximos_dias = vm.grade.data.weather.proximos_dias.slice(0, 4);
    }
  };

  this.feedsObj = {
    data: {},
    tentar: 10,
    tentativas: 0,
    posicoes: ['conteudo_superior', 'conteudo_mensagem'],
    get: function(onSuccess, onError) {
      var error, success;
      if (this.loading) {
        return;
      }
      this.loading = true;
      success = (resp) => {
        this.loading = false;
        this.tentativas = 0;
        this.handle(resp.data);
        this.verificarNoticias();
        if (typeof onSuccess === "function") {
          onSuccess();
        }
        this.loaded = true;
        return onLoaded();
      };
      error = (resp) => {
        this.loading = false;
        onLoaded();
        console.error('Feeds:', resp);
        this.tentativas++;
        if (this.tentativas > this.tentar) {
          console.error('Feeds: Não foi possível comunicar com o servidor!');
          return;
        }
        this.tentarNovamenteEm = 1000 * this.tentativas;
        console.warn(`Feeds: Tentando em ${this.tentarNovamenteEm / 1000} segundos`);
        setTimeout((function() {
          return feedsObj.get();
        }), this.tentarNovamenteEm);
        return typeof onError === "function" ? onError() : void 0;
      };
      Vue.http.get('/feeds').then(success, error);
    },
    handle: function(data) {
      var base, base1, base2, base3, feed, feeds, i, j, len, len1, name, name1, posicao, ref;
      this.data = data;
      ref = this.posicoes;
      // pre-montar a estrutura dos feeds com base na grade para ser usado em verificarNoticias()
      for (i = 0, len = ref.length; i < len; i++) {
        posicao = ref[i];
        (base = vm.grade.data)[posicao] || (base[posicao] = []);
        feeds = (typeof (base1 = vm.grade.data[posicao]).select === "function" ? base1.select(function(e) {
          return e.tipo_midia === 'feed';
        }) : void 0) || [];
        for (j = 0, len1 = feeds.length; j < len1; j++) {
          feed = feeds[j];
          (base2 = this.data)[name = feed.fonte] || (base2[name] = {});
          (base3 = this.data[feed.fonte])[name1 = feed.categoria] || (base3[name1] = []);
        }
      }
    },
    verificarNoticias: function() {
      var base, base1, categoria, categorias, fonte, i, item, items, j, len, len1, noticias, posicao, ref, ref1, ref2;
      ref = this.data;
      // serve para remover feeds que nao tem noticias
      for (fonte in ref) {
        categorias = ref[fonte];
        for (categoria in categorias) {
          noticias = categorias[categoria];
          if ((noticias || []).empty()) {
            ref1 = this.posicoes;
            for (i = 0, len = ref1.length; i < len; i++) {
              posicao = ref1[i];
              if (!vm.grade.data[posicao]) {
                continue;
              }
              (base = vm.grade.data)[posicao] || (base[posicao] = []);
              items = typeof (base1 = vm.grade.data[posicao]).select === "function" ? base1.select(function(e) {
                return e.fonte === fonte && e.categoria === categoria;
              }) : void 0;
              ref2 = items || [];
              for (j = 0, len1 = ref2.length; j < len1; j++) {
                item = ref2[j];
                vm.grade.data[posicao].removeById(item.id);
              }
            }
          }
        }
      }
    }
  };

  this.timelineConteudoSuperior = {
    promessa: null,
    nextIndex: 0,
    feedIndex: {},
    playlistIndex: {},
    init: function() {
      if (!vm.loaded) {
        return;
      }
      if (this.promessa == null) {
        return this.executar();
      }
    },
    executar: function() {
      var itemAtual, segundos;
      if (this.promessa) {
        clearTimeout(this.promessa);
      }
      itemAtual = this.getNextItem();
      if (!itemAtual) {
        return console.error("@getNextItem() - itemAtual é indefinido!", itemAtual);
      }
      vm.indexConteudoSuperior = vm.listaConteudoSuperior.getIndexByField('id', itemAtual.id);
      if (vm.indexConteudoSuperior == null) {
        vm.listaConteudoSuperior.push(itemAtual);
        vm.indexConteudoSuperior = vm.listaConteudoSuperior.length - 1;
      }
      this.stopUltimoVideo();
      segundos = (itemAtual.segundos * 1000) || 5000;
      this.promessa = setTimeout(function() {
        return timelineConteudoSuperior.executar();
      }, segundos);
      if (itemAtual.is_video) {
        this.playVideo(itemAtual);
      }
    },
    playVideo: function(itemAtual) {
      this.ultimoVideo = `video-player-${itemAtual.id}`;
      setTimeout(() => {
        var video;
        video = document.getElementById(this.ultimoVideo);
        if (video) {
          video.currentTime = 0;
          return video.play();
        }
      });
      setTimeout(() => {
        var video;
        video = document.getElementById(this.ultimoVideo);
        if (video != null ? video.paused : void 0) {
          return video.play();
        }
      }, 1000);
    },
    stopUltimoVideo: function() {
      var video, videoId;
      videoId = this.ultimoVideo;
      if (!videoId) {
        return;
      }
      video = document.getElementById(videoId);
      if (video) {
        video.pause();
      }
      this.ultimoVideo = null;
    },
    getNextItem: function() {
      var currentItem, index, lista, total;
      lista = vm.grade.data.conteudo_superior || [];
      total = lista.length;
      if (!total) {
        return console.warn("vm.grade.data.conteudo_superior está vazio!", lista);
      }
      index = this.nextIndex;
      if (index >= total) {
        index = 0;
      }
      this.nextIndex++;
      if (this.nextIndex >= total) {
        this.nextIndex = 0;
      }
      currentItem = lista[index];
      switch (currentItem.tipo_midia) {
        case 'feed':
          return this.getItemFeed(currentItem);
        case 'playlist':
          return this.getItemPlaylist(currentItem);
        default:
          return currentItem;
      }
    },
    getItemFeed: function(currentItem) {
      var base, categ, feed, feedItems, fonte, index, ref;
      feedItems = ((ref = feedsObj.data[currentItem.fonte]) != null ? ref[currentItem.categoria] : void 0) || [];
      if (feedItems.empty()) {
        console.warn(`Feeds de ${currentItem.fonte} ${currentItem.categoria} está vazio`);
        timelineConteudoSuperior.promessa = setTimeout(function() {
          return timelineConteudoSuperior.executar();
        }, 2000);
        return;
      }
      fonte = currentItem.fonte;
      categ = currentItem.categoria;
      (base = this.feedIndex)[fonte] || (base[fonte] = {});
      if (this.feedIndex[fonte][categ] == null) {
        this.feedIndex[fonte][categ] = 0;
      } else {
        this.feedIndex[fonte][categ]++;
      }
      if (this.feedIndex[fonte][categ] >= feedItems.length) {
        this.feedIndex[fonte][categ] = 0;
      }
      index = this.feedIndex[fonte][categ];
      feed = feedItems[index] || feedItems[0];
      if (!feed) {
        return;
      }
      currentItem.id = `${currentItem.id}${feed.nome_arquivo}`;
      currentItem.data = feed.data;
      currentItem.qrcode = feed.qrcode;
      currentItem.titulo = feed.titulo;
      currentItem.titulo_feed = feed.titulo_feed;
      currentItem.categoria_feed = feed.categoria_feed;
      currentItem.nome_arquivo = feed.nome_arquivo;
      return currentItem;
    },
    getItemPlaylist: function(playlist) {
      var currentItem;
      if (this.playlistIndex[playlist.id] == null) {
        this.playlistIndex[playlist.id] = 0;
      } else {
        this.playlistIndex[playlist.id]++;
      }
      if (this.playlistIndex[playlist.id] >= playlist.conteudo_superior.length) {
        this.playlistIndex[playlist.id] = 0;
      }
      currentItem = playlist.conteudo_superior[this.playlistIndex[playlist.id]];
      if (currentItem.tipo_midia !== 'feed') {
        return currentItem;
      }
      return this.getItemFeed(currentItem);
    }
  };

  this.timelineConteudoMensagem = {
    promessa: null,
    nextIndex: 0,
    playlistIndex: {},
    init: function() {
      if (!vm.loaded) {
        return;
      }
      if (this.promessa == null) {
        return this.executar();
      }
    },
    executar: function() {
      var itemAtual, segundos;
      if (this.promessa) {
        clearTimeout(this.promessa);
      }
      itemAtual = this.getNextItem();
      if (!itemAtual) {
        return;
      }
      vm.indexConteudoMensagem = vm.listaConteudoMensagem.getIndexByField('id', itemAtual.id);
      if (vm.indexConteudoMensagem == null) {
        vm.listaConteudoMensagem.push(itemAtual);
        vm.indexConteudoMensagem = vm.listaConteudoMensagem.length - 1;
      }
      segundos = (itemAtual.segundos * 1000) || 5000;
      this.promessa = setTimeout(function() {
        return timelineConteudoMensagem.executar();
      }, segundos);
    },
    getNextItem: function() {
      var currentItem, index, lista, total;
      lista = vm.grade.data.conteudo_mensagem || [];
      total = lista.length;
      if (!total) {
        return;
      }
      index = this.nextIndex;
      if (index >= total) {
        index = 0;
      }
      this.nextIndex++;
      if (this.nextIndex >= total) {
        this.nextIndex = 0;
      }
      currentItem = lista[index];
      switch (currentItem.tipo_midia) {
        case 'feed':
          return this.getItemFeed(currentItem);
        default:
          return currentItem;
      }
    },
    getItemFeed: function(currentItem) {
      var feed, feedItems, index, ref;
      feedItems = ((ref = feedsObj.data[currentItem.fonte]) != null ? ref[currentItem.categoria] : void 0) || [];
      if (feedItems.empty()) {
        return currentItem;
      }
      index = parseInt(Math.random() * 100) % feedItems.length;
      feed = feedItems[index] || feedItems[0];
      if (!feed) {
        return;
      }
      currentItem.id = `${currentItem.id}${feed.titulo}`;
      currentItem.data = feed.data;
      currentItem.qrcode = feed.qrcode;
      currentItem.titulo = feed.titulo;
      currentItem.titulo_feed = feed.titulo_feed;
      currentItem.categoria_feed = feed.categoria_feed;
      return currentItem;
    }
  };

  relogio = {
    exec: function() {
      var hour, min, now;
      // now = new Date
      now = moment();
      if (now.isDST()) {
        now.add(-1, 'hour');
      }
      hour = now.get('hour');
      min = now.get('minute');
      if (hour < 10) {
        // sec  = now.getSeconds()
        hour = `0${hour}`;
      }
      if (min < 10) {
        min = `0${min}`;
      }
      // sec  = "0#{sec}"  if sec < 10
      this.elemHora || (this.elemHora = document.getElementById('hora'));
      if (this.elemHora) {
        this.elemHora.innerHTML = hour + ':' + min;
      }
      this.timer = setTimeout(relogio.exec, 1000 * 60); // 1 minuto
    }
  };

  // @elemHora.innerHTML = hour + ':' + min + ':' + sec if @elemHora
  // setTimeout relogio.exec, 1000
  this.vm = new Vue({
    el: '#main-player',
    data: data,
    methods: {
      playVideo: timelineConteudoSuperior.playVideo,
      mouse: function() {
        if (this.mouseTimeout) {
          clearTimeout(this.mouseTimeout);
        }
        this.body || (this.body = document.getElementById('body-player'));
        this.body.style.cursor = 'default';
        return this.mouseTimeout = setTimeout(() => {
          return this.body.style.cursor = 'none';
        }, 1000);
      }
    },
    computed: {
      now: function() {
        return Date.now();
      }
    },
    mounted: function() {
      var updateOnlineStatus;
      this.loading = true;
      this.mouse();
      relogio.exec();
      updateOnlineStatus = function() {
        return vm.online = navigator.onLine;
      };
      setInterval(function() {
        // return if vm.loaded
        return checkTv();
      }, 1000 * 3); // 1 segundo
      setTimeout(function() {
        if (vm.loaded) {
          return;
        }
        updateOnlineStatus();
        return gradeObj.get(function() {
          return feedsObj.get(function() {
            vm.loading = false;
            return vm.loaded = true;
          });
        });
      }, 1000 * 1); // 1 segundo
      setInterval(function() {
        updateOnlineStatus();
        return gradeObj.get(function() {
          return feedsObj.get(function() {
            vm.loading = false;
            return vm.loaded = true;
          });
        });
      }, 1000 * 60 * 2); // a cada 2 minutos
      window.addEventListener('online', updateOnlineStatus);
      window.addEventListener('offline', updateOnlineStatus);
    }
  });

  Vue.filter('formatDayMonth', function(value) {
    if (value) {
      return moment(value).format('DD MMM');
    }
  });

  Vue.filter('formatDate', function(value) {
    if (value) {
      return moment(value).format('DD/MM/YYYY');
    }
  });

  Vue.filter('formatDateTime', function(value) {
    if (value) {
      return moment(value).format('DD/MM/YYYY HH:mm');
    }
  });

  Vue.filter('formatWeek', function(value) {
    if (value) {
      return moment(value).format('dddd');
    }
  });

  Vue.filter('currency', function(value) {
    return (value || 0).toLocaleString('pt-Br', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    });
  });

  restartPlayerSeNecessario = function(data) {
    var _exec, xSegundos;
    xSegundos = data.restart_player_em_x_segundos;
    if (!xSegundos) {
      return;
    }
    console.log(`restart_player será executado em ${xSegundos} segundos`);
    _exec = function() {
      return window.location.reload();
    };
    return setTimeout(() => {
      return _exec();
    }, xSegundos * 1000);
  };

  // @timers = []
// @timers.push = setTimeout => @exec(), 2000

}).call(this);
