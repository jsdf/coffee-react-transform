
var hex=new Array('0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f');

module.exports = function stringEncode(preescape)
{
	var escaped="";
	
	var i=0;
	for(i=0;i<preescape.length;i++)
	{
		escaped=escaped+encodeCharx(preescape.charAt(i));
	}
	
	return escaped;
}

function encodeCharx(original)
{
	var found=true;
	var thecharchar=original.charAt(0);
	var thechar=original.charCodeAt(0);
	switch(thecharchar) {
		case '\n': return "\\n"; break; //newline
		case '\r': return "\\r"; break; //Carriage return
		case '\'': return "\\'"; break;
		case '"': return "\\\""; break;
		case '\&': return "\\&"; break;
		case '\\': return "\\\\"; break;
		case '\t': return "\\t"; break;
		case '\b': return "\\b"; break;
		case '\f': return "\\f"; break;
		case '/': return "\\x2F"; break;
		case '<': return "\\x3C"; break;
		case '>': return "\\x3E"; break;
		default:
			found=false;
			break;
	}
	if(!found)
	{
		if(thechar>127) {
			var c=thechar;
			var a4=c%16;
			c=Math.floor(c/16); 
			var a3=c%16;
			c=Math.floor(c/16);
			var a2=c%16;
			c=Math.floor(c/16);
			var a1=c%16;
		//	alert(a1);
			return "\\u"+hex[a1]+hex[a2]+hex[a3]+hex[a4]+"";		
		}
		else
		{
			return original;
		}
	}		
}
