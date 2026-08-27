# Library Requirements

This file lists the Python functions and modules used by the examples in
*Software Design by Example in Python* to interact with the file system and the
network, and whether an equivalent exists in the Dafny standard library (enabled
with `--standard-libraries`).

Dafny's standard library provides only whole-file I/O (`Std.FileIO`) and JSON
(`Std.JSON`) for the capabilities below. It has no networking, hashing, SQLite,
CSV/YAML, temporary-file, or path-manipulation support. `Std.FileIO` reads or
writes an entire file in a single call; there are no open/close file handles or
streaming reads.

## Standard streams

- `sys.stdin` (read)
  - missing (no standard-input support)
- `sys.stdout` (write)
  - exists: `print` (writes to standard output)
- `sys.stderr` (write)
  - missing

## File operations

- `open(path, mode)`: text and binary modes (`"r"`, `"w"`, `"rb"`)
  - missing (no file handles; `Std.FileIO` operates on whole files)
- `file.close()`: when `open()` isn't used with a context manager `with`
  - missing
- `file.read()`: read whole file
  - exists: `Std.FileIO.ReadUTF8FromFile` (text) or `Std.FileIO.ReadBytesFromFile` (bytes)
- `file.read(n)`: fixed-size streaming blocks
  - missing (`Std.FileIO` is whole-file only)
- `file.readlines()`: read all lines
  - missing
- `file.write(text)`: save characters to file
  - exists: `Std.FileIO.WriteUTF8ToFile` (text) or `Std.FileIO.WriteBytesToFile` (bytes)
- `print(..., file=handle)`: write text to a file handle
  - missing

## Path manipulation

- `Path(...)`: string to path
  - missing (paths are plain `string`s passed to `Std.FileIO`)
- `Path.cwd()`: where am I?
  - missing
- `Path.joinpath()`: combine paths
  - missing (path strings are concatenated with `/` or `+`)
- `Path.parent`: get path components
  - missing
- `Path.stem`: get path components
  - missing
- `Path.suffix`: get path components
  - missing
- `Path.name`: get path components
  - missing
- `Path.read_text()`: read without `open`
  - exists: `Std.FileIO.ReadUTF8FromFile`
- `Path.write_text()`: write without `open`
  - exists: `Std.FileIO.WriteUTF8ToFile`
- `Path.exists()`: inspect filesystem
  - missing
- `Path.is_file()`: inspect filesystem
  - missing
- `Path.touch()`: ensure existence
  - missing
- `Path.mkdir()` (including `parents=True, exist_ok=True`): create directories
  - partial: `Std.FileIO.WriteUTF8ToFile`/`WriteBytesToFile` create nonexistent parent directories; there is no standalone `mkdir`
- `Path.unlink()`: delete file
  - missing
- `Path.rmdir()`: delete directory
  - missing
- `Path.rename()`: change name
  - missing
- `Path.iterdir()`: get directory contents
  - missing
- `Path.glob()`: wildcard walk of a directory tree
  - missing
- `Path.rglob()`: recursive wildcard walk of a directory tree
  - missing

## Temporary files and directories

- `tempfile.TemporaryDirectory()`: make temporary directory
  - missing
- `tempfile.NamedTemporaryFile(...)`: make temporary file
  - missing

## Serialization

- JSON: `json.load()`
  - exists: `Std.JSON.API.Deserialize` (from `seq<byte>`, not from a file or string)
- JSON: `json.dump()`
  - exists: `Std.JSON.API.Serialize` (to `seq<byte>`; `SerializeAlloc` returns an `array<byte>`)
- CSV: `csv.reader()`
  - missing
- CSV: `csv.writerow()`
  - missing
- CSV: `csv.writerows()`
  - missing
- CSV: `csv.DictReader()`
  - missing
- YAML: `yaml.load()`
  - missing
- Binary records: `struct.pack()`
  - missing
- Binary records: `struct.unpack()`
  - missing
- Binary records: `struct.calcsize()`
  - missing

## Hashing

- `hashlib.sha256().hexdigest()`: whole-file digest
  - missing (the standard library has `Std.Base64`, but no SHA/MD5)
- `hashlib.md5()` with `.update()`: streaming hash over fixed-size blocks
  - missing

## SQLite

- `sqlite3.connect()`: connect to database
  - missing
- `connection.execute()`: run query
  - missing
- `connection.fetchall()`: get records
  - missing
- `connection.commit()`: save changes
  - missing

## TCP sockets

- `socket.socket()`: create a TCP socket
  - missing
- `socket.gethostbyname()`: hostname/DNS resolution
  - missing
- Client side: `.connect()`
  - missing
- Client side: `.send()`
  - missing
- Client side: `.sendall()`
  - missing
- Client side: `.recv()`
  - missing
- Client side: `.close()`
  - missing
- Server side: `.bind()`
  - missing
- Server side: `.listen()`
  - missing
- Server side: `.accept()`
  - missing
- Server side: `.recv()`
  - missing
- Server side: `.send()`
  - missing
- Server side: `.close()`
  - missing

## TCP server framework

- `socketserver.TCPServer()`: create basic TCP server
  - missing
- `socketserver.BaseRequestHandler` subclass with `.handle()`
  - missing
- `self.request.recv()`
  - missing
- `self.request.sendall()`
  - missing
- `self.client_address`
  - missing
- `server.serve_forever()`
  - missing

## HTTP server

- `HTTPServer()`
  - missing
- `BaseHTTPRequestHandler` subclass
  - missing
- `do_GET()` handler with `self.path`
  - missing
- `do_GET()` handler with `self.command`
  - missing
- `self.send_response()`
  - missing
- `self.send_header()`
  - missing
- `self.end_headers()`
  - missing
- `self.wfile.write(body)`
  - missing
- `server.serve_forever()`
  - missing
- `HTTPStatus` enum (from the `http` module) for status codes
  - missing

## HTTP client

- `requests.get()`
  - missing
- `response.status_code`
  - missing
- `response.headers[]`
  - missing
- `response.text`
  - missing
- `urllib.request.Request()`
  - missing
- `req.add_header()`
  - missing
- `urllib.request.urlopen()`
  - missing
- `response.read()`
  - missing
