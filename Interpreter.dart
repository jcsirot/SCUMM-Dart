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

class Interpreter {

  //Stream data;
  Map<int, Function> opcodes;

  Function log;
  Function data;

  Interpreter() {
    opcodes = new Map<int, Function>();
    opcodes[0x00] = op_stopObjectCode;
    opcodes[0x01] = OP3(op_putActor, false, false, false);
    opcodes[0x03] = OP1(op_getActorRoom, false);
    opcodes[0x05] = OP1(op_drawObject, false);
    opcodes[0x08] = OP1(op_isNotEqual, false);
    opcodes[0x0a] = OP3(op_startScript, false, false, false);
    opcodes[0x0c] = op_resourceRoutine;
    opcodes[0x11] = OP2(op_animateActor, false, false);
    opcodes[0x13] = OP1(op_actorOps, false);
    opcodes[0x14] = OP1(op_print, false);
    opcodes[0x18] = op_jumpRelative;
    opcodes[0x19] = OP3(op_doSentence, false, false, false);
    opcodes[0x1a] = OP1(op_move, false);
    opcodes[0x1c] = OP1(op_startSound, false);
    opcodes[0x21] = OP3(op_putActor, false, false, true);
    opcodes[0x2d] = OP2(op_putActorInRoom, false, false);
    opcodes[0x26] = op_setVarRange(true);
    opcodes[0x28] = op_equalZero;
    opcodes[0x27] = op_stringOps;
    opcodes[0x2c] = op_cursorCommand;
    opcodes[0x2e] = op_delay;
    opcodes[0x32] = OP1(op_setCameraAt, false);
    opcodes[0x33] = op_roomOps;
    opcodes[0x38] = OP1(op_isLessEquals, false);
    opcodes[0x3a] = OP1(op_sub, false);
    opcodes[0x3c] = OP1(op_stopSound, false);
    opcodes[0x40] = op_cutScene;
    opcodes[0x41] = OP3(op_putActor, false, true, false);
    opcodes[0x44] = OP1(op_isLess, false);
    opcodes[0x46] = op_increment;
    opcodes[0x48] = OP1(op_isEqual, false);
    opcodes[0x4a] = OP3(op_startScript, false, false, true);
    opcodes[0x51] = OP2(op_animateActor, false, true);
    opcodes[0x58] = op_override;
    opcodes[0x5a] = OP1(op_add, false);
    opcodes[0x60] = OP1(op_freezeScripts, false);
    opcodes[0x61] = OP3(op_putActor, false, true, true);
    opcodes[0x68] = OP1(op_isScriptRunning, false);
    opcodes[0x6d] = OP2(op_putActorInRoom, false, true);
    opcodes[0x72] = OP1(op_loadRoom, false);
    opcodes[0x78] = OP1(op_isGreater, false);
    opcodes[0x7a] = OP1(op_verbOps, false);
    opcodes[0x80] = op_breakHere;
    opcodes[0x81] = OP3(op_putActor, true, false, false);
    opcodes[0x83] = OP1(op_getActorRoom, true);
    opcodes[0x85] = OP1(op_drawObject, true);
    opcodes[0x88] = OP1(op_isNotEqual, true);
    opcodes[0x91] = OP2(op_animateActor, true, false);
    opcodes[0x93] = OP1(op_actorOps, true);
    opcodes[0x94] = OP1(op_print, true);
    opcodes[0x9a] = OP1(op_move, true);
    opcodes[0x9c] = OP1(op_startSound, true);
    opcodes[0xa0] = op_stopObjectCode;
    opcodes[0xa1] = OP3(op_putActor, true, false, true);
    opcodes[0xa6] = op_setVarRange(false);
    opcodes[0xa8] = op_notEqualZero;
    opcodes[0xaa] = OP1(op_sub, true);
    opcodes[0xac] = op_expression;
    opcodes[0xad] = OP2(op_putActorInRoom, true, false);
    opcodes[0xb2] = OP1(op_setCameraAt, true);
    opcodes[0xb8] = OP1(op_isLessEquals, true);
    opcodes[0xbc] = OP1(op_stopSound, true);
    opcodes[0xc1] = OP3(op_putActor, true, true, false);
    opcodes[0xc4] = OP1(op_isLess, true);
    opcodes[0xc8] = OP1(op_isEqual, true);
    opcodes[0xcc] = op_pseudoRoom;
    opcodes[0xd1] = OP2(op_animateActor, true, true);
    opcodes[0xda] = OP1(op_add, true);
    opcodes[0xe0] = OP1(op_freezeScripts, true);
    opcodes[0xe1] = OP3(op_putActor, true, true, true);
    opcodes[0xe8] = OP1(op_isScriptRunning, true);
    opcodes[0xed] = OP2(op_putActorInRoom, true, true);
    opcodes[0xf2] = OP1(op_loadRoom, true);
    opcodes[0xf8] = OP1(op_isGreater, true);
    opcodes[0xfa] = OP1(op_verbOps, true);
  }

