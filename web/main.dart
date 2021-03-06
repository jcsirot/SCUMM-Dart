/* ***** BEGIN LICENSE BLOCK *****
 *
 * Copyright 2012-2013 Jean-Christophe Sirot <sirot@chelonix.net>
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

import "dart:html";
import "package:scummdart/scumm.dart";

void main() {
  var canvas = document.query('#surface');
  var ctx = canvas.getContext('2d');

  Scumm scumm = new Scumm(canvas, false);
  scumm.loadGame("MONKEY1");
}