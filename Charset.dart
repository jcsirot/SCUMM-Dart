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
 * Scummdart is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * scummdart. If not, see http://www.gnu.org/licenses/.
 *
 * ***** END LICENSE BLOCK *****  */

class Charset extends Resource {

  static final String TYPE = "CHAR";

  List<int> palette;
  int bpp;
  int height;
  int count;
  List<int> offsets;
  Stream data;

  Charset(int index, int room, int offset) : super(index, room, offset) {
    this.palette = new List<int>();
    this.offsets = new List<int>();
  }

  void initWithData(Stream data) {
    int size = data.read32LE();
    data.read();
    data.read(); // unknwon
    palette.add(0);
    for (int i = 0; i < 15; i++) {
      palette.add(data.read());
    }
    bpp = data.read();
    height = data.read();
    count = data.read16LE();
    for (int i = 0; i < count; i++) {
      offsets.add(data.read32LE() + 21);
    }
    this.data = data;
    this.data.reset();
    this.loaded = true;
  }

  int getCharWidth(int chr) {
    int ptr = offsets[chr];
    data.reset();
    data.seek(ptr);
    int w = data.read();
    int h = data.read();
    int dx = data.readS();
    int dy = data.readS();
    return w + dx;
  }

  int getStringWidth(String str) {
    int width = 1;
    Stream ins = new ScummFile.fromList(str.charCodes());
    while (!ins.eof()) {
      int chr = ins.read();
      if (chr == 0xff || chr == 0xfe) {
        chr = ins.read();
        if (chr == 2 || chr == 1 || chr == 9) {
          break;
        }
      }
      width += getCharWidth(chr);
    }
    return width;
  }

  void printString(String str, int x, int y, int width, int color, VirtualScreen vs) {
    int oldColor = palette[1];
    palette[1] = color;
    Stream ins = new ScummFile.fromList(str.charCodes());
    WritableStream out = new ScummFile.fromUint8Array(vs.textBuffer);
    while (!ins.eof()) {
      int chr = ins.read();
      if (chr >= 254) { // FIXME
        continue;
      }
      out.reset();
      out.seek(y * 320 + x);
      printChar(chr, y, out);
      x += getCharWidth(chr);
    }
    palette[1] = oldColor;
  }

  void printChar(int chr, int top, WritableStream out) {
    int ptr = offsets[chr];
    data.reset();
    data.seek(ptr);
    int w = data.read();
    int h = data.read();
    int dx = data.readS();
    int dy = data.readS();

    out.seek(320 * dy + dx); // FIXME Not for 1st char?

    int bits = data.read();
    int numbits = 8;

    for (int y = 0; y < h && y + top < 320; y++) {
      for (int x = 0; x < w; x++) {
        int color = (bits >> (8 - bpp)) & 0xff;

        if (color != 0 && (y + top) >= 0) {
          out.write(palette[color]);
        } else {
          out.seek(1);
        }
        bits <<= bpp;
        bits &= 0xff;
        numbits -= bpp;
        if (numbits == 0) {
          bits = data.read();
          numbits = 8;
        }
      }
      out.seek(320 - w);
    }
  }
}