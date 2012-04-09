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

class Costume extends Resource {

  static final String TYPE = "COST";

  int animCount;
  bool mirrored;
  List<int> palette;
  List<int> frameOffsets;
  Map<int, int> animOffsets;
  Map<int, CostumeAnimation> animations;
  List<int> animCommands;
  int dataOffset;
  Stream data;

  Costume(int index, int room, int offset) : super(index, room, offset) {
    this.frameOffsets = new List<int>(16);
    for (int i = 0; i < 16; i++) {
      frameOffsets[i] = 0xffff;
    }
    animOffsets = new Map<int, int>();
    animCommands = new List<int>();
    animations = new Map<int, CostumeAnimation>();
  }

  void initWithData(Stream data) {
    animCount = data.read();
    int format = data.read();
    mirrored = (format & 0x80) != 0;
    switch (format & 0x7f) {
    case 0x58:
      palette = new List<int>(16);
      break;
    case 0x59:
      palette = new List<int>(32);
      break;
    default:
      throw new Exception("Invalid costume palette size: ${format & 0x7f}");
    }
    for (int i = 0; i < palette.length; i++) {
      palette[i] = data.read();
    }
    int animCmdOffset = data.read16LE() - 6;
    for (int i = 0; i < 16; i++) {
      frameOffsets[i] = data.read16LE() - 6;
    }
    for (int i = 0; i < animCount + 1; i++) {
      int offset = data.read16LE();
      if (offset != 0) {
        animOffsets[i] = offset - 6;
      }
    }
    this.data = data;
    animOffsets.forEach((int i, int offset) {
      this.data.reset();
      this.data.seek(offset);
      decodeAnimation(i);
    });
    data.reset();
    data.seek(animCmdOffset);
    for (int i = 0; i < frameOffsets[0] - animCmdOffset; i++) {
      animCommands.add(data.read() & 0x7f);
    }
    data.reset();
    this.loaded = true;
  }
  
  void decodeAnimation(int idx) {
    int mask = data.readU16LE();
    int i = 0;
    CostumeAnimation cAnim = new CostumeAnimation();
    do {
      if ((mask & 0x8000) != 0) {
        int j = data.readU16LE();
        if (j == 0xFFFF) {
          cAnim[i] = new AnimDefinition.disabled();
        } else {
          int r = data.read();
          bool loop = (r & 0x80) == 0;
          int len = (r & 0x7f);
          cAnim[i] = new AnimDefinition(j, len, loop);
        }
        i++;
        mask <<= 1;
      }
    } while ((mask & 0xFFFF) != 0);
    animations[idx] = cAnim;
  }
  
  CostumeAnimationProgress animationForFrame(int facing, int frame) {
    CostumeAnimationProgress rv = new CostumeAnimationProgress();
    int anim = Actor.angleToDirection(facing) + frame * 4;
    CostumeAnimation cAnim = animations[anim];
    cAnim.forEach((int k, AnimDefinition def) {
      rv[k] = new AnimProgress.fromAnimation(def);
    });
    return rv;
  }

  void decodeData(Actor a, int f, int usemask) {
    int anim = Actor.angleToDirection(a.facing) + f * 4;
    if (anim > this.animCount) {
      return;
    }
    data.reset();
    int offset = animOffsets[anim];
    if (offset == 0) {
      return;
    }
    data.seek(offset);

    int mask = data.readU16LE();
    int i = 0;
    do {
      if((mask & 0x8000) != 0) {
        int j = data.readU16LE();
        if ((usemask & 0x8000) != 0) {
          if (j == 0xFFFF) {
            a.cdata.curpos[i] = 0xffff;
            a.cdata.start[i] = 0;
            a.cdata.frame[i] = f;
          } else {
            int extra = data.read();
            int cmd = animCommands[j];
            if (cmd == 0x7a) {
              a.cdata.stopped &= ~(1 << i);
            } else if(cmd == 0x79) {
              a.cdata.stopped |= (1 << i);
            } else {
              a.cdata.curpos[i] = a.cdata.start[i] = j;
              a.cdata.end[i] = j + (extra & 0x7f);
              if((extra & 0x80) != 0) {
                a.cdata.curpos[i] |= 0x8000;
              }
              a.cdata.frame[i] = f;
            }
          }
        } else {
          if(j != 0xffff) {
            data.read();
          }
        }
      }
      i++;
      usemask <<= 1;
      mask <<= 1;
    } while ((mask & 0xFFFF) != 0);
  }
  
