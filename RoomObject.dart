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

class RoomObject {

  static final int MASK_OR = 1;

  int id;
  int numIm;
  int numZp;
  int flags;
  int x, y;
  int width, height;
  Map<int, Stream> images;

  RoomObject.fromOBIM(Stream data) {
    Stream header = data.readTLV("IMHD");
    id = header.read16LE();
    numIm = header.read16LE();
    numZp = header.read16LE();
    flags = header.read();
    flags |= MASK_OR;
    header.read(); // unknown
    x = header.read16LE();
    y = header.read16LE();
    width = header.read16LE();
    height = header.read16LE();
    images = new Map<int, Stream>();
    for (int i = 1; i <= numIm; i++) {
      images[i] = data.readTLV("IM0$i");
    }
  }
}