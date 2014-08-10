library csv_parser_spec;

import 'package:unittest/unittest.dart';
import '../lib/csv_utils.dart';
import 'package:unittest/vm_config.dart';

void main(){
  useVMConfiguration();
  group("csv", (){
    var reversibleExamples = {
      '1,2,3': [['1','2','3']],
      '"1a"",1b",2': [['1a",1b','2']],
      '1\n2\n3': [['1'],['2'],['3']],
      '1\n\n3': [['1'],[''],['3']],
      '\n1\n3': [[''],['1'],['3']],
      '1\n3\n': [['1'],['3'],['']],
      '': [['']],
      '1\n"2a\n2b"\n3': [['1'],['2a\n2b'],['3']],
      '1,2': [['1','2']],
      '1,,2': [['1','','2']],
      ',1,2': [['','1','2']],
      '1,2,': [['1','2','']],
      '"1,2"': [['1,2']],
      '"1,,2"': [['1,,2']],
      '"1a""1b"': [['1a"1b']],
      '1,2,"3 ,"","",",4,5': [['1','2','3 ,",",','4','5']]
    };
    var parsingOnlyExamples = {
      '1\r\n2\r\n3': [['1'],['2'],['3']],
      '"1"': [['1']],
      '1a"1b': [['1a"1b']],
      '1a""1b': [['1a""1b']],
      '"1a""1b"': [['1a"1b']],
    };
    
    group("parser", (){
      reversibleExamples.forEach((text, data){
        test("Parsing: $text", (){
          expect(new CsvConverter.Excel().parse(text), data);  
        });
      });
      parsingOnlyExamples.forEach((text, data){
        test("Parsing: $text", (){
          expect(new CsvConverter.Excel().parse(text), data);  
        });
      });
      test("should use provided field delimiter", (){
        expect(new CsvConverter.Excel(fieldDelimiter: '\t').parse('1\t2a,2b\t3'), [['1','2a,2b','3']]);
      });
      test("should use provided field quoter", (){
        expect(new CsvConverter.Excel(quoteSymbol: "'").parse("'1a'',1b',2"), [["1a',1b",'2']]);
      });
      test("should handle CR as usual if asked", (){
        expect(new CsvConverter.Excel(lineDelimiter: LineDelimiter.UNIX).parse("1\r\n2\r\n3"), [['1\r'],['2\r'],['3']]);
      });
      //malformed
      test("should report about malformed csv", (){
        try{
          new CsvConverter.Excel().parse('"1a"1b"');
          fail("expected to throw ArgumentError");
        }on ArgumentError catch (e){
          expect(e.message, "Unexpected symbol at position 4");  
        }
      });
    });
    group("composer", (){
      reversibleExamples.forEach((text, data){
        test("Composing: $text", (){
          expect(new CsvConverter.Excel().compose(data), text);  
        });
      });
      test("should use provided field delimiter", (){
        expect(new CsvConverter.Excel(fieldDelimiter: '\t').compose([['1','2a,2b','3']]), '1\t2a,2b\t3');
      });
      test("should use provided field quoter", (){
        expect(new CsvConverter.Excel(quoteSymbol: "'").compose([["1a',1b",'2']]), "'1a'',1b',2");
      });
      test("should handle CR as usual if asked", (){
        expect(new CsvConverter.Excel(lineDelimiter: LineDelimiter.WINDOWS).compose([['1'],['2'],['3']]), "1\r\n2\r\n3");
      });
    });
  });  
}
