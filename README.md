# geomyid
Gopher server written in Common Lisp (for SBCL/FreeBSD)

This software (rather intensively) uses unportable features from both SBCL and FreeBSD.
The main unportable feature from FreeBSD is its extended attributes,
of which all those used are in the "user" namespace (see getextattr(8) and extattr(2)).
These are used to affect how files are displayed in directory listings.

#### Extended attributes, their functions, and their defaults if not specified.
##### selector-type
The Gopher type for a resource. Autodetected based upon file extension, falling back to '0' for files and '1' for directories.
##### title
The name displayed for a resource in directory listings. Defaults to the file name.
##### selector
The path of the file. Defaults to actual path relative to the local gopher root.
##### host
What server the file is hosted on. Defaults to the local host.
##### port
What port the file is available on. Defaults to the port specified to (serve) or 70.

Directory listings are sorted case-sensitively by the determined selector.