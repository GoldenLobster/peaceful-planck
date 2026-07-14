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
    const home = await yt.music.getHomeFeed();
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
