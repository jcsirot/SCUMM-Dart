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

class GFX {

  ResourceManager resMgr;
  VirtualScreen main;
  VirtualScreen text;
  VirtualScreen verb;
  CanvasElement canvas;

  int cam_x;
  int cam_dest_x;
  int screenStartStrip;
  Palette currentPalette;

  GFX(ResourceManager resMgr) {
    this.resMgr = resMgr;
    this.canvas = document.query('#surface');
    this.currentPalette = new Palette();
    //var ctx = canvas.getContext('2d');
  }

  void init() {
    initScreens(16, 144);
  }

  void initScreens(int b, int h) {
    main = new VirtualScreen(VirtualScreen.MAIN, b, VirtualScreen.WIDTH, VirtualScreen.HEIGHT - b, true, true);
    text = new VirtualScreen(VirtualScreen.TEXT, 0, VirtualScreen.WIDTH, b, false, false);
    verb = new VirtualScreen(VirtualScreen.VERB, h, VirtualScreen.WIDTH, VirtualScreen.HEIGHT - h, false, false);
  }

  void adjustPalette(int index, int r, int g, int b) {
    currentPalette.add(index, r, g, b);
  }

  void setCamera(int x) {
    cam_x = x;
    cam_dest_x = x;
    // FIXME check camera min & max positions
  }

  void moveCamera() {
    main.screenStartStrip = (cam_x / 8).floor() - 20;
    main.xstart = screenStartStrip * 8;
  }

  void redrawBGStrip(Room room, int start, int count) {
    int s = start + main.screenStartStrip;
    this.currentPalette = room.palette;
    main.drawBitmap(room, s, 0, room.width, main.height, s, count, 0);
  }

  void drawDirty() {
    CanvasRenderingContext2D ctx = canvas.getContext('2d');
    ctx.fillStyle = "black";
    ctx.fillRect(0,0, 320, 200);

    // verb.updateDirtyScreen(2);

    main.drawStripToScreen(ctx, 0, 320, 0, 200, currentPalette);
    // FIXME renderTexts();
  }

  void drawCostume(Actor a) {
    // FIXME setup scale
    for(int i = 0; i < 16; i++) {
      drawLimb(a, i);
    }
    a.progress.progress();
  }

  void drawLimb(Actor a, int limb) {
    if (!a.progress.isDefined(limb)) {
      return;
    }
    int i = a.progress[limb].current;
    a.costume.drawImage(main, limb, i, a.x, a.y);
  }
}