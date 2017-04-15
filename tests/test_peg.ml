

open Pure
open Fold
open Fold.Lex

module C = Colors

module Result = struct
  include Result

  let map f = function
    | Ok x -> Ok (f x)
    | Error e -> Error e
end

let show = function
  | Ok xs -> "[" ^ String.concat "; " (List.map Token.to_string xs) ^ "]"
  | Error e -> Parser.error_to_string e


let (=>) (peg, input) (expected, leftover) =
  let parser = PEG.parse peg in
  let actual = Result.map fst (Parser.run parser input) in
  let desc = Fmt.strf "(%s, %a)" (PEG.to_string peg) (Fmt.Dump.list Token.pp) (Iter.to_list input) in
  if actual = expected then
    print ("%s %s" % (C.bright_green "✓", C.bright_white desc))
  else begin
    print ("%s %s" % (C.bright_red "✗", C.bright_white desc));
    print ("  - Expected: %s" % C.green (show expected));
    print ("  - Actual:   %s" % C.red (show actual))
  end


let a = Symbol "a"
let b = Symbol "b"

let iter = Iter.of_list

let () =
  (* (p, s) => (r, s')
   *
   * where p  is the parsing expression
   *       s  is the initial input state of the parser
   *       r  is the produced result after appling [p]
   *       s' is the input state after applying [p]
   *)

  PEG.(Epsilon, iter []) => (Ok [], []);
  PEG.(Epsilon, iter [a]) => (Ok [], [a]);
  PEG.(Terminal "a", iter [a]) => (Ok [a], []);
  PEG.(Terminal "a", iter []) => (Error (Parser.Unexpected_end { expected = a }), []);
  PEG.(Terminal "a", iter [b]) => (Error (Parser.Unexpected_token { expected = a; actual = b }), [b]);
  PEG.(Terminal "a", iter [a; b]) => (Ok [a], [b]);
  PEG.(Many (Terminal "a"), iter []) => (Ok [], []);
  PEG.(Many (Terminal "a"), iter [a; b]) => (Ok [a], [b]);
  PEG.(Many (Terminal "a"), iter [a; a; a]) => (Ok [a; a; a], []);
  PEG.(Alternative [Terminal "a"; Terminal "b"], iter [a]) => (Ok [a], []);
  PEG.(Alternative [Terminal "a"; Terminal "b"], iter [b]) => (Ok [b], [])

