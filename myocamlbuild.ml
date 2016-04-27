(**************************************************************************)
(*  Copyright (C) 2016  Pietro Abate <pietro.abate@inria.fr>              *)
(*                                                                        *)
(*  This library is free software: you can redistribute it and/or modify  *)
(*  it under the terms of the GNU Lesser General Public License as        *)
(*  published by the Free Software Foundation, either version 3 of the    *)
(*  License, or (at your option) any later version.  A special linking    *)
(*  exception to the GNU Lesser General Public License applies to this    *)
(*  library, see the COPYING file for more information.                   *)
(**************************************************************************)

open Ocamlbuild_plugin

let clibs = [("minisat","minisat")]

let _ = dispatch begin function
   | After_rules ->
       flag ["c"; "compile"; "g++"] (S[A"-cc"; A"g++"; A"-ccopt"; A"-fPIC"]);
       flag ["cc"; "compile"; "g++"] (S[A"-cc"; A"g++"; A"-ccopt"; A"-fPIC"]);

       List.iter begin fun (lib,dir) ->
         flag ["ocaml"; "link"; "c_use_"^lib; "byte"]
         (S[A"-custom"; A"-cclib"; A"-lstdc++";
            A"-cclib"; A"-lz";
            A"-ccopt"; A("-L"^lib); 
            A"-cclib"; A("-l"^lib)]);

         flag ["ocaml"; "link"; "c_use_"^lib; "native"]
         (S[A"-cclib"; A"-lstdc++";
            A"-cclib"; A"-lz"; 
            A"-ccopt"; A("-L"^lib); 
            A"-cclib"; A("-l"^lib)]);

         flag [ "byte"; "library"; "link" ]
         (S[A"-dllib"; A("-l"^lib); 
            A"-cclib"; A("-l"^lib^"stubs")]);

         flag [ "native"; "library"; "link" ]
         (S[A"-cclib"; A("-l"^lib); 
            A"-cclib"; A("-l"^lib^"_stubs")]);

         (* Make sure the C pieces is built... *)
         if Sys.file_exists dir then begin
           dep  ["ocaml"; "compile"; "c_use_"^lib] [dir^"/lib"^lib^"_stubs.a"];
           dep  ["ocaml"; "link"; "c_use_"^lib] [dir^"/lib"^lib^"_stubs.a"];
         end
         else begin
           dep  ["ocaml"; "compile"; "c_use_"^lib] ["lib"^lib^"_stubs.a"];
           dep  ["ocaml"; "link"; "c_use_"^lib] ["lib"^lib^"_stubs.a"];
         end

       end clibs ;

       (** Rule for native dynlinkable plugins *)
       rule ".cmxa.cmxs" ~prod:"%.cmxs" ~dep:"%.cmxa"
       (fun env _ ->
         let cmxs = Px (env "%.cmxs") and cmxa = P (env "%.cmxa") in
         Cmd (S [!Options.ocamlopt ; A"-linkall" ; A"-shared" ; A"-o" ; cmxs ; cmxa])
       );

   | _ -> ()
end