  void run(ScummVM vm) {
    this.log = (String str) {
      print("[SCRIPT-${vm.currentThread.script.index}] $str");
    };
    this.data = () {
      return vm.currentThread.data;
    };
    while (true) {
      ExecutionContext t = vm.currentThread;
      if (t.getStatus() == ExecutionContext.DEAD) {
        return;
      }
      if (t.isSuspended()) {
        return;
      }
      if (t.data.eof()) {
        throw new Exception("End of the script has been reached.");
      }
      exec(vm);
    }
  }

  void exec(ScummVM vm) {
    int opcode = data().read();
    if (!opcodes.containsKey(opcode)) {
      throw new Exception("Unsupported script opcode: 0x${opcode.toRadixString(16)}");
    }
    opcodes[opcode](vm);
  }

  /* ===== Utilities methods ===== */

  Function OP1(Function op, bool indirect) {
    return (ScummVM vm) => op(vm, indirect);
  }

  Function OP2(Function op, bool indirect1, bool indirect2) {
    return (ScummVM vm) => op(vm, indirect1, indirect2);
  }

  Function OP3(Function op, bool indirect1, bool indirect2, bool indirect3) {
    return (ScummVM vm) => op(vm, indirect1, indirect2, indirect3);
  }

  List<int> readVarargs(ScummVM vm) {
    List<int> args = new List<int>();
    while (true) {
      int subOpcode = data().read();
      if (subOpcode == 0xff) {
        break;
      }
      bool ind = (subOpcode & 0x80) > 0;
      args.add(ind ? vm.getVar(data().read16LE()) : data().read16LE());
    }
    while(args.length < 16) { // FIXME length?
      args.add(0);
    }
    return args;
  }

  int jmp(ScummVM vm, bool cond) {
    int offset = data().read16LE();
    if (cond) {
      data().seek(offset);
    }
    return offset;
  }

  /* ===== Opcodes implementations ===== */

  void op_startScript(ScummVM vm, bool indirect, bool recursive, bool freezeResistant) {
    int scriptId = indirect ? vm.getVar(data().read16LE()) : data().read();
    List<int> params = readVarargs(vm);
    log("op_startScript script=$scriptId params=$params");
    //Script script = vm.getScript(scriptId);
    vm.spawnWithId(scriptId, params);
    //ExecutionContext fork = ctx.fork(script, params);
    //this.run(fork);
    /* Reinit Log after exiting nested script */
    //initLog(vm);
    log("op_startScript exit spawned script");
  }

