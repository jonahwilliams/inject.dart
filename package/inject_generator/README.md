# Injector codegen generator

This package makes it easy to test the expected generated code outputs of
dart:inject. At a high level, the `test_cases.dart` file specifies a list of
test cases. Each test case specifies:

- A list of input file names to files in `test_files`.
- A list of expected ouptut file names to golden files in `test_files`.

## Code generator
The `generate.dart` file is a script that will overwrite the existing goldens
with the actual output. To run:

1. Go into a google3/ directory. Do not navigate into a subdirectory, or the
   files will be written to the wrong place.
2. Run:
   ```shell
   blaze run third_party/dart/inject_generator:generate
   ```

NOTE: if you're creating new test case which has a new golden file, the first
time the script tries to write the file, you may run into a OS permission
error. Simply run `touch file_name.golden` to create a file, and then the
script will have permission to write over it.

## Tests
The `golden_tests.dart` file tests that the output of all the test cases
matches the golden files.

