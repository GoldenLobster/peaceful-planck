const fs = require('fs');
const bundle = fs.readFileSync('assets/js/bundle.js', 'utf8');

const context = {};
const timers = {};
context.nativeFetch = function(reqStr, callbackId) {
    const req = JSON.parse(reqStr);
    const url = req.url;
    delete req.url;
    fetch(url, req).then(async res => {
        const text = await res.text();
        const headers = {};
        res.headers.forEach((v, k) => headers[k] = v);
        context['fetch_resolve_' + callbackId](res.status, res.statusText, JSON.stringify(headers), Buffer.from(text).toString('base64'), res.url);
    }).catch(e => {
        context['fetch_reject_' + callbackId](e.toString());
    });
};
context.nativeSetTimeout = function(id, ms) { timers[id] = setTimeout(() => context.fireTimeout(id), ms); };
context.nativeClearTimeout = function(id) { clearTimeout(timers[id]); delete timers[id]; };
context.nativeSetInterval = function(id, ms) { timers[id] = setInterval(() => context.fireInterval(id), ms); };
context.nativeClearInterval = function(id) { clearInterval(timers[id]); delete timers[id]; };

const vm = require('vm');
vm.createContext(context);
vm.runInContext("var globalThis = this; var window = this; var global = this;", context);
vm.runInContext(bundle, context);

(async () => {
    await vm.runInContext("globalThis.initYouTube().then(() => { console.log(globalThis.yt.session.context.client.userAgent); })", context);
})();