  void op_resourceRoutine(ScummVM vm) {
    int subOpcode = data().read();
    // print("op_resourceRoutine opcode=0x${subOpcode.toRadixString(16)}");
    switch (subOpcode & 0x1f) {
    case 0x01:
      int resId = data().read();
      log("op_resourceRoutine load script=$resId");
      vm.getScript(resId);
      break;
    case 0x03:
      int resId = data().read();
      log("op_resourceRoutine load costume=$resId");
      vm.getCostume(resId);
      break;
    case 0x04:
      int resId = data().read();
      log("op_resourceRoutine load room=$resId");
      // load room. Do we need to do something?
      break;
    case 0x09:
      int resId = data().read();
      // FIXME lock script
      break;
    case 0xc:
      int resId = data().read();
      break;
    case 0x11:
      // FIXME clear the heap
      break;
    case 0x12:
      int resId = data().read();
      vm.loadCharsetResource(resId);
      log("op_resourceRoutine load charset=$resId");
      break;
    default:
      throw new Exception("Unsupported op_resourceRoutine sub-opcode=0x${subOpcode.toRadixString(16)}");
    }
  }

  void op_move(ScummVM vm, bool indirect) {
    int target = data().read16LE();
    int value = indirect ? vm.getVar(data().read16LE()) : data().read16LE();
    vm.setVar(target, value);
    //print("[SCRIPT-${vm.script.index}] op_move target=$target param=$value");
    log("op_move target=$target param=$value");
  }

  void op_cursorCommand(ScummVM vm) {
    int subOpcode = data().read();
    switch (subOpcode) {
    case Cursor.SO_CURSOR_ON:
    case Cursor.SO_CURSOR_OFF:
    case Cursor.SO_USERPUT_ON:
    case Cursor.SO_USERPUT_OFF:
      break;
    case Cursor.SO_CURSOR_SOFT_OFF:
      // FIXME
      break;
    case Cursor.SO_USERPUT_SOFT_OFF:
      // FIXME
      break;
    case Cursor.SO_CHARSET_SET:
      int charsetId = data().read();
      log("op_cursorCommand setCharset=$charsetId");
      /* FIXME set charset */
      break;
    default:
      throw new Exception("Unsupported op_cursorCommand sub-opcode=0x${subOpcode.toRadixString(16)}");
    }
    vm.setGlobalVar(ScummVM.CURSOR_STATE, 1);
    log("op_cursorCommand opcode=0x${subOpcode.toRadixString(16)}");
  }

  void op_isEqual(ScummVM vm, bool indirect) {
    int varAddr = data().read16LE();
    int value = indirect ? vm.getVar(data().read16LE()) : data().read16LE();
    int offset = jmp(vm, value != vm.getVar(varAddr));
    log("op_isEqual var=$varAddr offset=$offset");
  }

  void op_isNotEqual(ScummVM vm, bool indirect) {
    int varAddr = data().read16LE();
    int value = indirect ? vm.getVar(data().read16LE()) : data().read16LE();
    int offset = jmp(vm, value == vm.getVar(varAddr));
    log("op_isNotEqual var=$varAddr offset=$offset");
  }

  void op_stringOps(ScummVM vm) {
    int subOpcode = data().read();
    switch (subOpcode & 0x1f) {
    case 1:
      int idx = data().read();
      List<int> array = data().readArray();
      log("op_stringOps Load String index=$idx array=$array");
      vm.storeArray(idx, array);
      break;
    case 2:
    case 3:
      int arrIdx = data().read();
      int idx = data().read();
      int value = data().read();
      vm.storeArrayData(arrIdx, idx, value);
      break;
    case 4:
    case 5:
      int index = data().read();
      int len = data().read();
      if (len == 0) {
        vm.freeArray(index);
      } else {
        vm.storeArray(index, new List<int>(len));
      }
      break;
    default:
      log("Unsupported stringOps opcode ${subOpcode.toRadixString(16)}");
    }
    log("op_stringOps opcode=${subOpcode.toRadixString(16)}");
  }

  void op_notEqualZero(ScummVM vm) {
    int varAddr = data().read16LE();
    int offset = jmp(vm, vm.getVar(varAddr) == 0);
    log("op_notEqualZero var=$varAddr offset=$offset");
  }

  void op_equalZero(ScummVM vm) {
    int varAddr = data().read16LE();
    int offset = jmp(vm, vm.getVar(varAddr) != 0);
    log("op_equalZero var=$varAddr offset=$offset");
  }

