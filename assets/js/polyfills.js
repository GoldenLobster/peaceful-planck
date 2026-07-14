import { Buffer } from 'buffer';
import 'fast-text-encoding';
import 'core-js/web/url';
import 'core-js/web/url-search-params';
import { EventTarget } from 'event-target-shim';
import CustomEvent from 'custom-event';

globalThis.EventTarget = EventTarget;
globalThis.CustomEvent = CustomEvent;
globalThis.Buffer = Buffer;
globalThis.btoa = function(str) { return Buffer.from(str, 'binary').toString('base64'); };
globalThis.atob = function(b64Encoded) { return Buffer.from(b64Encoded, 'base64').toString('binary'); };
globalThis.document = {};

globalThis.console = {
    log: function() {},
    warn: function() {},
    error: function() {},
    info: function() {},
    debug: function() {}
};

globalThis.crypto = {
    getRandomValues: function(array) {
        for (let i = 0; i < array.length; i++) {
            array[i] = Math.floor(Math.random() * 256);
        }
        return array;
    },
    randomUUID: function() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            var r = Math.random() * 16 | 0, v = c === 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        });
    }
};

const timers = new Map();
globalThis.setTimeout = (cb, ms) => {
    const id = Math.floor(Math.random() * 1000000);
    timers.set(id, cb);
    globalThis.nativeSetTimeout(id, ms || 0);
    return id;
};
globalThis.fireTimeout = (id) => {
    const cb = timers.get(id);
    if (cb) {
        timers.delete(id);
        cb();
    }
};
globalThis.clearTimeout = (id) => {
    timers.delete(id);
    globalThis.nativeClearTimeout(id);
};

const intervals = new Map();
globalThis.setInterval = (cb, ms) => {
    const id = Math.floor(Math.random() * 1000000);
    intervals.set(id, cb);
    globalThis.nativeSetInterval(id, ms || 0);
    return id;
};
globalThis.fireInterval = (id) => {
    const cb = intervals.get(id);
    if (cb) {
        cb();
    }
};
globalThis.clearInterval = (id) => {
    intervals.delete(id);
    globalThis.nativeClearInterval(id);
};

class Headers {
    constructor(init) {
        this.map = new Map();
        if (init) {
            for (let [k, v] of Object.entries(init)) {
                this.map.set(k.toLowerCase(), v);
            }
        }
    }
    get(name) { return this.map.get(name.toLowerCase()); }
    set(name, value) { this.map.set(name.toLowerCase(), value); }
    forEach(cb) {
        for (let [k, v] of this.map.entries()) {
            cb(v, k);
        }
    }
}

class Response {
    constructor(body, init) {
        this.bodyText = body;
        this.status = init.status || 200;
        this.statusText = init.statusText || 'OK';
        this.headers = new Headers(init.headers);
        this.url = init.url || '';
    }
    async text() { return this.bodyText; }
    async json() { return JSON.parse(this.bodyText); }
    async arrayBuffer() {
        const buf = new ArrayBuffer(this.bodyText.length);
        const view = new Uint8Array(buf);
        for (let i = 0; i < this.bodyText.length; i++) {
            view[i] = this.bodyText.charCodeAt(i);
        }
        return buf;
    }
    get ok() {
        return this.status >= 200 && this.status < 300;
    }
}

globalThis.Headers = Headers;
globalThis.Response = Response;

globalThis.Request = class Request {
    constructor(input, init = {}) {
        if (input && input instanceof globalThis.Request) {
            this.url = input.url;
            this.method = init.method || input.method;
            this.headers = new Headers(init.headers || input.headers);
            this.body = init.body || input.body;
        } else {
            this.url = input ? input.toString() : '';
            this.method = init.method || 'GET';
            this.headers = new Headers(init.headers);
            this.body = init.body;
        }
    }
};

globalThis.fetch = async (input, options = {}) => {
    let req;
    if (input && input instanceof globalThis.Request) {
        req = new globalThis.Request(input, options);
    } else if (input && typeof input === 'object' && input.url) {
        // If input is some other Request-like object
        req = new globalThis.Request(input.url, { ...input, ...options });
    } else {
        req = new globalThis.Request(input, options);
    }
    
    return new Promise((resolve, reject) => {
        const callbackId = Math.random().toString(36).substring(7);
        
        globalThis[`fetch_resolve_${callbackId}`] = (status, statusText, headersStr, bodyBase64, url) => {
            const headers = JSON.parse(headersStr);
            const binaryString = globalThis.atob(bodyBase64);
            const res = new Response(binaryString, { status, statusText, headers, url });
            delete globalThis[`fetch_resolve_${callbackId}`];
            delete globalThis[`fetch_reject_${callbackId}`];
            resolve(res);
        };
        
        globalThis[`fetch_reject_${callbackId}`] = (errorStr) => {
            delete globalThis[`fetch_resolve_${callbackId}`];
            delete globalThis[`fetch_reject_${callbackId}`];
            reject(new Error(errorStr));
        };
        
        let body = req.body;
        if (body instanceof Uint8Array || body instanceof ArrayBuffer) {
             body = new TextDecoder().decode(body);
        }
        
        const headersObj = {};
        req.headers.forEach((v, k) => { headersObj[k] = v; });
        
        const reqStr = JSON.stringify({
            url: req.url,
            method: req.method,
            headers: headersObj,
            body: body ? body.toString() : null
        });
        
        console.log("FETCH URL: " + req.url);
        
        globalThis.nativeFetch(reqStr, callbackId);
    });
};
