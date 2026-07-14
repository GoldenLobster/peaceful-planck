import { Buffer } from 'buffer';
import 'fast-text-encoding';
import 'url-polyfill';
import { EventTarget } from 'event-target-shim';
import CustomEvent from 'custom-event';
import { Innertube, UniversalCache } from 'youtubei.js';

globalThis.EventTarget = EventTarget;
globalThis.CustomEvent = CustomEvent;
globalThis.Buffer = Buffer;
globalThis.btoa = function(str) { return Buffer.from(str, 'binary').toString('base64'); };
globalThis.atob = function(b64Encoded) { return Buffer.from(b64Encoded, 'base64').toString('binary'); };

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

class Headers {
    constructor(init) {
        this.map = new Map();
        if (init) {
            Object.keys(init).forEach(key => {
                this.map.set(key.toLowerCase(), init[key]);
            });
        }
    }
    get(name) { return this.map.get(name.toLowerCase()) || null; }
    set(name, value) { this.map.set(name.toLowerCase(), value); }
    has(name) { return this.map.has(name.toLowerCase()); }
    forEach(callback) { this.map.forEach((value, key) => callback(value, key)); }
    entries() { return this.map.entries(); }
}

class Response {
    constructor(buffer, init) {
        this.buffer = buffer; 
        this.status = init.status || 200;
        this.statusText = init.statusText || 'OK';
        this.ok = this.status >= 200 && this.status < 300;
        this.headers = new Headers(init.headers);
    }
    async text() { 
        return new TextDecoder().decode(this.buffer); 
    }
    async json() { 
        return JSON.parse(new TextDecoder().decode(this.buffer)); 
    }
    async arrayBuffer() {
        return this.buffer.buffer;
    }
    get body() {
        return null; 
    }
}

globalThis.Headers = Headers;
globalThis.Response = Response;

globalThis.fetch = async (url, options = {}) => {
    return new Promise((resolve, reject) => {
        const callbackId = Math.random().toString(36).substring(7);
        
        globalThis[`fetch_resolve_${callbackId}`] = (status, statusText, headersStr, bodyBase64) => {
            const headers = JSON.parse(headersStr);
            const binaryString = globalThis.atob(bodyBase64);
            const len = binaryString.length;
            const bytes = new Uint8Array(len);
            for (let i = 0; i < len; i++) {
                bytes[i] = binaryString.charCodeAt(i);
            }
            
            const response = new Response(bytes, { status, statusText, headers });
            
            delete globalThis[`fetch_resolve_${callbackId}`];
            delete globalThis[`fetch_reject_${callbackId}`];
            resolve(response);
        };
        
        globalThis[`fetch_reject_${callbackId}`] = (errorStr) => {
            delete globalThis[`fetch_resolve_${callbackId}`];
            delete globalThis[`fetch_reject_${callbackId}`];
            reject(new Error(errorStr));
        };
        
        let body = options.body;
        if (body instanceof Uint8Array || body instanceof ArrayBuffer) {
             body = new TextDecoder().decode(body);
        }
        
        const reqStr = JSON.stringify({
            url: url.toString(),
            method: options.method || 'GET',
            headers: options.headers || {},
            body: body ? body.toString() : null
        });
        
        globalThis.nativeFetch(reqStr, callbackId);
    });
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

let yt = null;

globalThis.initYouTube = async () => {
    if (yt) return true;
    try {
        yt = await Innertube.create({
            cache: new UniversalCache(false),
            generate_session_locally: true
        });
        return true;
    } catch(e) {
        console.error("Init Error", e);
        throw e;
    }
};

globalThis.search = async (query) => {
    if (!yt) await globalThis.initYouTube();
    const results = await yt.music.search(query);
    return JSON.stringify(results.contents);
};

globalThis.getSong = async (videoId) => {
    if (!yt) await globalThis.initYouTube();
    const track = await yt.music.getInfo(videoId);
    return JSON.stringify(track.basic_info);
};

globalThis.getPlaylist = async (playlistId) => {
    if (!yt) await globalThis.initYouTube();
    const playlist = await yt.music.getPlaylist(playlistId);
    return JSON.stringify(playlist.items);
};

globalThis.getArtist = async (artistId) => {
    if (!yt) await globalThis.initYouTube();
    const artist = await yt.music.getArtist(artistId);
    return JSON.stringify(artist.sections);
};

globalThis.getAlbum = async (albumId) => {
    if (!yt) await globalThis.initYouTube();
    const album = await yt.music.getAlbum(albumId);
    return JSON.stringify(album.contents);
};

globalThis.getStream = async (videoId) => {
    if (!yt) await globalThis.initYouTube();
    const info = await yt.getBasicInfo(videoId);
    const format = info.chooseFormat({ type: 'audio', quality: 'best' });
    return format?.url || null;
};

globalThis.getHome = async () => {
    if (!yt) await globalThis.initYouTube();
    const home = await yt.music.getHome();
    return JSON.stringify(home.sections);
};

globalThis.getLibrary = async () => {
    if (!yt) await globalThis.initYouTube();
    const library = await yt.music.getLibrary();
    return JSON.stringify(library.contents);
};
