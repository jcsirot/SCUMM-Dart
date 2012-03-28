/* ***** BEGIN LICENSE BLOCK *****
 *
 * Copyright 2012 Jean-Christophe Sirot <sirot@chelonix.net>
 *
 * This file is part of scummdart.
 *
 * Scummdart is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * jsChessboard is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * scummdart. If not, see http://www.gnu.org/licenses/.
 *
 * ***** END LICENSE BLOCK *****  */

class ScummFile implements Stream, WritableStream {

  int ptr;
  int len;
  Uint8Array data;

  ScummFile(ArrayBuffer buffer) {
    this.ptr = 0;
    this.data = new Uint8Array.fromBuffer(buffer);
    this.len = this.data.length;
  }

  ScummFile.fromList(List<int> list) {
    this.ptr = 0;
    this.data = new Uint8Array.fromList(list);
    this.len = this.data.length;
  }

  ScummFile.fromUint8Array(Uint8Array data) {
    this.ptr = 0;
    this.data = data;
    this.len = this.data.length;
  }

  int length() {
    return data.length;
  }

  void seek(int offset) {
    this.ptr += offset;
  }

  int pointer() {
    return this.ptr;
  }

  bool eof() {
    return ptr >= data.length;
  }

  void write(int x) {
    if (x != 0) {
      //print("Write $x at $ptr");
    }
    this.data[ptr++] = (x & 0xff);
  }

  int read() {
    return data[ptr++];
  }

  void reset() {
    this.ptr = 0;
  }

  int read32BE() {
    return
      (data[ptr++] << 24) |
      (data[ptr++] << 16) |
      (data[ptr++] << 8) |
       data[ptr++];
  }

  int read32LE() {
    return
       data[ptr++] |
      (data[ptr++] << 8) |
      (data[ptr++] << 16) |
      (data[ptr++] << 24);
  }

  int read16BE() {
    int x = data[ptr++] << 8 | data[ptr++];
    if ((x & 0x8000) != 0) {
      x = x - 0x10000;
    }
    return x;
  }

  int read16LE() {
    int x = data[ptr++] | (data[ptr++] << 8);
    if ((x & 0x8000) != 0) {
      x = x - 0x10000;
    }
    return x;
  }

  String readString(int len) {
    return new String.fromCharCodes(array(len));
  }

  List<int> readArray() {
    List<int> tmp = new List<int>();
    while (true) {
      int value = read();
      if (value == 0) {
        break;
      }
      tmp.add(value);
      if (value == 0xff) {
        value = read();
        tmp.add(value);
        if (value != 1 && value != 2 && value != 3 && value != 8) {
          tmp.add(read());
          tmp.add(read());
        }
      }
    }
    return tmp;
  }

  Uint8Array array(int len) {
    ptr += len;
    return data.subarray(ptr-len, ptr);
  }

  Stream readTLV(String tag) {
    String t = readString(4);
    if (t != tag) {
      throw new Exception("Unexpected tag: expected $tag and found $t");
    }
    int len = read32BE();
    Stream sub = subStream(len-8);
    ptr += (len-8);
    return sub;
  }

  Stream readLV() {
    int len = read32BE();
    Stream sub = subStream(len-8);
    ptr += (len-8);
    return sub;
  }

  Stream subStream(int len) {
    Uint8Array sub = data.subarray(ptr, ptr+len);
    return new ScummFile.fromUint8Array(sub);
  }

  Stream dup() {
    Stream stream = new ScummFile.fromUint8Array(data);
    stream.seek(ptr);
    return stream;
  }
}