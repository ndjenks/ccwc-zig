// The unicode standard makes a difference between user-perceived characters and characters as known in computing
// Both types of characters can be classified as grapheme. A grapheme can consist of one or more code units.
// Meaning a user-perceived character can be represented by more than one code unit
// To be able to identify that a user perceived character has more than one code unit, the unicode standard
// defines a set of boundaries to identify these.
// Here the algorithm used to break a grapheme into its corresponding code units
// is the Deterministic Finite Automation (DFA) presented and implemented by Bob Steagall during
// CPPCON18.
// THIS IS NOT MY PROPERTY !!!
const std = @import("std");
//ILL = 0, //- C0..C1, F5..FF  ILLEGAL octets that should never appear in a UTF-8 sequence

//ASC = 1, //- 00..7F          ASCII leading byte range

//CR1 = 2, //- 80..8F          Continuation range 1
//CR2 = 3, //- 90..9F          Continuation range 1
//CR3 = 4, //- A0..BF          Continuation range 1

//L2A = 5, //- C2..DF          Leading byte range A / 2-byte sequence

//L3A = 6, //- E0              Leading byte range A / 3-byte sequence
//L3B = 7, //- E1..EC, EE..EF  Leading byte range B / 3-byte sequence
//L3C = 8, //- ED              Leading byte range C / 3-byte sequence
////
//L4A = 9, //- F0              Leading byte range A / 4-byte sequence
//L4B = 10, //- F1..F3          Leading byte range B / 4-byte sequence
//L4C = 11, //- F4              Leading byte range C / 4-byte sequence

const ILL = 0;
const ASC = 1;
const CR1 = 2;
const CR2 = 3;
const CR3 = 4;
const L2A = 5;
const L3A = 6;
const L3B = 7;
const L3C = 8;
const L4A = 9;
const L4B = 10;
const L4C = 11;

const BGN = 0; //- Start
const ERR = 12; //- Invalid sequence
//
const CS1 = 24; //- Continuation state 1
const CS2 = 36; //- Continuation state 2
const CS3 = 48; //- Continuation state 3
//
const P3A = 60; //- Partial 3-byte sequence state A
const P3B = 72; //- Partial 3-byte sequence state B
//
const P4A = 84; //- Partial 4-byte sequence state A
const P4B = 96; //- Partial 4-byte sequence state B
//
const END = BGN; //- Start and End are the same state!
const err = ERR; //- For readability in the state transition table

pub fn GraphemeBreaker() type {
    return struct {
        const DFAOctetCategory = [256]u8{
            ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, //- 00..0F
            ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, //- 10..1F
            ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, //- 20..2F
            ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, //- 30..3F
            ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, //- 40..4F
            ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, //- 50..5F
            ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, //- 60..6F
            ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC, //- 70..7F
            CR1, CR1, CR1, CR1, CR1, CR1, CR1, CR1, CR1, CR1, CR1, CR1, CR1, CR1, CR1, CR1, //- 80..8F
            CR2, CR2, CR2, CR2, CR2, CR2, CR2, CR2, CR2, CR2, CR2, CR2, CR2, CR2, CR2, CR2, //- 90..9F
            CR3, CR3, CR3, CR3, CR3, CR3, CR3, CR3, CR3, CR3, CR3, CR3, CR3, CR3, CR3, CR3, //- A0..AF
            CR3, CR3, CR3, CR3, CR3, CR3, CR3, CR3, CR3, CR3, CR3, CR3, CR3, CR3, CR3, CR3, //- B0..BF
            ILL, ILL, L2A, L2A, L2A, L2A, L2A, L2A, L2A, L2A, L2A, L2A, L2A, L2A, L2A, L2A, //- C0..CF
            L2A, L2A, L2A, L2A, L2A, L2A, L2A, L2A, L2A, L2A, L2A, L2A, L2A, L2A, L2A, L2A, //- D0..DF
            L3A, L3B, L3B, L3B, L3B, L3B, L3B, L3B, L3B, L3B, L3B, L3B, L3B, L3C, L3B, L3B, //- E0..EF
            L4A, L4B, L4B, L4B, L4C, ILL, ILL, ILL, ILL, ILL, ILL, ILL, ILL, ILL, ILL, ILL, //- F0..FF
        };
        const DFATransitions = [108]u8{
            err, END, err, err, err, CS1, P3A, CS2, P3B, P4A, CS3, P4B, //- BGN|END
            err, err, err, err, err, err, err, err, err, err, err, err, //- ERR
            err, err, END, END, END, err, err, err, err, err, err, err, //- CS1
            err, err, CS1, CS1, CS1, err, err, err, err, err, err, err, //- CS2
            err, err, CS2, CS2, CS2, err, err, err, err, err, err, err, //- CS3
            err, err, err, err, CS1, err, err, err, err, err, err, err, //- P3A
            err, err, CS1, CS1, err, err, err, err, err, err, err, err, //- P3B
            err, err, err, CS2, CS2, err, err, err, err, err, err, err, //- P4A
            err, err, CS2, err, err, err, err, err, err, err, err, err, //- P4B
        };

        pub fn breaker(word: [*]u8, codeUnits: *std.ArrayList(u8)) !void {
            var currentState: u8 = undefined;
            var codeUnit: u8 = undefined;
            var graphemeClass: u8 = undefined;
            var start: usize = 0;
            _ = &start;
            var wordSlice = word[start..];

            codeUnit = wordSlice[0];
            wordSlice += 1;
            graphemeClass = DFAOctetCategory[codeUnit];
            currentState = DFATransitions[graphemeClass];
            try codeUnits.append(codeUnit);

            while (currentState > ERR) {
                if (wordSlice > wordSlice.len - 1) {
                    codeUnit = wordSlice[0];
                    wordSlice += 1;
                    graphemeClass = .DFAOctetCategory[codeUnit];
                    currentState = .DFATransitions[graphemeClass];
                    try codeUnits.append(codeUnit);
                } else {
                    return ERR;
                }
            }
        }
    };
}
