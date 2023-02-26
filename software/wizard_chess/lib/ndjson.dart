import 'dart:convert';
import 'dart:typed_data';

extension RawNdJsonStream on Stream<Uint8List> {
  Stream<dynamic> toJsonStream() async* {
    String partialMessage = "";
    await for (final characters in this) {
      partialMessage += String.fromCharCodes(characters);
      print("toJsonStream: $partialMessage");

      var lines = partialMessage.split('\n');
      for (final line in lines.getRange(0, lines.length - 1)) {
        if (line.trim() == "") {
          continue;
        }
        yield jsonDecode(line);
      }

      partialMessage = lines.last;
    }
  }
}