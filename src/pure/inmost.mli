(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* Note: this is not a stable API! *)



type client
type server
type 'a message
type request = client message
type response = server message

type 'a promise = 'a Lwt.t
type handler = request -> response promise
type middleware = handler -> handler

type method_ = Method.method_
type status = Status.status

type stream = Stream.stream
type buffer = Stream.buffer



val request :
  ?method_:[< method_ ] ->
  ?target:string ->
  ?version:int * int ->
  ?headers:(string * string) list ->
  stream ->
  stream ->
    request

val method_ : request -> method_
val target : request -> string
val version : request -> int * int
val set_method_ : request -> [< method_ ] -> unit
val set_version : request -> int * int -> unit



val response :
  ?status:[< status ] ->
  ?code:int ->
  ?headers:(string * string) list ->
  stream ->
  stream ->
    response

val status : response -> status



val header : 'a message -> string -> string option
val headers : 'a message -> string -> string list
val all_headers : 'a message -> (string * string) list
val has_header : 'a message -> string -> bool
val add_header : 'a message -> string -> string -> unit
val drop_header : 'a message -> string -> unit
val set_header : 'a message -> string -> string -> unit
val set_all_headers : 'a message -> (string * string) list -> unit
val sort_headers : (string * string) list -> (string * string) list



val body : 'a message -> string promise
val set_body : response -> string -> unit
val read : request -> string option promise
val set_stream : 'a message -> unit
(* TODO Rename set_stream, it makes kind of no sense now. *)
val write : response -> string -> unit promise
val flush : response -> unit promise
val close_stream : response -> unit promise
(* TODO This will need to read different streams depending on whether it is
   passed a request or a response. *)
val client_stream : 'a message -> stream
val server_stream : 'a message -> stream
val set_client_stream : 'a message -> stream -> unit
val next :
  stream ->
  data:(buffer -> int -> int -> bool -> bool -> unit) ->
  close:(int -> unit) ->
  flush:(unit -> unit) ->
  ping:(buffer -> int -> int -> unit) ->
  pong:(buffer -> int -> int -> unit) ->
    unit
val write_buffer :
  ?offset:int -> ?length:int -> response -> buffer -> unit promise



val no_middleware : middleware
val pipeline : middleware list -> middleware



type websocket = stream
val websocket :
  ?headers:(string * string) list ->
  (websocket -> unit promise) ->
    response promise
val send : ?kind:[< `Text | `Binary ] -> websocket -> string -> unit promise
val receive : websocket -> string option promise
val close_websocket : ?code:int -> websocket -> unit promise
val is_websocket : response -> (websocket -> unit promise) option



type 'a local
val new_local : ?name:string -> ?show_value:('a -> string) -> unit -> 'a local
val local : 'b message -> 'a local -> 'a option
val set_local : 'b message -> 'a local -> 'a -> unit
val fold_locals : (string -> string -> 'a -> 'a) -> 'a -> 'b message -> 'a