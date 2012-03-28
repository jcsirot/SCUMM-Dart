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

class Room {

  int index;
  String name;
  String fileId;
  int fileOffset;
  int offset;

  int width;
  int height;
  int objectCount;
  Map<int, OBIM> obims;
  Map<int, Script> scripts;
  Palette palette;
  Stream bg;
  List<Stream> images;
  Script entry;
  Script exit;

  Room(this.index, this.name) {
    this.obims = new Map<int, OBIM>();
    this.scripts = new Map<int, Script>();
  }

  void initWithData(Stream data) {
      Stream header = data.readTLV("RMHD");
      this.width = header.read16LE();
      this.height = header.read16LE();
      this.objectCount = header.read16LE();
      Stream cycleStream = data.readTLV("CYCL");
      Stream trnsStream = data.readTLV("TRNS");
      data.readTLV("EPAL");
      data.readTLV("BOXD");
      data.readTLV("BOXM");
      readPalette(data.readTLV("CLUT"));
      data.readTLV("SCAL");
      //readImages(data.readTLV("RMIM"));
      bg = data.readTLV("RMIM");
      for (int i = 0; i < objectCount; i++) {
        OBIM obim = readOBIM(data.readTLV("OBIM"));
        obims[obim.id] = obim;
      }
      for (int i = 0; i < objectCount; i++) {
        data.readTLV("OBCD");
      }
      data.readTLV("EXCD");
      Stream encd = data.readTLV("ENCD");
      entry = new Script(10002, 0, 0);
      entry.initWithData(encd);
      int nbLocalScript = data.readTLV("NLSC").read();
      for (int i = 0; i < nbLocalScript; i++) {
        Script s = readLocalScript(data.readTLV("LSCR"));
        scripts[s.index] = s;
      }
  }

  void readPalette(Stream data) {
    palette = new Palette();
    for (int i = 0; i < 256; i++) {
      palette.add(i, data.read(), data.read(), data.read());
    }
  }

  void readImages(Stream data) {
    Stream rmih = data.readTLV("RMIH");
    int nbz = rmih.read16LE();
    //im00 = data.readTLV("IM00");
  }

  OBIM readOBIM(Stream obim) {
    Stream objHeader = obim.readTLV("IMHD");
    int id = objHeader.read16LE();
    int numIm = objHeader.read16LE();
    int numZp = objHeader.read16LE();
    int flags = objHeader.read();
    objHeader.read(); // unknown
    int x = objHeader.read16LE();
    int y = objHeader.read16LE();
    int width = objHeader.read16LE();
    int height = objHeader.read16LE();
    List<Stream> images = new List<Stream>();
    for (int i = 1; i <= numIm; i++) {
      images.add(obim.readTLV("IM0$i"));
    }
    return new OBIM(id, flags, x, y, width, height, images);
  }

  Script readLocalScript(Stream data) {
    int id = data.read();
    return new Script.local(id, this.index, data.subStream(data.length() - 1));
  }
}

class OBIM {
  int id;
  int flags;
  int x, y, w, h;
  List<Stream> images;

  OBIM(int id, int flags, int x, int y, int w, int h, List<Stream> images) {
    this.id = id;
    this.flags = flags;
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.images = images;
  }
}