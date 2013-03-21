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

  List<TextLine> splitString(String msg, int maxWidth) {
    List<TextLine> lines = [];
    List<int> codes = msg.codeUnits;
    int idx = 0;
    int chr;
    int curw = 1;
    int lastSpace = -1;
    int lastWidth = 0;
    int lastOffset = 0;
    while (idx < codes.length) {
      chr = codes[idx++];
      if (chr == 0x40) { /* @ */
        continue;
      }
      if (chr == 0xfe || chr == 0xff) {
        chr = codes[idx++];
        if (chr == 1) {
          lines.add(new TextLine(codes.getRange(lastOffset, idx-2-lastOffset), curw));
          lastOffset = idx;
          curw = 1;
          continue;
        } else if (chr == 2) {
          lines.add(new TextLine(codes.getRange(lastOffset, idx-2-lastOffset), curw));
          return lines;
        } else {
          throw new Exception("splitString unsupported char code: ${chr}");
        }
      }
      if (chr == 0x20) { /* SPACE */
        lastSpace = idx - 1;
        lastWidth = curw;
      }
      curw += getCharWidth(chr);
      if (lastSpace == -1) {
        continue;
      }
      if (curw > maxWidth) {
        lines.add(new TextLine(codes.getRange(lastOffset, lastSpace-lastOffset), lastWidth));
        curw = 1;
        idx = lastSpace + 1;
        lastOffset = idx;
        lastSpace = -1;
        print("Break line, index=${lastSpace}");
      }
    }
    lines.add(new TextLine(codes.getRange(lastOffset, idx-lastOffset), curw));
    return lines;
  }

  void printChar(int chr, int top, Stream out) {
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
    List<TextLine> lines = splitString(msg.value, 320);
    int oldColor = palette[1];
    palette[1] = msg.params.color;
    Stream out = new Stream.fromUint8Array(vs.textBuffer);
    int x = 0;
    int y = msg.params.y;
    lines.forEach((TextLine line) {
      Stream ins = new Stream.fromList(line.chars);
      x = msg.params.center ? msg.params.x - (line.width >> 1) : msg.params.x;
      int idx = 0;
      while (!ins.eof()) {
        int chr = ins.read();
        if (chr >= 254) { // FIXME
          ins.read();
          continue;
        } else {
          out.reset();
          out.seek(y * 320 + x);
          x += getCharWidth(chr);
        }
        printChar(chr, y, out);
      }
      y += height;
    });
    palette[1] = oldColor;
  }
}

class TextLine {
  List<int> chars;
  int width;

  TextLine(this.chars, this.width);
}