(* Much of the templ code is take from the Jane Street Hardcaml AOC Tempelate: https://github.com/janestreet/hardcaml_template_project/tree/with-extensions *)
open! Core
open! Hardcaml
open! Signal
open! With_valid

let num_bits = 16

(* Add is_r and val inputs *)

module I = struct
  type 'a t =
    { clock : 'a
    ; clear : 'a
    ; start : 'a
    ; finish : 'a
    ; is_r : 'a
    ; value : 'a [@bits num_bits]
    ; data_in_valid : 'a
    }
  [@@deriving hardcaml]
end

module O = struct
  type 'a t =
    { cnt_valid : 'a
    ; cnt_value : 'a [@bits num_bits]
    } [@@deriving hardcaml]
end

module States = struct
  type t =
    | Idle
    | Accepting_inputs
    | Done
  [@@deriving sexp_of, compare ~localize, enumerate]
end

let create scope ({ clock; clear; start; finish; is_r; value; data_in_valid } : _ I.t) : _ O.t
  =
  let spec = Reg_spec.create ~clock ~clear () in
  let open Always in
  let sm =
   
    State_machine.create (module States) spec
  in
  let%hw_var sum = Variable.reg spec ~width:num_bits in
  let%hw_var cnt = Variable.reg spec ~width:num_bits in
 
  let cnt_valid = Variable.wire ~default:gnd in
  (* Signed mod 100 (to adjust raw vals). Naive way: add/subtract 100 till range met (first identify range with quick script).valid
  Speedup (loses acc): first make positive (just add 5k for robstuness/safety) and use form: x% 100 = x- 100*floor(x/100). Approximte 1/100 with 
  M/2^k and do shifts. M/2^k = 1/100, 100M = 2^k, M < 65536/2 (signed). Just take flr(log2(100*2^15)) = 21. K = 21, M ~ 20972. Then do x - 100 * floor(x * 20972 >> 21). *)
  (*Keeping naive for accuracy and ref
  let mod100 x =
    let h = of_int ~width:num_bits 100 in
    let is_neg v = msb v in
    let normalize v =
      mux2 (is_neg v) (v +: h) (mux2 (v >=:. 100) (v -: h) v)
    in
    (* 10 passes handles values up to ±1000 *)
    let x = normalize x in
    let x = normalize x in
    let x = normalize x in
    let x = normalize x in
    let x = normalize x in
    let x = normalize x in
    let x = normalize x in
    let x = normalize x in
    let x = normalize x in
    let x = normalize x in
    x
  in
  *)
  let mod100 raw =
    let h = of_int ~width:num_bits 100 in
    (* Add offset to make positive *)
    let x = raw +: of_int ~width:num_bits 5000 in
    (* can't overflow so expand x*)
    let wide_bits = 32 in
    let x_wide = uresize x wide_bits in
    
    let m = of_int ~width:wide_bits 20972 in
    (* x * m >> 21 ~ floor(x / 100) *)
    let prod = x_wide *: m in 
    let shift = srl prod 21 in  
    let approx = sel_bottom shift num_bits in  (* dont need expansion anymore*)
    (*now take h* floor (x/100) for subtraction/correction term*)
    let sub = sel_bottom (uresize h wide_bits *: uresize approx wide_bits) num_bits in
    let modded = x -: sub in
    modded
  in
  compile
    [ sm.switch
        [ ( Idle
          , [ when_
                start
                [ sum <-- of_int ~width:num_bits 50
                ; cnt <-- zero num_bits
                ; sm.set_next Accepting_inputs 
                ]
            ] )
        ; ( Accepting_inputs
          , [ when_
                data_in_valid
                ( 
                  let raw_sum = mux2 is_r (sum.value +: value) (sum.value -: value) in
                  let mod_sum = mod100 raw_sum in
                  [ sum <-- mod_sum
                  (* Check new for 0*)
                  ; when_ (mod_sum ==:. 0)
                      [ cnt <-- cnt.value +:. 1
                      ; cnt_valid <-- vdd 
                      ]
                  ]
                )
            ; when_ finish [ sm.set_next Done ]
            ] )
        ; ( Done
          , [ when_ finish [ sm.set_next Accepting_inputs ]
            ] )
        ]
    ];
  (* [.value] is used to get the underlying Signal.t from a Variable.t in the Always DSL. *)
  { cnt_valid = cnt_valid.value; cnt_value = cnt.value }
;;

(* The [hierarchical] wrapper is used to maintain module hierarchy in the generated
   waveforms and (optionally) the generated RTL. *)
let hierarchical scope =
  let module Scoped = Hierarchy.In_scope (I) (O) in
  Scoped.hierarchical ~scope ~name:"day01" create
;;
