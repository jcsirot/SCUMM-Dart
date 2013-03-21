/* ***** BEGIN LICENSE BLOCK *****
 *
 * Copyright 2012 Jean-Christophe Sirot <sirot@chelonix.net>
 *
 * This file is part of SCUMMDart.
 *
 * SCUMMDart is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * SCUMMDart is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * scummdart. If not, see http://www.gnu.org/licenses/.
 *
 * ***** END LICENSE BLOCK *****  */

part of scummdart;

class AssetManager {
  static final Logger LOGGER = LoggerFactory.getLogger("AssetManager");

  List<String> downloadQueue;
  Map<String, ArrayBuffer> cache;
  int successCount = 0;
  int errorCount = 0;
  String baseUrl;

  AssetManager(String baseUrl) {
    this.baseUrl = baseUrl;
    if (!baseUrl.endsWith("/")) {
      this.baseUrl = "${this.baseUrl}/";
    }
    downloadQueue = new List<String>();
    cache = new Map<String, ArrayBuffer>();
  }

  ArrayBuffer operator [](String name) {
    return cache[name];
  }

  void queue(String path) {
    downloadQueue.add(path);
  }

  void download(String path, Function callback) {
    _download("${this.baseUrl}${path}", callback);
  }

  bool isDone() => downloadQueue.length == successCount + errorCount;

  void downloadAll(Function callback) {
    if (downloadQueue.length == 0) {
      callback();
    }

    downloadQueue.forEach((String path) {
      download(path, () {
        downloadQueue.clear();
        callback();
      });
    });
  }

  void _download(String path, Function callback) {
    var xhr = new HttpRequest();
    xhr.open("GET", path);
    xhr.responseType = "arraybuffer";
    xhr.onLoad.listen((e) {
      successCount ++;
      LOGGER.info("${path} load succeeded");
      ArrayBuffer buf = xhr.response;
      Uint8Array data = new Uint8Array.fromBuffer(buf);
      Uint8Array target = new Uint8Array(data.length);
      for (int i = 0; i < data.length; i++) {
        target[i] = data[i] ^ 0x69;
      }
      cache[path] = target.buffer;
      if (isDone()) {
        callback();
      }
    });
    xhr.onError.listen((e) {
      errorCount ++;
      LOGGER.info("${path} load failed");
      if (isDone()) {
        callback();
      }
    });
    xhr.send();
  }
}