  Function op_setVarRange(bool useByteValues) {
    return (ScummVM vm) => op_setVarRange_(vm, useByteValues);
  }

  void op_setVarRange_(ScummVM vm, bool useByteValues) {
    int index = data().read16LE();
    int len = data().read();
    for (int i = 0; i < len; i++) {
      vm.setGlobalVar(index + i, useByteValues ? data().read() : data().read16LE());
    }
    log("op_setVarRange/useByteValues=$useByteValues var=$index len=$len");
  }

  void op_expression(ScummVM vm) {
    int target = data().read16LE();
    while (true) {
      int subOpcode = data().read();
      if (subOpcode == 0xff) {
        break;
      }
      switch (subOpcode) {
      case 0x1:
        int value = data().read16LE();
        vm.currentThread.push(value);
        log("op_expression push value=$value");
        break;
      case 0x81:
        int varIdx = data().read16LE();
        vm.currentThread.push(vm.getVar(varIdx));
        log("op_expression push var=$varIdx");
        break;
      case 0x2:
        int v1 = vm.currentThread.pop();
        int v2 = vm.currentThread.pop();
        int value = v2 + v1;
        vm.currentThread.push(value);
        log("op_expression add");
        break;
      case 0x3:
        int v1 = vm.currentThread.pop();
        int v2 = vm.currentThread.pop();
        int value = v2 - v1;
        vm.currentThread.push(value);
        log("op_expression sub");
        break;
      case 0x4:
        int v1 = vm.currentThread.pop();
        int v2 = vm.currentThread.pop();
        int value = v2 * v1;
        vm.currentThread.push(value);
        log("op_expression mult");
        break;
      case 0x5:
        int v1 = vm.currentThread.pop();
        int v2 = vm.currentThread.pop();
        int value = v2 / v1;
        vm.currentThread.push(value);
        log("op_expression div");
        break;
      case 0x6:
        // FIXME execute opcode
        throw new Exception("op_expression NYI");
      default:
        log("Unsupported op_expression opcode=0x${subOpcode.toRadixString(16)}");
      }
    }
    vm.setVar(target, vm.currentThread.pop());
    log("op_expression target=$target");
  }

  void op_roomOps(ScummVM vm) {
    //print("script #$index, ptr=0x${(data().pointer()).toRadixString(16)}");
    int subOpcode = data().read();
    log("op_roomOps opcode=0x${subOpcode.toRadixString(16)}");
    switch (subOpcode) {
    case 0x03:
      int b = data().read16LE();
      int h = data().read16LE();
      log("op_roomOps Init Screen b=$b, h=$h");
      vm.initScreens(b, h);
      break;
    case 0x04:  // SO_ROOM_PALETTE
      int r = data().read16LE();
      int g = data().read16LE();
      int b = data().read16LE();
      int aux = data().read();
      int index = ((aux & 0x80) != 0) ? vm.getVar(data().read()) : data().read();
      log("op_roomOps Adjust Room Palette index=$index, r=$r, g=$g, b=$b");
      vm.adjustPalette(index, r, g, b);
      break;
    case 0x0a:
      int effect = data().read16LE();
      break;
    case 0x8a:
      int effect = vm.getVar(data().read16LE());
      break;
    case 0xe4:
      int r = vm.getVar(data().read16LE());
      int g = vm.getVar(data().read16LE());
      int b = vm.getVar(data().read16LE());
      int index = ((data().read() & 0x80) == 0) ? data().read() : vm.getVar(data().read16LE());
      log("op_roomOps Adjust Room Palette index=$index, r=$r, g=$g, b=$b");
      vm.adjustPalette(index, r, g, b);
      break;
    default:
      throw new Exception("Unsupported op_roomOps sub-opcode 0x${subOpcode.toRadixString(16)}");
    }
  }

