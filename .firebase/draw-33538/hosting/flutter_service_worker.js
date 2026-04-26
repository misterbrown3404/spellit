'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "392f5a05fcb2df720362860d00ffdf17",
"version.json": "1f256a8aaa3e20020637db83cd6739a7",
"index.html": "a2b788f83db9e6f59c2970f9d2781187",
"/": "a2b788f83db9e6f59c2970f9d2781187",
"main.dart.js": "036d40308c846a010614489423225306",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"favicon.png": "385264221fa8c57f2cd515c7d627a74e",
"icons/Icon-192.png": "c3e294d71c5fbf352e71d2d3fcc02f99",
"icons/Icon-maskable-192.png": "c3e294d71c5fbf352e71d2d3fcc02f99",
"icons/Icon-maskable-512.png": "936a0bd4f60a43cceee73b7c311bf58d",
"icons/Icon-512.png": "936a0bd4f60a43cceee73b7c311bf58d",
"manifest.json": "04d500a2887469b2cdf5eec21831a244",
"assets/AssetManifest.json": "9bd815128cdd5584406b605f02923b08",
"assets/NOTICES": "618c882c5a0c64cae849ec4d0c20fe9c",
"assets/FontManifest.json": "92818e61d2b3673d24f9b8edfad3c095",
"assets/AssetManifest.bin.json": "84323dacb2209268e26a7f225a71fb25",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "ecb8ca44f22a4543e7fb6d07b7a616fb",
"assets/fonts/MaterialIcons-Regular.otf": "1c239a0586417423913c9ee6e2a3c8a1",
"assets/assets/audio/clutch_music.wav": "778d4813e64ea3ee4a773ac30d04eb8f",
"assets/assets/audio/sfx/streak.wav": "33be99bf8689b6338573187d318f1ded",
"assets/assets/audio/sfx/power_recieved.wav": "6399541b6c26af3867e637476836e5f8",
"assets/assets/audio/sfx/power_up.wav": "6399541b6c26af3867e637476836e5f8",
"assets/assets/audio/sfx/victory.mp3": "8aff5a5d653c69a249a2573c1827cfe4",
"assets/assets/audio/sfx/defeat.wav": "d1ea7d2655851af687f1f0345d07a008",
"assets/assets/audio/sfx/coin.wav": "3e892f66aef332ff50db501a3551cd38",
"assets/assets/audio/sfx/click.wav": "e96ee402928089582ce0a1d160b64075",
"assets/assets/audio/sfx/invalid.wav": "949efbdf35bfec9f23e1a2158751678d",
"assets/assets/audio/sfx/letter_tap.wav": "ef089d777712e7216ab1a71071ef2636",
"assets/assets/audio/sfx/word_submit.wav": "fa5b0df64acbbaeb96d8ffb82cea1d16",
"assets/assets/audio/game_music.mp3": "f50eb90dc96fadc065360fab3be56ae6",
"assets/assets/audio/menu_music.mp3": "ed04023daf961eb845795d0e99a94062",
"assets/assets/icons/bomb.png": "88a30592ae8f4ebfcecbf63793902058",
"assets/assets/icons/icon.png": "830b12c9000ef8e1d90872d7519eb32e",
"assets/assets/icons/shield.png": "5b93d1a787753bf25253b5e586fcb362",
"assets/assets/icons/double.png": "f782c92c6eb957da9464af0212f345cb",
"assets/assets/icons/freeze.png": "a2b5155270debb8a1a77f2fadff7df91",
"assets/assets/icons/shuffle.png": "fd230a95cd1e3fb01b30995c271ef62f",
"assets/assets/icons/reveal.png": "a0c0abf73b0d038af5e4e860ef3a54ac",
"assets/assets/words.txt": "2cec583470f12e4ba3afc22244d5cef1",
"assets/assets/fonts/Poppins-Medium.ttf": "bf59c687bc6d3a70204d3944082c5cc0",
"assets/assets/fonts/Poppins-Regular.ttf": "093ee89be9ede30383f39a899c485a82",
"assets/assets/fonts/Poppins-Bold.ttf": "08c20a487911694291bd8c5de41315ad",
"assets/assets/fonts/Poppins-SemiBold.ttf": "6f1520d107205975713ba09df778f93f",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
