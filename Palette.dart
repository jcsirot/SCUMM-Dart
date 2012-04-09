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

class Palette {

  List<PaletteColor> colors;

  Palette() {
    this.colors = new List<PaletteColor>(256);
  }
  
  Palette.withSize(int size) {
    this.colors = new List<PaletteColor>(size);
  }

  void add(int index, int r, int g, int b) {
    PaletteColor c = new PaletteColor(r, g, b);
    colors[index] = c;
  }

  PaletteColor operator[](int index) {
    return colors[index];
  }
}

class PaletteColor {
  int r, g, b;

  PaletteColor(int r, int g, int b) {
    this.r = r;
    this.g = g;
    this.b = b;
  }
}