/* ***** BEGIN LICENSE BLOCK *****
 *
 * Copyright 2012-2013 Jean-Christophe Sirot <sirot@chelonix.net>
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

abstract class StripeDecoder {
  void drawStrip(Stream dst, Stream src, int width, int lineCount, int shr, int mask);

  void writeRoomColor(Stream dst, int color) {
    dst.write(color); // FIXME use the palette
  }
}

class StripeDecoderH extends StripeDecoder {

  static final Logger LOGGER = LoggerFactory.getLogger("StripeDecodeH");

  int cl = 8;
  int x = 8;
  int inc = -1;
  int h;
  int color;
  int bits;

  bool READ_BIT() {
    cl--; var bit = bits & 1; bits >>= 1; return bit == 1;
  }

  void FILL_BITS(Stream src) {
    if (cl <= 8) {
      var v = src.read();
      bits |= (v << cl);
      cl += 8;
    }
  }

  void drawStrip(Stream dst, Stream src, int width, int lineCount, int shr, int mask) {

    color = src.read();
    bits = src.read();
    h = lineCount;

    do {
      var x = 8;
      do {
        FILL_BITS(src);
        if (color != 0xff) {
          writeRoomColor(dst, color);
        } else {
          dst.seek(1);
        }
        if (!READ_BIT()) {
        } else if (!READ_BIT()) {
          FILL_BITS(src);
          color = bits & mask;
          bits >>= shr;
          cl -= shr;
          inc = -1;
        } else if(!READ_BIT()) {
          color += inc;
        } else {
          inc = -inc;
          color += inc;
        }
      } while ((--x) != 0);
      if (h > 1)
        dst.seek(312);
    } while((--h) != 0);
  }
}

class StripeDecoderV extends StripeDecoder {

  static final Logger LOGGER = LoggerFactory.getLogger("StripeDecodeV");

  int cl = 8;
  int x = 8;
  int inc = -1;
  int color;
  int bits;

  bool READ_BIT() {
    cl--; var bit = bits & 1; bits >>= 1; return bit == 1;
  }

  void FILL_BITS(Stream src) {
    if (cl <= 8) {
      var v = src.read();
      bits |= (v << cl);
      cl += 8;
    }
  }

  void drawStrip(Stream dst, Stream src, int width, int lineCount, int shr, int mask) {
    color = src.read();
    bits = src.read();

    do {
      var h = lineCount;
      do {
        FILL_BITS(src);
        if (color != 0xff)
          writeRoomColor(dst, color);
        dst.seek(319);
        if (!READ_BIT()) {
        } else if (!READ_BIT()) {
          FILL_BITS(src);
          color = bits & mask;
          bits >>= shr;
          cl -= shr;
          inc = -1;
        } else if (!READ_BIT()) {
          color += inc;
        } else {
          inc = -inc;
          color += inc;
        }
      } while((--h) != 0);
      dst.seek(1 - lineCount * 320);
    } while((--x) != 0);
  }
}

class StripeDecoderComplex extends StripeDecoder
{
  int cl = 8;
  int x = 8;
  int color;
  int bits;
  int bit, incm, reps;

  bool READ_BIT() {
    cl--; var bit = bits & 1; bits >>= 1; return bit == 1;
  }

  void FILL_BITS(Stream src) {
    if (cl <= 8) {
      var v = src.read();
      bits |= (v << cl);
      cl += 8;
    }
  }

  void drawStrip(Stream dst, Stream src, int width, int lineCount, int shr, int mask) {
    color = src.read();
    bits = src.read();

    void AGAIN_POS() {
      if (!READ_BIT()) {
      } else if (!READ_BIT()) {
        FILL_BITS(src);
        color = bits & mask;
        bits >>= shr;
        cl -= shr;
      } else {
        incm = (bits & 7) - 4;
        cl -= 3;
        bits >>= 3;
        if (incm != 0) {
          color += incm;
        } else {
          FILL_BITS(src);
          reps = bits & 0xff;
          do {
            if (--x == 0) {
              x = 8;
              lineCount--;
              if (lineCount <= 1) {
                return;
              }
              dst.seek(width - 8);
            }
            if (color != 0xff) {
              writeRoomColor(dst, color);
            } else {
              dst.seek(1);
            }
          } while(--reps > 0);
          bits >>= 8;
          bits |= src.read() << (cl - 8);
          AGAIN_POS();
        }
      }
    }

    do {
      x = 8;
      do {
        FILL_BITS(src);
        if (color != 0xff) {
          writeRoomColor(dst, color);
        } else {
          dst.seek(1);
        }
        AGAIN_POS();
      } while(--x > 0);
      if (lineCount > 1) {
        dst.seek(320 - 8);
      }
      if (lineCount <= 1) {
        return;
      }
    } while(--lineCount > 0);
  }
}
