dart-csv
========

Utilities for reading and writing CSV (comma separated value) text files in Dart.

```dart
  import 'package:csv_utils/csv_utils.dart';
  
  var source = 'value1a,value1b\n"value2a,""value2b"';
  var list = new CsvConverter.Excel().parse(source);
  //list is [['value1a','value1b'],['value2a,"value2b']]
  var text = new CsvConverter.Excel().compose(list);
  //text is 'value1a,value1b\n"value2a,""value2b"'
  print(source==text);
  //prints true
  
  //you can specify custom delimeters
  var list2 = new CsvConverter.Excel(fieldDelimiter: '\t', quoteSymbol: "'", 
  	lineDelimiter: LineDelimiter.WINDOWS).parse("value1a\tvalue1b\r\n'value2a\tvalue2b'"); 
  
```
This utility currently supports only Excel flavors of CSV:

Microsoft Excel Style
* Two quotes escape character ("" escapes "), no other characters are escaped.
* Compatible with Microsoft Excel and many other programs that have adopted the format for data import and export.
* Leading and trailing white space on an unquoted field is significant.
* Specified by RFC4180.
