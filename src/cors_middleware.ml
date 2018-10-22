open Opium.Std

let add_cors_headers (headers: Cohttp.Header.t): Cohttp.Header.t =
  Cohttp.Header.add_list headers [
    ("access-control-allow-origin", "*");
    ("access-control-allow-headers", "Accept, Content-Type");
    ("access-control-allow-methods", "GET, HEAD, POST, DELETE, OPTIONS, PUT, PATCH")
  ]

let allow_cors =
  let open Lwt in
  let filter handler req =
    handler req >|= fun response -> 
    response 
    |> Response.headers
    |> add_cors_headers
    |> fun h -> { response with Response.headers = h; }
  in 
    Rock.Middleware.create ~name:"allow cors" ~filter


let accept_options = App.options "**" begin fun _ ->
  respond' (`String "OK")
end

let apply_cors_middleware app = 
  app
  |> middleware allow_cors
  |> accept_options