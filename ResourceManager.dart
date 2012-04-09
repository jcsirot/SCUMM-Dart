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

class ResourceManager {

  AssetManager assets;
  Map<int, Room> rooms;
  Map<int, Script> scripts;
  Map<int, Charset> charsets;
  Map<int, Costume> costumes;

  ResourceManager(AssetManager assets) {
    this.assets = assets;
    rooms = new Map<int, Room>();
    scripts = new Map<int, Script>();
    charsets = new Map<int, Charset>();
    costumes = new Map<int, Costume>();
  }

  void loadIndex() {
    print("Reading Index");
    Stream st = assets["game/monkey/MONKEY1.000"];
    while (!st.eof()) {
      String name = st.readString(4);
      int len = st.read32BE();
      print(name);
      print("len=" + len);
      if (name == "RNAM") {
        loadRoomNames(st);
      } else if (name == "MAXS"){
        /* skip this section */
        st.seek(18);
      } else if (name == "DROO") {
        loadRooms(st);
      } else if (name == "DSCR") {
        loadScripts(st);
      } else if (name == "DSOU") {
        loadSounds(st);
      } else if (name == "DCOS") {
        loadCostumes(st);
      } else if (name == "DCHR") {
        loadCharsets(st);
      } else if (name == "DOBJ") {
        loadObjects(st);
      }
    }
  }

  void loadRoomNames(Stream st) {
    print("Loading room names");
    while (true) {
      int no = st.read();
      if (no == 0) {
        break;
      }
      Uint8Array tmp = st.array(9);
      for (int j = 0; j < 9; j++) {
        tmp[j] ^= 0xff;
      }
      String name = new String.fromCharCodes(tmp);
      print(name + " (#" + no + ")");
      rooms[no] = new Room(no, name);
    }
  }

  void loadRooms(Stream data) {
    print("Loading rooms");
    loadItems(data, (int idx, int no, int offset) {
      print("Room #"+ idx + " Id=" + no +" offset=" + offset);
      if (rooms.containsKey(idx)) {
        rooms[idx].fileId = no;
      } else {
        print("Room #" + idx + " does not exist");
      }
    });
  }

  void loadScripts(Stream data) {
    print("Loading scripts");
    loadItems(data, (int idx, int no, int offset) {
      print("Script #" + idx + " Room #"+ no +" offset=" + offset);
      scripts[idx] = new Script(idx, no, offset);
    });
  }

  void loadSounds(Stream data) {
    print("Loading sounds");
    loadItems(data, (int idx, int no, int offset) => print("Room #"+ no +" offset=" + offset));
  }

  void loadCostumes(Stream data) {
    print("Loading costumes");
    loadItems(data, (int idx, int no, int offset) {
      print("Costume #$idx Room #$no offset=$offset");
      costumes[idx] = new Costume(idx, no, offset);
    });
  }

  void loadCharsets(Stream data) {
    print("Loading charsets");
    loadItems(data, (int idx, int no, int offset) {
      print("Charset #$idx Room=$no offset=$offset");
      charsets[idx] = new Charset(idx, no, offset);
    });
  }

  void loadObjects(Stream data) {
    print("Loading objects");
    loadItems(data, (int idx, int owner, int classdata) {});//print("Owner&state="+ owner +" class=" + classdata));
  }

  /* Most item collections are sharing the same data structure */
  void loadItems(Stream data, void callback(int idx, int x, int y)) {
    int nbItems = data.read16LE();
    print("# of items=" + nbItems);
    List<int> it1 = new List<int>();
    List<int> it2 = new List<int>();
    for (int i = 0; i < nbItems; i += 1) {
      int no = data.read();
      it1.add(no);
    }
    for (int i = 0; i < nbItems; i += 1) {
      int offset = data.read32LE();
      it2.add(offset);
    }
    for (int i = 0; i < nbItems; i += 1) {
      callback(i, it1[i], it2[i]);
    }
  }

  /* FIXME getXXX duplicated code */
  
  Charset getCharset(int idx) {
    Charset charset = charsets[idx];
    if (!charset.isLoaded()) {
      Stream data = loadResource(Charset.TYPE, charset.room, charset.offset);
      charset.initWithData(data);
    }
    return charset;
  }

  Script getScript(int idx) {
    Script script = scripts[idx];
    if (script != null && !script.isLoaded()) {
      Stream data = loadResource(Script.TYPE, script.room, script.offset);
      script.initWithData(data);
    }
    return script;
  }

  Costume getCostume(int idx) {
    Costume costume = costumes[idx];
    if (!costume.isLoaded()) {
      Stream data = loadResource(Costume.TYPE, costume.room, costume.offset);
      costume.initWithData(data);
    }
    return costume;
  }

  Stream loadResource(String type, int roomIdx, int offset) {
    print("Loading resource of type $type in room #$roomIdx at offset $offset");
    Room room = rooms[roomIdx];
    loadRoomsOffsets(room);
    Stream data = assets["game/monkey/MONKEY1.00${room.fileId}"];
    int ptr = room.fileOffset + offset;
    data.seek(ptr);
    String tag = data.readString(4);
    if (tag !=  type) {
      print("[WARN] Unexpected resource type: expected $type and found $tag");
    }
    int len = data.read32BE();
    print("TAG: " + tag);
    print("LEN: " + len);
    return data.subStream(len-8);
  }

  void loadRoomsOffsets(Room room) {
    Stream data = assets["game/monkey/MONKEY1.00" + room.fileId];
    data.seek(16);
    int nb = data.read();
    for (int i = 0; i < nb; i++) {
      int r = data.read();
      int off = data.read32LE();
      rooms[r].fileOffset = off;
      //print("Room #" + r + " offset " + off);
    }
  }

  Room setupRoom(int index) {
    Room room = rooms[index];
    room.initWithData(loadResource("ROOM", index, 0));
    return room;
  }
}