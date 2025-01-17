(********************************************************************
 * This file is part of the source code analyzer Discover.
 *
 * Copyright (c) 2020-2022 Singapore Blockchain Innovation Programme.
 * All rights reserved.
 ********************************************************************)

open Dcore
module PS = Outils.Process
module LL = Llvm
module LI = Llir
module LU = Llutils
module LN = Llnormalize

let print_module_stats filename =
  if !print_stats_prog
  then (
    let llcontext = LL.create_context () in
    let llmem = LL.MemoryBuffer.of_file filename in
    let modul = Llvm_bitreader.parse_bitcode llcontext llmem in
    let _ = LU.print_pointer_stats modul in
    LL.MemoryBuffer.dispose llmem)
  else ()
;;

let export_bitcode_to_file (input_file : string) (modul : LL.llmodule) =
  let basename = Filename.chop_extension (Filename.basename input_file) in
  let dirname = Filename.dirname input_file in
  let output_file = dirname ^ Filename.dir_sep ^ basename ^ ".ll" in
  let _ = LL.print_module output_file modul in
  debug ("Export LLVM IR to: " ^ output_file)
;;

let process_module (input_file : string) (modul : LL.llmodule) : LI.program =
  let _ = print ("Normalize bitcode: " ^ input_file) in
  let _ = LN.rename_vars_and_params modul in
  let _ = if !llvm_simplify then LN.normalize_module input_file modul in
  let _ = if !export_bitcode then export_bitcode_to_file input_file modul in
  let _ = LN.check_normalization modul in
  let prog = modul |> LI.mk_raw_program input_file |> LI.update_program_info in
  let _ =
    debugp ~header:true
      ~enable:((not !print_concise_output) && !print_core_prog)
      "CORE BITCODE PROGRAM" LI.pr_program prog in
  prog
;;

(** Disassemble LLVM bitcode (.bc files) to IR (.ll files) *)
let disassemble_bitcode (filename : string) : unit =
  match Sys.file_exists filename with
  | `No | `Unknown ->
    errorf "Failed to disasemble LLVM bitcode (file not found): %s" filename
  | `Yes ->
    match PS.run_command [ !llvm_dis_exe; filename ] with
    | Ok () -> ()
    | Error log -> errorf ~log "Failed to disassemble bitcode file: %s" filename
;;

(** Optimize LLVM bitcode by running the LLVM's opt tool *)
let optimize_bitcode (input_file : string) : string =
  let _ = print ("Optimize bitcode file: " ^ input_file) in
  let basename = Filename.chop_extension (Filename.basename input_file) in
  let dirname = Filename.dirname input_file in
  let _ = Sys.make_dir dirname in
  let output_file = dirname ^ Filename.dir_sep ^ basename ^ ".opt.bc" in
  let _ =
    let _ = Sys.remove_file output_file in
    if !llvm_optimize
    then (
      let user_options =
        if String.is_empty !opt_user_options
        then []
        else String.split ~on:' ' !opt_user_options in
      let cmd =
        [ !llvm_opt_exe; input_file; "-o"; output_file ]
        @ [ "-mem2reg" ] (* promote pointer variables to registers *)
        @ [ "--disable-verify" ] @ user_options in
      match PS.run_command cmd with
      | Ok () -> ()
      | Error log ->
        errorf ~log "Failed to optimize bitcode file: %s" input_file)
    else ignore (PS.run_command [ "cp"; input_file; output_file ]) in
  let _ = if is_debug_mode () then disassemble_bitcode output_file in
  output_file
;;

(** Normalize LLVM bitcode by running the Discover's llvm-normalizer tool *)
let normalize_bitcode (input_file : string) : string =
  let _ = print ("Normalize bitcode file: " ^ input_file) in
  let basename = Filename.chop_extension (Filename.basename input_file) in
  let dirname = Filename.dirname input_file in
  let _ = Sys.make_dir dirname in
  let output_file = dirname ^ Filename.dir_sep ^ basename ^ ".norm.bc" in
  let _ =
    let _ = Sys.remove_file output_file in
    if !llvm_normalize
    then (
      let cmd = [ !normalizer_exe; input_file; "--output"; output_file ] in
      match PS.run_command cmd with
      | Ok () -> ()
      | Error log ->
        errorf ~log "Failed to normalize bitcode file: %s" input_file)
    else ignore (PS.run_command [ "cp"; input_file; output_file ]) in
  let _ = if is_debug_mode () then disassemble_bitcode output_file in
  output_file
;;

let process_bitcode (input_file : string) : LI.program =
  let _ = print_module_stats input_file in
  let _ = if is_debug_mode () then disassemble_bitcode input_file in
  let optimized_file = optimize_bitcode input_file in
  let output_file = normalize_bitcode optimized_file in
  let llcontext = LL.create_context () in
  let llmem = LL.MemoryBuffer.of_file output_file in
  let modul = Llvm_bitreader.parse_bitcode llcontext llmem in
  let _ = LL.MemoryBuffer.dispose llmem in
  let _ =
    if !print_input_prog
    then printp ~ruler:`Long "ORIGINAL BITCODE MODULE" LI.pr_module modul in
  process_module output_file modul
;;

let compile_program (input_file : string) : LI.program =
  let llcontext = LL.create_context () in
  let llmem = LL.MemoryBuffer.of_file input_file in
  let modul = Llvm_irreader.parse_ir llcontext llmem in
  process_module input_file modul
;;
