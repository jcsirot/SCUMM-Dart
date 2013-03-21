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

class VirtualScreen {

  static final Logger LOGGER = LoggerFactory.getLogger("VirtualScreen");

  static final int WIDTH = 320;
  static final int HEIGHT = 200;
  static final int MAIN = 0;
  static final int TEXT = 1;
  static final int VERB = 2;
  static final int UNKNOWN = 3;

  int id;
  int top;
  int width;
  int height;
  bool dual;
  bool scrollable;
  Uint8Array buffer;
  Uint8Array buffer2;
  Uint8Array textBuffer;
  Uint8Array composite;
  List<Uint8Array> zplanes;
  int xstart;
  int screenStartStrip;
  int size;

  VirtualScreen(int virtualScreenId, int top, int width, int height, bool dualBuffer, bool scrollable) {
    this.id = virtualScreenId;
    this.top = top;
    this.width = width;
    this.height = height;
    this.dual = dualBuffer;
    this.scrollable = scrollable;
    this.xstart = 0;
    /* 1 byte per pixel */
    this.size = this.width * this.height;
    if (this.scrollable) {
      /* scrollable room can be 4 screens wide */
      this.size += 4 * 320;
    }
    this.composite = new Uint8Array(size);
    this.buffer = new Uint8Array(size);
    if (this.dual) {
      this.buffer2 = new Uint8Array(size);
    }
    this.textBuffer = new Uint8Array(WIDTH * HEIGHT);
    for (int i = 0; i < textBuffer.length; i++) {
      textBuffer[i] = 0xfd;
    }
    this.zplanes = new List<Uint8Array>(5);
    for (int i = 1; i < zplanes.length; i++) {
      zplanes[i] = new Uint8Array(40 * HEIGHT);
    }
  }

  Uint8Array getWorkBuffer() {
    return dual ? buffer2 : buffer;
  }

  Uint8Array getWorkBufferWithCoords(int x, int y) {
    Uint8Array buf = dual ? buffer2 : buffer;
    return buf.subarray(y * 320 + xstart + x);
  }

  Uint8Array getMainBufferWithCoords(int x, int y) {
    return buffer.subarray(y * 320 + xstart + x);
  }

  void resetMainBuffer() {
    if (!dual) {
      return;
    }
    Stream src = new Stream.fromUint8Array(getWorkBufferWithCoords(0, 0));
    Stream dst = new Stream.fromUint8Array(getMainBufferWithCoords(0, 0));
    while (!src.eof()) {
      dst.write(src.read());
    }
  }

  void clearText() {
    for (int i = 0; i < textBuffer.length; i++) {
      textBuffer[i] = 0xfd;
    }
  }

  void drawBackground(Room room, int start, int count) {
    Stream data = room.bg;
    data.reset();
    int zpLen = data.readTLV("RMIH").read16LE();
    Stream im00 = data.readTLV("IM00");
    drawBitmap(im00, start, 0, room.width, this.height, start, count, zpLen, 0);
    //decodeMask(zp);
  }

  void drawBitmap(Stream src, int x, int y, int width, int height, int start, int count, int zpLen, int flags) {
    /*
    Stream src = room.bg;
    data.reset();
    int zpLen = data.readTLV("RMIH").read16LE();
    Stream im00 = data.readTLV("IM00");
    Stream smap = im00.readTLV("SMAP");
    List<Stream> zp = new List<Stream>(zpLen);
    for (int i = 1; i <= zpLen; i++) {
      zp.add(im00.readTLV("ZP0$i"));
    }
    */

    var smap = src.readTLV("SMAP");
    var zp = new List<Stream>();
    for (int i = 1; i <= zpLen; i++) {
      zp.add(src.readTLV("ZP0$i"));
    }

    if (y + height > this.height) {
      print("Strip drawn to ${y + height} below window bottom ${this.height}");
    }

    var sx = x - this.xstart ~/ 8;
    if(sx < 0) {
      count -= -sx;
      x += -sx;
      start += -sx;
      sx = 0;
    }
    int limit = (max(width, this.width) ~/ 8).floor() - x;
    if (limit > count) {
      limit = count;
    } else if (limit > 40 - sx) {
      limit = 40 - sx;
    }

    for (int k = 0; k < limit; ++k, ++start, ++sx, ++x) {
      int offset = y * 320 + (x * 8);
      // adjust vs dirty
      Stream dst = new Stream.fromUint8Array(getWorkBufferWithCoords(0, 0)); // FIXME
      dst.reset();
      dst.seek(offset);
      drawStrip(dst, x, y, width, height, start, smap);
      decodeMaskStripe(zp, x, y, width, height, k, flags);

      /*
      if(this.number == 0) {
        dst = this.backBuf.newRelativeStream(offset);
        frontBuf = this.pixels.newRelativeStream(offset);
        t.copy8Col(frontBuf, this.pitch, dst, height, 1);
      }
      */
    }
    resetMainBuffer();
    //decodeMask(zp, x, y, width, height, flags);
  }