  void op_stopObjectCode(ScummVM vm) {
    //vm.currentThread.setStatus(ExecutionContext.DEAD);
    vm.currentThread.kill();
    //vm.stopThisScript();
    log("op_stopObjectCode");
  }

  void op_verbOps(ScummVM vm, bool indirect) {
    int verbId = indirect ? vm.getVar(data().read16LE()) : data().read();
    while (true) {
      int subOpcode = data().read();
      if (subOpcode == 0xff) {
        break;
      }
      log("op_verbOps verbId=$verbId sub-opcode=0x${subOpcode.toRadixString(16)}");
      switch (subOpcode) {
      case 0x02:
        List<int> verbName = data().readArray();
        //vm.setVerb(verbId, verbName);
        break;
      case 0x03:
        int verbColor = data().read();
        //vm.setVerbColor(verbId, verbColor);
        break;
      case 0x06:
        //vm.setVerbOn(verbId);
        break;
      case 0x83:
        int verbColor = vm.getVar(data().read16LE());
        //vm.setVerbColor(verbId, verbColor);
        break;
      default:
        throw new Exception("Unsupported op_verbOps sub-opcode 0x${subOpcode.toRadixString(16)}");
      }
    }
  }

  void op_pseudoRoom(ScummVM vm) {
    log("op_pseudoRoom");
    while (true) {
      int val = data().read();
      if (val == 0) {
        break;
      }
      int res = data().read();
      // resource mapper
    }
  }

  void op_print(ScummVM vm, bool indirect) {
    int actorId = indirect ? vm.getVar(data().read16LE()) : data().read();
    Message msg;
    switch (actorId) {
    case 253:
      msg = new DebugMessage();
      break;
    default:
      msg = new DefaultMessage();
      break;
    }

    while (true) {
      int subOpcode = data().read();
      if (subOpcode == 0xff) {
        break;
      }
      switch (subOpcode) {
      case 0x00:
        msg.x = data().read16LE();
        msg.y = data().read16LE();
        log("op_print actor=$actorId x=${msg.x}, y=${msg.y}");
        break;
      case 0x01:
        // Color;
        msg.color = data().read();
        log("op_print actor=$actorId color=${msg.color}");
        break;
      case 0x04:
        // Center the text;
        msg.center = true;
        log("op_print actor=$actorId center");
        break;
      case 0x07:
        msg.overhead = true;
        log("op_print actor=$actorId overhead");
        break;
      case 0x0f:
        String s = new String.fromCharCodes(data().readArray());
        msg.setValue(s);
        log("op_print actor=$actorId print string");
        msg.printString(vm);
        return;
      default:
        throw new Exception("Unsupported op_print sub-opcode 0x${subOpcode.toRadixString(16)}");
      }
    }
  }

  void op_isGreater(ScummVM vm, bool indirect) {
    int varId = data().read16LE();
    int value = indirect ? vm.getVar(data().read16LE()) : data().read16LE();
    log("op_isGreater var=$varId value=$value");
    int offset = jmp(vm, value <= vm.getVar(varId));
  }

  void op_isLess(ScummVM vm, bool indirect) {
    int varId = data().read16LE();
    int value = indirect ? vm.getVar(data().read16LE()) : data().read16LE();
    log("op_isLess var=$varId value=$value");
    int offset = jmp(vm, value >= vm.getVar(varId));
  }

  void op_isLessEquals(ScummVM vm, bool indirect) {
    int varId = data().read16LE();
    int value = indirect ? vm.getVar(data().read16LE()) : data().read16LE();
    log("op_isLessEquals var=$varId value=$value");
    int offset = jmp(vm, value > vm.getVar(varId));
  }

  void op_jumpRelative(ScummVM vm) {
    jmp(vm, true);
  }

  void op_breakHere(ScummVM vm) {
    log("op_breakHere");
    vm.currentThread.suspend();
  }

