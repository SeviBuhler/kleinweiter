import {test} from 'node:test';
import assert from 'node:assert/strict';
import {imageType} from '../lib/image.mjs';
test('Reject SVG, HTML and incomplete headers; accept only supported raster signatures',()=>{
 assert.equal(imageType(new TextEncoder().encode('<svg onload="alert(1)">')),null);
 assert.equal(imageType(Uint8Array.from([137,80,78,71])),null);
 assert.equal(imageType(Uint8Array.from([137,80,78,71,13,10,26,10])),'image/png');
 assert.equal(imageType(Uint8Array.from([255,216,255])),'image/jpeg');
 assert.equal(imageType(new TextEncoder().encode('RIFFxxxxWEBP')),'image/webp');
});
