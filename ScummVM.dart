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

  Map<int, Charset> charsets;
  List<ExecutionContext> threads;
  Timer timer;
  Interpreter interpreter;

  GlobalContext global;
  ResourceManager resMgr;
  GFX gfx;
  Game game;
  int delta = 0;

  ScummVM() {
    this.charsets = new Map<int, Charset>();
    this.threads = new List<ExecutionContext>();
    this.timer = new Timer();
    this.interpreter = new Interpreter();
  }

  void start(Game game) {
    this.game = game;
    init();
    runBootstrapScript();
    window.webkitRequestAnimationFrame(mainLoop, document.query('#surface'));
  }

  void init() {
    print("Initializing VM");
    resMgr = new ResourceManager(game.assetManager);
    resMgr.loadIndex();
    gfx = new GFX(resMgr);
    global = new GlobalContext(this, resMgr, gfx);
  }

  void freeze(bool force) {
    ExecutionContext cur;
    threads.forEach((ExecutionContext ctx) {
      if (ctx.getStatus() == ExecutionContext.RUNNING && !ctx.isSuspended()) {
        cur = ctx;
      }
    });
    threads.forEach((ExecutionContext ctx) {
      if (ctx.script.index != cur.script.index && ctx.status != ExecutionContext.PENDED && ctx.status != ExecutionContext.DEAD) {
        ctx.freeze(force);
      }
    });
  }

  void unfreeze() {
    ExecutionContext cur;
    threads.forEach((ExecutionContext ctx) {
      if (ctx.getStatus() == ExecutionContext.RUNNING && !ctx.isSuspended()) {
        cur = ctx;
      }
    });
    threads.forEach((ExecutionContext ctx) {
      if (ctx.script.index != cur.script.index && ctx.frozenCount > 0) {
        ctx.unfreeze();
      }
    });
  }

  void spawn(Script script, List<int> params) {
    ExecutionContext parent;
    threads.forEach((ExecutionContext ctx) {
      if (ctx.getStatus() == ExecutionContext.RUNNING && !ctx.isSuspended()) {
        parent = ctx;
      }
    });
    ExecutionContext fork = parent.fork(script, params);
    parent.setStatus(ExecutionContext.PENDED);
    fork.setStatus(ExecutionContext.RUNNING);
    threads.add(fork);
    interpreter.run(fork);
    parent.setStatus(ExecutionContext.RUNNING);
  }

  bool isScriptRunning(int scriptId) {
    return threads.some((ExecutionContext ctx) {
      return ctx.script.index == scriptId;
    });
  }

  void stopScript(int scriptId) {
    threads.forEach((ExecutionContext ctx) {
      if (ctx.script.index == scriptId) {
        ctx.setStatus(ExecutionContext.DEAD);
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
    Script script = resMgr.getScript(index);
    ExecutionContext ctx = new ExecutionContext.root(global, script, params);
    ctx.setStatus(ExecutionContext.RUNNING);
    threads.add(ctx);
    interpreter.run(ctx);
  }

  void decreaseScriptsDelay(int clockTick) {
    threads.forEach((ExecutionContext ctx) {
      if (ctx != null) {
        if (ctx.getStatus() == ExecutionContext.DELAYED) {
          ctx.decreaseDelay(clockTick);
        }
      }
    });
  }

  void runAllScripts() {
    int i = 0;
    while (i < threads.length) {
      if (threads[i].getStatus() == ExecutionContext.DEAD) {
        threads.removeRange(i, 1);
      } else {
        i++;
      }
    }
    threads.forEach((ExecutionContext ctx) {
      if (ctx != null) {
        if (ctx.getStatus() == ExecutionContext.RUNNING && ctx.frozenCount == 0) {
          ctx.restore();
          interpreter.run(ctx);
        }
      }
    });
  }

  void redraw() {
    gfx.moveCamera();
    global.redrawBackground();
    //global.resetActorBgs();
    global.drawActors();
    gfx.drawDirty();
  }

  bool mainLoop(int time) {
    int clockTick = (this.timer.tick() * 60).round();
    delta += clockTick;
    if (delta >= 4) {
      global.setGlobalVar(GlobalContext.TIMER, delta);
      global.setGlobalVar(GlobalContext.TIMER_TOTAL, global.getGlobalVar(GlobalContext.TIMER_TOTAL) + delta);
      decreaseScriptsDelay(delta);
      // process input
      global.setGlobalVar(GlobalContext.MUSIC_TIMER, global.getGlobalVar(GlobalContext.MUSIC_TIMER) + 6);
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

  /* Resources */

  Script getScript(int id) {
    return resMgr.getScript(id);
  }

  void loadCharsetResource(int id) {
    resMgr.getCharset(id);
  }

}