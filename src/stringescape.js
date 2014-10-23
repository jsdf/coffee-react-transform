
var hex = '0123456789abcdef'.split('');

module.exports  =  function stringEncode(input, opts) {
  opts = opts || {};
  var escaped = "";

  for (var i = 0; i < input.length; i++) {
    translation = encodeChar(input.charAt(i), opts);
    escaped = escaped + translation
  }
  
  return escaped;
}

function encodeChar(inputChar, opts) {
  var character = inputChar.charAt(0);
  var characterCode = inputChar.charCodeAt(0);

  switch(character) {
    case '\n':
      if (opts.singleQuotes) return character;
      if (!opts.preserveNewlines) return "\\n";
      return character;
    case '\r':
      if (opts.singleQuotes) return character;
      if (!opts.preserveNewlines) return "\\r";
      return character;
    case '\'': return "\\'";
    case '"':
      if (opts.singleQuotes) return character;
      return "\\\"";
    case '\&':
      return "\\&";
    case '\\': return "\\\\";
    case '\t':
      if (opts.singleQuotes) return character;
      return "\\t";
    case '\b':
      if (opts.singleQuotes) return character;
      return "\\b";
    case '\f':
      if (opts.singleQuotes) return character;
      return "\\f";
    case '/': return "\\x2F";
    case '<': return "\\x3C";
    case '>': return "\\x3E";
  }

  if (characterCode > 127) {
    var c = characterCode;
    var a4 = c % 16;
    c = ~~(c/16); 
    var a3 = c % 16;
    c = ~~(c/16);
    var a2 = c % 16;
    c = ~~(c/16);
    var a1 = c % 16;
    
    return ["\\u", hex[a1], hex[a2], hex[a3], hex[a4]].join('');    
  } else {
    return inputChar;
  }
}