  void drawImage(VirtualScreen vs, int limb, int idx, int ax, int ay) {
    WritableStream dst = new ScummFile.fromUint8Array(vs.getWorkBufferWithCoords(0, 0));
    int code = animCommands[idx];
    if (code == 0x7b) {
      return;
    }
    data.reset();
    data.seek(frameOffsets[limb]);
    data.seek(2 * code);
    int off = data.read16LE() - 6;
    data.reset();
    data.seek(off);
    
    int width = data.read();
    data.read();
    int height = data.read();
    data.read();
    int cx = data.read16LE();
    int cy = data.read16LE();
    int xinc = data.read16LE();
    int yinc = data.read16LE();

    ax = ax + cx;
    ay = ay + cy;
    
    // clip the costume when larger than screen width
    int skipCols = vs.width - ax; //width - (ax + width - vs.width);
    int mask, shr;
    if (palette.length == 16) {
      mask = 0x0f; shr = 4;
    } else {
      mask = 0x07; shr = 3;
    }
    
    dst.seek(320 * ay + ax);
    
    //Stream zplane = new ScummFile.fromUint8Array(vs.zplanes[0]);
    //zplane.seek(ay * 40);
    //zplane.seek(ax >> 3);
    
    int x = 0, y = 0;
    while (true) {
      int b = data.read();
      int color = b >> shr;
      int len = b & mask;
      if (len == 0) {
        len = data.read();
      }
      while (len > 0) {
        //int maskbit = 0x80 >> (ax & 7);
        //int mask = zplane.read();
        //zplane.seek(-1);
        //bool masked = (mask & maskbit) != 0;
        if (color != 0 && !vs.isMasked(x+ax, y+ay, 1)) {
          dst.write(palette[color]);  
          dst.seek(-1);
        }
        dst.seek(320);
        //zplane.seek(40);
        len--;
        y++;
        if (y >= height) {
          if (--skipCols == 0) {
            return;
          }
          y = 0;
          x++;
          dst.seek(1 - 320 * height);
          //zplane.reset();
          //zplane.seek(ay*40);
          //zplane.seek((ax+x) >> 3);
          if (x >= width) {
            return;
          }
        }
      }
    }
  }
}

class CostumeAnimation {
  int mask;
  Map<int, AnimDefinition> animDefinitions;

  CostumeAnimation() {
    this.animDefinitions = new Map<int, AnimDefinition>();
  }

  void operator []=(int index, AnimDefinition def) {
    animDefinitions[index] = def;
  }
  
  AnimDefinition operator [](int index) {
    return animDefinitions[index];
  }
  
  void forEach(Function f) {
    animDefinitions.forEach(f);
  }
}

class AnimDefinition {

  int start;
  int length;
  bool loop;

  AnimDefinition.disabled() {
    this.start = 0xffff;
    this.length = 0;
    this.loop = false;
  }

  AnimDefinition(int start, int length, bool loop) {
    this.start = start;
    this.length = length;
    this.loop = loop;
  }

  bool isDisabled() {
    return start == 0xffff;
  }
}

class CostumeAnimationProgress {

  Map<int, AnimProgress> animations;

  CostumeAnimationProgress() {
    animations = new Map<int, AnimProgress>();
  }
  
  void operator []=(int index, AnimProgress def) {
    animations[index] = def;
  }
  
  AnimProgress operator[](int index) {
    return animations[index];
  }
  
  bool isDefined(int limb) {
    return animations.containsKey(limb);
  }
  
  void progress() {
    animations.forEach((int k, AnimProgress v) {
      v.progress();
    });
  }
}

class AnimProgress extends AnimDefinition {
  
  int current;
  
  AnimProgress.fromAnimation(AnimDefinition def):super(def.start, def.length, def.loop) {
    this.current = def.start;
  }
  
  void progress() {
    if (current < start + length) {
      current++;
    } else if (loop) {
      current = start;
    }
  }
}

class CostumeData {
  int animCounter = 0;
  int stopped;
  List<int> active;
  List<int> frame;
  List<int> start;
  List<int> end;
  List<int> curpos;

  CostumeData() {
    frame = new List<int>(16);
    start = new List<int>(16);
    end = new List<int>(16);
    curpos = new List<int>(16);
    active = new List<int>(16);
    for (int i = 0; i < 16; i++) {
      active[i] = 0;
      start[i] = end[i] = frame[i] = curpos[i] = 0xffff;
    }
  }
}