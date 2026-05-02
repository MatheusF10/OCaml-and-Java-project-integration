open Str

(* --- Type Definitions --- *)

(* Defines the different types of academic activities available in the system *)
type activity_type =
  | Forum
  | Assignment
  | Quiz
  | SelfAssessment

(* Structure to store student activity data with a unique ID field to avoid record ambiguity *)
type activity =
  { act_student_id : int
  ; kind : activity_type
  ; score : float
  }

(* Structure for attendance records: total classes vs. missed classes *)
type attendance_data =
  { att_student_id : int
  ; total_classes : int
  ; absences : int
  }

(* Basic student profile information *)
type student =
  { id : int
  ; name : string
  ; email : string
  }

(* The global database structure containing lists of all parsed records *)
type database =
  { students : student list
  ; activities : activity list
  ; attendances : attendance_data list
  }

(* --- Parsing Functions --- *)

(* 
   Parses a student record from a Prolog-style string: aluno(ID, 'Name', 'Email').
*)
let parse_student line =
  (* Define a regular expression to capture ID, Name, and Email, allowing for optional spaces *)
  let re = regexp "aluno(\\([0-9]+\\),[ ]*'\\([^']+\\)',[ ]*'\\([^']+\\)')." in
  (* Check if the current line matches the student pattern starting from index 0 *)
  if string_match re line 0
  then
    (* Return a Some student record with converted types *)
    Some
      { id = int_of_string (matched_group 1 line) (* Group 1: Student ID *)
      ; name = matched_group 2 line (* Group 2: Full Name *)
      ; email = matched_group 3 line (* Group 3: Email address *)
      }
  else None (* Return None if the line does not match the student format *)
;;

(* 
   Parses an activity record: atividade_aluno(ID, type, score, ...).
*)
let parse_activity line =
  (* Regex to capture Student ID, activity kind, and the numerical score *)
  let re = regexp "atividade_aluno(\\([0-9]+\\),[ ]*\\([a-z]+\\),[ ]*\\([0-9.]+\\),.*" in
  if string_match re line 0
  then (
    let kind_str = matched_group 2 line in
    (* Map the string descriptor from the file to the activity_type variant *)
    let kind =
      match kind_str with
      | "forum" -> Forum
      | "tarefa" -> Assignment
      | "quiz" -> Quiz
      | _ -> Forum (* Default to Forum if the type is unrecognized *)
    in
    (* Build and return the activity record *)
    Some
      { act_student_id = int_of_string (matched_group 1 line)
      ; kind
      ; score = float_of_string (matched_group 3 line)
      })
  else None
;;

(* 
   Parses attendance records: assiduidade(ID, total_classes, absences).
*)
let parse_attendance line =
  (* Regex to capture the three integer values required for attendance *)
  let re = regexp "assiduidade(\\([0-9]+\\),[ ]*\\([0-9]+\\),[ ]*\\([0-9]+\\))." in
  if string_match re line 0
  then
    (* Construct the attendance record with unique field name to prevent conflicts *)
    Some
      { att_student_id = int_of_string (matched_group 1 line)
      ; total_classes = int_of_string (matched_group 2 line)
      ; absences = int_of_string (matched_group 3 line)
      }
  else None
;;

(* 
   Parses self-evaluation records: autoavaliacao(ID, score).
*)
let parse_self_eval line =
  (* Regex to capture the ID and the floating-point self-assigned grade *)
  let re = regexp "autoavaliacao(\\([0-9]+\\),[ ]*\\([0-9.]+\\))." in
  if string_match re line 0
  then
    (* Store self-evaluation as an 'activity' type for easier processing later *)
    Some
      { act_student_id = int_of_string (matched_group 1 line)
      ; kind = SelfAssessment
      ; score = float_of_string (matched_group 2 line)
      }
  else None
;;

