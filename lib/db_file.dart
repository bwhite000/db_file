library DbFile;

import "dart:io";
import "dart:async";
//import "dart:convert" show JSON, UTF8, LineSplitter;

/**
 * Take a CSV formatted file and process it as a data store.
 */
class DbFile {
  bool isInitiated = false;
  File file;
  final bool shouldCacheInMemory = false;
  final List<String> columnNames = <String>[];
  final List<List<String>> rowValues = <List<String>>[];

  DbFile(final String filePath) :
      this.file = new File(filePath);

  Future<Null> init() async {
    final List<String> lines = await this.file.readAsLines();
    bool hasParsedColumnsAlready = false;

    for (int i = 0, len = lines.length; i < len; i++) {
      if (lines[i].isEmpty) {
        continue;
      } else {
        if (hasParsedColumnsAlready == false) {
          hasParsedColumnsAlready = true;

          // Get the columnNames
          this.columnNames.addAll(lines[i].split(','));
        } else {
          // Separately store all of the values from the rows
          this.rowValues.add(lines[i].split(','));
        }
      }
    }

    if (this.columnNames.isEmpty) {
      throw new Exception('There were no column names to parse from this file.');
    }
  }

  /// Insert a row into the database table
  Future<Null> insertOne(final Map<String, dynamic> dataToInsert) async {
    if (await this.file.exists()) {
      final IOSink sink = this.file.openWrite(mode: FileMode.WRITE_ONLY_APPEND);
      // Holder for the bare data that will be added to this CSV table row
      final List<dynamic> _listOfDataToInsert = <dynamic>[];

      // Create the CSV values, or the default empty String value, for each columnName
      // from the supplied data to insert.
      this.columnNames.forEach((final String columnName) {
        if (dataToInsert.containsKey(columnName)) {
          _listOfDataToInsert.add(dataToInsert[columnName]);
        } else {
          _listOfDataToInsert.add('');
        }
      });

      // Add this data to the in-memory copy, also
      this.rowValues.add(_listOfDataToInsert);

      // Add this data to the on-disk database table file
      sink.write(_listOfDataToInsert.join(',') + '\n');

      // Close the file connection and release the resources
      await sink.close();
    } else {
      throw new FileNotFoundException();
    }
  }

  /// Batch insert multiple rows in the database table
  Future<Null> insertAll(final List<Map<String, dynamic>> listOfDataToInsert) async {
    if (await this.file.exists()) {
      final IOSink sink = this.file.openWrite(mode: FileMode.WRITE_ONLY_APPEND);
      final List<String> _listOfListsOfData = <String>[];

      listOfDataToInsert.forEach((final Map<String, dynamic> dataToInsert) {
        // Holder for the bare data that will be added to this CSV table row
        final List<dynamic> _listOfDataToInsert = <dynamic>[];

        // Create the CSV values, or the default empty String value, for each columnName
        // from the supplied data to insert.
        this.columnNames.forEach((final String columnName) {
          if (dataToInsert.containsKey(columnName)) {
            _listOfDataToInsert.add(dataToInsert[columnName]);
          } else {
            _listOfDataToInsert.add('');
          }
        });

        // Add this data to the in-memory copy, also
        this.rowValues.add(_listOfDataToInsert);

        _listOfListsOfData.add(_listOfDataToInsert.join(','));
      });

      // Add this data to the on-disk database table file
      sink.write(_listOfListsOfData.join('\n'));

      // Close the file connection and release the resources
      await sink.close();
    } else {
      throw new FileNotFoundException();
    }
  }

  Future updateOne() async {
    if (await this.file.exists()) {
    } else {
      throw new FileNotFoundException();
    }
  }

  Future removeOne()  async {
    if (await this.file.exists()) {
    } else {
      throw new FileNotFoundException();
    }
  }

