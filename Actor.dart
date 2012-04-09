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

  static final int INIT_FRAME = 1;
  static final int WALK_FRAME = 2;
  static final int STAND_FRAME = 3;
  static final int TALK_START_FRAME = 4;
  static final int TALK_STOP_FRAME = 5;

  static final int MF_NEW_LEG = 1;
  static final int MF_IN_LEG = 2;
  static final int MF_TURN = 4;
  static final int MF_LAST_LEG = 8;
  static final int MF_FROZEN = 0x80;


  int id;
  int x, y, elevation;
  int facing;
  int frame;
  CostumeAnimationProgress progress;
  Room room;
  Costume costume;
  CostumeData cdata;
  bool costumeInitialized;
  int top, bottom;
  int moving;
  int animProgress;
  bool visible;
  bool redraw;
  int walkScript, talkScript;
  Function testCurrentRoom;

  static List<int> NEW_DIRECTIONS = const <int>[270, 90, 180, 0];
  static int directionToAngle(int dir) {
    return NEW_DIRECTIONS[dir];
  }

  static int angleToDirection(int dir) {
    if(dir >= 71 && dir <= 109) return 1;
    if(dir >= 109 && dir <= 251) return 2;
    if(dir >= 251 && dir <= 289) return 0;
    return 3;
  }

  Actor(int id, Function testCurrentRoom) {
    this.id = id;
    this.x = 0;
    this.y = 0;
    this.elevation = 0;
    this.moving = 0;
    this.facing = 180;
    this.visible = false;
    this.costumeInitialized = false;
    this.cdata = new CostumeData();
    this.testCurrentRoom = testCurrentRoom;
  }

  bool isInCurrentRoom() {
    return testCurrentRoom(this.room);
  }
  
  void put(int x, int y) {
    putInRoom(x, y, this.room);
  }

  void putInRoom(int x, int y, Room r) {
    this.x = x;
    this.y = y;
    this.room = r;
    redraw = true;
    if (visible) {
      if (isInCurrentRoom()) {
        // FIXME adjust position if moving
      } else {
        hide();
      }
    } else {
      if (isInCurrentRoom()) {
        show();
      }
    }
  }
  
  bool isInRoom(int roomId) {
    return room.index == roomId;
  }
  
  void setCostume(Costume c) {
    this.costume = c;
    if (visible) {
      //hide
      costumeInitialized = false;
      cdata = new CostumeData();
      //show
    } else {
      //reset
    }
    //init palette
  }
  
  void show() {
    if (room == null || visible) {
      return;
    }
    //FIXME adjust position
    if (!costumeInitialized) {
      startAnimate(INIT_FRAME);
      costumeInitialized = true;
    }
    visible = true;
    costumeInitialized = true;
  }
  
  void hide() {
    
  }

  void animate(int animation) {
    int cmd = 0x3f - (animation >> 2) + 2;
    int dir = directionToAngle(animation & 0x03);

    switch (cmd) {
    case 2:       // stop walking
      startAnimate(STAND_FRAME);
      stopMoving();
      break;
    case 3:
      moving &= ~MF_TURN;
      setDirection(dir);
      break;
    default:
      startAnimate(animation);
    }
  }

  void startAnimate(int f) {
    switch(frame) {
    case 0x38:
      f = INIT_FRAME;
      break;
    case 0x39:
      f = WALK_FRAME;
      break;
    case 0x3a:
      f = STAND_FRAME;
      break;
    case 0x3b:
      f = TALK_START_FRAME;
      break;
    case 0x3c:
      f = TALK_STOP_FRAME;
      break;
    }
    if(isInCurrentRoom() && costume != null) {
      animProgress = 0;
      redraw = true;
      cdata.animCounter = 0;
      if(f == INIT_FRAME) {
       cdata = new CostumeData();
      }
      //costume.decodeData(this, f, 0xFFFF);
      this.frame = f;
      this.progress = costume.animationForFrame(facing, frame);
    }
  }
  
  void setDirection(int dir) {
    if (dir == facing) {
      return;
    }
    facing = dir; // FIXME need angle to be normalized?
    if (costume == null) {
      return;
    }
    int amask = 0x8000;
    int vald;
    for (int i = 0; i < 16; i++, amask >>= 1) {
      vald = cdata.frame[i];
      if (vald == 0xFFFF) {
        continue;
      }
      costume.decodeData(this, vald, amask);
    }
    redraw = true;
  }

  void stopMoving() {
    moving = 0;
  }
}