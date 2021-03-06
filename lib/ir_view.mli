(*
 * Copyright (c) 2013-2015 Thomas Gazagnaire <thomas@gazagnaire.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

(** In-memory partial views of the database, with lazy fetching. *)

module type S = sig
  include Ir_s.HIERARCHICAL
  val empty: unit -> t Lwt.t
  val rebase: t -> into:t -> unit Ir_merge.result Lwt.t
  val rebase_exn: t -> into:t -> unit Lwt.t
  type db
  val of_path: db -> key -> t Lwt.t
  val update_path: db -> key -> t -> unit Lwt.t
  val rebase_path: db -> key -> t -> unit Ir_merge.result Lwt.t
  val rebase_path_exn: db -> key -> t -> unit Lwt.t
  val merge_path: db -> ?max_depth:int -> ?n:int -> key -> t -> unit Ir_merge.result Lwt.t
  val merge_path_exn: db -> ?max_depth:int -> ?n:int -> key -> t -> unit Lwt.t
  module Action: sig
    type t =
      [ `Read of (key * value option)
      | `Write of (key * value option)
      | `Rmdir of key
      | `List of (key * key list) ]
    include Tc.S0 with type t := t
    val pretty: t -> string
    val prettys: t list -> string
  end
  val actions: t -> Action.t list
  val diff: t -> t -> (key * value Ir_watch.diff) list Lwt.t
  type commit_id
  val parents: t -> commit_id list
  val make_head: db -> Ir_task.t -> parents:commit_id list -> contents:t -> commit_id Lwt.t
  val watch_path: db -> key -> ?init:(commit_id * t) ->
    ((commit_id * t) Ir_watch.diff -> unit Lwt.t) -> (unit -> unit Lwt.t) Lwt.t
end

module Make (S: Ir_s.STORE_EXT):
  S with type db = S.t
     and type key = S.key
     and type value = S.value
     and type commit_id = S.commit_id
