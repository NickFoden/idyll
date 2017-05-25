@builtin "whitespace.ne"

Sourcefile -> Blocks "EOF" {%
  function(data, location, reject) {
    return data[0];
  }
%}

Blocks -> ("BREAK" __):* ((BreakBlock __ ("BREAK" __):+) | (NoBreakBlock __ ("BREAK" __):*)):*  (BreakBlock __):? {%
  function(data, location, reject) {
    var blocks = [];
    data[1].forEach(function(d) {
      blocks.push(d[0][0]);
    })

    if (data[2]) {
      blocks.push(data[2][0]);
    }
    return blocks;
  }
%}

Block -> (BreakBlock | NoBreakBlock) {%
  function(data, location, reject) {
    return data[0][0];
  }
%}

NoBreakBlock -> (Header | MultilineCode | UnorderedList | OrderedList) {%
  function(data, location, reject) {
    return data[0][0];
  }
%}

BreakBlock -> (Paragraph) {%
  function(data, location, reject) {
    return data[0][0];
  }
%}

Header -> "HEADER_" [1-6] __ TokenValue {%
  function(data, location, reject) {
    return ["h" + data[1], [], [data[3]]];
  }
%}

UnorderedList -> "UNORDERED_LIST" (__ ListItem):+ __ "LIST_END"  {%
  function(data, location, reject) {
    var children = [];
    data[1].map(function (child) {
      children.push(["li", [], child[1]]);
    });
    return ["ul", [], children];
  }
%}

OrderedList -> "ORDERED_LIST" (__ ListItem):+ __ "LIST_END" {%
  function(data, location, reject) {
    var children = [];
    data[1].map(function (child) {
      children.push(["li", [], child[1]]);
    });
    return ["ol", [], children];
  }
%}

ListItem -> "LIST_ITEM" (__ ParagraphItem):+ {%
  function(data, location, reject) {
    var children = [];
    data[1].map(function (child) {
      children.push(child[1]);
    });
    return children;
  }
%}

MultilineCode -> "MULTILINE_CODE" __ TokenValue __ TokenValue {%
  function(data, location, reject) {
    return ["pre", [], [["code", [], [data[4]]]]];
  }
%}

Paragraph -> (ParagraphItem __):* ParagraphItem  {%
  function(data, location, reject) {
    var children = [];
    data[0].map(function (child) {
      children.push(child[0]);
    });
    children.push(data[1]);
    if (children.length === 1 && typeof children[0] !== 'string') {
      return children[0];
    } else if (children.filter(function (c) { return typeof c === 'string' }).length === 0) {
      return ["div", [], children];
    }

    return ["p", [], children];
  }
%}

ParagraphItem -> (Text | ClosedComponent | OpenComponent | TextInline) {%
  function(data, location, reject) {
    return data[0][0];
  }
%}

Text -> ("WORDS" __ TokenValue) {%
  function(data, location, reject) {
    return data[0][2];
  }
%}

TextInline -> (CodeInline | BoldInline | EmInline | LinkInline | ImageInline) {%
  function(data, location, reject) {
    return data[0][0];
  }
%}

BoldInline -> "STRONG" __ TokenValue {%
  function(data, location, reject) {
    return ['strong', [], [data[2]]];
  }
%}

EmInline -> "EM" __ TokenValue {%
  function(data, location, reject) {
    return ['em', [], [data[2]]];
  }
%}

CodeInline -> "INLINE_CODE" __ TokenValue {%
  function(data, location, reject) {
    return ['code', [], [data[2]]];
  }
%}

ImageInline -> "IMAGE" __ TokenValue __ TokenValue {%
  function(data, location, reject) {
    return ['img', [["src", ["value", data[4]]], ["alt", ["value", data[2]]]], []];
  }
%}

LinkInline -> "LINK" __ TokenValue __ TokenValue {%
  function(data, location, reject) {
    return ['a', [["href", ["value", data[4]]]], [data[2]]];
  }
%}

OpenComponent -> OpenComponentStart __ Blocks:? OpenComponentEnd {%
  function(data, location, reject) {
    return [data[0][0], data[0][1], data[2] || []];
  }
%}

OpenComponentStart -> "OPEN_BRACKET" __ ComponentName __ ComponentProperties "CLOSE_BRACKET"  {%
  function(data, location, reject) {
    return [data[2], data[4]];
  }
%}

OpenComponentEnd -> "OPEN_BRACKET" __ "FORWARD_SLASH" __ ComponentName __ "CLOSE_BRACKET"

ClosedComponent -> "OPEN_BRACKET" __ ComponentName __ ComponentProperties "FORWARD_SLASH" __ "CLOSE_BRACKET" {%
  function(data, location, reject) {
    return [data[2], data[4], []];
  }
%}

ComponentName -> "COMPONENT_NAME" __ TokenValue {%
  function(data, location, reject) {
    return data[2];
  }
%}

ComponentProperties -> (ComponentProperty __):* {%
  function(data, location, reject) {
    return data[0].map(function(d) { return d[0]; });
  }
%}

ComponentProperty -> "COMPONENT_WORD" __ TokenValue __ "PARAM_SEPARATOR" __  ComponentPropertyValue {%
  function(data, location, reject) {
    var key = data[2];
    var val = data[6];
    return [key, val];
  }
%}

ComponentPropertyValue -> ("NUMBER" | "EXPRESSION" | "STRING" | "COMPONENT_WORD" | "BOOLEAN") __ TokenValue {%
  function(data, location, reject) {
    var t = data[0][0];
    var val = data[2];
    if (t === 'NUMBER') {
      val = +val;
    } else if (t === 'EXPRESSION' || t === 'STRING') {
      val = val.substring(1, val.length-1);
    } else if (t === 'BOOLEAN') {
      val = (val === 'true');
    }

    var typeString = '';
    if (t === 'EXPRESSION') {
      typeString = 'expression';
    } else if (t === 'NUMBER' || t === 'STRING' || t === 'BOOLEAN') {
      typeString = 'value';
    } else if (t === 'COMPONENT_WORD') {
      typeString = 'variable';
    }
    return [typeString, val];
  }
%}

TokenValue -> "TOKEN_VALUE_START" __ "\"" [^\"]:* "\"" __ "TOKEN_VALUE_END" {%
  function(data, location, reject) {
    return data[3].join('').replace(/&quot;/g, '"');
  }
%}

