#import('dart:html');
//#import('dart:dom', prefix:"dom");

#source('Stream.dart');
#source('WritableStream.dart');
#source('ScummFile.dart');
#source('Scumm.dart');
#source('Timer.dart');
#source('ScummVM.dart');
#source('Game.dart');
#source('Actor.dart');
#source('ResourceManager.dart');
#source('AssetManager.dart');
#source('Resource.dart');
#source('Script.dart');
#source('Charset.dart');
#source('Costume.dart');
#source('Room.dart');
#source('RoomObject.dart');
#source('Thread.dart');
#source('Cursor.dart');
#source('GFX.dart');
#source('VirtualScreen.dart');
#source('Palette.dart');
#source('Message.dart');
#source('DebugMessage.dart');
#source('DefaultMessage.dart');
#source('Interpreter.dart');


void main() {
  var canvas = document.query('#surface');
  var ctx = canvas.getContext('2d');

  Scumm scumm = new Scumm();
  scumm.loadGame("MONKEY1");
}