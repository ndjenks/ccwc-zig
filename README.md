# ccwc-zig
This is a coding challenge from John Crickett to re-implement the command line utility "wc".

# Usage
Just like "wc" it has the following options:
| Options |            Description        | 
|:-------:|:-----------------------------:|
|  -h     | Print command-specific usage  |
|  -l     | Print line count              |
|  -w     | Print word count              |
|  -c     | Print byte count              |
|  -m     | Print character count         |

```
./zig-out/bin/ccwc-zig -l filepath                 -- Prints number of lines

./zig-out/bin/ccwc-zig -wl filepath                -- Prints number of lines and words

./zig-out/bin/ccwc-zig filepath                    -- Prints number of lines, words and bytes

cat filepath | ./zig-out/bin/ccwc-zig -lm          -- Reads from stdin and prints number
                                                      of lines and chars

cat filepath | ./zig-out/bin/ccwc-zig              -- Reads from stdin and prints number
                                                      of lines, words and bytes
```

Feel free to review the code.




