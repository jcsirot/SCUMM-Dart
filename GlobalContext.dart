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

class GlobalContext {

  static final int EGO = 1;
  static final int ROOM = 4;
  static final int OVERRIDE = 5;
  static final int MUSIC_TIMER = 14;
  static final int CAMERA_MIN_X = 17;
  static final int CAMERA_MAX_X = 18;
  static final int ROOM_RESOURCE = 22;
  static final int ENTRY_SCRIPT = 28;
  static final int ENTRY_SCRIPT2 = 29;
  static final int EXIT_SCRIPT = 30;
  static final int SENTENCE_SCRIPT = 34;
  static final int CUTSCENE_START_SCRIPT = 35;
  static final int CUTSCENE_END_SCRIPT = 36;
  static final int DEBUG_MODE = 39;
  static final int TIMER = 46;
  static final int TIMER_TOTAL = 47;
  static final int VIDEO_MODE = 49;
  static final int CURSOR_STATE = 52;
  static final int NEW_ROOM = 72;
  static final int MI1_SPECIAL = 74;

  ScummVM vm;
  ResourceManager res;
  GFX gfx;
  Room currentRoom;

  Map<int, Actor> actors;
  List<int> vars;
  Map<int, List<int>> arrays;

  GlobalContext(ScummVM vm, ResourceManager res, GFX gfx) {
    this.vm = vm; // This code is ugly. Need to be fixed later
    this.res = res;
    this.gfx = gfx;
    this.actors = new Map<int, Actor>();
    this.vars = new List<int>(800);
    this.arrays = new Map<int, List<int>>();
    initVars();
    initActors();
  }

  void initVars() {
    for (int i = 0; i < vars.length; i++) {
      vars[i] = 0;
    }
    vars[DEBUG_MODE] = 1;
    vars[EGO] = 3;
    vars[VIDEO_MODE] = 19;
    vars[MI1_SPECIAL] = 1225; // MI1 Special value (for copy protection?)
  }

  void initActors() {
    for (int i = 1; i <= 13; i++) {
      actors[i] = new Actor(i);
    }
  }

  void spawn(int scriptId, List<int> params) {
    Script script = getScript(scriptId);
    vm.spawn(script, params);
  }

  void freezeScripts(bool unfreeze, bool force) {
    if (unfreeze) {
      vm.unfreeze();
    } else {
      vm.freeze(force);
    }
  }

  void setGlobalVar(int index, int value) {
    vars[index] = value;
  }

  int getGlobalVar(int index) {
    return vars[index];
  }

  void storeArray(int index, List<int> array) {
    arrays[index] = array;
  }

  void storeArrayData(int arrayIndex, int index, int value) {
    arrays[arrayIndex][index] = value;
  }

  void freeArray(int index) {
    arrays.remove(index);
  }

  bool isScriptRunning(int scriptId) {
    return vm.isScriptRunning(scriptId);
  }

  void stopScript(int scriptId) {
    vm.stopScript(scriptId);
  }

  /* Room */
  void startRoom(int roomId) {
    setGlobalVar(NEW_ROOM, roomId);
    int scriptId = getGlobalVar(EXIT_SCRIPT);
    if (scriptId != 0) {
      vm.spawn(getScript(scriptId), new List<int>(16));
    }
    setGlobalVar(ROOM, roomId);
    setGlobalVar(ROOM_RESOURCE, roomId);
    // FIXME clear room objects
    if (roomId == 0) {
      return;
    }

    this.currentRoom = res.setupRoom(roomId);

    setGlobalVar(CAMERA_MIN_X, 160);
    setGlobalVar(CAMERA_MAX_X, this.currentRoom.width - 160);
    // FIXME set camera position

    // FIXME Configure & show actors

    scriptId = getGlobalVar(ENTRY_SCRIPT);
    vm.spawn(getScript(scriptId), new List<int>(16));
    vm.spawn(this.currentRoom.entry, new List<int>(16));
    scriptId = getGlobalVar(ENTRY_SCRIPT2);
    vm.spawn(getScript(scriptId), new List<int>(16));
  }

  /* Resources */

  Script getScript(int id) {
    Script s = res.getScript(id);
    if (s == null) {
      s = this.currentRoom.scripts[id];
    }
    return s;
  }

  Costume getCostume(int id) {
     return res.getCostume(id);
  }

  void loadCharsetResource(int id) {
    res.getCharset(id);
  }

  /* GFX */

  void initScreens(int b, int h) {
    gfx.initScreens(b, h);
  }

  void redrawBackground() {
    if (currentRoom == null) {
      return;
    }
    gfx.redrawBGStrip(currentRoom, 0, 40);
  }

  void setCameraAt(int x) {
    gfx.setCamera(x);
  }

  void adjustPalette(int index, int r, int g, int b) {
    gfx.adjustPalette(index, r, g, b);
  }

  /* Actors */

  void putActorInRoom(int actorId, int roomId) {
    Actor a = actors[actorId];
    if (roomId == 0) {
      a.put(0, 0, null);
    } else {
      throw new Exception("NYI putActorInRoom $roomId");
    }
  }

  int getActorRoom(int actorId) {
    Room room = actors[actorId].room;
    return room == null ? 0 : room.index;
  }
}