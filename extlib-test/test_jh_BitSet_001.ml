(*
 * ExtLib Testing Suite
 * Copyright (C) 2004 Janne Hellsten
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version,
 * with the special exception on linking described in file LICENSE.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *)

open ExtList

module B = BitSet

let biased_rnd_28 () = 
  let n_bits = [| 4; 8; 16; 28 |] in
  let n = n_bits.(Random.int (Array.length n_bits)) in
  Random.int (1 lsl n)

let popcount n = 
  let p = ref 0 in
  for i = 0 to 29 do
    if n land (1 lsl i) <> 0 then
      incr p
  done;
  !p

let bitset_of_int n = 
  assert (n <= (1 lsl 29));
  let s = B.create 30 in
  for i = 0 to 29 do
    if (n land (1 lsl i)) <> 0 then
      B.set s i
  done;
  assert (popcount n = B.count s);
  s

let int_of_bitset s = 
  let n = ref 0 in
  for i = 0 to 29 do
    if B.is_set s i then
      n := !n lor (1 lsl i)
  done;
  !n

let bitset_of_int_scale n scl = 
  assert (n <= (1 lsl 29));
  let s = B.create 30 in
  for i = 0 to 29 do
    if (n land (1 lsl i)) <> 0 then
      B.set s (i*scl)
  done;
  assert (popcount n = B.count s);
  s

let int_of_bitset_scale s scl = 
  let n = ref 0 in
  for i = 0 to 29 do
    if B.is_set s (i*scl) then
      n := !n lor (1 lsl i)
  done;
  !n

let test_rnd_creation () =
  for i = 0 to 255 do
    let r1 = biased_rnd_28 () in
    let s = bitset_of_int r1 in
    let c = B.copy s in
    assert (int_of_bitset s = r1);
    assert (c = s);
    assert (B.compare c s = 0);
    B.unite c s;
    assert (c = s);
    B.intersect c (B.empty ());
    assert (B.count c = 0);
  done

let test_intersect () = 
  for i = 0 to 255 do
    let s = bitset_of_int (biased_rnd_28 ()) in
    B.intersect s (B.empty ());
    assert (B.count s = 0)
  done

let test_diff () = 
  for i = 0 to 255 do
    let r = biased_rnd_28 () in
    let s = bitset_of_int r in
    if r <> 0 then
      assert (B.count s <> 0);
    assert (B.count ((B.diff s s)) = 0);
  done

let test_sym_diff () =
  for i = 0 to 255 do
    let s = (Random.int 3)+1 in
    let r1 = biased_rnd_28 () in
    let r2 = biased_rnd_28 () in
    let s1 = bitset_of_int_scale r1 s in
    let s2 = bitset_of_int_scale r2 s in
    assert (int_of_bitset_scale (bitset_of_int_scale r1 s) s = r1);
    assert (int_of_bitset_scale (B.sym_diff s1 s2) s = r1 lxor r2);
    assert (int_of_bitset_scale (B.sym_diff s2 s1) s = r1 lxor r2);
    assert (B.count (B.sym_diff s1 s1) = 0);
    assert (B.count (B.sym_diff s2 s2) = 0);
  done

let test_compare () =
  for i = 0 to 255 do
    let r1 = biased_rnd_28 () in
    let r2 = biased_rnd_28 () in
    let s1 = bitset_of_int r1 
    and s2 = bitset_of_int r2 in
    let sr = B.compare s1 s2
    and ir = compare r1 r2 in
    assert (sr = ir)
  done;
  for i = 0 to 255 do
    let scl = (Random.int 15)+1 in
    let r1 = biased_rnd_28 () in
    let r2 = biased_rnd_28 () in
    let s1 = bitset_of_int_scale r1 scl
    and s2 = bitset_of_int_scale r2 scl in
    let sr = B.compare s1 s2
    and ir = compare r1 r2 in
    assert (sr = ir)
  done;
  for i = 1 to 255 do
    let s1 = bitset_of_int (i-1) in
    let s2 = bitset_of_int i in
    assert (B.compare s1 s2 = -1)
  done;
  for i = 1 to 255 do
    let s1 = bitset_of_int (i-1) in
    let s2 = bitset_of_int i in
    assert (B.compare s1 s2 = -1)
  done

module BSSet = Set.Make (struct type t = BitSet.t let compare = B.compare end)

let test_compare_2 () = 
  let nums = List.init 256 Std.identity in
  let num_set = 
    List.fold_left (fun acc e -> BSSet.add (bitset_of_int e) acc) BSSet.empty nums in
  List.iter
    (fun e -> 
       let bs = bitset_of_int e in
       assert (BSSet.mem bs num_set)) nums

let test_empty () = 
  for len = 0 to 63 do
    let s = B.empty () in
    for i = 0 to len do 
      assert (not (B.is_set s i));
      B.set s i
    done;
    assert (not (B.is_set s (len+1)));
    for i = 0 to len do 
      assert (B.is_set s i)
    done
  done

let test_exceptions () = 
  let expect_exn f =
    try 
      f ();
      false (* Should've raised an exception! *)
    with B.Negative_index _ -> true in
  let s = B.create 100 in
  assert (expect_exn (fun () -> B.set s (-15)));
  assert (expect_exn (fun () -> B.unset s (-15)));
  assert (expect_exn (fun () -> B.toggle s (-15)));
  assert (expect_exn 
            (fun () ->
               let s = B.create 8 in
               B.is_set s (-19)))

module IS = Set.Make (struct type t = int let compare = compare end)

let set_of_int n = 
  let rec loop accu i =
    if i < 30 then
      if ((1 lsl i) land n) <> 0 then
        loop (IS.add i accu) (i+1)
      else 
        loop accu (i+1)
    else accu in
  loop IS.empty 0

let int_of_set s = 
  IS.fold (fun i acc -> (1 lsl i) lor acc) s 0

let test_set_opers () = 
  let rnd_oper () = 
    match Random.int 3 with
      0 -> (IS.inter, B.inter)
    | 1 -> (IS.diff, B.diff)
    | 2 -> (IS.union, B.union)
    | _ -> assert false in
  for i = 0 to 255 do
    let r1 = biased_rnd_28 () in
    let r2 = biased_rnd_28 () in
    let s1 = set_of_int r1
    and s2 = set_of_int r2
    and bs1 = bitset_of_int r1 
    and bs2 = bitset_of_int r2 in
    assert (int_of_set s1 = r1);
    assert (int_of_set s2 = r2);
    assert (int_of_bitset bs1 = r1);
    assert (int_of_bitset bs2 = r2);
    let (isop,bsop) = rnd_oper () in
    let is = isop s1 s2 
    and bs = bsop bs1 bs2 in
    let is_int = int_of_set is in
    let bs_int = int_of_bitset bs in
    assert (is_int = bs_int);
  done

let test () =
  Util.run_test ~test_name:"jh_BitSet.test_intersect" test_intersect;
  Util.run_test ~test_name:"jh_BitSet.test_diff" test_diff;
  Util.run_test ~test_name:"jh_BitSet.test_sym_diff" test_sym_diff;
  Util.run_test ~test_name:"jh_BitSet.test_rnd_creation" test_rnd_creation;
  Util.run_test ~test_name:"jh_BitSet.test_empty" test_empty;
  Util.run_test ~test_name:"jh_BitSet.test_exceptions" test_exceptions;
  Util.run_test ~test_name:"jh_BitSet.test_compare" test_compare;
  Util.run_test ~test_name:"jh_BitSet.test_compare_2" test_compare_2;
  Util.run_test ~test_name:"jh_BitSet2.test_set_opers" test_set_opers