(* 
   Loads the database from a file by reading all lines and then 
   processing each line into the corresponding data structures.
*)
let load_database filename =
  let lines =
    try
      (* Attempt to open the file channel *)
      let chan = open_in filename in
      (* Helper function to read all lines into a list using tail-recursion *)
      let rec read_all acc =
        try
          let line = input_line chan in
          read_all (line :: acc)
        with
        | End_of_file ->
          (* Ensure the channel is closed after reaching the end of the file *)
          close_in chan;
          (* Reverse the list to maintain the original file order *)
          List.rev acc
      in
      read_all []
    with
    | _ ->
      (* Error handling for missing files or permission issues *)
      Printf.printf "Error: Could not read file %s\n" filename;
      []
  in
  (* Iterates through the lines and populates the database records using functional folding *)
  List.fold_left
    (fun acc line ->
       (* Try matching the line against student pattern *)
       match parse_student line with
       | Some s -> { acc with students = s :: acc.students }
       | None ->
         (* Try matching against activity pattern *)
         (match parse_activity line with
          | Some a -> { acc with activities = a :: acc.activities }
          | None ->
            (* Try matching against attendance pattern *)
            (match parse_attendance line with
             | Some att -> { acc with attendances = att :: acc.attendances }
             | None ->
               (* Try matching against self-evaluation pattern *)
               (match parse_self_eval line with
                | Some se -> { acc with activities = se :: acc.activities }
                | None -> acc))))
    { students = []; activities = []; attendances = [] }
    lines
;;