  void op_isScriptRunning(ScummVM vm, bool indirect) {
    int varId = data().read16LE();
    int scriptId = indirect ? vm.getVar(data().read16LE()) : data().read();
    log("op_isScriptRunning result=$varId script=$scriptId");
    vm.setGlobalVar(varId, vm.isScriptRunning(scriptId) ? 1 : 0); // FIXME
  }

  void op_cutScene(ScummVM vm) {
    List<int> params = readVarargs(vm);
    log("op_cutScene params=$params");
    vm.beginCutScene(params);
  }

  void op_add(ScummVM vm, bool indirect) {
    int varId = data().read16LE();
    int value = indirect ? vm.getVar(data().read16LE()) : data().read16LE();
    log("op_add var=$varId value=$value");
    vm.setVar(varId, vm.getVar(varId) + value);
  }

  void op_sub(ScummVM vm, bool indirect) {
    int varId = data().read16LE();
    int value = indirect ? vm.getVar(data().read16LE()) : data().read16LE();
    log("op_sub var=$varId value=$value");
    vm.setVar(varId, vm.getVar(varId) - value);
  }

  void op_doSentence(ScummVM vm, bool ind1, bool ind2, bool ind3) {
    int verbId = ind1 ? vm.getVar(data().read16LE()) : data().read();
    if (verbId == 0xfe) {
      log("op_doSentence verb=$verbId");
      int scriptId = vm.getVar(ScummVM.SENTENCE_SCRIPT);
      vm.stopScript(scriptId);
    } else {
      int objA = ind2 ? vm.getVar(data().read16LE()) : data().read16LE();
      int objB = ind3 ? vm.getVar(data().read16LE()) : data().read16LE();
      log("op_doSentence verb=$verbId objectA=$objA objectB=$objB");
      // FIXME doSentence
    }
  }

  void op_freezeScripts(ScummVM vm, bool indirect) {
    int flag = indirect ? vm.getVar(data().read16LE()) : data().read();
    log("op_freezeScripts flag=0x${flag.toRadixString(16)}");
    vm.freezeScripts(flag == 0, (flag & 0x80) != 0);
  }

  void op_loadRoom(ScummVM vm, bool indirect) {
    int roomId = indirect ? vm.getVar(data().read16LE()) : data().read();
    log("op_loadRoom room=$roomId");
    vm.startRoom(roomId);
  }

  void op_setCameraAt(ScummVM vm, bool indirect) {
    int xpos = indirect ? vm.getVar(data().read16LE()) : data().read16LE();
    log("op_setCameraAt xpos=$xpos");
    vm.setCameraAt(xpos);
  }

  void op_startSound(ScummVM vm, bool indirect) {
    int sound = indirect ? vm.getVar(data().read16LE()) : data().read();
    log("op_startSound sound=$sound");
    vm.setGlobalVar(ScummVM.MUSIC_TIMER, 0);
    // FIXME?
  }

  void op_stopSound(ScummVM vm, bool indirect) {
    int sound = indirect ? vm.getVar(data().read16LE()) : data().read();
    log("op_stopSound sound=$sound");
    // FIXME?
  }

  void op_delay(ScummVM vm) {
    int delay = data().read() | (data().read() << 8) | (data().read() << 16);
    log("op_delay delay=$delay");
    vm.currentThread.delayExecution(delay);
  }

  void op_override(ScummVM vm) {
    int subOpcode = data().read();
    if (subOpcode == 0) {
      log("op_override end");
    } else {
      log("op_override begin");
      vm.setGlobalVar(ScummVM.OVERRIDE, 0);
      data().read();
      data().read();
      data().read();
      // FIXME
    }
  }

  void op_putActorInRoom(ScummVM vm, bool ind1, bool ind2) {
    int actorId = ind1 ? vm.getVar(data().read16LE()) : data().read();
    int roomId = ind2 ? vm.getVar(data().read16LE()) : data().read();
    log("op_putActorInRoom actor=$actorId room=$roomId");
    vm.putActorInRoom(actorId, roomId);
  }

  void op_increment(ScummVM vm) {
    int varAddr = data().read16LE();
    log("op_increment var=$varAddr");
    int value = vm.getVar(varAddr);
    vm.setVar(varAddr, value + 1);
  }

