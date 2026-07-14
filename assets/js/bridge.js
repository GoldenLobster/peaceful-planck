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
}

globalThis.fetch = async (url, options = {}) => {
    return new Promise((resolve, reject) => {
        const callbackId = Math.random().toString(36).substring(7);
        
        globalThis[`fetch_resolve_${callbackId}`] = (status, statusText, headersStr, bodyBase64) => {
            const headers = JSON.parse(headersStr);
            const binaryString = globalThis.atob(bodyBase64);
            const res = new Response(binaryString, { status, statusText, headers });
            delete globalThis[`fetch_resolve_${callbackId}`];
            delete globalThis[`fetch_reject_${callbackId}`];
            resolve(res);
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

globalThis.getStream = async (songId) => {
    if (!yt) await globalThis.initYouTube();
    const info = await yt.music.getInfo(songId);
    const format = info.chooseFormat({ type: 'audio', quality: 'best' });
    return format.decipher(yt.session.player);
};

globalThis.search = async (query) => {
    if (!yt) await globalThis.initYouTube();
    const results = await yt.music.search(query);
    
    return JSON.stringify({
        songs: results.songs?.contents?.map(s => ({
            id: s.id,
            title: s.title,
            artistName: s.artists?.[0]?.name || 'Unknown',
            thumbnailUrl: s.thumbnails?.[0]?.url,
            durationSeconds: s.duration?.seconds || 0
        })) || [],
        albums: results.albums?.contents?.map(a => ({
            id: a.id,
            title: a.title,
            artistName: a.author?.[0]?.name || 'Unknown',
            thumbnailUrl: a.thumbnails?.[0]?.url
        })) || [],
        artists: results.artists?.contents?.map(a => ({
            id: a.id,
            name: a.name,
            thumbnailUrl: a.thumbnails?.[0]?.url
        })) || [],
        playlists: results.playlists?.contents?.map(p => ({
            id: p.id,
            title: p.title,
            author: p.author?.name,
            thumbnailUrl: p.thumbnails?.[0]?.url
        })) || []
    });
};

globalThis.getHome = async () => {
    if (!yt) await globalThis.initYouTube();
    const home = await yt.music.getHome();
    return JSON.stringify(home.sections);
};

globalThis.getLibrary = async () => {
    if (!yt) await globalThis.initYouTube();
    try {
        const lib = await yt.music.getLibrary();
        return JSON.stringify(lib);
    } catch(e) {
        return JSON.stringify({ songs: [], albums: [], playlists: [] });
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