  Map<String, dynamic> findOne(final String columnName, final String columnDataEqualsVal, {
    final bool isCaseSensitive: true // Always true currently
  }) {
    // Get the index of the row value that this column will be located at (i.e. column number)
    int listIndexOfColumnName = this.columnNames.indexOf(columnName);

    // Return an exception if the desired column name is not in this database table
    if (listIndexOfColumnName == null) {
      throw new Exception('The provided columnName was not found in this database table.');
    }

    // Loop through all of the rows to try to find a matching value
    for (int i = 0, len = this.rowValues.length; i < len; i++) {
      // Temporary shorthand for the current row
      final List<dynamic> _currentRow = this.rowValues[i];
      final RegExp intRegExp = new RegExp(r'^\d+$');
      final RegExp doubleRegExp = new RegExp(r'^\d+\.\d+$');
      dynamic columnRowValue = _currentRow[listIndexOfColumnName];

      // Parse the type of the value for this column, converting to non-String type, if possible
      if (intRegExp.hasMatch(_currentRow[listIndexOfColumnName])) {
        columnRowValue = int.parse(_currentRow[listIndexOfColumnName]);
      } else if (doubleRegExp.hasMatch(_currentRow[listIndexOfColumnName])) {
        columnRowValue = double.parse(_currentRow[listIndexOfColumnName]);
      } else {
        columnRowValue = _currentRow[listIndexOfColumnName];
      }

      // See if the value in this row at the specific column matches the desired value
      if (columnRowValue == columnDataEqualsVal) {
        // The value to be assembled and returned for this row's match
        final Map<String, dynamic> _returnValueMap = {};
        int _columnNameLoopIndex = 0; // Must manually record the index in forEach

        // Assemble a key/value map of the column-name/row-value-for-the-column
        this.columnNames.forEach((final String columnName) {
          if (_currentRow[_columnNameLoopIndex] is String) {
            // Set the return value for this column, converting to non-String type, if possible
            if (intRegExp.hasMatch(_currentRow[_columnNameLoopIndex])) {
              _returnValueMap[columnName] = int.parse(_currentRow[_columnNameLoopIndex]);
            } else if (doubleRegExp.hasMatch(_currentRow[_columnNameLoopIndex])) {
              _returnValueMap[columnName] = double.parse(_currentRow[_columnNameLoopIndex]);
            } else {
              _returnValueMap[columnName] = _currentRow[_columnNameLoopIndex];
            }
          } else {
            _returnValueMap[columnName] = _currentRow[_columnNameLoopIndex];
          }

          // Bump up the index for the manual loop index
          _columnNameLoopIndex++;
        });

        // Return the findOne value data.
        return _returnValueMap;
      }
    }

    // Default for if no match is found
    return null;

    /*
    final Completer<Map> completer = new Completer<Map>();
    List<String> columnNames = <String>[];
    int lookingForIndex;
    final RegExp openingDoubleQuoteRegExp = new RegExp(r'^"');
    final RegExp closingDoubleQuoteRegExp = new RegExp(r'"$');
    final Map<String, dynamic> results = <String, dynamic>{};
    List<String> lineVals; // Reduce Garbage Collection by reusing.

    this.file.openRead()
      .transform(UTF8.decoder)
      .transform(new LineSplitter())
      .where((final String line) => line.isNotEmpty)
      .listen((final String lineVal) {
        // If this is the first line
        if (columnNames.length == 0) {
          columnNames = lineVal.split(',');

          for (int i = 0, len = columnNames.length; i < len; i++) {
            if (columnNames[i] == columnName) {
              lookingForIndex = i;
              break;
            }
          }

          if (lookingForIndex == null) {
            throw new Exception('The provided columnName was not found in this data store: ($columnName).');
          }
        } else { // Regular data line
          // Has a result already been found? If yes, do nothing and return.
          if (results.length > 0) {
            return;
          }

          // TODO: Reference how this RegExp functions: http://stackoverflow.com/questions/632475/regex-to-pick-commas-outside-of-quotes
          lineVals = lineVal.split(new RegExp(r'(,)(?=(?:[^"]|"[^"]*")*$)'));

          // Make sure the data is formatted correctly.
          if (lineVals.length != columnNames.length) {
            throw new Exception('The amount of values is different than the amount of keys. Incorrect database format: \n  key names => $columnNames - (${columnNames.length})\n  line values => $lineVals - (${lineVals.length})\n  lineData => $lineVal');
          }

          if (lineVals[lookingForIndex] == '"$columnDataEqualsVal"') {
            for (int _i = 0, _len = columnNames.length; _i < _len; _i++) {
              results[columnNames[_i]] = lineVals[_i].replaceFirst(openingDoubleQuoteRegExp, '').replaceFirst(closingDoubleQuoteRegExp, '');
            }
          }
        }
      }, onDone: () {
        completer.complete(results);
      });

    return completer.future;
    */
  }

  Future<Map> findAll() {
    final Completer<Map> completer = new Completer<Map>();

    return completer.future;
  }

  Future clear() async {
    // Delete the file contents, if it exists
    if (await this.file.exists()) {
      this.file = await this.file.writeAsString("");
    } else {
      await this.file.create();
    }
  }
}

class FileNotFoundException implements Exception {
  String causeMessage;

  FileNotFoundException([final String this.causeMessage]);
}