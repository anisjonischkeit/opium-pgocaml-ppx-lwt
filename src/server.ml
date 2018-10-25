open Opium.Std
open Cors_middleware

module PGOCaml = PGOCaml_generic.Make(Pgocaml_thread)

(* ENDPOINTS *)

let print_param execute_query = get "/insertUser" begin fun req ->
  let (>>=) = Lwt.bind in

  let insert =
      [%sqlf {|
      INSERT INTO employees (name, salary, email) 
      VALUES ($name, $salary, $?email)
      RETURNING name, salary
      |}] in 
  
  let insert_query = (insert ~name:(param req "name") ~salary:10_000_l ?email:None) in
  
    execute_query (insert_query)
    >>= function
      | Ok _ ->  Lwt.return (`String ("Hello " ^ param req "name") |> respond)
      | Error _ ->  Lwt.return (`String ("Something went wrong") |> respond)
  ;

end

let () =
  let read_only_dbh = PGOCaml.connect
    ~host:"127.0.0.1" 
    ~port:5432 
    ~user:"postgres"
    ~password:"mysecretpassword"
    ~database: "testdb" () in
  let (>>=) = Lwt.bind in

  let execute_query dbh query = 
    dbh 
    >>= (fun db -> 
      Lwt.catch 
        (fun () -> Lwt.map (fun x -> Result.Ok x) (query db)) 
        (fun e -> Lwt.return (Result.Error e))
    )
  in

  App.empty
  |> apply_cors_middleware
  |> print_param @@ execute_query read_only_dbh
  |> App.run_command
