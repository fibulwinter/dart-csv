library csv_utils;

class CsvConverter{
  String fieldDelimiter;
  String quoteSymbol;
  LineDelimiter lineDelimiter;
  
  CsvConverter.Excel({this.fieldDelimiter: ',', this.quoteSymbol: '"', this.lineDelimiter}){
    if(lineDelimiter==null){
      this.lineDelimiter=LineDelimiter.AUTO;
    }
  }
  
  List<List<String>> parse(String text){
    var parser = new _Parser(fieldDelimiter, quoteSymbol, lineDelimiter);
    return parser.parse(text);
  }
  
  String compose(List<List<String>> data){
    var encoder = new _Composer(this.fieldDelimiter, this.quoteSymbol, lineDelimiter);
    return encoder.compose(data);
  }

}

class LineDelimiter{
  static LineDelimiter AUTO = new LineDelimiter('\n');
  static LineDelimiter WINDOWS = new LineDelimiter('\r\n');
  static LineDelimiter UNIX = new LineDelimiter('\n');
  
  String delimiter;
  
  LineDelimiter(this.delimiter);
}

class _Composer{
  String fieldDelimiter;
  String quoteSymbol;
  String doubelQuoteSymbol;
  LineDelimiter lineDelimiter;
  _Composer(this.fieldDelimiter, this.quoteSymbol, this.lineDelimiter){
    this.doubelQuoteSymbol = '$quoteSymbol$quoteSymbol';
  }
  
  String compose(List<List<String>> data){
    return data.map((List<String> fields){
      return fields.map(escape).join(fieldDelimiter);
    }).join(lineDelimiter.delimiter);  
  }
  
  String escape(String field){
    if(field.contains(fieldDelimiter) 
        || field.contains(lineDelimiter.delimiter) 
        || field.contains(quoteSymbol)){
      return "$quoteSymbol${field.replaceAll(quoteSymbol, doubelQuoteSymbol)}$quoteSymbol";
    }else{
      return field;
    }
  }
  
}

class _Parser{
  String fieldDelimiter;
  String quoteSymbol;
  String doubleQuoteSymbol;
  LineDelimiter lineDelimiter;
  String text;
  List<List<String>> result;
  List<String> currentLine;
  int lastDelimeter=-1;  
  int pos=0;  
  
  _Parser(this.fieldDelimiter, this.quoteSymbol, this.lineDelimiter){
    doubleQuoteSymbol="$quoteSymbol$quoteSymbol";
    currentLine = [];
    result = [currentLine];
  }
  
  List<List<String>> parse(String text){
    this.text = text;
    try{
    var state = _State.FIELD_START;
    while(state!=_State.END){
      if(pos>=text.length){
        onDelimeter(state);
        state = state.onEoF();
      }else{
        var c = text[pos];
        if(c==quoteSymbol){
          state = state.onQuote();
        }else if(c==fieldDelimiter){
          onDelimeter(state);
          state = state.onDelimiter();
        }else if(c=='\r' && lineDelimiter!=LineDelimiter.UNIX){
          onDelimeter(state);
          onNewLine(state);
          state = state.onR();
        }else if(c=='\n'){
          onDelimeter(state);
          onNewLine(state);
          state = state.onEoL();
        }else{
          state = state.onOther();
        }
      }
      pos++;
    }
    }on ArgumentError catch(e){
      throw new ArgumentError("${e.message} at position $pos");
    }
    return result;
  }
  
  void onDelimeter(_State state){
    if(!state.lineTerminator){
      //    print("onDelimeter(newLine: $newLine, inDoubleQuotes: $inDoubleQuotes");
      if(state.isDoubleQuoted){
        var s = text.substring(lastDelimeter+2, pos-1);
        s = s.replaceAll(doubleQuoteSymbol, quoteSymbol);
        currentLine.add(s);
        lastDelimeter=pos;
      }else{
        var s = text.substring(lastDelimeter+1, pos);
        currentLine.add(s);
      }
      lastDelimeter=pos;
    }else if(state==_State.ON_R){
      lastDelimeter=pos;
    }
  }

