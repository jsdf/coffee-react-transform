
var hex = '0123456789abcdef'.split('');

module.exports  =  function stringEncode(input, opts) {
  opts = opts || {};
  var escaped = "";
  
  for (var i = 0; i < input.length; i++) {
    escaped = escaped + encodeChar(input.charAt(i), opts.preserveNewlines);
  }
  
  return escaped;
}

function encodeChar(inputChar, preserveNewlines) {
  var character = inputChar.charAt(0);
  var characterCode = inputChar.charCodeAt(0);

  switch(character) {
    case '\n':
      if (!preserveNewlines) return "\\n";
      else return character;
    case '\r':
      if (!preserveNewlines) return "\\r";
      else return character;
    case '\'': return "\\'";
    case '"': return "\\\"";
    case '\&': return "\\&";
    case '\\': return "\\\\";
    case '\t': return "\\t";
    case '\b': return "\\b";
    case '\f': return "\\f";
    case '/': return "\\x2F";
    case '<': return "\\x3C";
    case '>': return "\\x3E";
  }

  return inputChar;
}
