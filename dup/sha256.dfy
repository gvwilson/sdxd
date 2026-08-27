// SHA-256 message digest.
//
// A Dafny implementation SHA-256.
// Dafny has no `struct` module, so we convert between bytes and words
// ourselves (`WordAt` and `ByteAt`). Dafny's 32-bit bit-vector type (`bv32`)
// already wraps its arithmetic modulo 2^32, so the `& 0xFFFFFFFF` masks are
// unnecessary. Bitwise `&`, `|`, `^`, and `~` behave the same on `bv32` as
// they do on Python's integers after masking.
//
// The result of `Sha256` is the 32-byte digest (the 8 final words, each
// written big-endian). `HexDigest` renders it as the usual 64-character
// lowercase hexadecimal string, matching Python's `sha256` return value.

// Round constants K[i], as defined in FIPS 180-4.
const Kt: seq<bv32> := [
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
]

// The eight initial hash values H[0..7].
const H0: bv32 := 0x6A09E667
const H1: bv32 := 0xBB67AE85
const H2: bv32 := 0x3C6EF372
const H3: bv32 := 0xA54FF53A
const H4: bv32 := 0x510E527F
const H5: bv32 := 0x9B05688C
const H6: bv32 := 0x1F83D9AB
const H7: bv32 := 0x5BE0CD19

// Bitwise complement of a 32-bit word.
function Not(x: bv32): bv32 {
  x ^ 0xFFFFFFFF
}

// The logical functions used by SHA-256.
function Ch(x: bv32, y: bv32, z: bv32): bv32 {
  (x & y) ^ (Not(x) & z)
}

function Maj(x: bv32, y: bv32, z: bv32): bv32 {
  (x & y) ^ (x & z) ^ (y & z)
}

// Rotate a 32-bit word right by n places.
function ROTR(x: bv32, n: int): bv32
  requires 0 <= n < 32
{
  (x >> n) | (x << (32 - n))
}

function Sigma0(x: bv32): bv32 {
  ROTR(x, 2) ^ ROTR(x, 13) ^ ROTR(x, 22)
}

function Sigma1(x: bv32): bv32 {
  ROTR(x, 6) ^ ROTR(x, 11) ^ ROTR(x, 25)
}

function sigma0(x: bv32): bv32 {
  ROTR(x, 7) ^ ROTR(x, 18) ^ (x >> 3)
}

function sigma1(x: bv32): bv32 {
  ROTR(x, 17) ^ ROTR(x, 19) ^ (x >> 10)
}

// 2^e, used to pick bytes out of the 64-bit message length.
function Power256(e: nat): nat
  ensures Power256(e) > 0
{
  if e == 0 then 1 else 256 * Power256(e - 1)
}

// Byte shift of the 64-bit big-endian representation of `n` (shift 7 is
// the most significant byte, shift 0 the least significant).
function LengthByte(n: nat, shift: nat): bv8 {
  ((n / Power256(shift)) % 256) as bv8
}

// The 64-bit big-endian length, as 8 bytes.
function LengthBytes(n: nat): seq<bv8> {
  [
    LengthByte(n, 7), LengthByte(n, 6), LengthByte(n, 5), LengthByte(n, 4),
    LengthByte(n, 3), LengthByte(n, 2), LengthByte(n, 1), LengthByte(n, 0)
  ]
}

// A run of `n` zero bytes.
function Zeros(n: nat): seq<bv8>
  decreases n
{
  if n == 0 then [] else [0 as bv8] + Zeros(n - 1)
}

// Pad `message` to a multiple of 512 bits: a single 0x80 byte, as many zero
// bytes as needed so the length is 448 (mod 512) bits, then the original
// length in bits as a 64-bit big-endian value.
function Pad(message: seq<bv8>): seq<bv8> {
  message
    + [0x80 as bv8]
    + Zeros((55 - |message|) % 64)
    + LengthBytes(|message| * 8)
}

