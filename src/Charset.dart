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

  int getLineWidth(String str, [int start = 0]) {
    int width = 1;
    List<int> codes = str.charCodes();
    Stream ins = new ScummFile.fromList(codes.getRange(start, codes.length - start));
    while (!ins.eof()) {
      int chr = ins.read();
      if (chr == 0xff || chr == 0xfe) {
        chr = ins.read();
        if (chr == 2 || chr == 1 || chr == 9) {
          break;
        }
      } else if (chr == 0xd) {
        break;
      }
      width += getCharWidth(chr);
    }
    return width;
  }

  String addLineBreaks(String msg, int maxWidth) {
    List<int> codes = msg.charCodes();
    int idx = 0;
    int chr;
    int curw = 1;
    int lastSpace = -1;
    while (idx < codes.length) {
      chr = codes[idx++];
      if (chr == 0x40) { /* @ */
        continue;
      }
      if (chr == 0xfe || chr == 0xff) {
        chr = codes[idx++];
        if (chr == 1) {
          codes[idx - 1] = 0xd;
          curw = 1;
          continue;
        } else if (chr == 2) {
          break;
        } else {
          throw new Exception("addLineBreaks unsupported char code: ${chr}");
        }
      }
      if (chr == 0x20) { /* SPACE */
        lastSpace = idx - 1;
      }
      curw += getCharWidth(chr);
      if (lastSpace == -1) {
        continue;
      }
      if (curw > maxWidth) {
        codes[lastSpace] = 0xd;
        curw = 1;
        idx = lastSpace + 1;
        lastSpace = -1;
        print("Break line, indexx=${lastSpace}");
      }
    }
    return new String.fromCharCodes(codes);
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

  void printString(Message msg, VirtualScreen vs) {
    vs.clearText();
    String str = addLineBreaks(msg.value, 320);
    int width = getLineWidth(msg.value);
    int x = msg.params.center ? msg.params.x - (width >> 1) : msg.params.x;
    int y = msg.params.y;
    int oldColor = palette[1];
    palette[1] = msg.params.color;
    Stream ins = new ScummFile.fromList(str.charCodes());
    WritableStream out = new ScummFile.fromUint8Array(vs.textBuffer);
    int idx = 0;
    while (!ins.eof()) {
      int chr = ins.read();
      if (chr >= 254) { // FIXME
        idx++;
        continue;
      } else if (chr == 0xd) {
        y += height;
        width = getLineWidth(str, ++idx);
        x = msg.params.center ? msg.params.x - (width >> 1) : msg.params.x;
        out.reset();
        out.seek(y * 320 + x);
      } else {
        out.reset();
        out.seek(y * 320 + x);
        x += getCharWidth(chr);
      }
      idx++;
      printChar(chr, y, out);
    }
    palette[1] = oldColor;
  }
}