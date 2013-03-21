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

abstract class MessageFactory<M extends Message> {

  MessageParameters _defaults;

  MessageParameters get defaults => new MessageParameters.copy(_defaults);
  set defaults(MessageParameters params) => this._defaults = params;

  MessageFactory() {
    this.defaults = new MessageParameters();
  }

  M build(String message, MessageParameters params);
}

class MessageParameters {

  int x, y;
  int right, height;
  int color;
  int charset;
  bool center;
  bool overhead;
  bool no_talk_anim;
  bool wrapping;

  MessageParameters() { }

  MessageParameters.copy(MessageParameters params) {
    this.x = params.x;
    this.y = params.y;
    this.right = params.right;
    this.height = params.height;
    this.color = params.color;
    this.charset = params.charset;
    this.center = params.center;
    this.overhead = params.overhead;
    this.no_talk_anim = params.no_talk_anim;
    this.wrapping = params.wrapping;
  }
}

abstract class Message {

  String value;
  MessageParameters params;

  Message(this.value, this.params);

  void printString(ScummVM vm);

  String format(ScummVM vm) {
    List<int> sb = new List<int>();
    Stream ins = new Stream.fromList(value.codeUnits);
    while (!ins.eof()) {
      int chr = ins.read();
      if (chr == 0xff) {
        chr = ins.read();
        if (chr == 1) {
          sb.add(0x0d);
        } else if (chr == 2) {
          // End of String, no final newline
          break;
        } else if (chr == 3 || chr == 8) {
          sb.add(0xff);
          sb.add(chr);
        } else if (chr == 4) {
          int v = vm.getVar(ins.read16LE()); // FIXME
          sb.addAll(v.toString().codeUnits);
        } else {
          throw new Exception("WTF?");
        }
      } else if (chr == 0xfa) {
        sb.add(0x20);
      } else if (chr == 0) {
        sb.add(0x0d);
      } else if (chr == 0x82) {
        sb.add(0xe9);
      } else if (chr == 0x88) {
        sb.add(0xea);
      } else if (chr == 0x8b) {
        sb.add(0xef);
      } else {
        sb.add(chr);
      }
    }
    return new String.fromCharCodes(sb);
  }
}