  void onNewLine(_State state){
    if(!state.lineTerminator){
      currentLine = [];
      result.add(currentLine);
    }
  }
  
}

abstract class _State{
  final bool isDoubleQuoted;
  final bool isR;
  final bool lineTerminator;
  _State({ 
    this.isDoubleQuoted: false,
    this.isR: false,
    this.lineTerminator: false});
  
  _State onEoF()=>_State.END;
  _State onDelimiter()=>_State.FIELD_START;
  _State onEoL()=>_State.FIELD_START;
  _State onR()=>_State.ON_R;
  _State onQuote();
  _State onOther();
  
  static final _State FIELD_START = new _FieldStartState(); 
  static final _State ON_R = new _OnRState(); 
  static final _State IN_SIMPLE_FIELD = new _InSimpleFieldState(); 
  static final _State IN_QUOTED_FIELD = new _InQuotedFieldState(); 
  static final _State QUOTED_END_CANDIDATE = new _QuotedEndCandidateState(); 
  static final _State END = new _EndState(); 
  static final _State SIMPLE_DELIMITER = new _SimpleDelimiterState(); 
  static final _State QUOTED_DELIMITER = new _QuotedDelimiterState(); 
}

class _FieldStartState extends _State{
  _State onQuote()=>_State.IN_QUOTED_FIELD;
  _State onOther()=>_State.IN_SIMPLE_FIELD;
}

class _OnRState extends _State{
  _OnRState():super(lineTerminator: true);
  _State onEoF()=> throw new ArgumentError("Unexpected end of file");
  _State onDelimiter()=>throw new ArgumentError("Unexpected symbol");
  _State onEoL()=>_State.FIELD_START;
  _State onR()=>throw new ArgumentError("Unexpected symbol");
  _State onQuote()=>throw new ArgumentError("Unexpected symbol");
  _State onOther()=>throw new ArgumentError("Unexpected symbol");
}

class _InSimpleFieldState extends _State{
  _State onQuote() => this;
  _State onOther() => this;
}

class _SimpleDelimiterState extends _State{
  _State onQuote()=>throw new ArgumentError("Unexpected symbol");
  _State onOther()=>throw new ArgumentError("Unexpected symbol");
}
 
class _EndState extends _State{
  _EndState():super(lineTerminator: true);
  _State onEoF()=> throw new ArgumentError("Unexpected symbol");
  _State onDelimiter()=>throw new ArgumentError("Unexpected symbol");
  _State onEoL()=>throw new ArgumentError("Unexpected symbol");
  _State onR()=>throw new ArgumentError("Unexpected symbol");
  _State onQuote()=>throw new ArgumentError("Unexpected symbol");
  _State onOther()=>throw new ArgumentError("Unexpected symbol");
}

class _InQuotedFieldState extends _State{
  _InQuotedFieldState():super(lineTerminator: true);
  _State onEoF()=> throw new ArgumentError("Unexpected end of file: quoted record is uncompleted");
  _State onDelimiter()=>this;
  _State onEoL()=>this;
  _State onR()=>this;
  _State onQuote()=>_State.QUOTED_END_CANDIDATE;
  _State onOther()=>this;
}

class _QuotedEndCandidateState extends _State{
  _QuotedEndCandidateState():super(isDoubleQuoted: true);
  _State onQuote()=>_State.IN_QUOTED_FIELD;
  _State onOther()=>throw new ArgumentError("Unexpected symbol");
}

class _QuotedDelimiterState extends _State{
  _QuotedDelimiterState():super(isDoubleQuoted: true);
  _State onQuote()=>throw new ArgumentError("Unexpected symbol");
  _State onOther()=>throw new ArgumentError("Unexpected symbol");
}


 
