//@ sourceMappingURL=songlocator-api.map
// Generated by CoffeeScript 1.6.1
var ResolverSet, Server, parseArguments, readConfigSync, v4, _ref,
  __slice = [].slice;

Server = require('ws').Server;

v4 = require('node-uuid').v4;

ResolverSet = require('songlocator-base').ResolverSet;

_ref = require('songlocator-cli'), readConfigSync = _ref.readConfigSync, parseArguments = _ref.parseArguments;

exports.SongLocatorServer = (function() {

  function SongLocatorServer(config) {
    this.config = config;
    this.server = void 0;
  }

  SongLocatorServer.prototype.log = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return console.log.apply(console, args);
  };

  SongLocatorServer.prototype.debug = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    if (this.config.debug != null) {
      return this.log.apply(this, args);
    }
  };

  SongLocatorServer.prototype.serve = function() {
    var _this = this;
    this.server = new Server({
      port: this.config.port || 3000
    });
    this.server.on('connection', function(sock) {
      var cfg, name, resolver, resolverCls, resolvers, send;
      _this.debug('got new connection');
      send = function(msg) {
        _this.debug('response', {
          qid: msg.qid,
          length: msg.results.length
        });
        return sock.send(JSON.stringify(msg));
      };
      resolvers = (function() {
        var _ref1, _results;
        _ref1 = this.config.resolvers;
        _results = [];
        for (name in _ref1) {
          cfg = _ref1[name];
          resolverCls = (require("songlocator-" + name)).Resolver;
          _results.push(new resolverCls(cfg));
        }
        return _results;
      }).call(_this);
      resolver = new ResolverSet(resolvers);
      resolver.on('results', send);
      return sock.on('message', function(message) {
        var qid, req;
        req = (function() {
          try {
            return JSON.parse(message);
          } catch (e) {
            return void 0;
          }
        })();
        if (!req) {
          return;
        }
        qid = req.qid || v4();
        _this.debug('request', req);
        if (req.method === 'search') {
          return resolver.search(qid, req.query);
        } else if (req.method === 'resolve') {
          return resolver.search(qid, req.title, req.artist, req.album);
        }
      });
    });
    return this.log("start listening on localhost:" + this.config.port);
  };

  return SongLocatorServer;

})();

exports.main = function(port) {
  var config, opts, resolverName, server, _i, _len, _ref1;
  if (port == null) {
    port = 3000;
  }
  opts = parseArguments().opts;
  config = readConfigSync(opts.config) || {};
  _ref1 = opts.resolvers;
  for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
    resolverName = _ref1[_i];
    config[resolverName] = {};
  }
  server = new exports.SongLocatorServer({
    debug: opts.debug,
    port: port,
    resolvers: config
  });
  return server.serve();
};