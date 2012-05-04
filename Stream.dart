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

interface Stream {

  int length();
  void seek(int offset);
  int pointer();
  void reset();
  bool eof();

  int read();
  int read32BE();
  int read32LE();
  int read16BE();
  int read16LE();
  int readU16LE();
  int readS();
  String readString(int len);
  /** Read an almost 0-terminated array */
  List<int> readArray();
  Uint8Array array(int len);
  Stream readTLV(String tag);
  Stream readLV();

  Stream subStream(int len);
  Stream dup();
}