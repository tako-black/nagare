(**
 * Copyright (c) 2015, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the "hack" directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 *
 *)

open Core
open Nast
open Utils

module SN = Naming_special_names

let mem x xs =
  List.exists xs (fun { ua_name; _ } -> x = snd ua_name)

let find x xs =
  List.find xs (fun { ua_name; _ } -> x = snd ua_name)

let deprecated ~kind (_, name) attrs =
  let attr = find SN.UserAttributes.uaDeprecated attrs in
  match attr with
  | Some { ua_name; ua_params = [msg] } -> begin
      match Nast_eval.static_string_no_consts msg with
      | Result.Ok (_p, msg) ->
          let name = strip_ns name in
          let deprecated_prefix =
            Printf.sprintf "The %s %s is deprecated: " kind name in
          Some (deprecated_prefix ^ msg)
      | Result.Error Nast_eval.Type_error -> None
      | Result.Error (Nast_eval.Not_static p) ->
          Errors.attribute_param_type p "static string literal";
          None
      end
  | Some { ua_name = (pos, _); _ }  ->
      Errors.attribute_arity pos SN.UserAttributes.uaDeprecated 1;
      None
  | None -> None