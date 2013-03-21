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

class DebugMessageFactory extends MessageFactory<DebugMessage> {

  static DebugMessageFactory that;

  factory DebugMessageFactory() {
    if (that == null) {
          that = new DebugMessageFactory._internal();
    }
    return that;
  }

  DebugMessageFactory._internal() {
    this.defaults = new MessageParameters();
  }

  DebugMessage build(String msg, MessageParameters params) {
    return new DebugMessage(msg, params);
  }
}

class DebugMessage extends Message {

  DebugMessage(String msg, MessageParameters params) : super(msg, params);

  void printString(ScummVM vm) {
    String str = format(vm);
    print("[DEBUG] $str");
  }
}