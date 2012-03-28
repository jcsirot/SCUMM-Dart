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

class Actor {

  int id;
  int x, y, elevation;
  Room room;
  int top, bottom;
  bool visible;
  bool redraw;

  Actor(int id) {
    this.id = id;
  }

  void put(int x, int y, Room r) {
    this.x = x;
    this.y = y;
    this.room = r;
  }

  bool isInRoom(int roomId) {
    return room.index == roomId;
  }
}