// Read four big-endian bytes starting at `off` as one 32-bit word.
function WordAt(data: seq<bv8>, off: nat): bv32
  requires off + 4 <= |data|
{
  ((data[off] as bv32) << 24)
  | ((data[off + 1] as bv32) << 16)
  | ((data[off + 2] as bv32) << 8)
  | (data[off + 3] as bv32)
}

// The `k`-th byte (0 is most significant) of a 32-bit word.
function ByteAt(w: bv32, k: int): bv8
  requires 0 <= k < 4
{
  (((w >> (8 * (3 - k))) as nat) % 256) as bv8
}

// A 32-bit word as four big-endian bytes.
function WordBytes(w: bv32): seq<bv8> {
  [ByteAt(w, 0), ByteAt(w, 1), ByteAt(w, 2), ByteAt(w, 3)]
}

// Compute the SHA-256 digest of `message` as 32 bytes.
method Sha256(message: seq<bv8>) returns (digest: seq<bv8>) {
  var padded := Pad(message);

  var h0 := H0;
  var h1 := H1;
  var h2 := H2;
  var h3 := H3;
  var h4 := H4;
  var h5 := H5;
  var h6 := H6;
  var h7 := H7;

  var numBlocks := |padded| / 64;
  for block := 0 to numBlocks {
    // Build the 64-word message schedule for this 512-bit block.
    var w := new bv32[64];
    for j := 0 to 16 {
      w[j] := WordAt(padded, block * 64 + 4 * j);
    }
    for i := 16 to 64 {
      w[i] := sigma1(w[i - 2]) + w[i - 7] + sigma0(w[i - 15]) + w[i - 16];
    }

    var a := h0;
    var b := h1;
    var c := h2;
    var d := h3;
    var e := h4;
    var f := h5;
    var g := h6;
    var h := h7;

    // The 64 compression rounds.
    for i := 0 to 64 {
      var t1 := h + Sigma1(e) + Ch(e, f, g) + Kt[i] + w[i];
      var t2 := Sigma0(a) + Maj(a, b, c);
      h := g;
      g := f;
      f := e;
      e := d + t1;
      d := c;
      c := b;
      b := a;
      a := t1 + t2;
    }

    h0 := h0 + a;
    h1 := h1 + b;
    h2 := h2 + c;
    h3 := h3 + d;
    h4 := h4 + e;
    h5 := h5 + f;
    h6 := h6 + g;
    h7 := h7 + h;
  }

  digest :=
    WordBytes(h0) + WordBytes(h1) + WordBytes(h2) + WordBytes(h3)
    + WordBytes(h4) + WordBytes(h5) + WordBytes(h6) + WordBytes(h7);
}

// One hexadecimal digit for a value in [0, 16).
function HexDigit(n: nat): char
  requires n < 16
{
  match n {
    case 0 => '0'
    case 1 => '1'
    case 2 => '2'
    case 3 => '3'
    case 4 => '4'
    case 5 => '5'
    case 6 => '6'
    case 7 => '7'
    case 8 => '8'
    case 9 => '9'
    case 10 => 'a'
    case 11 => 'b'
    case 12 => 'c'
    case 13 => 'd'
    case 14 => 'e'
    case 15 => 'f'
  }
}

// One byte as two lowercase hexadecimal characters.
function ByteToHex(b: bv8): string {
  [HexDigit((b as nat) / 16), HexDigit((b as nat) % 16)]
}

// A sequence of bytes as a lowercase hexadecimal string.
function ToHex(data: seq<bv8>): string
  decreases |data|
{
  if |data| == 0 then "" else ByteToHex(data[0]) + ToHex(data[1..])
}

// The SHA-256 digest of `message` as a 64-character hex string, matching
// Python's `sha256(message)`.
method HexDigest(message: seq<bv8>) returns (hex: string) {
  var digest := Sha256(message);
  hex := ToHex(digest);
}
