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

class Cursor {

  static final int SO_CURSOR_ON	= 0x01;        // Turns the cursor on
  static final int SO_CURSOR_OFF = 0x02;       // Turns the cursor off
  static final int SO_USERPUT_ON = 0x03;       // Enables user input
  static final int SO_USERPUT_OFF = 0x04;      // Disables user input
  static final int SO_CURSOR_SOFT_ON = 0x05;   // Increments the cursor's state?
  static final int SO_CURSOR_SOFT_OFF = 0x06;  // Decrements the cursor's state?
  static final int SO_USERPUT_SOFT_ON = 0x07;  // Increments "user input" counter (when greater than 0, user input is enabled).
  static final int SO_USERPUT_SOFT_OFF = 0x08; // Decrements "user input" counter (when 0 or less, user input is disabled).
  static final int SO_CURSOR_IMAGE = 0x0a;     // Changes the cursor image to a new one, based on image in a character set. Only used in Loom.
  // static final int SO_CURSOR_HOTSPOT = 0x0b // Changes the hotspot of a cursor. Only used in Loom.
  static final int SO_CURSOR_SET = 0x0c;       // Changes the current cursor. Must be between 0 and 3 inclusive.
  static final int SO_CHARSET_SET = 0x0d;      // Initializes the given character set.
  static final int SO_CHARSET_COLORS = 0x0e;   // Initializes the character set data & colors to the given arguments? Must have 16 arguments?
}