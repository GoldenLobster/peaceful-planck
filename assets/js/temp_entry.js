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
            if (init instanceof Headers) {
                init.forEach((v, k) => this.map.set(k, v));
            } else if (typeof init.forEach === 'function') {
                init.forEach((v, k) => this.map.set(k, v));
            } else if (Array.isArray(init)) {
                for (let [k, v] of init) {
                    this.map.set(k.toLowerCase(), v);
                }
            } else {
                for (let [k, v] of Object.entries(init)) {
                    this.map.set(k.toLowerCase(), v);
                }
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
import './polyfills.js';
import { Innertube, UniversalCache } from 'youtubei.js';

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
        throw e;
    }
};

globalThis.getStream = async (songId) => {
    if (!yt) await globalThis.initYouTube();
    const info = await yt.music.getInfo(songId);
    const format = info.chooseFormat({ type: 'audio', quality: 'best' });
    return format.decipher(yt.session.player);
};

function mapItem(item, overrideType) {
    let type = overrideType || 'Unknown';
    if (!overrideType) {
        if (item.item_type === 'song' || item.item_type === 'video') type = 'Song';
        else if (item.item_type === 'album') type = 'Album';
        else if (item.item_type === 'playlist') type = 'Playlist';
        else if (item.item_type === 'artist') type = 'Artist';
        else type = 'Song';
    }
    
    let id = item.id || item.endpoint?.payload?.videoId || item.endpoint?.payload?.browseId || '';
    let title = typeof item.title === 'string' ? item.title : (item.title?.text || item.name || '');
    let authorRaw = item.author || item.subtitle?.text || item.subtitle || item.artists || 'Unknown';
    let authorName = 'Unknown';
    if (typeof authorRaw === 'string') authorName = authorRaw;
    else if (Array.isArray(authorRaw)) authorName = authorRaw[0]?.name || 'Unknown';
    else if (authorRaw?.name) authorName = authorRaw.name;
    
    let thumbnails = [];
    if (item.thumbnails) thumbnails = item.thumbnails;
    else if (item.thumbnail?.contents) thumbnails = item.thumbnail.contents;
    
    let seconds = 0;
    if (typeof item.duration?.seconds === 'number') seconds = item.duration.seconds;
    
    return {
        type,
        id,
        title,
        author: [{ name: authorName }],
        thumbnails,
        duration: { seconds }
    };
}

globalThis.search = async (query) => {
    if (!yt) await globalThis.initYouTube();
    const results = await yt.music.search(query);
    
    const mapped = [];
    const shelves = results.contents?.contents || (Array.isArray(results.contents) ? results.contents : []);
    
    for (const shelf of shelves) {
        if (!shelf.contents) continue;
        
        const shelfTitle = shelf.header?.title?.text || shelf.title?.text || '';
        let type = 'Unknown';
        if (shelfTitle.toLowerCase().includes('song')) type = 'Song';
        else if (shelfTitle.toLowerCase().includes('video')) type = 'Song';
        else if (shelfTitle.toLowerCase().includes('album')) type = 'Album';
        else if (shelfTitle.toLowerCase().includes('artist')) type = 'Artist';
        else if (shelfTitle.toLowerCase().includes('playlist')) type = 'Playlist';
        
        for (const item of shelf.contents) {
            mapped.push(mapItem(item, type !== 'Unknown' ? type : undefined));
        }
    }
    
    return JSON.stringify(mapped);
};

globalThis.getHome = async () => {
    if (!yt) await globalThis.initYouTube();
    const home = await yt.music.getHomeFeed();
    
    const mappedSections = (home.sections || []).map(section => {
        const title = section.header?.title?.text || section.title?.text || 'Recommendations';
        const contents = (section.contents || []).map(i => mapItem(i)).filter(i => i.id);
        
        return {
            header: { title: { text: title } },
            contents
        };
    });
    
    return JSON.stringify(mappedSections);
};

globalThis.getLibrary = async () => {
    if (!yt) await globalThis.initYouTube();
    try {
        const lib = await yt.music.getLibrary();
        const mapped = [];
        if (lib.contents) {
             mapped.push(...lib.contents.map(i => mapItem(i)));
        } else if (lib.items) {
             mapped.push(...lib.items.map(i => mapItem(i)));
        }
        return JSON.stringify(mapped);
    } catch(e) {
        return JSON.stringify([]);
    }
};

globalThis.getAlbum = async (albumId) => {
    if (!yt) await globalThis.initYouTube();
    const album = await yt.music.getAlbum(albumId);
    return JSON.stringify(album);
};

globalThis.getPlaylist = async (playlistId) => {
    if (!yt) await globalThis.initYouTube();
    const playlist = await yt.music.getPlaylist(playlistId);
    return JSON.stringify(playlist);
};

globalThis.getArtist = async (artistId) => {
    if (!yt) await globalThis.initYouTube();
    const artist = await yt.music.getArtist(artistId);
    return JSON.stringify(artist);
};