  void op_getActorRoom(ScummVM vm, bool indirect) {
    int varAddr = data().read16LE();
    int actorId = indirect ? vm.getVar(data().read16LE()) : data().read();
    log("op_getActorRoom res=$varAddr actor=$actorId");
    int roomId = vm.getActorRoom(actorId);
    vm.setVar(varAddr, roomId);
  }

  void op_actorOps(ScummVM vm, bool indirect) {
    int actorId = indirect ? vm.getVar(data().read16LE()) : data().read();
    while (true) {
      int subOpcode = data().read();
      if (subOpcode == 0xff) {
        break;
      }
      switch (subOpcode) {
      case 0x00:
        data().read(); // dummy
        break;
      case 0x01:
        int costumeId = data().read();
        log("op_actorOps actor=$actorId SO_COSTUME costume=$costumeId");
        vm.setActorCostume(actorId, costumeId);
        break;
      case 0x08:
        log("op_actorOps actor=$actorId SO_DEFAULT");
        break;
      case 0x0b:
        int index = data().read();
        int color = data().read();
        log("op_actorOps actor=$actorId SO_PALETTE index=$index color=$color");
        break;
      case 0x11:
        int sx = data().read();
        int sy = data().read();
        log("op_actorOps actor=$actorId SO_ACTOR_SCALE sx=$sx sy=$sy");
        break;
      case 0x12:
         log("op_actorOps actor=$actorId SO_NEVER_ZCLIP");
         vm.forceClipping(actorId, false);
         break;
      case 0x13:
        int zp = data().read();
        log("op_actorOps actor=$actorId SO_ALWAYS_ZCLIP z-plane=$zp");
         vm.forceClipping(actorId, true);
        break;
      case 0x14:
        log("op_actorOps actor=$actorId SO_IGNORE_BOXES");
        break;
      case 0x15:
        log("op_actorOps actor=$actorId SO_FOLLOW_BOXES");
        vm.putActorIfInCurrentRoom(actorId);
        break;
      case 0x80:
        data().read16LE(); // dummy
        break;
      default:
        throw new Exception("Unsupported op_actorOps actor=$actorId opcode=0x${subOpcode.toRadixString(16)}");
      }
    }
  }

  void op_putActor(ScummVM vm, bool ind1, bool ind2, bool ind3) {
    int actorId = ind1 ? vm.getVar(data().read16LE()) : data().read();
    int x = ind2 ? vm.getVar(data().read16LE()) : data().read16LE();
    int y = ind3 ? vm.getVar(data().read16LE()) : data().read16LE();
    log("op_putActor actor=$actorId x=$x y=$y");
    vm.putActor(actorId, x, y);
  }

  void op_animateActor(ScummVM vm, bool ind1, bool ind2) {
    int actorId = ind1 ? vm.getVar(data().read16LE()) : data().read();
    int animation = ind2 ? vm.getVar(data().read16LE()) : data().read();
    log("op_animateActor actor=$actorId animation=$animation");
    vm.animateActor(actorId, animation);
  }

  void op_drawObject(ScummVM vm, bool indirect) {
    int objectId = indirect ? vm.getVar(data().read16LE()) : data().read16LE();
    int x = null, y = null, state = null;
    while (true) {
      int subOpcode = data().read();
      if (subOpcode == 0xff) {
        break;
      }
      switch (subOpcode) {
      case 0x01:
        x = data().read16LE();
        y = data().read16LE();
        log("op_drawObject object=$objectId xpos=$x ypos=$y");
        break;
      case 0x02:
        int state = data().read16LE();
        log("op_drawObject object=$objectId state=$state");
        break;
      default:
        throw new Exception("Unsupported op_drawObject object=$objectId opcode=0x${subOpcode.toRadixString(16)}");
      }
    }
    log("op_drawObject draw object=$objectId");
    vm.pushObject(objectId);
  }
}