  void decodeMaskStripe(List<Stream> zp, int x, int y, int width, int height, int strpnr, int flags) {
    zp.forEach((Stream s) {
      s.reset();
      //Uint8Array a = new Uint8Array(height);
      s.seek(2 * strpnr); // FIXME?
      int offset = s.read16LE() - 8;
      //WritableStream out = new ScummFile.fromUint8Array(a);
      s.reset();
      s.seek(offset);
      Stream out = new Stream.fromUint8Array(zplanes[1]); // FIXME
      out.seek(y * 40 + x);
      decodeStripe(s, out, height);
    });
  }

  void decodeMask(List<Stream> zp, int x, int y, int width, int height, int flags) {
    zp.forEach((Stream s) {
      s.reset();
      Uint8Array a = new Uint8Array(height * width); // FIXME
      s.seek(2 * screenStartStrip);
      List<int> stripOffs = new List<int>();
      for (int i = 0; i < 40; i++) {
        stripOffs.add(s.read16LE() - 8);
      }
      Stream out = new Stream.fromUint8Array(a);
      for (int i = 0; i < 40; i++) {
        s.reset();
        s.seek(stripOffs[i]);
        out.reset();
        out.seek(i);
        decodeStripe(s, out, height);
      };
      // FIXME
      out = new Stream.fromUint8Array(zplanes[1]);
      Stream src = new Stream.fromUint8Array(a);
      out.reset();
      out.seek(y * 40 + x);
      while (!src.eof()) {
        out.write(src.read());
      }
    });
  }

  bool isMasked(int x, int y, int z) {
    int maskbit = 0x80 >> (x & 7);
    int mask = this.zplanes[z][y * 40 + (x >> 3)];
    return (mask & maskbit) != 0;
  }

  void decodeStripe(Stream s, Stream out, int lines) {
    while (lines > 0) {
      int count = s.read();
      if ((count & 0x80) != 0) {
        count &= 0x7f;
        int b = s.read();
        do {
          out.write(b);
          out.seek(39);
          lines--;
          count--;
        } while (count > 0 && lines > 0);
      } else {
        do {
          out.write(s.read());
          out.seek(39);
          lines--;
          count--;
        } while (count > 0 && lines > 0);
      }
    }
  }

  void drawStrip(Stream dst, int x, int y, int width, int height, int index, Stream data) {
    data.reset();
    data.seek(index * 4);
    int offset = data.read32LE();
    data.reset();
    data.seek(offset - 8);
    decompressStrip(dst, data, width, height);
  }

  void decompressStrip(Stream dst, Stream data, int width, int lineCount) {
    int code = data.read();
    int shr = code % 10;
    int mask = 0xff >> (8 - shr);
    switch (code) {
    case 1:
      throw new Exception("drawing strip raw");
    case 14:
    case 15:
    case 16:
    case 17:
    case 18:
      LOGGER.debug("drawing strip basic V");
      StripeDecoder dec = new StripeDecoderV();
      dec.drawStrip(dst, data, width, lineCount, shr, mask);
      break;
    case 24:
    case 25:
    case 26:
    case 27:
    case 28:
      LOGGER.debug("drawing strip basic H");
      StripeDecoder dec = new StripeDecoderH();
      dec.drawStrip(dst, data, width, lineCount, shr, mask);
      break;
    case 64:
    case 65:
    case 66:
    case 67:
    case 68:
    case 104:
    case 105:
    case 106:
    case 107:
    case 108:
      LOGGER.debug("drawing strip complex");
      StripeDecoder dec = new StripeDecoderComplex();
      dec.drawStrip(dst, data, width, lineCount, shr, mask);
      break;
    default:
      throw new Exception("unknown decompressBitmap code $code");
    }
  }

  void drawStripToScreen(CanvasRenderingContext2D ctx, int x, int width, int top, int bottom, Palette pal) {
    int scale = 2;
    int y = top;
    int height = bottom;

    ImageData dst = ctx.getImageData(x, y, width, height);
    Stream src = new Stream.fromUint8Array(getMainBufferWithCoords(0, 0));
    Stream txt = new Stream.fromUint8Array(textBuffer);
    int i = 0;
    for (int h = 0; h < height; h++) {
      for (int w = 0; w < width; w++) {
        int txtcolor = txt.read();
        int palcolor = src.read();
        var color = pal[txtcolor == 0xfd ? palcolor : txtcolor];
        //var color = pal[palcolor];
        if (color != null) {
          dst.data[i * 4] = color.r;
          dst.data[i * 4 + 1] = color.g;
          dst.data[i * 4 + 2] = color.b;
        }
        i++;
      }
    }
    ctx.putImageData(dst, x, top);
  }
}