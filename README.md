An example Dart command-line application that performs string replace operations.
e.g. a package name change.

## Usage

It's interactive when run and gives the following output

```txt
Update KEY to VALUE in project/ios/Runner.xcodeproj/project.pbxproj? Y/n
Y
Updating: project/ios/Runner.xcodeproj/project.pbxproj
```

Arguments:
* f - file name which contains a map of format

```txt
KEY1=VALUE1
KEY2=VALUE2
```

* d - directory to recursively scan all files
* r - if false performs key -> value replacement otherwise performs value -> key  
* h - whether to include hidden files and directories
* a - if true skips all interactivity and performs all replacements automatically

example:
-f .keys -d [folder_name] -h


