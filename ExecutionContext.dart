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
  /* parent context for nested scripts */
  ExecutionContext parent;

  ExecutionContext.root(ScummVM vm, Script script, List<int> params) {
    this.script = script;
    this.data = script.data.dup();
    this.vm = vm;
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
    this.vm = ctx.vm;
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

  void setStatus(int status) {
    this.status = status;
  }

  int getStatus() {
    return this.status;
  }

  void kill() {
    setStatus(DEAD);
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

  int getLocalVar(int index) {
    return local[index];
  }

  int setLocalVar(int index, int value) {
    local[index] = value;
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

  /* heap operations */

  void push(int value) {
    stack.add(value);
  }

  int pop() {
    return stack.removeLast();
  }
}