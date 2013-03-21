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

class Script extends Resource {

  static final String TYPE = "SCRP";

  Stream data;

  Script(int index, int room, int offset): super(index, room, offset);

  factory Script.local(int index, int room, Stream stream) {
    Script s = new Script(index, room, 0);
    s.initWithData(stream);
    return s;
  }

  void initWithData(Stream data) {
    this.data = data;
    this.loaded = true;
  }
}