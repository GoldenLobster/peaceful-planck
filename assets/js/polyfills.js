import { Buffer } from 'buffer';
import 'fast-text-encoding';
import 'url-polyfill';
import { EventTarget } from 'event-target-shim';
import CustomEvent from 'custom-event';

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
