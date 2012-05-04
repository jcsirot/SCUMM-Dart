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

class ScummVM {

  /* Global const */
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

  Map<int, Charset> charsets;
  List<Thread> threads;
  Timer timer;
  Interpreter interpreter;
  ResourceManager res;
  GFX gfx;
  Game game;
  int delta = 0;

  Thread currentThread;
  Room currentRoom;
  Map<int, Actor> actors;
  List<int> vars;
  Map<int, List<int>> arrays;
  List<RoomObject> objs;

  ScummVM() {
    this.charsets = new Map<int, Charset>();
    this.threads = new List<Thread>();
    this.timer = new Timer();
    this.interpreter = new Interpreter();
    this.actors = new Map<int, Actor>();
    this.vars = new List<int>(800);
    this.arrays = new Map<int, List<int>>();
    this.objs = new List<RoomObject>();
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
      actors[i] = new Actor(i, (Room r) {
        return r == currentRoom;
      });
    }
  }

  void start(Game game) {
    this.game = game;
    init();
    runBootstrapScript();
    window.webkitRequestAnimationFrame(mainLoop, document.query('#surface'));
  }

  void init() {
    print("Initializing VM");
    res = new ResourceManager(game.assetManager);
    res.loadIndex();
    gfx = new GFX(res);
  }

  void freeze(bool force) {
    Thread cur;
    threads.forEach((Thread t) {
      if (t.getStatus() == Thread.RUNNING && !t.isSuspended()) {
        cur = t;
      }
    });
    threads.forEach((Thread t) {
      if (t.script.index != cur.script.index && t.status != Thread.PENDED && t.status != Thread.DEAD) {
        t.freeze(force);
      }
    });
  }

  void unfreeze() {
    Thread cur;
    threads.forEach((Thread t) {
      if (t.getStatus() == Thread.RUNNING && !t.isSuspended()) {
        cur = t;
      }
    });
    threads.forEach((Thread t) {
      if (t.script.index != cur.script.index && t.frozenCount > 0) {
        t.unfreeze();
      }
    });
  }

  void spawnWithId(int scriptId, List<int> params) {
    spawn(getScript(scriptId), params);
  }

  void spawn(Script script, List<int> params) {
    Thread parent;
    threads.forEach((Thread t) {
      if (t.getStatus() == Thread.RUNNING && !t.isSuspended()) {
        parent = t;
      }
    });
    Thread fork = parent.fork(script, params);
    parent.setStatus(Thread.PENDED);
    fork.setStatus(Thread.RUNNING);
    threads.add(fork);
    run(fork);
    parent.setStatus(Thread.RUNNING);
    this.currentThread = parent;
  }

  void freezeScripts(bool unfreeze, bool force) {
    if (unfreeze) {
      this.unfreeze();
    } else {
      this.freeze(force);
    }
  }

  bool isScriptRunning(int scriptId) {
    return threads.some((Thread t) {
      return t.script.index == scriptId;
    });
  }

  void stopScript(int scriptId) {
    threads.forEach((Thread t) {
      if (t.script.index == scriptId) {
        t.setStatus(Thread.DEAD);
      }
    });
  }

  void runBootstrapScript() {
    List<int> params = new List<int>(16);
    for (int i = 0; i < 16; i++) {
      params[i] = 0;
    }
    runScript(1, params);
  }

  void runScript(int index, List<int> params) {
    Script script = res.getScript(index);
    Thread t = new Thread.root(this, script, params);
    t.setStatus(Thread.RUNNING);
    threads.add(t);
    run(t);
  }

  void decreaseScriptsDelay(int clockTick) {
    threads.forEach((Thread t) {
      if (t != null) {
        if (t.getStatus() == Thread.DELAYED) {
          t.decreaseDelay(clockTick);
        }
      }
    });
  }

  void runAllScripts() {
    int i = 0;
    while (i < threads.length) {
      if (threads[i].getStatus() == Thread.DEAD) {
        threads.removeRange(i, 1);
      } else {
        i++;
      }
    }
    threads.forEach((Thread t) {
      if (t != null) {
        if (t.getStatus() == Thread.RUNNING && t.frozenCount == 0) {
          t.restore();
          run(t);
        }
      }
    });
  }

  void run(Thread thread) {
    this.currentThread = thread;
    interpreter.run(this);
  }

  void redraw() {
    gfx.moveCamera();
    redrawBackground();
    //global.resetActorBgs();
    drawActors();
    gfx.drawDirty();
  }

  bool mainLoop(int time) {
    int clockTick = (this.timer.tick() * 60).round();
    delta += clockTick;
    if (delta >= 5) {
      setGlobalVar(TIMER, delta);
      setGlobalVar(TIMER_TOTAL, getGlobalVar(TIMER_TOTAL) + delta);
      decreaseScriptsDelay(delta);
      // process input
      setGlobalVar(MUSIC_TIMER, getGlobalVar(MUSIC_TIMER) + 6);
      runAllScripts();
      redraw();
      delta = 0;
    }
    window.webkitRequestAnimationFrame(mainLoop, document.query('#surface'));
  }

  /* GFX */

  void initScreens(int b, int h) {
    gfx.initScreens(b, h);
  }

  void beginCutScene(List<int> params) {
    // FIXME initialize the cut scene
    spawnWithId(getVar(CUTSCENE_START_SCRIPT), params);
  }

  void redrawBackground() {
    if (currentRoom == null) {
      return;
    }
    gfx.redrawBGStrip(currentRoom, 0, 40);
    objs.forEach((RoomObject obj) {
      gfx.drawObject(obj);
    });
    objs = new List<RoomObject>();
  }

  void drawActors() {
    gfx.main.resetMainBuffer();
    // sort actors
    actors.getValues().filter((Actor a) => a.costume != null).forEach((Actor a) {
      gfx.drawCostume(a);
    });
  }

  void setCameraAt(int x) {
    gfx.setCamera(x);
  }

  void adjustPalette(int index, int r, int g, int b) {
    gfx.adjustPalette(index, r, g, b);
  }

  void pushObject(int objectId) {
    RoomObject obj = currentRoom.getObject(objectId);
    objs.add(obj);
  }

  /* Resources */

  Script getScript(int id) {
    Script s = res.getScript(id);
    if (s == null) {
      s = this.currentRoom.scripts[id];
    }
    return s;
  }

  void loadCharsetResource(int id) {
    res.getCharset(id);
  }

  Costume getCostume(int id) {
     return res.getCostume(id);
  }

  /* Variables */

  int getVar(int varAddr) {
    // FIXME Scumm V5 uses indirect word variables - NYI here
    if ((varAddr & 0x8000) != 0) {
      /* bit variable */
      throw new Exception("Bit variable NYI");
    } else if ((varAddr & 0x4000) != 0) {
      /* local variable */
      return currentThread.getLocalVar(varAddr & 0xf);
    } else if ((~varAddr & 0xe000) != 0) {
      /* global variable */
      return getGlobalVar(varAddr & 0x1fff);
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
      currentThread.setLocalVar(varAddr & 0xf, value);
    } else if ((~varAddr & 0xe000) != 0) {
      /* global variable */
      setGlobalVar(varAddr & 0x1fff, value);
    } else {
      throw new Exception("Unknown variable type");
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

  /* Room */

  void startRoom(int roomId) {
    setGlobalVar(NEW_ROOM, roomId);
    int scriptId = getGlobalVar(EXIT_SCRIPT);
    if (scriptId != 0) {
      spawn(getScript(scriptId), new List<int>(16));
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
    spawn(getScript(scriptId), new List<int>(16));
    spawn(this.currentRoom.entry, new List<int>(16));
    scriptId = getGlobalVar(ENTRY_SCRIPT2);
    spawn(getScript(scriptId), new List<int>(16));
  }

  /* Actors */

  void putActorInRoom(int actorId, int roomId) {
    Actor a = actors[actorId];
    if (roomId == 0) {
      a.putInRoom(0, 0, null);
    } else {
      a.room = res.setupRoom(roomId);
      a.show();
    }
  }

  void putActor(int actorId, int x, int y) {
    Actor a = actors[actorId];
    a.put(x, y);
  }

  void putActorIfInCurrentRoom(int actorId) {
    Actor a = actors[actorId];
    if (a.isInCurrentRoom()) {
      a.put(0, 0);
    }
  }

  int getActorRoom(int actorId) {
    Room room = actors[actorId].room;
    return room == null ? 0 : room.index;
  }

  void setActorCostume(int actorId, int costumeId) {
    Actor a = actors[actorId];
    Costume c = res.getCostume(costumeId);
    a.setCostume(c);
  }

  void animateActor(int actorId, int frame) {
    Actor a = actors[actorId];
    a.animate(frame);
  }

  void drawActorMessage(Message msg) {
    Charset charset = res.getCharset(4); // FIXME
    int width = charset.getStringWidth(msg.value);
    int xstart = msg.center ? msg.x - (width >> 1) : msg.x;
    charset.printString(msg.value, xstart, msg.y, width, msg.color, gfx.main);
  }

  void forceClipping(int actorId, bool clipped) {
    Actor a = actors[actorId];
    a.clipped = clipped;
  }

}