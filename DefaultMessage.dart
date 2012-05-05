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

class DefaultMessageFactory extends MessageFactory<DefaultMessage> {

  static DefaultMessageFactory that;

  factory DefaultMessageFactory() {
    if (that == null) {
      that = new DefaultMessageFactory._internal();
    }
    return that;
  }

  DefaultMessageFactory._internal();

  DefaultMessage build(String msg, MessageParameters params) {
    return new DefaultMessage(msg, params);
  }
}

class DefaultMessage extends Message {

  DefaultMessage(String msg, MessageParameters params) : super(msg, params);

  void printString(ScummVM vm) {
    String str = format(vm);
    print("[DEFAULT] $str");
    vm.drawActorMessage(this);
  }
}