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

  Interpreter() {
    opcodes = new Map<int, Function>();
    opcodes[0x00] = op_stopObjectCode;
    opcodes[0x03] = OP1(op_getActorRoom, false);
    opcodes[0x08] = OP1(op_isNotEqual, false);
    opcodes[0x0a] = OP3(op_startScript, false, false, false);
    opcodes[0x0c] = op_resourceRoutine;
    opcodes[0x13] = OP1(op_actorOps, false);
    opcodes[0x14] = OP1(op_print, false);
    opcodes[0x18] = op_jumpRelative;
    opcodes[0x19] = OP3(op_doSentence, false, false, false);
    opcodes[0x1a] = OP1(op_move, false);
    opcodes[0x1c] = OP1(op_startSound, false);
    opcodes[0x2d] = OP2(op_putActorInRoom, false, false);
    opcodes[0x26] = op_setVarRange(true);
    opcodes[0x28] = op_equalZero;
    opcodes[0x27] = op_stringOps;
    opcodes[0x2c] = op_cursorCommand;
    opcodes[0x2e] = op_delay;
    opcodes[0x32] = OP1(op_setCameraAt, false);
    opcodes[0x33] = op_roomOps;
    opcodes[0x38] = OP1(op_isLessEquals, false);
    opcodes[0x3c] = OP1(op_stopSound, false);
    opcodes[0x40] = op_cutScene;
    opcodes[0x44] = op_isLess(false);
    opcodes[0x46] = op_increment;
    opcodes[0x48] = op_isEqual(false);
    opcodes[0x4a] = OP3(op_startScript, false, false, true);
    opcodes[0x58] = op_override;
    opcodes[0x5a] = OP1(op_add, false);
    opcodes[0x60] = OP1(op_freezeScripts, false);
    opcodes[0x68] = OP1(op_isScriptRunning, false);
    opcodes[0x6d] = OP2(op_putActorInRoom, false, true);
    opcodes[0x72] = OP1(op_loadRoom, false);
    opcodes[0x78] = op_isGreater(false);
    opcodes[0x7a] = op_verbOps(false);
    opcodes[0x80] = op_breakHere;
    opcodes[0x83] = OP1(op_getActorRoom, true);
    opcodes[0x88] = OP1(op_isNotEqual, true);
    opcodes[0x93] = OP1(op_actorOps, true);
    opcodes[0x94] = OP1(op_print, true);
    opcodes[0x9a] = OP1(op_move, true);
    opcodes[0x9c] = OP1(op_startSound, true);
    opcodes[0xa0] = op_stopObjectCode;
    opcodes[0xa6] = op_setVarRange(false);
    opcodes[0xa8] = op_notEqualZero;
    opcodes[0xac] = op_expression;
    opcodes[0xad] = OP2(op_putActorInRoom, true, false);
    opcodes[0xb2] = OP1(op_setCameraAt, true);
    opcodes[0xb8] = OP1(op_isLessEquals, true);
    opcodes[0xbc] = OP1(op_stopSound, true);
    opcodes[0xc4] = op_isLess(true);
    opcodes[0xc8] = op_isEqual(true);
    opcodes[0xcc] = op_pseudoRoom;
    opcodes[0xda] = OP1(op_add, true);
    opcodes[0xe0] = OP1(op_freezeScripts, true);
    opcodes[0xe8] = OP1(op_isScriptRunning, true);
    opcodes[0xed] = OP2(op_putActorInRoom, true, true);
    opcodes[0xf2] = OP1(op_loadRoom, true);
    opcodes[0xf8] = op_isGreater(true);
    opcodes[0xfa] = op_verbOps(true);
  }

  void run(ExecutionContext ctx) {
    //data = ctx.data;
    while (true) {
      if (ctx.getStatus() == ExecutionContext.DEAD) {
        return;
      }
      if (ctx.isSuspended()) {
        return;
      }
      if (ctx.data.eof()) {
        throw new Exception("End of the script has been reached.");
      }
      exec(ctx);
    }
  }

  void exec(ExecutionContext ctx) {
    int opcode = ctx.data.read();
    if (!opcodes.containsKey(opcode)) {
      throw new Exception("Unsupported script opcode: 0x${opcode.toRadixString(16)}");
    }
    opcodes[opcode](ctx);
  }

  /* ===== Utilities methods ===== */

  Function OP1(Function op, bool indirect) {
    return (ExecutionContext ctx) => op(ctx, indirect);
  }

  Function OP2(Function op, bool indirect1, bool indirect2) {
    return (ExecutionContext ctx) => op(ctx, indirect1, indirect2);
  }

  Function OP3(Function op, bool indirect1, bool indirect2, bool indirect3) {
    return (ExecutionContext ctx) => op(ctx, indirect1, indirect2, indirect3);
  }


  List<int> readVarargs(ExecutionContext ctx) {
    List<int> args = new List<int>(16); // FIXME length?
    for (int i = 0; i < args.length; i++) {
      args[i] = 0;
    }
    while (true) {
      int subOpcode = ctx.data.read();
      if (subOpcode == 0xff) {
        break;
      }
      bool ind = (subOpcode & 0x80) > 0;
      args.add(ind ? ctx.getVar(ctx.data.read16LE()) : ctx.data.read16LE());
    }
    return args;
  }

  int jmp(ExecutionContext ctx, bool cond) {
    int offset = ctx.data.read16LE();
    if (cond) {
      ctx.data.seek(offset);
    }
    return offset;
  }

  /* ===== Opcodes implementations ===== */

  void op_startScript(ExecutionContext ctx, bool indirect, bool recursive, bool freezeResistant) {
    int scriptId = indirect ? ctx.getVar(ctx.data.read16LE()) : ctx.data.read();
    List<int> params = readVarargs(ctx);
    print("op_startScript script=$scriptId params=$params");
    //Script script = ctx.getScript(scriptId);
    ctx.spawn(scriptId, params);
    //ExecutionContext fork = ctx.fork(script, params);
    //this.run(fork);
  }

  void op_resourceRoutine(ExecutionContext ctx) {
    int subOpcode = ctx.data.read();
    // print("op_resourceRoutine opcode=0x${subOpcode.toRadixString(16)}");
    switch (subOpcode & 0x1f) {
    case 0x01:
      int resId = ctx.data.read();
      print("op_resourceRoutine load script=$resId");
      ctx.getScript(resId);
      break;
    case 0x03:
      int resId = ctx.data.read();
      print("op_resourceRoutine load costume=$resId");
      ctx.getCostume(resId);
      break;
    case 0x04:
      int resId = ctx.data.read();
      print("op_resourceRoutine load room=$resId");
      // load room. Do we need to do something?
      break;
    case 0x09:
      int resId = ctx.data.read();
      // FIXME lock script
      break;
    case 0xc:
      int resId = ctx.data.read();
      break;
    case 0x11:
      // FIXME clear the heap
      break;
    case 0x12:
      int resId = ctx.data.read();
      ctx.loadCharsetResource(resId);
      print("op_resourceRoutine load charset=$resId");
      break;
    default:
      throw new Exception("Unsupported op_resourceRoutine sub-opcode=0x${subOpcode.toRadixString(16)}");
    }
  }
  
  void op_move(ExecutionContext ctx, bool indirect) {
    int target = ctx.data.read16LE();
    int value = indirect ? ctx.getVar(ctx.data.read16LE()) : ctx.data.read16LE();
    ctx.setVar(target, value);
    //print("[SCRIPT-${ctx.script.index}] op_move target=$target param=$value");
    print("op_move target=$target param=$value");
  }

  void op_cursorCommand(ExecutionContext ctx) {
    int subOpcode = ctx.data.read();
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
      int idx = ctx.data.read();
      /* FIXME set charset */
      break;
    default:
      throw new Exception("Unsupported op_cursorCommand sub-opcode=0x${subOpcode.toRadixString(16)}");
    }
    ctx.setGlobalVar(GlobalContext.CURSOR_STATE, 1);
    print("op_cursorCommand opcode=0x${subOpcode.toRadixString(16)}");
  }

  Function op_isEqual(bool indirect) {
    return (ExecutionContext ctx) => op_isEqual_(ctx, indirect);
  }

  void op_isEqual_(ExecutionContext ctx, bool indirect) {
    int varAddr = ctx.data.read16LE();
    int value = indirect ? ctx.getVar(ctx.data.read16LE()) : ctx.data.read16LE();
    int offset = jmp(ctx, value != ctx.getVar(varAddr));
    print("op_isEqual var=$varAddr offset=$offset");
  }

  void op_isNotEqual(ExecutionContext ctx, bool indirect) {
    int varAddr = ctx.data.read16LE();
    int value = indirect ? ctx.getVar(ctx.data.read16LE()) : ctx.data.read16LE();
    int offset = jmp(ctx, value == ctx.getVar(varAddr));
    print("op_isNotEqual var=$varAddr offset=$offset");
  }

  void op_stringOps(ExecutionContext ctx) {
    int subOpcode = ctx.data.read();
    switch (subOpcode & 0x1f) {
    case 1:
      int idx = ctx.data.read();
      List<int> array = ctx.data.readArray();
      print("op_stringOps Load String index=$idx array=$array");
      ctx.storeArray(idx, array);
      break;
    case 2:
    case 3:
      int arrIdx = ctx.data.read();
      int idx = ctx.data.read();
      int value = ctx.data.read();
      ctx.storeArrayData(arrIdx, idx, value);
      break;
    case 4:
    case 5:
      int index = ctx.data.read();
      int len = ctx.data.read();
      if (len == 0) {
        ctx.freeArray(index);
      } else {
        ctx.storeArray(index, new List<int>(len));
      }
      break;
    default:
      print("Unsupported stringOps opcode ${subOpcode.toRadixString(16)}");
    }
    print("op_stringOps opcode=${subOpcode.toRadixString(16)}");
  }

  void op_notEqualZero(ExecutionContext ctx) {
    int varAddr = ctx.data.read16LE();
    int offset = jmp(ctx, ctx.getVar(varAddr) == 0);
    print("op_notEqualZero var=$varAddr offset=$offset");
  }

  void op_equalZero(ExecutionContext ctx) {
    int varAddr = ctx.data.read16LE();
    int offset = jmp(ctx, ctx.getVar(varAddr) != 0);
    print("op_equalZero var=$varAddr offset=$offset");
  }

  Function op_setVarRange(bool useByteValues) {
    return (ExecutionContext ctx) => op_setVarRange_(ctx, useByteValues);
  }

  void op_setVarRange_(ExecutionContext ctx, bool useByteValues) {
    int index = ctx.data.read16LE();
    int len = ctx.data.read();
    for (int i = 0; i < len; i++) {
      ctx.setGlobalVar(index + i, useByteValues ? ctx.data.read() : ctx.data.read16LE());
    }
    print("op_setVarRange/useByteValues=$useByteValues var=$index len=$len");
  }

  void op_expression(ExecutionContext ctx) {
    int target = ctx.data.read16LE();
    while (true) {
      int subOpcode = ctx.data.read();
      if (subOpcode == 0xff) {
        break;
      }
      switch (subOpcode) {
      case 0x1:
        int value = ctx.data.read16LE();
        ctx.push(value);
        print("op_expression push value=$value");
        break;
      case 0x81:
        int varIdx = ctx.data.read16LE();
        ctx.push(ctx.getVar(varIdx));
        print("op_expression push var=$varIdx");
        break;
      case 0x2:
        int v1 = ctx.pop();
        int v2 = ctx.pop();
        int value = v2 + v1;
        ctx.push(value);
        print("op_expression add");
      case 0x3:
        int v1 = ctx.pop();
        int v2 = ctx.pop();
        int value = v2 - v1;
        ctx.push(value);
        print("op_expression sub");
        break;
      case 0x4:
        int v1 = ctx.pop();
        int v2 = ctx.pop();
        int value = v2 * v1;
        ctx.push(value);
        print("op_expression mult");
        break;
      case 0x5:
        int v1 = ctx.pop();
        int v2 = ctx.pop();
        int value = v2 / v1;
        ctx.push(value);
        print("op_expression div");
        break;
      case 0x6:
        // FIXME execute opcode
        throw new Exception("NYI");
      default:
        print("Unsupported op_expression opcode=0x${subOpcode.toRadixString(16)}");
      }
    }
    ctx.setGlobalVar(target, ctx.pop());
    print("op_expression target=$target");
  }

  void op_roomOps(ExecutionContext ctx) {
    //print("script #$index, ptr=0x${(ctx.data.pointer()).toRadixString(16)}");
    int subOpcode = ctx.data.read();
    print("op_roomOps opcode=0x${subOpcode.toRadixString(16)}");
    switch (subOpcode) {
    case 0x03:
      int b = ctx.data.read16LE();
      int h = ctx.data.read16LE();
      print ("op_RoomOps Init Screen b=$b, h=$h");
      ctx.initScreens(b, h);
      break;
    case 0x04:  // SO_ROOM_PALETTE
      int r = ctx.data.read16LE();
      int g = ctx.data.read16LE();
      int b = ctx.data.read16LE();
      int aux = ctx.data.read();
      int index = ((aux & 0x80) != 0) ? ctx.getVar(ctx.data.read()) : ctx.data.read();
      print ("op_RoomOps Adjust Room Palette index=$index, r=$r, g=$g, b=$b");
      ctx.adjustPalette(index, r, g, b);
      break;
    case 0x0a:
      int effect = ctx.data.read16LE();
      break;
    case 0x8a:
      int effect = ctx.getVar(ctx.data.read16LE());
      break;
    case 0xe4:
      int r = ctx.getVar(ctx.data.read16LE());
      int g = ctx.getVar(ctx.data.read16LE());
      int b = ctx.getVar(ctx.data.read16LE());
      int index = ((ctx.data.read() & 0x80) == 0) ? ctx.data.read() : ctx.getVar(ctx.data.read16LE());
      print ("op_RoomOps Adjust Room Palette index=$index, r=$r, g=$g, b=$b");
      ctx.adjustPalette(index, r, g, b);
      break;
    default:
      throw new Exception("Unsupported op_roomOps sub-opcode 0x${subOpcode.toRadixString(16)}");
    }
  }

  void op_stopObjectCode(ExecutionContext ctx) {
    ctx.setStatus(ExecutionContext.DEAD);
    //ctx.stopThisScript();
    print("op_stopObjectCode");
  }

  Function op_verbOps(bool indirect) {
    return (ExecutionContext ctx) => op_verbOps_(ctx, indirect);
  }

  void op_verbOps_(ExecutionContext ctx, bool indirect) {
    int verbId = indirect ? ctx.getVar(ctx.data.read16LE()) : ctx.data.read();
    while (true) {
      int subOpcode = ctx.data.read();
      if (subOpcode == 0xff) {
        break;
      }
      print("op_verbOps verbId=$verbId sub-opcode=0x${subOpcode.toRadixString(16)}");
      switch (subOpcode) {
      case 0x02:
        List<int> verbName = ctx.data.readArray();
        //ctx.setVerb(verbId, verbName);
        break;
      case 0x03:
        int verbColor = ctx.data.read();
        //ctx.setVerbColor(verbId, verbColor);
        break;
      case 0x06:
        //ctx.setVerbOn(verbId);
        break;
      case 0x83:
        int verbColor = ctx.getVar(ctx.data.read16LE());
        //ctx.setVerbColor(verbId, verbColor);
        break;
      default:
        throw new Exception("Unsupported op_verbOps sub-opcode 0x${subOpcode.toRadixString(16)}");
      }
    }
  }

  void op_pseudoRoom(ExecutionContext ctx) {
    print("op_pseudoRoom");
    while (true) {
      int val = ctx.data.read();
      if (val == 0) {
        break;
      }
      int res = ctx.data.read();
      // resource mapper
    }
  }

  void op_print(ExecutionContext ctx, bool indirect) {
    int actorId = indirect ? ctx.getVar(ctx.data.read16LE()) : ctx.data.read();
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
      int subOpcode = ctx.data.read();
      if (subOpcode == 0xff) {
        break;
      }
      print("op_print actor=$actorId sub-opcode=$subOpcode");
      switch (subOpcode) {
      case 0x00:
        msg.x = ctx.data.read16LE();
        msg.y = ctx.data.read16LE();
        break;
      case 0x01:
        // Color;
        msg.color = ctx.data.read();
        break;
      case 0x04:
        // Center the text;
        break;
      case 0x07:
        msg.overhead = true;
        break;
      case 0x0f:
        String s = new String.fromCharCodes(ctx.data.readArray());
        msg.setValue(s);
        msg.printString(ctx);
        return;
      default:
        throw new Exception("Unsupported op_print sub-opcode 0x${subOpcode.toRadixString(16)}");
      }
    }
  }

  Function op_isGreater(bool indirect) {
    return (ExecutionContext ctx) => op_isGreater_(ctx, indirect);
  }

  void op_isGreater_(ExecutionContext ctx, bool indirect) {
    int varId = ctx.data.read16LE();
    int value = indirect ? ctx.getVar(ctx.data.read16LE()) : ctx.data.read16LE();
    print("op_isGreater var=$varId value=$value");
    int offset = jmp(ctx, value <= ctx.getVar(varId));
  }

  Function op_isLess(bool indirect) {
    return (ExecutionContext ctx) => op_isLess_(ctx, indirect);
  }

  void op_isLess_(ExecutionContext ctx, bool indirect) {
    int varId = ctx.data.read16LE();
    int value = indirect ? ctx.getVar(ctx.data.read16LE()) : ctx.data.read16LE();
    print("op_isLess var=$varId value=$value");
    int offset = jmp(ctx, value >= ctx.getVar(varId));
  }

  void op_isLessEquals(ExecutionContext ctx, bool indirect) {
    int varId = ctx.data.read16LE();
    int value = indirect ? ctx.getVar(ctx.data.read16LE()) : ctx.data.read16LE();
    print("op_isLessEquals var=$varId value=$value");
    int offset = jmp(ctx, value > ctx.getVar(varId));
  }

  void op_jumpRelative(ExecutionContext ctx) {
    jmp(ctx, true);
  }

  void op_breakHere(ExecutionContext ctx) {
    print("op_breakHere");
    ctx.suspend();
  }

  void op_isScriptRunning(ExecutionContext ctx, bool indirect) {
    int varId = ctx.data.read16LE();
    int scriptId = indirect ? ctx.getVar(ctx.data.read16LE()) : ctx.data.read();
    print("op_isScriptRunning result=$varId script=$scriptId");
    ctx.setGlobalVar(varId, ctx.isScriptRunning(scriptId) ? 1 : 0); // FIXME
  }

  void op_cutScene(ExecutionContext ctx) {
    List<int> params = readVarargs(ctx);
    print("op_cutScene params=$params");
    ctx.beginCutScene(params);
  }

  void op_add(ExecutionContext ctx, bool indirect) {
    int varId = ctx.data.read16LE();
    int value = indirect ? ctx.getVar(ctx.data.read16LE()) : ctx.data.read16LE();
    print("op_add var=$varId value=$value");
    ctx.setGlobalVar(varId, ctx.getVar(varId) + value);
  }

  void op_doSentence(ExecutionContext ctx, bool ind1, bool ind2, bool ind3) {
    int verbId = ind1 ? ctx.getVar(ctx.data.read16LE()) : ctx.data.read();
    if (verbId == 0xfe) {
      print("op_doSentence verb=$verbId");
      int scriptId = ctx.getVar(GlobalContext.SENTENCE_SCRIPT);
      ctx.stopScript(scriptId);
    } else {
      int objA = ind2 ? ctx.getVar(ctx.data.read16LE()) : ctx.data.read16LE();
      int objB = ind3 ? ctx.getVar(ctx.data.read16LE()) : ctx.data.read16LE();
      print("op_doSentence verb=$verbId objectA=$objA objectB=$objB");
      // FIXME doSentence
    }
  }

  void op_freezeScripts(ExecutionContext ctx, bool indirect) {
    int flag = indirect ? ctx.getVar(ctx.data.read16LE()) : ctx.data.read();
    print ("op_freezeScripts flag=0x${flag.toRadixString(16)}");
    ctx.freezeScripts(flag == 0, (flag & 0x80) != 0);
  }

  void op_loadRoom(ExecutionContext ctx, bool indirect) {
    int roomId = indirect ? ctx.getVar(ctx.data.read16LE()) : ctx.data.read();
    print("op_loadRoom room=$roomId");
    ctx.startRoom(roomId);
  }

  void op_setCameraAt(ExecutionContext ctx, bool indirect) {
    int xpos = indirect ? ctx.getVar(ctx.data.read16LE()) : ctx.data.read16LE();
    print("op_setCameraAt xpos=$xpos");
    ctx.setCameraAt(xpos);
  }

  void op_startSound(ExecutionContext ctx, bool indirect) {
    int sound = indirect ? ctx.getVar(ctx.data.read16LE()) : ctx.data.read();
    print("op_startSound sound=$sound");
    ctx.setGlobalVar(GlobalContext.MUSIC_TIMER, 0);
    // FIXME?
  }

  void op_stopSound(ExecutionContext ctx, bool indirect) {
    int sound = indirect ? ctx.getVar(ctx.data.read16LE()) : ctx.data.read();
    print("op_stopSound sound=$sound");
    // FIXME?
  }

  void op_delay(ExecutionContext ctx) {
    int delay = ctx.data.read() | (ctx.data.read() << 8) | (ctx.data.read() << 16);
    print("op_delay delay=$delay");
    ctx.delayExecution(delay);
  }

  void op_override(ExecutionContext ctx) {
    int subOpcode = ctx.data.read();
    if (subOpcode == 0) {
      print("op_override end");
    } else {
      print("op_override begin");
      ctx.setGlobalVar(GlobalContext.OVERRIDE, 0);
      ctx.data.read();
      ctx.data.read();
      ctx.data.read();
      // FIXME
    }
  }

  void op_putActorInRoom(ExecutionContext ctx, bool ind1, bool ind2) {
    int actorId = ind1 ? ctx.getVar(ctx.data.read16LE()) : ctx.data.read();
    int roomId = ind2 ? ctx.getVar(ctx.data.read16LE()) : ctx.data.read();
    print("op_putActorInRoom actor=$actorId room=$roomId");
    ctx.putActorInRoom(actorId, roomId);
  }

  void op_increment(ExecutionContext ctx) {
    int varAddr = ctx.data.read16LE();
    print("op_increment var=$varAddr");
    int value = ctx.getVar(varAddr);
    ctx.setVar(varAddr, value + 1);
  }

  void op_getActorRoom(ExecutionContext ctx, bool indirect) {
    int varAddr = ctx.data.read16LE();
    int actorId = indirect ? ctx.getVar(ctx.data.read16LE()) : ctx.data.read();
    print("op_getActorRoom res=$varAddr actor=$actorId");
    int roomId = ctx.getActorRoom(actorId);
    ctx.setVar(varAddr, roomId);
  }

  void op_actorOps(ExecutionContext ctx, bool indirect) {
    int actorId = indirect ? ctx.getVar(ctx.data.read16LE()) : ctx.data.read();
    while (true) {
      int subOpcode = ctx.data.read();
      if (subOpcode == 0xff) {
        break;
      }
      switch (subOpcode) {
      case 0x00:
        ctx.data.read(); // dummy
        break;
      case 0x01:
        int costumeId = ctx.data.read();
        print("op_actorOps actor=$actorId SO_COSTUME costume=$costumeId");
        break;
      case 0x0b:
        int index = ctx.data.read();
        int color = ctx.data.read();
        print("op_actorOps actor=$actorId SO_PALETTE index=$index color=$color");
        break;
      case 0x12:
         print("op_actorOps actor=$actorId SO_NEVER_ZCLIP");
         break;
      case 0x14:
        print("op_actorOps actor=$actorId SO_IGNORE_BOXES");
        break;
      case 0x80:
        ctx.data.read16LE(); // dummy
        break;
      default:
        throw new Exception("Unsupported op_actorOps actor=$actorId opcode=0x${subOpcode.toRadixString(16)}");
      }
    }
  }
}