(* 
   Calculates and displays performance indicators for a specific student ID.
   Includes forum participation count, grade averages, and attendance.
*)
let show_indicators id db =
  try
    (* Find the student by ID; raises Not_found if the student doesn't exist *)
    let s = List.find (fun s -> s.id = id) db.students in
    (* Filter all activities tied to this specific student *)
    let student_acts = List.filter (fun a -> a.act_student_id = id) db.activities in
    (* Categorize activities by their specific kind *)
    let forums = List.filter (fun a -> a.kind = Forum) student_acts in
    let tasks = List.filter (fun a -> a.kind = Assignment) student_acts in
    let quizzes = List.filter (fun a -> a.kind = Quiz) student_acts in
    let self_eval = List.find_opt (fun a -> a.kind = SelfAssessment) student_acts in
    (* Utility function to calculate the arithmetic mean of a list of activities *)
    let calc_media list =
      if list = []
      then 0.0
      else
        List.fold_left (fun acc a -> acc +. a.score) 0.0 list
        /. float_of_int (List.length list)
    in
    (* Calculate specific averages for Assignments, Quizzes, and both combined *)
    let media_tarefas = calc_media tasks in
    let media_quizzes = calc_media quizzes in
    let media_conjunta = calc_media (tasks @ quizzes) in
    (* Format attendance as a string percentage or "N/A" if record is missing *)
    let assid_str =
      try
        let att = List.find (fun a -> a.att_student_id = id) db.attendances in
        string_of_int ((att.total_classes - att.absences) * 100 / att.total_classes) ^ "%"
      with
      | _ -> "N/A"
    in
    (* Handle self-evaluation grade if present *)
    let auto_str =
      match self_eval with
      | Some e -> string_of_float e.score
      | None -> "N/A"
    in
    (* Print indicators following the project's specified format *)
    Printf.printf
      "%d; %d; %.2f; %.2f; %.2f; %s; %s\n%!"
      s.id
      (List.length forums)
      media_tarefas
      media_quizzes
      media_conjunta
      assid_str
      auto_str
  with
  | Not_found -> Printf.printf "Student with ID %d not found.\n%!" id
;;

(* 
   Evaluates a specific student's performance by applying decision rules R1 through R4.
   Determines the student's academic status (e.g., Aprovado, Condicionado) and 
   handles self-evaluation coherence bonuses.
*)
let evaluate_student id db =
  try
    (* Find the student record to ensure the ID exists and to retrieve the name *)
    let s = List.find (fun s -> s.id = id) db.students in
    (* Filter all activities related to this specific student *)
    let student_acts = List.filter (fun a -> a.act_student_id = id) db.activities in
    (* --- Rule Calculations --- *)
    (* R1: Participation is adequate if there are at least 3 forum entries *)
    let forum_count = List.length (List.filter (fun a -> a.kind = Forum) student_acts) in
    let r1 = forum_count >= 3 in
    (* R2: Academic performance is adequate if the average of tasks and quizzes is >= 10 *)
    let eval_acts =
      List.filter (fun a -> a.kind = Assignment || a.kind = Quiz) student_acts
    in
    let avg_grade =
      if eval_acts = []
      then 0.0
      else
        List.fold_left (fun acc a -> acc +. a.score) 0.0 eval_acts
        /. float_of_int (List.length eval_acts)
    in
    let r2 = avg_grade >= 10.0 in
    (* R3: Attendance is adequate if the student attended at least 75% of classes *)
    let attendance_perc =
      try
        let att = List.find (fun a -> a.att_student_id = id) db.attendances in
        float_of_int (att.total_classes - att.absences)
        /. float_of_int att.total_classes
        *. 100.0
      with
      | _ -> 0.0
    in
    let r3 = attendance_perc >= 75.0 in
    (* R4: Self-evaluation is coherent if it's within 2 points of the objective average *)
    let self_eval_grade =
      try (List.find (fun a -> a.kind = SelfAssessment) student_acts).score with
      | _ -> -100.0 (* Sentinel value used when self-assessment is missing *)
    in
    let r4 = abs_float (self_eval_grade -. avg_grade) <= 2.0 in
    (* --- Decision Tree Logic --- *)
    (* Determine the initial status based on the combination of R1, R2, and R3 *)
    let base_state =
      if r1 && r2 && r3
      then "Aprovado"
      else if r1 && r2 && not r3
      then "Condicionado"
      else if r2
      then "Em Observação"
      else if r1 || r2
      then "Em Risco"
      else "Retido"
    in
    (* Apply R4 Bonus: Improve the status by one level if self-evaluation is coherent *)
    let final_state =
      if r4 && base_state <> "Retido"
      then (
        match base_state with
        | "Condicionado" -> "Aprovado"
        | "Em Observação" -> "Condicionado"
        | "Em Risco" -> "Em Observação"
        | _ -> base_state)
      else base_state
    in
    (* 
       Final output including the student ID and name (fixing the unused variable 's').
       The format follows: ID (Name); Rules Status; Final Evaluation.
    *)
    Printf.printf
      "%d (%s); R1: %b; R2: %b; R3: %b; R4: %b; Estado: %s\n%!"
      id
      s.name
      r1
      r2
      r3
      r4
      final_state
  with
  (* Error handling for cases where the ID provided does not match any student *)
  | Not_found ->
    Printf.printf "Error: Student with ID %d not found in the database.\n%!" id
;;

(* Helper to define state priority for sorting: Aprovado (1) to Retido (5) *)
let state_priority = function
  | "Aprovado" -> 1
  | "Condicionado" -> 2
  | "Em Observacao" -> 3
  | "Em Risco" -> 4
  | "Retido" -> 5
  | _ -> 6
;;

let get_student_final_status id db =
  try
    let student_acts = List.filter (fun a -> a.act_student_id = id) db.activities in
    (* R1: Forums *)
    let r1 = List.length (List.filter (fun a -> a.kind = Forum) student_acts) >= 3 in
    (* R2: Grades *)
    let eval_acts =
      List.filter (fun a -> a.kind = Assignment || a.kind = Quiz) student_acts
    in
    let avg =
      if eval_acts = []
      then 0.0
      else
        List.fold_left (fun acc a -> acc +. a.score) 0.0 eval_acts
        /. float_of_int (List.length eval_acts)
    in
    let r2 = avg >= 10.0 in
    (* R3: Attendance *)
    let att_perc =
      try
        let att = List.find (fun a -> a.att_student_id = id) db.attendances in
        float_of_int (att.total_classes - att.absences)
        /. float_of_int att.total_classes
        *. 100.0
      with
      | _ -> 0.0
    in
    let r3 = att_perc >= 75.0 in
    (* R4: Coherence *)
    let self_eval =
      try (List.find (fun a -> a.kind = SelfAssessment) student_acts).score with
      | _ -> -100.0
    in
    let r4 = abs_float (self_eval -. avg) <= 2.0 in
    let base =
      if r1 && r2 && r3
      then "Aprovado"
      else if r1 && r2 && not r3
      then "Condicionado"
      else if r2
      then "Em Observacao"
      else if r1 || r2
      then "Em Risco"
      else "Retido"
    in
    let final =
      if r4 && base <> "Retido"
      then (
        match base with
        | "Condicionado" -> "Aprovado"
        | "Em Observacao" -> "Condicionado"
        | "Em Risco" -> "Em Observacao"
        | _ -> base)
      else base
    in
    final, avg, att_perc
  with
  | _ -> "Retido", 0.0, 0.0
;;

let list_by_status db =
  (* Process all students to calculate their final data *)
  let evaluated_list =
    List.map
      (fun s ->
         let status, avg, att = get_student_final_status s.id db in
         s, status, avg, att)
      db.students
  in
  (* Sort by State (Priority) and then by Name *)
  let sorted_list =
    List.sort
      (fun (s1, st1, _, _) (s2, st2, _, _) ->
         let p1 = state_priority st1 in
         let p2 = state_priority st2 in
         if p1 <> p2 then compare p1 p2 else compare s1.name s2.name)
      evaluated_list
  in
  (* Data output in simple semicolon-separated format *)
  List.iter
    (fun (s, status, avg, att) ->
       Printf.printf "%d; %s; %.2f; %.0f%%\n" s.id status avg att)
    sorted_list;
  flush stdout
;;

(* 
   Lists all students sorted alphabetically by name.
   Calculates total activity count and attendance percentage for each student.
*)
let list_students db =
  (* Sort students alphabetically to meet evaluation requirements *)
  let sorted = List.sort (fun a b -> compare a.name b.name) db.students in
  List.iter
    (fun s ->
       (* Filter activities belonging to the current student *)
       let student_activities =
         List.filter (fun a -> a.act_student_id = s.id) db.activities
       in
       let activities_count = List.length student_activities in
       (* Calculate attendance percentage based on total classes and absences *)
       let att_perc =
         try
           let att = List.find (fun a -> a.att_student_id = s.id) db.attendances in
           if att.total_classes = 0
           then 0.0
           else
             float_of_int (att.total_classes - att.absences)
             /. float_of_int att.total_classes
             *. 100.0
         with
         | Not_found -> 0.0
       in
       (* Output formatted string: ID; Name; Email; Activity Count; Attendance % *)
       Printf.printf
         "%d; %s; %s; %d; %.0f%%\n%!"
         s.id
         s.name
         s.email
         activities_count
         att_perc)
    sorted
;;

(* 
   Main entry point of the program.
   Handles command-line arguments to trigger database operations.
*)
let () =
  (* Define the source file containing the Prolog-style database *)
  let filename = "database_26.pl" in
  (* Load and parse the entire database into memory at startup *)
  let db = load_database filename in
  (* Convert command-line arguments to a list for pattern matching *)
  match Array.to_list Sys.argv with
  | _ :: "listar_alunos" :: _ -> list_students db
  | _ :: "indicadores" :: id_str :: _ ->
    (try
       let id = int_of_string id_str in
       show_indicators id db
     with
     | Failure _ ->
       Printf.printf "Error: Student ID '%s' must be a valid integer.\n%!" id_str
     | _ -> Printf.printf "An unexpected error occurred.\n%!")
  | _ :: "avaliar" :: id_str :: _ ->
    (try
       let id = int_of_string id_str in
       evaluate_student id db
     with
     | Failure _ ->
       Printf.printf "Error: Student ID '%s' must be a valid integer.\n%!" id_str
     | _ -> Printf.printf "An unexpected error occurred during evaluation.\n%!")
  | _ :: "listar_estados" :: _ -> list_by_status db
  | _ :: comando :: _ -> Printf.printf "Error: Unknown command '%s'.\n" comando
  (* Default case: Display usage instructions if arguments are missing or invalid *)
  | _ ->
    Printf.printf "Comandos Disponíveis:\n";
    Printf.printf "listar_alunos\n";
    Printf.printf "indicadores\n";
    Printf.printf "avaliar\n";
    Printf.printf "listar_estados\n"
;;
