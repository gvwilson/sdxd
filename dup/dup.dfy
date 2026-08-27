// Find duplicate files.
//

// This is a Dafny translation of the "Finding Duplicate Files" chapter
// from *Software Design by Example in Python*.  The Python version uses
// SHA-256 from `hashlib`, but Dafny's standard library does not have a
// cryptographic hash function. We therefore implement a small hash of our
// own and use the standard libraries for:
//
// * Std.FileIO.ReadBytesFromFile: read a file's bytes
// * Std.Collections.Map.Get: safe map lookup
//
// Because our hash is not cryptographic, two *different* files could in
// principle collide. To guarantee correctness we use the hash only to
// group candidates, then confirm with a byte-for-byte comparison in
// each group.

import Std.FileIO
import Std.Collections.Map

// A non-cryptographic, deterministic hash over a sequence of bytes.
// It is a polynomial (rolling) hash: each byte is folded in with a prime
// multiplier, and the result is reduced modulo a large prime so the value
// stays in a small, fixed range. (Dafny integers are arbitrary precision, so
// the modulo keeps the hash code bounded as files grow.)
function HashBytes(data: seq<bv8>): nat {
  HashBytesFrom(data, 0)
}

function HashBytesFrom(data: seq<bv8>, acc: nat): nat
  decreases |data|
{
  if |data| == 0 then
    acc
  else
    HashBytesFrom(data[1..], (acc * 16777619 + (data[0] as nat)) % 1000000007)
}

// Do the bytes of the two files match exactly?
method SameBytes(left: string, right: string) returns (same: bool) {
  var leftResult := FileIO.ReadBytesFromFile(left);
  var rightResult := FileIO.ReadBytesFromFile(right);
  if leftResult.Success? && rightResult.Success? {
    return leftResult.value == rightResult.value;
  } else {
    // Either file could not be read, so we cannot claim they are equal.
    return false;
  }
}

// Given a group of filenames that all share one hash code, compare every
// distinct pair and return the pairs whose contents really match.
method FindDuplicatePairs(filenames: seq<string>) returns (pairs: seq<(string, string)>) {
  pairs := [];
  for i := 0 to |filenames| {
    var left := filenames[i];
    for j := 0 to i {
      var right := filenames[j];
      var same := SameBytes(left, right);
      if same {
        pairs := pairs + [(left, right)];
      }
    }
  }
}

// Read every file, hash its bytes, and group the filenames by hash code.
// `groups` maps a hash code to the filenames that produced it. `keys` keeps
// the hash codes in the order we first saw them, so we can report groups
// deterministically.
method BuildGroups(filenames: seq<string>)
  returns (groups: map<nat, seq<string>>, keys: seq<nat>)
{
  groups := map[];
  keys := [];

  for i := 0 to |filenames| {
    var filename := filenames[i];
    var read := FileIO.ReadBytesFromFile(filename);
    if read.Success? {
      var hash := HashBytes(read.value);
      if hash in groups {
        groups := groups[hash := groups[hash] + [filename]];
      } else {
        groups := groups[hash := [filename]];
        keys := keys + [hash];
      }
    } else {
      print "warning: cannot read '", filename, "': ", read.error, "\n";
    }
  }
}

// For each group with more than one file, confirm the duplicates with a
// byte-for-byte comparison and print the matching pairs.
method ReportDuplicates(groups: map<nat, seq<string>>, keys: seq<nat>) {
  for i := 0 to |keys| {
    // Map.Get avoids a proof obligation that `keys[i]` is present.
    var maybeFiles := Map.Get(groups, keys[i]);
    if maybeFiles.Some? {
      var files := maybeFiles.value;
      if |files| > 1 {
        var duplicates := FindDuplicatePairs(files);
        for j := 0 to |duplicates| {
          print duplicates[j].0, " ", duplicates[j].1, "\n";
        }
      }
    }
  }
}

method Main(args: seq<string>) {
  var groups, keys := BuildGroups(args);
  ReportDuplicates(groups, keys);
}
