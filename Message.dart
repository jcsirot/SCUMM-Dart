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

class Message {

  int x, y;
  int right, height;
  int color;
  int charset;
  bool center;
  bool overhead;
  bool no_talk_anim;
  bool wrapping;
  String value;

  abstract void printString(ExecutionContext ctx);

  void setValue(String value) {
    this.value = value;
  }

  String format(ExecutionContext ctx) {
    List<int> sb = new List<int>();
    Stream ins = new ScummFile.fromList(value.charCodes());
    while (!ins.eof()) {
      int chr = ins.read();
      if (chr == 0xff) {
        chr = ins.read();
        if (chr == 1 || chr == 2 || chr == 3 || chr == 8) {
          sb.add(0xff);
          sb.add(chr);
        } else if (chr == 4) {
          int v = ctx.getVar(ins.read16LE()); // FIXME
          sb.addAll(v.toString().charCodes());
        } else {
          throw new Exception("WTF?");
        }
      } else {
        sb.add(chr);
      }
    }
    return new String.fromCharCodes(sb);
  }
}