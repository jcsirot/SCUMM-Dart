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

class ExecutionContext {

  static final int RUNNING = 1;
  static final int PENDED = 2;
  static final int DELAYED = 3;
  static final int FROZEN = 4;
  static final int DEAD = 5;

  Script script;
  Stream data;
  List<int> local;
  bool recursive;
  bool freezeResistant;
  int frozenCount;
  int status;
  List<int> stack;
  bool active;
  int delay;

  ScummVM vm;
  GlobalContext global;
  /* parent context for nested scripts */
  ExecutionContext parent;

  ExecutionContext.root(GlobalContext global, Script script, List<int> params) {
    this.script = script;
    this.data = script.data.dup();
    this.global = global;
    this.local = params;
    this.stack = new List<int>();
    this.parent = null;
    this.active = true;
    this.frozenCount = 0;
    this.delay = 0;
  }

  ExecutionContext.fork(ExecutionContext ctx, Script script, List<int> params) {
    this.script = script;
    this.data = script.data.dup();
    this.global = ctx.global;
    this.parent = ctx;
    this.local = params;
    this.stack = new List<int>();
    this.active = true;
    this.frozenCount = 0;
    this.delay = 0;
  }

  ExecutionContext fork(Script script, List<int> params) {
    ExecutionContext ctx = new ExecutionContext.fork(this, script, params);
    return ctx;
  }

  void spawn(int scriptId, List<int> params) {
    global.spawn(scriptId, params);
  }

  void setStatus(int status) {
    this.status = status;
  }

  int getStatus() {
    return this.status;
  }

  void freeze(bool force) {
    if (!freezeResistant || force) {
      frozenCount++;
    }
  }

  void unfreeze() {
    if (frozenCount > 0) {
      frozenCount--;
    }
  }

  void freezeScripts(bool unfreeze, bool force) {
    global.freezeScripts(unfreeze, force);
  }

  void delayExecution(int delay) {
    this.delay = delay;
    this.status = DELAYED;
    suspend();
  }

  void decreaseDelay(int clockTick) {
    this.delay -= clockTick;
    if (delay < 0) {
      this.status = RUNNING;
      this.delay = 0;
    }
  }

  int getVar(int varAddr) {
    // FIXME Scumm V5 uses indirect word variables - NYI here
    if ((varAddr & 0x8000) != 0) {
      /* bit variable */
      throw new Exception("Bit variable NYI");
    } else if ((varAddr & 0x4000) != 0) {
      /* local variable */
      return getLocalVar(varAddr & 0xf);
    } else if ((~varAddr & 0xe000) != 0) {
      /* global variable */
      return global.getGlobalVar(varAddr & 0x1fff);
    } else {
      throw new Exception("Unknown variable type");
    }
    return 0;
  }

  void setVar(int varAddr, int value) {
    // FIXME Scumm V5 uses indirect word variables - NYI here
    if ((varAddr & 0x8000) != 0) {
      /* bit variable */
      throw new Exception("Bit variable NYI");
    } else if ((varAddr & 0x4000) != 0) {
      /* local variable */
      setLocalVar(varAddr & 0xf, value);
    } else if ((~varAddr & 0xe000) != 0) {
      /* global variable */
      global.setGlobalVar(varAddr & 0x1fff, value);
    } else {
      throw new Exception("Unknown variable type");
    }
  }

  void setGlobalVar(int index, int value) {
    global.setGlobalVar(index, value);
  }

  int getGlobalVar(int index) {
    return global.getGlobalVar(index);
  }

  int getLocalVar(int index) {
    return local[index];
  }

  int setLocalVar(int index, int value) {
    local[index] = value;
  }

  void storeArray(int index, List<int> array) {
    global.storeArray(index, array);
  }

  void storeArrayData(int arrayIndex, int index, int value) {
    global.storeArrayData(arrayIndex, index, value);
  }

  void freeArray(int index) {
    global.freeArray(index);
  }

  bool isSuspended() {
    return !active;
  }

  void suspend() {
    this.active = false;
  }

  void restore() {
    this.active = true;
  }

  bool isScriptRunning(int scriptId) {
    return global.isScriptRunning(scriptId);
  }

  void stopScript(int scriptId) {
    global.stopScript(scriptId);
  }

  void startRoom(int roomId) {
    global.startRoom(roomId);
  }

  /* heap operations */

  void push(int value) {
    stack.add(value);
  }

  int pop() {
    return stack.removeLast();
  }

  /* Resources */

  Script getScript(int id) {
    return global.getScript(id);
  }

  Costume getCostume(int id) {
    return global.getCostume(id);
  }

  void loadCharsetResource(int id) {
    global.loadCharsetResource(id);
  }

  /* GFX */

  void initScreens(int b, int h) {
    global.initScreens(b, h);
  }

  void beginCutScene(List<int> params) {
    // FIXME initialize the cut scene
    global.spawn(getVar(GlobalContext.CUTSCENE_START_SCRIPT), params);
  }

  void setCameraAt(int xpos) {
    global.setCameraAt(xpos);
  }

  void adjustPalette(int index, int r, int g, int b) {
    global.adjustPalette(index, r, g, b);
  }

  /* Actors */

  void putActorInRoom(int actorId, int roomId) {
    global.putActorInRoom(actorId, roomId);
  }

  int getActorRoom(int actorId) {
    return global.getActorRoom(actorId);
  }
}