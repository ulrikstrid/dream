(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let show input =
  Eml.Location.reset ();

  let underlying = Stream.of_string input in
  let input_stream = Eml.Location.stream (fun () ->
    try Some (Stream.next underlying)
    with _ -> None) in

  try
    input_stream
    |> Eml.Tokenizer.scan
    |> List.map Eml.Token.show
    |> List.iter print_endline
  with Failure message ->
    print_endline message

let%expect_test _ =
  show "";
  [%expect {| (1, 0) Code_block |}]

let%expect_test _ =
  show " ";
  [%expect {| (1, 0) Code_block |}]

let%expect_test _ =
  show " \n ";
  [%expect {| (1, 0) Code_block |}]

let%expect_test _ =
  show "\n\n";
  [%expect {| (1, 0) Code_block |}]

let%expect_test _ =
  show "let foo =\n  bar\n";
  [%expect {|
    (1, 0) Code_block
    let foo =
      bar |}]

let%expect_test _ =
  show "let foo =\n< bar";
  [%expect {|
    (1, 0) Code_block
    let foo =
    < bar |}]

let%expect_test _ =
  show "let foo =\n < bar";
  [%expect {|
    (1, 0) Code_block
    let foo =
     < bar |}]

let%expect_test _ =
  show "let foo =\n  < bar";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Text {|  < bar|} |xxx}]

let%expect_test _ =
  show "let foo =\n   < bar";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Text {|   < bar|} |xxx}]

let%expect_test _ =
  show "let foo =\n  <html>\n  </html>";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Text {|  <html>|}
    Newline
    Text {|  </html>|} |xxx}]

let%expect_test _ =
  show "let foo =\n  <html>\n  plain";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Text {|  <html>|}
    Newline
    Text {|  plain|} |xxx}]

let%expect_test _ =
  show "let foo =\n  <html>\n  </html>\nlet bar = ()\n";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Text {|  <html>|}
    Newline
    Text {|  </html>|}
    Newline
    (4, 0) Code_block
    let bar = () |xxx}]

let%expect_test _ =
  show "let foo =\n  <% a %>\n";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Text {|  |}
    (2, 5) Embedded () a
    Text {||}
    Newline |xxx}]

let%expect_test _ =
  show "let foo =\n  <% a % %>\n";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Text {|  |}
    (2, 5) Embedded () a %
    Text {||}
    Newline |xxx}]

let%expect_test _ =
  show "let foo =\n  <% a %%>\n";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Text {|  |}
    (2, 5) Embedded () a %
    Text {||}
    Newline |xxx}]

let%expect_test _ =
  show "let foo =\n  <%= a %>\n";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Text {|  |}
    (2, 6) Embedded (=) a
    Text {||}
    Newline |xxx}]

let%expect_test _ =
  show "let foo =\n  <% a\nb %>\n";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Text {|  |}
    (2, 5) Embedded () a
    b
    Text {||}
    Newline |xxx}]

let%expect_test _ =
  show "let foo =\n  <%";
  [%expect {| Line 2: end of input in embedded code |}]

let%expect_test _ =
  show "let foo =\n  <%\na %>";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Text {|  |}
    (3, 2) Embedded (
    a)
    Text {||} |xxx}]

let%expect_test _ =
  show "let foo =\n  <% \n a";
  [%expect {| Line 3: end of input in embedded code |}]

let%expect_test _ =
  show "let foo =\n  <html>\n\na";
  [%expect {xxx|
    (1, 0) Code_block

     alet foo =

    Text {|  <html>|}
    Newline
    Text {||}
    Newline
    (4, 0) Code_block
    a |xxx}]
