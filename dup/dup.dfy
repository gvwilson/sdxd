// Find duplicate files.
//
// This is a Dafny translation of the "Finding Duplicate Files" chapter
// from *Software Design by Example in Python*.  The Python version uses
// SHA-256 from `hashlib`; Dafny's standard library has no cryptographic
// hash, so we use the SHA-256 implementation in `sha256.dfy`.
//
// We use the standard libraries for:
//
// * Std.FileIO.ReadBytesFromFile: read a file's bytes
// * Std.Collections.Map.Get: safe map lookup

include "sha256.dfy"

import Std.FileIO
import Std.Collections.Map

// Read every file, compute its SHA-256 digest, and group the filenames by
// digest. `groups` maps a hex digest to the filenames that produced it;
// `keys` keeps the digests in the order we first saw them, so we can
// report groups deterministically.
method BuildGroups(filenames: seq<string>)
  returns (groups: map<string, seq<string>>, keys: seq<string>)
{
  groups := map[];
  keys := [];

  for i := 0 to |filenames| {
    var filename := filenames[i];
    var read := FileIO.ReadBytesFromFile(filename);
    if read.Success? {
      var digest := HexDigest(read.value);
      if digest in groups {
        groups := groups[digest := groups[digest] + [filename]];
      } else {
        groups := groups[digest := [filename]];
        keys := keys + [digest];
      }
    } else {
      print "warning: cannot read '", filename, "': ", read.error, "\n";
    }
  }
}

// For each group with more than one file, print the duplicate pairs.
method ReportDuplicates(groups: map<string, seq<string>>, keys: seq<string>) {
  for i := 0 to |keys| {
    // Map.Get avoids a proof obligation that `keys[i]` is present.
    var maybeFiles := Map.Get(groups, keys[i]);
    if maybeFiles.Some? {
      var files := maybeFiles.value;
      if |files| > 1 {
        for left := 0 to |files| {
          for right := 0 to left {
            print files[left], " ", files[right], "\n";
          }
        }
      }
    }
  }
}

method Main(args: seq<string>) {
  var groups, keys := BuildGroups(args);
  ReportDuplicates(groups, keys);
}
