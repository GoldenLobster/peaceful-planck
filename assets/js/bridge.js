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
