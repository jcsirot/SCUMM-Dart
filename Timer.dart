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

class Timer {

  num gameTime = 0;
  static final num MAX_STEP = 0.05;
  num wallLastTimestamp = 0;

  num tick() {
    num wallCurrent = new Date.now().value;
    num wallDelta = (wallCurrent - wallLastTimestamp) / 1000;
    wallLastTimestamp = wallCurrent;

    num gameDelta = Math.min(wallDelta, MAX_STEP);
    gameTime += gameDelta;
    return gameDelta;
  }
}
