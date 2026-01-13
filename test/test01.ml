open! Core
open! Hardcaml
open! Hardcaml_waveterm
module Day01 = Hardcaml_aoc.Day01 

let create_sim () =
  let module Sim = Cyclesim.With_interface (Day01.I) (Day01.O) in
  Sim.create (Day01.create (Scope.create ~flatten_design:true ()))

(*simple parsing*)
let parse_line line =
  let char_code = String.get line 0 in
  let num_part = String.sub line ~pos:1 ~len:(String.length line - 1) in
  let value = Int.of_string num_part in
  
  match char_code with
  | 'R' -> (true, value)  (* R means is_r = 1 *)
  | 'L' -> (false, value) (* L means is_r = 0 *)
  | _ -> failwith "bad input"

(* main loop *)
let%expect_test "Day 1 Sim" =
  let sim = create_sim () in
  let inputs = Cyclesim.inputs sim in
  let outputs = Cyclesim.outputs sim in

  let step () = Cyclesim.cycle sim in

  (*reset*)
  inputs.clear := Bits.vdd;
  step ();
  inputs.clear := Bits.gnd;
  step ();

  inputs.start := Bits.vdd;
  step ();
  inputs.start := Bits.gnd;
  step ();

  (*parsing*)
  let lines = In_channel.read_lines "/workspaces/hardcaml_template_project/input01.txt" in
  List.iter lines ~f:(fun line ->
    let (is_r, value) = parse_line line in
    inputs.is_r := if is_r then Bits.vdd else Bits.gnd;
    inputs.value := Bits.of_int ~width:16 value;
    inputs.data_in_valid := Bits.vdd;
    step ();
    inputs.data_in_valid := Bits.gnd;
  );

  inputs.finish := Bits.vdd;
  step ();
  inputs.finish := Bits.gnd;
  step ();
  
  let final_valid = Bits.to_int !(outputs.cnt_valid) in
  let final_count = Bits.to_int !(outputs.cnt_value) in
  
  print_s [%message 
    "FINAL" 
    (final_valid : int) 
    (final_count : int)
    ]
;;
;;