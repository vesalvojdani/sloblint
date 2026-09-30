(** Tools for dealing with library functions. *)

open Batteries
open GoblintCil
open GobConfig

module M = Messages

let intmax_t = lazy (
  let res = ref None in
  GoblintCil.iterGlobals !Cilfacade.current_file (function
      | GType ({tname = "intmax_t"; ttype; _}, _) ->
        res := Some ttype;
      | _ -> ()
    );
  !res
)

let stripOuterBoolCast = function
  | CastE (_, TInt (IBool, _), e) -> e (* TODO: keep explicit cast? *)
  | Const (CInt (b, IBool, s)) -> Const (CInt (b, IInt, s))
  | e -> e

(** C standard library functions.
    These are specified by the C standard.

    Every entry has {!LibraryDesc.KeepsSpecified}. By the C standard, none of
    these functions keeps a pointer derived from an argument after it returns,
    other than those marked [k]: the buffer [setvbuf] and [setbuf] give a
    stream, which uses it until the stream is closed; [strtok]'s [str], which
    the calls that follow with a null [str] continue in; and the functions
    [atexit] and [signal] register. A pointer into an argument that the
    function returns, as [strchr] does, or writes through another argument,
    as [strtol] does through [endptr] and [memcpy] into [dest], is not kept
    by the function and so not part of {!LibraryDesc.kept}: a consumer must
    follow it through the call's result and its [Write] accesses. *)
let c_descs_list: (string * LibraryDesc.t) list = LibraryDsl.[
    ("memset", special ~attrs:[KeepsSpecified] [__ "dest" [w]; __ "ch" []; __ "count" []] @@ fun dest ch count -> Memset { dest; ch; count; });
    ("__builtin_memset", special ~attrs:[KeepsSpecified] [__ "dest" [w]; __ "ch" []; __ "count" []] @@ fun dest ch count -> Memset { dest; ch; count; });
    ("__builtin___memset_chk", special ~attrs:[KeepsSpecified] [__ "dest" [w]; __ "ch" []; __ "count" []; drop "os" []] @@ fun dest ch count -> Memset { dest; ch; count; });
    ("memcpy", special ~attrs:[KeepsSpecified] [__ "dest" [w]; __ "src" [r]; __ "n" []] @@ fun dest src n -> Memcpy { dest; src; n; });
    ("__builtin_memcpy", special ~attrs:[KeepsSpecified] [__ "dest" [w]; __ "src" [r]; __ "n" []] @@ fun dest src n -> Memcpy { dest; src; n; });
    ("__builtin___memcpy_chk", special ~attrs:[KeepsSpecified] [__ "dest" [w]; __ "src" [r]; __ "n" []; drop "os" []] @@ fun dest src n -> Memcpy { dest; src; n; });
    ("memccpy", special ~attrs:[KeepsSpecified] [__ "dest" [w]; __ "src" [r]; drop "c" []; __ "n" []] @@ fun dest src n -> Memcpy {dest; src; n; }); (* C23 *) (* TODO: use c *)
    ("memmove", special ~attrs:[KeepsSpecified] [__ "dest" [w]; __ "src" [r]; __ "count" []] @@ fun dest src count -> Memcpy { dest; src; n = count; });
    ("__builtin_memmove", special ~attrs:[KeepsSpecified] [__ "dest" [w]; __ "src" [r]; __ "count" []] @@ fun dest src count -> Memcpy { dest; src; n = count; });
    ("__builtin___memmove_chk", special ~attrs:[KeepsSpecified] [__ "dest" [w]; __ "src" [r]; __ "count" []; drop "os" []] @@ fun dest src count -> Memcpy { dest; src; n = count; });
    ("strcpy", special ~attrs:[KeepsSpecified] [__ "dest" [w]; __ "src" [r]] @@ fun dest src -> Strcpy { dest; src; n = None; });
    ("__builtin_strcpy", special ~attrs:[KeepsSpecified] [__ "dest" [w]; __ "src" [r]] @@ fun dest src -> Strcpy { dest; src; n = None; });
    ("__builtin___strcpy_chk", special ~attrs:[KeepsSpecified] [__ "dest" [w]; __ "src" [r]; drop "os" []] @@ fun dest src -> Strcpy { dest; src; n = None; });
    ("strncpy", special ~attrs:[KeepsSpecified] [__ "dest" [w]; __ "src" [r]; __ "n" []] @@ fun dest src n -> Strcpy { dest; src; n = Some n; });
    ("__builtin_strncpy", special ~attrs:[KeepsSpecified] [__ "dest" [w]; __ "src" [r]; __ "n" []] @@ fun dest src n -> Strcpy { dest; src; n = Some n; });
    ("__builtin___strncpy_chk", special ~attrs:[KeepsSpecified] [__ "dest" [w]; __ "src" [r]; __ "n" []; drop "os" []] @@ fun dest src n -> Strcpy { dest; src; n = Some n; });
    ("strcat", special ~attrs:[KeepsSpecified] [__ "dest" [r; w]; __ "src" [r]] @@ fun dest src -> Strcat { dest; src; n = None; });
    ("__builtin_strcat", special ~attrs:[KeepsSpecified] [__ "dest" [r; w]; __ "src" [r]] @@ fun dest src -> Strcat { dest; src; n = None; });
    ("__builtin___strcat_chk", special ~attrs:[KeepsSpecified] [__ "dest" [r; w]; __ "src" [r]; drop "os" []] @@ fun dest src -> Strcat { dest; src; n = None; });
    ("strncat", special ~attrs:[KeepsSpecified] [__ "dest" [r; w]; __ "src" [r]; __ "n" []] @@ fun dest src n -> Strcat { dest; src; n = Some n; });
    ("__builtin_strncat", special ~attrs:[KeepsSpecified] [__ "dest" [r; w]; __ "src" [r]; __ "n" []] @@ fun dest src n -> Strcat { dest; src; n = Some n; });
    ("__builtin___strncat_chk", special ~attrs:[KeepsSpecified] [__ "dest" [r; w]; __ "src" [r]; __ "n" []; drop "os" []] @@ fun dest src n -> Strcat { dest; src; n = Some n; });
    ("memcmp", unknown ~attrs:[KeepsSpecified] [drop "s1" [r]; drop "s2" [r]; drop "n" []]);
    ("__builtin_memcmp", unknown ~attrs:[KeepsSpecified] [drop "s1" [r]; drop "s2" [r]; drop "n" []]);
    ("memchr", unknown ~attrs:[KeepsSpecified] [drop "s" [r]; drop "c" []; drop "n" []]);
    ("asctime", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "time_ptr" [r_deep]]);
    ("fclose", unknown ~attrs:[KeepsSpecified] [drop "stream" [r_deep; w_deep; f_deep]]);
    ("feof", unknown ~attrs:[KeepsSpecified] [drop "stream" [r_deep; w_deep]]);
    ("ferror", unknown ~attrs:[KeepsSpecified] [drop "stream" [r_deep; w_deep]]);
    ("fflush", unknown ~attrs:[KeepsSpecified] [drop "stream" [r_deep; w_deep]]);
    ("fgetc", unknown ~attrs:[KeepsSpecified] [drop "stream" [r_deep; w_deep]]);
    ("getc", unknown ~attrs:[KeepsSpecified] [drop "stream" [r_deep; w_deep]]);
    ("fgets", unknown ~attrs:[KeepsSpecified] [drop "str" [w]; drop "count" []; drop "stream" [r_deep; w_deep]]);
    ("fopen", unknown ~attrs:[KeepsSpecified] [drop "pathname" [r]; drop "mode" [r]]);
    ("freopen", unknown ~attrs:[KeepsSpecified] [drop "pathname" [r]; drop "mode" [r]; drop "stream" [r_deep; w_deep]]);
    ("printf", unknown ~attrs:[KeepsSpecified] (drop "format" [r] :: VarArgs (drop' [r])));
    ("fprintf", unknown ~attrs:[KeepsSpecified] (drop "stream" [r_deep; w_deep] :: drop "format" [r] :: VarArgs (drop' [r])));
    ("sprintf", unknown ~attrs:[KeepsSpecified] (drop "buffer" [w] :: drop "format" [r] :: VarArgs (drop' [r])));
    ("snprintf", unknown ~attrs:[KeepsSpecified] (drop "buffer" [w] :: drop "bufsz" [] :: drop "format" [r] :: VarArgs (drop' [r])));
    ("fputc", unknown ~attrs:[KeepsSpecified] [drop "ch" []; drop "stream" [r_deep; w_deep]]);
    ("putc", unknown ~attrs:[KeepsSpecified] [drop "ch" []; drop "stream" [r_deep; w_deep]]);
    ("fputs", unknown ~attrs:[KeepsSpecified] [drop "str" [r]; drop "stream" [r_deep; w_deep]]);
    ("fread", unknown ~attrs:[KeepsSpecified] [drop "buffer" [w]; drop "size" []; drop "count" []; drop "stream" [r_deep; w_deep]]);
    ("fseek", unknown ~attrs:[KeepsSpecified] [drop "stream" [r_deep; w_deep]; drop "offset" []; drop "origin" []]);
    ("ftell", unknown ~attrs:[KeepsSpecified] [drop "stream" [r_deep]]);
    ("fwrite", unknown ~attrs:[KeepsSpecified] [drop "buffer" [r]; drop "size" []; drop "count" []; drop "stream" [r_deep; w_deep]]);
    ("rewind", unknown ~attrs:[KeepsSpecified] [drop "stream" [r_deep; w_deep]]);
    ("setvbuf", unknown ~attrs:[KeepsSpecified] [drop "stream" [r_deep; w_deep]; drop "buffer" [r; w; k]; drop "mode" []; drop "size" []]);
    (* TODO: if this is used to set an input buffer, the buffer (second argument) would need to remain TOP, *)
    (* as any future write (or flush) of the stream could result in a write to the buffer *)
    ("gmtime", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "timer" [r_deep]]);
    ("localeconv", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] []);
    ("localtime", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "time" [r]]);
    ("strlen", special ~attrs:[KeepsSpecified] [__ "s" [r]] @@ fun s -> Strlen s);
    ("_strlen", special ~attrs:[KeepsSpecified] [__ "s" [r]] @@ fun s -> Strlen s);
    ("__builtin_strlen", special ~attrs:[KeepsSpecified] [__ "s" [r]] @@ fun s -> Strlen s);
    ("strstr", special ~attrs:[KeepsSpecified] [__ "haystack" [r]; __ "needle" [r]] @@ fun haystack needle -> Strstr { haystack; needle; });
    ("strcmp", special ~attrs:[KeepsSpecified] [__ "s1" [r]; __ "s2" [r]] @@ fun s1 s2 -> Strcmp { s1; s2; n = None; });
    ("strtok", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "str" [r; w; k]; drop "delim" [r]]);
    ("__builtin_strcmp", special ~attrs:[KeepsSpecified] [__ "s1" [r]; __ "s2" [r]] @@ fun s1 s2 -> Strcmp { s1; s2; n = None; });
    ("strncmp", special ~attrs:[KeepsSpecified] [__ "s1" [r]; __ "s2" [r]; __ "n" []] @@ fun s1 s2 n -> Strcmp { s1; s2; n = Some n; });
    ("strchr", unknown ~attrs:[KeepsSpecified] [drop "s" [r]; drop "c" []]);
    ("__builtin_strchr", unknown ~attrs:[KeepsSpecified] [drop "s" [r]; drop "c" []]);
    ("strrchr", unknown ~attrs:[KeepsSpecified] [drop "s" [r]; drop "c" []]);
    ("malloc", special ~attrs:[KeepsSpecified] [__ "size" []] @@ fun size -> Malloc size);
    ("calloc", special ~attrs:[KeepsSpecified] [__ "n" []; __ "size" []] @@ fun n size -> Calloc {count = n; size});
    ("realloc", special ~attrs:[KeepsSpecified] [__ "ptr" [r; f]; __ "size" []] @@ fun ptr size -> Realloc { ptr; size });
    ("free", special ~attrs:[KeepsSpecified] [__ "ptr" [f]] @@ fun ptr -> Free ptr);
    ("abort", special ~attrs:[KeepsSpecified] [] Abort);
    ("exit", special ~attrs:[KeepsSpecified] [drop "exit_code" []] Abort);
    ("quick_exit", special ~attrs:[KeepsSpecified] [drop "exit_code" []] Abort);
    ("ungetc", unknown ~attrs:[KeepsSpecified] [drop "c" []; drop "stream" [r; w]]);
    ("scanf", unknown ~attrs:[KeepsSpecified] ((drop "format" [r]) :: (VarArgs (drop' [w]))));
    ("fscanf", unknown ~attrs:[KeepsSpecified] ((drop "stream" [r_deep; w_deep]) :: (drop "format" [r]) :: (VarArgs (drop' [w]))));
    ("sscanf", unknown ~attrs:[KeepsSpecified] ((drop "buffer" [r]) :: (drop "format" [r]) :: (VarArgs (drop' [w]))));
    ("__freading", unknown ~attrs:[KeepsSpecified] [drop "stream" [r]]);
    ("mbsinit", unknown ~attrs:[KeepsSpecified] [drop "ps" [r]]);
    ("mbrtowc", unknown ~attrs:[KeepsSpecified] [drop "pwc" [w]; drop "s" [r]; drop "n" []; drop "ps" [r; w]]);
    ("iswspace", unknown ~attrs:[KeepsSpecified] [drop "wc" []]);
    ("iswalnum", unknown ~attrs:[KeepsSpecified] [drop "wc" []]);
    ("iswprint", unknown ~attrs:[KeepsSpecified] [drop "wc" []]);
    ("iswxdigit", unknown ~attrs:[KeepsSpecified] [drop "ch" []]);
    ("rename" , unknown ~attrs:[KeepsSpecified] [drop "oldpath" [r]; drop "newpath" [r];]);
    ("perror", unknown ~attrs:[KeepsSpecified] [drop "s" [r]]);
    ("getchar", unknown ~attrs:[KeepsSpecified] []);
    ("putchar", unknown ~attrs:[KeepsSpecified] [drop "ch" []]);
    ("puts", unknown ~attrs:[KeepsSpecified] [drop "s" [r]]);
    ("srand", unknown ~attrs:[KeepsSpecified] [drop "seed" []]);
    ("rand", special ~attrs:[KeepsSpecified; ThreadUnsafe] [] Rand);
    ("strerror", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "errnum" []]);
    ("strspn", unknown ~attrs:[KeepsSpecified] [drop "s" [r]; drop "accept" [r]]);
    ("strcspn", unknown ~attrs:[KeepsSpecified] [drop "s" [r]; drop "accept" [r]]);
    ("strftime", unknown ~attrs:[KeepsSpecified] [drop "str" [w]; drop "count" []; drop "format" [r]; drop "tp" [r]]);
    ("strtod", unknown ~attrs:[KeepsSpecified] [drop "nptr" [r]; drop "endptr" [w]]);
    ("strtol", unknown ~attrs:[KeepsSpecified] [drop "nptr" [r]; drop "endptr" [w]; drop "base" []]);
    ("__strtol_internal", unknown ~attrs:[KeepsSpecified] [drop "nptr" [r]; drop "endptr" [w]; drop "base" []; drop "group" []]);
    ("strtoll", unknown ~attrs:[KeepsSpecified] [drop "nptr" [r]; drop "endptr" [w]; drop "base" []]);
    ("strtoul", unknown ~attrs:[KeepsSpecified] [drop "nptr" [r]; drop "endptr" [w]; drop "base" []]);
    ("strtoull", unknown ~attrs:[KeepsSpecified] [drop "nptr" [r]; drop "endptr" [w]; drop "base" []]);
    ("tolower", unknown ~attrs:[KeepsSpecified] [drop "ch" []]);
    ("__tolower", unknown ~attrs:[KeepsSpecified] [drop "ch" []]);
    ("toupper", unknown ~attrs:[KeepsSpecified] [drop "ch" []]);
    ("__toupper", unknown ~attrs:[KeepsSpecified] [drop "ch" []]);
    ("time", unknown ~attrs:[KeepsSpecified] [drop "arg" [w]]);
    ("tmpnam", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "filename" [w]]);
    ("vprintf", unknown ~attrs:[KeepsSpecified] [drop "format" [r]; drop "vlist" [r_deep]]); (* TODO: what to do with a va_list type? is r_deep correct? *)
    ("vfprintf", unknown ~attrs:[KeepsSpecified] [drop "stream" [r_deep; w_deep]; drop "format" [r]; drop "vlist" [r_deep]]); (* TODO: what to do with a va_list type? is r_deep correct? *)
    ("vsprintf", unknown ~attrs:[KeepsSpecified] [drop "buffer" [w]; drop "format" [r]; drop "vlist" [r_deep]]); (* TODO: what to do with a va_list type? is r_deep correct? *)
    ("asprintf", unknown ~attrs:[KeepsSpecified] (drop "strp" [w] :: drop "format" [r] :: VarArgs (drop' [r_deep]))); (* TODO: glibc section? *)
    ("vasprintf", unknown ~attrs:[KeepsSpecified] [drop "strp" [w]; drop "format" [r]; drop "ap" [r_deep]]); (* TODO: what to do with a va_list type? is r_deep correct? *)
    ("vsnprintf", unknown ~attrs:[KeepsSpecified] [drop "str" [w]; drop "size" []; drop "format" [r]; drop "ap" [r_deep]]); (* TODO: what to do with a va_list type? is r_deep correct? *)
    ("mktime", unknown ~attrs:[KeepsSpecified] [drop "tm" [r;w]]);
    ("ctime", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "rm" [r]]);
    ("clearerr", unknown ~attrs:[KeepsSpecified] [drop "stream" [w]]); (* TODO: why only w? *)
    ("setbuf", unknown ~attrs:[KeepsSpecified] [drop "stream" [w]; drop "buf" [w; k]]);
    ("wprintf", unknown ~attrs:[KeepsSpecified] (drop "fmt" [r] :: VarArgs (drop' [r])));
    ("fwprintf", unknown ~attrs:[KeepsSpecified] (drop "stream" [r_deep; w_deep] :: drop "fmt" [r] :: VarArgs (drop' [r])));
    ("swprintf", unknown ~attrs:[KeepsSpecified] (drop "wcs" [w] :: drop "maxlen" [] :: drop "fmt" [r] :: VarArgs (drop' [r])));
    ("assert", special ~attrs:[KeepsSpecified] [__ "exp" []] @@ fun exp -> Assert { exp; check = true; refine = get_bool "sem.assert.refine" }); (* only used if assert is used without include, e.g. in transformed files *)
    ("difftime", unknown ~attrs:[KeepsSpecified] [drop "time1" []; drop "time2" []]);
    ("system", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "command" [r]]);
    ("wcscat", unknown ~attrs:[KeepsSpecified] [drop "dest" [r; w]; drop "src" [r]]);
    ("wctomb", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "s" [w]; drop "wc" []]);
    ("wcrtomb", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "s" [w]; drop "wc" []; drop "ps" [r_deep; w_deep]]);
    ("wcstombs", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "dst" [w]; drop "src" [r]; drop "size" []]);
    ("wcsrtombs", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "dst" [w]; drop "src" [r_deep; w]; drop "size" []; drop "ps" [r_deep; w_deep]]);
    ("mbstowcs", unknown ~attrs:[KeepsSpecified] [drop "dest" [w]; drop "src" [r]; drop "n" []]);
    ("abs", special ~attrs:[KeepsSpecified] [__ "j" []] @@ fun j -> Math { fun_args = (Abs (IInt, j)) });
    ("labs", special ~attrs:[KeepsSpecified] [__ "j" []] @@ fun j -> Math { fun_args = (Abs (ILong, j)) });
    ("llabs", special ~attrs:[KeepsSpecified] [__ "j" []] @@ fun j -> Math { fun_args = (Abs (ILongLong, j)) });
    ("imaxabs", special ~attrs:[KeepsSpecified] [__ "j" []] @@ fun j -> Math { fun_args = (Abs (Cilfacade.get_ikind (Option.get (Lazy.force intmax_t)), j)) });
    ("localtime_r", unknown ~attrs:[KeepsSpecified] [drop "timep" [r]; drop "result" [w]]);
    ("strpbrk", unknown ~attrs:[KeepsSpecified] [drop "s" [r]; drop "accept" [r]]);
    ("_setjmp", special ~attrs:[KeepsSpecified] [__ "env" [w]] @@ fun env -> Setjmp { env }); (* only has one underscore *)
    ("setjmp", special ~attrs:[KeepsSpecified] [__ "env" [w]] @@ fun env -> Setjmp { env });
    ("longjmp", special ~attrs:[KeepsSpecified] [__ "env" [r]; __ "value" []] @@ fun env value -> Longjmp { env; value });
    ("atexit", unknown ~attrs:[KeepsSpecified] [drop "function" [if_ (fun () -> not (get_bool "sem.atexit.ignore")) s; k]]);
    ("atoi", unknown ~attrs:[KeepsSpecified] [drop "nptr" [r]]);
    ("atol", unknown ~attrs:[KeepsSpecified] [drop "nptr" [r]]);
    ("atoll", unknown ~attrs:[KeepsSpecified] [drop "nptr" [r]]);
    ("setlocale", unknown ~attrs:[KeepsSpecified] [drop "category" []; drop "locale" [r]]);
    ("clock", unknown ~attrs:[KeepsSpecified] []);
    ("atomic_flag_clear", unknown ~attrs:[KeepsSpecified] [drop "obj" [w]]);
    ("atomic_flag_clear_explicit", unknown ~attrs:[KeepsSpecified] [drop "obj" [w]; drop "order" []]);
    ("atomic_flag_test_and_set", unknown ~attrs:[KeepsSpecified] [drop "obj" [r; w]]);
    ("atomic_flag_test_and_set_explicit", unknown ~attrs:[KeepsSpecified] [drop "obj" [r; w]; drop "order" []]);
    ("atomic_load", unknown ~attrs:[KeepsSpecified] [drop "obj" [r]]);
    ("atomic_store", unknown ~attrs:[KeepsSpecified] [drop "obj" [w]; drop "desired" []]);
    ("_Exit", special ~attrs:[KeepsSpecified] [drop "status" []] @@ Abort);
    ("strcoll", unknown ~attrs:[KeepsSpecified] [drop "lhs" [r]; drop "rhs" [r]]);
    ("wscanf", unknown ~attrs:[KeepsSpecified] (drop "fmt" [r] :: VarArgs (drop' [w])));
    ("fwscanf", unknown ~attrs:[KeepsSpecified] (drop "stream" [r_deep; w_deep] :: drop "fmt" [r] :: VarArgs (drop' [w])));
    ("swscanf", unknown ~attrs:[KeepsSpecified] (drop "buffer" [r] :: drop "fmt" [r] :: VarArgs (drop' [w])));
    ("remove", unknown ~attrs:[KeepsSpecified] [drop "pathname" [r]]);
    ("raise", unknown ~attrs:[KeepsSpecified] [drop "sig" []]); (* safe-ish, we don't handle signal handlers for now *)
    ("timespec_get", unknown ~attrs:[KeepsSpecified] [drop "ts" [w]; drop "base" []]);
    ("signal", unknown ~attrs:[KeepsSpecified] [drop "signum" []; drop "handler" [s; k]]);
    ("va_arg", unknown ~attrs:[KeepsSpecified] [drop "ap" [r]; drop "T" []]);
    ("va_start", unknown ~attrs:[KeepsSpecified] [drop "ap" [r_deep]; drop "parmN" []]);
    ("va_end", unknown ~attrs:[KeepsSpecified] [drop "ap" [r_deep]]);
  ]
[@@coverage off]

(** C POSIX library functions.
    These are {e not} specified by the C standard, but available on POSIX systems.

    Every entry but [fcntl], [syscall], [semctl], [shmat] and [shmdt], whose
    variadic or address arguments mean something different for each command,
    has {!LibraryDesc.KeepsSpecified}. By POSIX, these functions keep a pointer
    derived from an argument after they return only where it is marked [k]:
    [putenv]'s [string], which becomes part of the environment without being
    copied; [hsearch]'s [item], whose [key] and [data] pointers the table
    stores; [getopt]'s and [getopt_long]'s [argv], into which [optarg] and the
    position of the next call point; [sigaction]'s [act], whose handler is
    registered; [timer_create]'s [sevp], whose [sigev_value] is delivered when
    the timer expires; and [openlog]'s [ident], which glibc does not copy.
    [strtok_r] keeps no pointer itself: the position of its next call is
    written to [*saveptr]. *)
let posix_descs_list: (string * LibraryDesc.t) list = LibraryDsl.[
    ("bzero", special ~attrs:[KeepsSpecified] [__ "dest" [w]; __ "count" []] @@ fun dest count -> Bzero { dest; count; });
    ("__builtin_bzero", special ~attrs:[KeepsSpecified] [__ "dest" [w]; __ "count" []] @@ fun dest count -> Bzero { dest; count; });
    ("explicit_bzero", special ~attrs:[KeepsSpecified] [__ "dest" [w]; __ "count" []] @@ fun dest count -> Bzero { dest; count; });
    ("__explicit_bzero_chk", special ~attrs:[KeepsSpecified] [__ "dest" [w]; __ "count" []; drop "os" []] @@ fun dest count -> Bzero { dest; count; });
    ("catgets", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "catalog" [r_deep]; drop "set_number" []; drop "message_number" []; drop "message" [r]]);
    ("crypt", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "key" [r]; drop "salt" [r]]);
    ("ctermid", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "s" [w]]);
    ("dbm_clearerr", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "db" [r_deep; w_deep]]);
    ("dbm_close", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "db" [r_deep; w_deep; f_deep]]);
    ("dbm_delete", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "db" [r_deep; w_deep]; drop "key" []]);
    ("dbm_error", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "db" [r_deep]]);
    ("dbm_fetch", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "db" [r_deep]; drop "key" []]);
    ("dbm_firstkey", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "db" [r_deep]]);
    ("dbm_nextkey", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "db" [r_deep]]);
    ("dbm_open", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "file" [r; w]; drop "open_flags" []; drop "file_mode" []]);
    ("dbm_store", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "db" [r_deep; w_deep]; drop "key" []; drop "content" []; drop "store_mode" []]);
    ("drand48", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] []);
    ("encrypt", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "block" [r; w]; drop "edflag" []]);
    ("setkey", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "key" [r]]);
    ("endgrent", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] []);
    ("endpwent", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] []);
    ("fcvt", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "number" []; drop "ndigits" []; drop "decpt" [w]; drop "sign" [w]]);
    ("ecvt", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "number" []; drop "ndigits" []; drop "decpt" [w]; drop "sign" [w]]);
    ("gcvt", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "number" []; drop "ndigit" []; drop "buf" [w]]);
    ("getdate", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "string" [r]]);
    ("getenv", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "name" [r]]);
    ("getgrent", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] []);
    ("getgrgid", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "gid" []]);
    ("getgrnam", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "name" [r]]);
    ("getlogin", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] []);
    ("getnetbyaddr", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "net" []; drop "type" []]);
    ("getnetbyname", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "name" [r]]);
    ("getnetent", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] []);
    ("getprotobyname", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "name" [r]]);
    ("getprotobynumber", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "proto" []]);
    ("getprotoent", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] []);
    ("getpwent", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] []);
    ("getpwnam", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "name" [r]]);
    ("getpwuid", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "uid" []]);
    ("getservbyname", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "name" [r]; drop "proto" [r]]);
    ("getservbyport", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "port" []; drop "proto" [r]]);
    ("getservent", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] []);
    ("getutxent", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] []);
    ("getutxid", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "utmpx" [r_deep]]);
    ("getutxline", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "utmpx" [r_deep]]);
    ("pututxline", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "utmpx" [r_deep]]);
    ("hcreate", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "nel" []]);
    ("hdestroy", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] []);
    ("hsearch", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "item" [r_deep; k_deep]; drop "action" [r_deep]]);
    ("l64a", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "value" []]);
    ("lrand48", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] []);
    ("mrand48", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] []);
    ("nl_langinfo", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "item" []]);
    ("nl_langinfo_l", unknown ~attrs:[KeepsSpecified] [drop "item" []; drop "locale" [r_deep]]);
    ("getc_unlocked", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "stream" [r_deep; w_deep]]);
    ("getchar_unlocked", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] []);
    ("ptsname", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "fd" []]);
    ("putc_unlocked", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "c" []; drop "stream" [r_deep; w_deep]]);
    ("putchar_unlocked", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "c" []]);
    ("putenv", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "string" [r; w; k]]);
    ("readdir", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "dirp" [r_deep]]);
    ("setenv", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "name" [r]; drop "name" [r]; drop "overwrite" []]);
    ("setgrent", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] []);
    ("setpwent", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] []);
    ("setutxent", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] []);
    ("strsignal", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "sig" []]);
    ("unsetenv", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "name" [r]]);
    ("lseek", unknown ~attrs:[KeepsSpecified] [drop "fd" []; drop "offset" []; drop "whence" []]);
    ("fcntl", unknown (drop "fd" [] :: drop "cmd" [] :: VarArgs (drop' [r; w])));
    ("__open_missing_mode", unknown ~attrs:[KeepsSpecified] []);
    ("fseeko", unknown ~attrs:[KeepsSpecified] [drop "stream" [r_deep; w_deep]; drop "offset" []; drop "whence" []]);
    ("fileno", unknown ~attrs:[KeepsSpecified] [drop "stream" [r_deep; w_deep]]);
    ("fdopen", unknown ~attrs:[KeepsSpecified] [drop "fd" []; drop "mode" [r]]);
    ("getopt", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "argc" []; drop "argv" [r_deep; k_deep]; drop "optstring" [r]]);
    ("getopt_long", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "argc" []; drop "argv" [r_deep; k_deep]; drop "optstring" [r_deep]; drop "longopts" [r]; drop "longindex" [w]]);
    ("iconv_open", unknown ~attrs:[KeepsSpecified] [drop "tocode" [r]; drop "fromcode" [r]]);
    ("iconv", unknown ~attrs:[KeepsSpecified] [drop "cd" [r]; drop "inbuf" [r]; drop "inbytesleft" [r;w]; drop "outbuf" [w]; drop "outbytesleft" [r;w]]);
    ("iconv_close", unknown ~attrs:[KeepsSpecified] [drop "cd" [f]]);
    ("strnlen", unknown ~attrs:[KeepsSpecified] [drop "s" [r]; drop "maxlen" []]);
    ("chmod", unknown ~attrs:[KeepsSpecified] [drop "pathname" [r]; drop "mode" []]);
    ("fchmod", unknown ~attrs:[KeepsSpecified] [drop "fd" []; drop "mode" []]);
    ("chown", unknown ~attrs:[KeepsSpecified] [drop "pathname" [r]; drop "owner" []; drop "group" []]);
    ("fchown", unknown ~attrs:[KeepsSpecified] [drop "fd" []; drop "owner" []; drop "group" []]);
    ("lchown", unknown ~attrs:[KeepsSpecified] [drop "pathname" [r]; drop "owner" []; drop "group" []]);
    ("clock_gettime", unknown ~attrs:[KeepsSpecified] [drop "clockid" []; drop "tp" [w]]);
    ("gettimeofday", unknown ~attrs:[KeepsSpecified] [drop "tv" [w]; drop "tz" [w]]);
    ("futimens", unknown ~attrs:[KeepsSpecified] [drop "fd" []; drop "times" [r]]);
    ("utimes", unknown ~attrs:[KeepsSpecified] [drop "filename" [r]; drop "times" [r]]);
    ("utimensat", unknown ~attrs:[KeepsSpecified] [drop "dirfd" []; drop "pathname" [r]; drop "times" [r]; drop "flags" []]);
    ("linkat", unknown ~attrs:[KeepsSpecified] [drop "olddirfd" []; drop "oldpath" [r]; drop "newdirfd" []; drop "newpath" [r]; drop "flags" []]);
    ("dirfd", unknown ~attrs:[KeepsSpecified] [drop "dirp" [r]]);
    ("fdopendir", unknown ~attrs:[KeepsSpecified] [drop "fd" []]);
    ("pathconf", unknown ~attrs:[KeepsSpecified] [drop "path" [r]; drop "name" []]);
    ("symlink" , unknown ~attrs:[KeepsSpecified] [drop "oldpath" [r]; drop "newpath" [r];]);
    ("ftruncate", unknown ~attrs:[KeepsSpecified] [drop "fd" []; drop "length" []]);
    ("mkfifo", unknown ~attrs:[KeepsSpecified] [drop "pathname" [r]; drop "mode" []]);
    ("alarm", unknown ~attrs:[KeepsSpecified] [drop "seconds" []]);
    ("pread", unknown ~attrs:[KeepsSpecified] [drop "fd" []; drop "buf" [w]; drop "count" []; drop "offset" []]);
    ("pwrite", unknown ~attrs:[KeepsSpecified] [drop "fd" []; drop "buf" [r]; drop "count" []; drop "offset" []]);
    ("hstrerror", unknown ~attrs:[KeepsSpecified] [drop "err" []]);
    ("inet_ntoa", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "in" []]);
    ("getsockopt", unknown ~attrs:[KeepsSpecified] [drop "sockfd" []; drop "level" []; drop "optname" []; drop "optval" [w]; drop "optlen" [w]]);
    ("setsockopt", unknown ~attrs:[KeepsSpecified] [drop "sockfd" []; drop "level" []; drop "optname" []; drop "optval" [r]; drop "optlen" []]);
    ("getsockname", unknown ~attrs:[KeepsSpecified] [drop "sockfd" []; drop "addr" [w_deep]; drop "addrlen" [w]]);
    ("gethostbyaddr", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "addr" [r_deep]; drop "len" []; drop "type" []]);
    ("gethostbyaddr_r", unknown ~attrs:[KeepsSpecified] [drop "addr" [r_deep]; drop "len" []; drop "type" []; drop "ret" [w_deep]; drop "buf" [w]; drop "buflen" []; drop "result" [w]; drop "h_errnop" [w]]);
    ("gethostbyname", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "name" [r]]);
    ("gethostbyname_r", unknown ~attrs:[KeepsSpecified] [drop "name" [r]; drop "result_buf" [w_deep]; drop "buf" [w]; drop "buflen" []; drop "result" [w]; drop "h_errnop" [w]]);
    ("gethostname", unknown ~attrs:[KeepsSpecified] [drop "name" [w]; drop "len" []]);
    ("getpeername", unknown ~attrs:[KeepsSpecified] [drop "sockfd" []; drop "addr" [w_deep]; drop "addrlen" [r; w]]);
    ("socket", unknown ~attrs:[KeepsSpecified] [drop "domain" []; drop "type" []; drop "protocol" []]);
    ("sigaction", unknown ~attrs:[KeepsSpecified] [drop "signum" []; drop "act" [r_deep; s_deep; k_deep]; drop "oldact" [w_deep]]);
    ("tcgetattr", unknown ~attrs:[KeepsSpecified] [drop "fd" []; drop "termios_p" [w_deep]]);
    ("tcsetattr", unknown ~attrs:[KeepsSpecified] [drop "fd" []; drop "optional_actions" []; drop "termios_p" [r_deep]]);
    ("access", unknown ~attrs:[KeepsSpecified] [drop "pathname" [r]; drop "mode" []]);
    ("ttyname", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "fd" []]);
    ("shm_open", unknown ~attrs:[KeepsSpecified] [drop "name" [r]; drop "oflag" []; drop "mode" []]);
    ("shmget", unknown ~attrs:[KeepsSpecified] [drop "key" []; drop "size" []; drop "shmflag" []]);
    ("shmat", unknown [drop "shmid" []; drop "shmaddr" []; drop "shmflag" []]) (* TODO: shmaddr? *);
    ("shmdt", unknown [drop "shmaddr" []]) (* TODO: shmaddr? *);
    ("sched_get_priority_max", unknown ~attrs:[KeepsSpecified] [drop "policy" []]);
    ("mprotect", unknown ~attrs:[KeepsSpecified] [drop "addr" []; drop "len" []; drop "prot" []]);
    ("ftime", unknown ~attrs:[KeepsSpecified] [drop "tp" [w]]);
    ("timer_create", unknown ~attrs:[KeepsSpecified] [drop "clockid" []; drop "sevp" [r; w; s; k_deep]; drop "timerid" [w]]);
    ("timer_settime", unknown ~attrs:[KeepsSpecified] [drop "timerid" []; drop "flags" []; drop "new_value" [r_deep]; drop "old_value" [w_deep]]);
    ("timer_gettime", unknown ~attrs:[KeepsSpecified] [drop "timerid" []; drop "curr_value" [w_deep]]);
    ("timer_getoverrun", unknown ~attrs:[KeepsSpecified] [drop "timerid" []]);
    ("lstat", unknown ~attrs:[KeepsSpecified] [drop "pathname" [r]; drop "statbuf" [w]]);
    ("fstat", unknown ~attrs:[KeepsSpecified] [drop "fd" []; drop "buf" [w]]);
    ("fstatat", unknown ~attrs:[KeepsSpecified] [drop "dirfd" []; drop "pathname" [r]; drop "buf" [w]; drop "flags" []]);
    ("chdir", unknown ~attrs:[KeepsSpecified] [drop "path" [r]]);
    ("closedir", unknown ~attrs:[KeepsSpecified] [drop "dirp" [r]]);
    ("mkdir", unknown ~attrs:[KeepsSpecified] [drop "pathname" [r]; drop "mode" []]);
    ("opendir", unknown ~attrs:[KeepsSpecified] [drop "name" [r]]);
    ("rmdir", unknown ~attrs:[KeepsSpecified] [drop "path" [r]]);
    ("open", unknown ~attrs:[KeepsSpecified] (drop "pathname" [r] :: drop "flags" [] :: VarArgs (drop "mode" [])));
    ("read", unknown ~attrs:[KeepsSpecified] [drop "fd" []; drop "buf" [w]; drop "count" []]);
    ("write", unknown ~attrs:[KeepsSpecified] [drop "fd" []; drop "buf" [r]; drop "count" []]);
    ("recv", unknown ~attrs:[KeepsSpecified] [drop "sockfd" []; drop "buf" [w]; drop "len" []; drop "flags" []]);
    ("recvfrom", unknown ~attrs:[KeepsSpecified] [drop "sockfd" []; drop "buf" [w]; drop "len" []; drop "flags" []; drop "src_addr" [w_deep]; drop "addrlen" [r; w]]);
    ("send", unknown ~attrs:[KeepsSpecified] [drop "sockfd" []; drop "buf" [r]; drop "len" []; drop "flags" []]);
    ("sendto", unknown ~attrs:[KeepsSpecified] [drop "sockfd" []; drop "buf" [r]; drop "len" []; drop "flags" []; drop "dest_addr" [r_deep]; drop "addrlen" []]);
    ("strdup", unknown ~attrs:[KeepsSpecified] [drop "s" [r]]);
    ("__strdup", unknown ~attrs:[KeepsSpecified] [drop "s" [r]]);
    ("strndup", unknown ~attrs:[KeepsSpecified] [drop "s" [r]; drop "n" []]);
    ("__strndup", unknown ~attrs:[KeepsSpecified] [drop "s" [r]; drop "n" []]);
    ("syscall", unknown (drop "number" [] :: VarArgs (drop' [r; w])));
    ("sysconf", unknown ~attrs:[KeepsSpecified] [drop "name" []]);
    ("syslog", unknown ~attrs:[KeepsSpecified] (drop "priority" [] :: drop "format" [r] :: VarArgs (drop' [r]))); (* TODO: is the VarArgs correct here? *)
    ("vsyslog", unknown ~attrs:[KeepsSpecified] [drop "priority" []; drop "format" [r]; drop "ap" [r_deep]]); (* TODO: what to do with a va_list type? is r_deep correct? *)
    ("freeaddrinfo", unknown ~attrs:[KeepsSpecified] [drop "res" [f_deep]]);
    ("getgid", unknown ~attrs:[KeepsSpecified] []);
    ("pselect", unknown ~attrs:[KeepsSpecified] [drop "nfds" []; drop "readdfs" [r]; drop "writedfs" [r]; drop "exceptfds" [r]; drop "timeout" [r]; drop "sigmask" [r]]);
    ("getnameinfo", unknown ~attrs:[KeepsSpecified] [drop "addr" [r_deep]; drop "addrlen" []; drop "host" [w]; drop "hostlen" []; drop "serv" [w]; drop "servlen" []; drop "flags" []]);
    ("strtok_r", unknown ~attrs:[KeepsSpecified] [drop "str" [r; w]; drop "delim" [r]; drop "saveptr" [r_deep; w_deep]]); (* deep accesses through saveptr if str is NULL: https://github.com/lattera/glibc/blob/895ef79e04a953cac1493863bcae29ad85657ee1/string/strtok_r.c#L31-L40 *)
    ("kill", unknown ~attrs:[KeepsSpecified] [drop "pid" []; drop "sig" []]);
    ("closelog", unknown ~attrs:[KeepsSpecified] []);
    ("dirname", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "path" [r]]);
    ("basename", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "path" [r]]);
    ("setpgid", unknown ~attrs:[KeepsSpecified] [drop "pid" []; drop "pgid" []]);
    ("dup2", unknown ~attrs:[KeepsSpecified] [drop "oldfd" []; drop "newfd" []]);
    ("pclose", unknown ~attrs:[KeepsSpecified] [drop "stream" [w; f]]);
    ("getcwd", unknown ~attrs:[KeepsSpecified] [drop "buf" [w]; drop "size" []]);
    ("inet_pton", unknown ~attrs:[KeepsSpecified] [drop "af" []; drop "src" [r]; drop "dst" [w]]);
    ("__inet_pton_alias", unknown ~attrs:[KeepsSpecified] [drop "af" []; drop "src" [r]; drop "dst" [w]]);
    ("__inet_pton_chk", unknown ~attrs:[KeepsSpecified] [drop "af" []; drop "src" [r]; drop "dst" [w]; drop "os" []]);
    ("__inet_pton_chk_warn", unknown ~attrs:[KeepsSpecified] [drop "af" []; drop "src" [r]; drop "dst" [w]; drop "os" []]);
    ("inet_ntop", unknown ~attrs:[KeepsSpecified] [drop "af" []; drop "src" [r]; drop "dst" [w]; drop "size" []]);
    ("__inet_ntop_alias", unknown ~attrs:[KeepsSpecified] [drop "af" []; drop "src" [r]; drop "dst" [w]; drop "size" []]);
    ("__inet_ntop_chk", unknown ~attrs:[KeepsSpecified] [drop "af" []; drop "src" [r]; drop "dst" [w]; drop "size" []; drop "os" []]);
    ("__inet_ntop_chk_warn", unknown ~attrs:[KeepsSpecified] [drop "af" []; drop "src" [r]; drop "dst" [w]; drop "size" []; drop "os" []]);
    ("gethostent", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] []);
    ("poll", unknown ~attrs:[KeepsSpecified] [drop "fds" [r]; drop "nfds" []; drop "timeout" []]);
    ("semget", unknown ~attrs:[KeepsSpecified] [drop "key" []; drop "nsems" []; drop "semflg" []]);
    ("semctl", unknown (drop "semid" [] :: drop "semnum" [] :: drop "cmd" [] :: VarArgs (drop "semun" [r_deep])));
    ("semop", unknown ~attrs:[KeepsSpecified] [drop "semid" []; drop "sops" [r]; drop "nsops" []]);
    ("__sigsetjmp", special ~attrs:[KeepsSpecified] [__ "env" [w]; drop "savesigs" []] @@ fun env -> Setjmp { env }); (* has two underscores *)
    ("sigsetjmp", special ~attrs:[KeepsSpecified] [__ "env" [w]; drop "savesigs" []] @@ fun env -> Setjmp { env });
    ("siglongjmp", special ~attrs:[KeepsSpecified] [__ "env" [r]; __ "value" []] @@ fun env value -> Longjmp { env; value });
    ("ftw", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "dirpath" [r]; drop "fn" [s]; drop "nopenfd" []]); (* TODO: use Call instead of Spawn *)
    ("nftw", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "dirpath" [r]; drop "fn" [s]; drop "nopenfd" []; drop "flags" []]); (* TODO: use Call instead of Spawn *)
    ("getaddrinfo", unknown ~attrs:[KeepsSpecified] [drop "node" [r]; drop "service" [r]; drop "hints" [r_deep]; drop "res" [w]]); (* only write res non-deep because it doesn't write to existing fields of res *)
    ("fnmatch", unknown ~attrs:[KeepsSpecified] [drop "pattern" [r]; drop "string" [r]; drop "flags" []]);
    ("realpath", unknown ~attrs:[KeepsSpecified] [drop "path" [r]; drop "resolved_path" [w]]);
    ("dprintf", unknown ~attrs:[KeepsSpecified] (drop "fd" [] :: drop "format" [r] :: VarArgs (drop' [r])));
    ("vdprintf", unknown ~attrs:[KeepsSpecified] [drop "fd" []; drop "format" [r]; drop "ap" [r_deep]]); (* TODO: what to do with a va_list type? is r_deep correct? *)
    ("mkdtemp", unknown ~attrs:[KeepsSpecified] [drop "template" [r; w]]);
    ("mkstemp", unknown ~attrs:[KeepsSpecified] [drop "template" [r; w]]);
    ("regcomp", unknown ~attrs:[KeepsSpecified] [drop "preg" [w_deep]; drop "regex" [r]; drop "cflags" []]);
    ("regexec", unknown ~attrs:[KeepsSpecified] [drop "preg" [r_deep]; drop "string" [r]; drop "nmatch" []; drop "pmatch" [w_deep]; drop "eflags" []]);
    ("regfree", unknown ~attrs:[KeepsSpecified] [drop "preg" [f_deep]]);
    ("ffs", unknown ~attrs:[KeepsSpecified] [drop "i" []]);
    ("_exit", special ~attrs:[KeepsSpecified] [drop "status" []] @@ Abort);
    ("execvp", unknown ~attrs:[KeepsSpecified] [drop "file" [r]; drop "argv" [r_deep]]);
    ("execl", unknown ~attrs:[KeepsSpecified] (drop "path" [r] :: drop "arg" [r] :: VarArgs (drop' [r])));
    ("statvfs", unknown ~attrs:[KeepsSpecified] [drop "path" [r]; drop "buf" [w]]);
    ("readlink", unknown ~attrs:[KeepsSpecified] [drop "path" [r]; drop "buf" [w]; drop "bufsz" []]);
    ("wcwidth", unknown ~attrs:[KeepsSpecified] [drop "c" []]);
    ("wcswidth", unknown ~attrs:[KeepsSpecified] [drop "s" [r]; drop "n" []]);
    ("link", unknown ~attrs:[KeepsSpecified] [drop "oldpath" [r]; drop "newpath" [r]]);
    ("renameat", unknown ~attrs:[KeepsSpecified] [drop "olddirfd" []; drop "oldpath" [r]; drop "newdirfd" []; drop "newpath" [r]]);
    ("posix_fadvise", unknown ~attrs:[KeepsSpecified] [drop "fd" []; drop "offset" []; drop "len" []; drop "advice" []]);
    ("lockf", unknown ~attrs:[KeepsSpecified] [drop "fd" []; drop "cmd" []; drop "len" []]);
    ("htonl", unknown ~attrs:[KeepsSpecified] [drop "hostlong" []]);
    ("htons", unknown ~attrs:[KeepsSpecified] [drop "hostshort" []]);
    ("ntohl", unknown ~attrs:[KeepsSpecified] [drop "netlong" []]);
    ("ntohs", unknown ~attrs:[KeepsSpecified] [drop "netshort" []]);
    ("sleep", unknown ~attrs:[KeepsSpecified] [drop "seconds" []]);
    ("usleep", unknown ~attrs:[KeepsSpecified] [drop "usec" []]);
    ("nanosleep", unknown ~attrs:[KeepsSpecified] [drop "req" [r]; drop "rem" [w]]);
    ("setpriority", unknown ~attrs:[KeepsSpecified] [drop "which" []; drop "who" []; drop "prio" []]);
    ("getpriority", unknown ~attrs:[KeepsSpecified] [drop "which" []; drop "who" []]);
    ("sched_yield", unknown ~attrs:[KeepsSpecified] []);
    ("getpid", unknown ~attrs:[KeepsSpecified] []);
    ("getppid", unknown ~attrs:[KeepsSpecified] []);
    ("getuid", unknown ~attrs:[KeepsSpecified] []);
    ("geteuid", unknown ~attrs:[KeepsSpecified] []);
    ("getpgrp", unknown ~attrs:[KeepsSpecified] []);
    ("setrlimit", unknown ~attrs:[KeepsSpecified] [drop "resource" []; drop "rlim" [r]]);
    ("getrlimit", unknown ~attrs:[KeepsSpecified] [drop "resource" []; drop "rlim" [w]]);
    ("setsid", unknown ~attrs:[KeepsSpecified] []);
    ("isatty", unknown ~attrs:[KeepsSpecified] [drop "fd" []]);
    ("sigemptyset", unknown ~attrs:[KeepsSpecified] [drop "set" [w]]);
    ("sigfillset", unknown ~attrs:[KeepsSpecified] [drop "set" [w]]);
    ("sigaddset", unknown ~attrs:[KeepsSpecified] [drop "set" [r; w]; drop "signum" []]);
    ("sigdelset", unknown ~attrs:[KeepsSpecified] [drop "set" [r; w]; drop "signum" []]);
    ("sigismember", unknown ~attrs:[KeepsSpecified] [drop "set" [r]; drop "signum" []]);
    ("sigprocmask", unknown ~attrs:[KeepsSpecified] [drop "how" []; drop "set" [r]; drop "oldset" [w]]);
    ("sigwait", unknown ~attrs:[KeepsSpecified] [drop "set" [r]; drop "sig" [w]]);
    ("sigwaitinfo", unknown ~attrs:[KeepsSpecified] [drop "set" [r]; drop "info" [w]]);
    ("sigtimedwait", unknown ~attrs:[KeepsSpecified] [drop "set" [r]; drop "info" [w]; drop "timeout" [r]]);
    ("fork", unknown ~attrs:[KeepsSpecified] []);
    ("dlopen", unknown ~attrs:[KeepsSpecified] [drop "filename" [r]; drop "flag" []]);
    ("dlerror", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] []);
    ("dlsym", unknown ~attrs:[KeepsSpecified] [drop "handle" [r]; drop "symbol" [r]]);
    ("dlclose", unknown ~attrs:[KeepsSpecified] [drop "handle" [r]]);
    ("inet_addr", unknown ~attrs:[KeepsSpecified] [drop "cp" [r]]);
    ("uname", unknown ~attrs:[KeepsSpecified] [drop "buf" [w_deep]]);
    ("strcasecmp", unknown ~attrs:[KeepsSpecified] [drop "s1" [r]; drop "s2" [r]]);
    ("strncasecmp", unknown ~attrs:[KeepsSpecified] [drop "s1" [r]; drop "s2" [r]; drop "n" []]);
    ("connect", unknown ~attrs:[KeepsSpecified] [drop "sockfd" []; drop "sockaddr" [r_deep]; drop "addrlen" []]);
    ("bind", unknown ~attrs:[KeepsSpecified] [drop "sockfd" []; drop "sockaddr" [r_deep]; drop "addrlen" []]);
    ("listen", unknown ~attrs:[KeepsSpecified] [drop "sockfd" []; drop "backlog" []]);
    ("select", unknown ~attrs:[KeepsSpecified] [drop "nfds" []; drop "readfds" [r; w]; drop "writefds" [r; w]; drop "exceptfds" [r; w]; drop "timeout" [r; w]]);
    ("accept", unknown ~attrs:[KeepsSpecified] [drop "sockfd" []; drop "addr" [w_deep]; drop "addrlen" [r; w]]);
    ("close", unknown ~attrs:[KeepsSpecified] [drop "fd" []]);
    ("writev", unknown ~attrs:[KeepsSpecified] [drop "fd" []; drop "iov" [r_deep]; drop "iovcnt" []]);
    ("readv", unknown ~attrs:[KeepsSpecified] [drop "fd" []; drop "iov" [w_deep]; drop "iovcnt" []]);
    ("unlink", unknown ~attrs:[KeepsSpecified] [drop "pathname" [r]]);
    ("popen", unknown ~attrs:[KeepsSpecified] [drop "command" [r]; drop "type" [r]]);
    ("stat", unknown ~attrs:[KeepsSpecified] [drop "pathname" [r]; drop "statbuf" [w]]);
    ("fsync", unknown ~attrs:[KeepsSpecified] [drop "fd" []]);
    ("fdatasync", unknown ~attrs:[KeepsSpecified] [drop "fd" []]);
    ("getrusage", unknown ~attrs:[KeepsSpecified] [drop "who" []; drop "usage" [w]]);
    ("alphasort", unknown ~attrs:[KeepsSpecified] [drop "a" [r]; drop "b" [r]]);
    ("gmtime_r", unknown ~attrs:[KeepsSpecified] [drop "timer" [r]; drop "result" [w]]);
    ("rand_r", special ~attrs:[KeepsSpecified] [drop "seedp" [r; w]] Rand);
    ("srandom", unknown ~attrs:[KeepsSpecified] [drop "seed" []]);
    ("random", special ~attrs:[KeepsSpecified] [] Rand);
    ("posix_memalign", unknown ~attrs:[KeepsSpecified] [drop "memptr" [w]; drop "alignment" []; drop "size" []]); (* TODO: Malloc *)
    ("stpcpy", unknown ~attrs:[KeepsSpecified] [drop "dest" [w]; drop "src" [r]]);
    ("dup", unknown ~attrs:[KeepsSpecified] [drop "oldfd" []]);
    ("readdir_r", unknown ~attrs:[KeepsSpecified] [drop "dirp" [r_deep]; drop "entry" [r_deep]; drop "result" [w]]);
    ("scandir", unknown ~attrs:[KeepsSpecified] [drop "dirp" [r]; drop "namelist" [w]; drop "filter" [r; c]; drop "compar" [r; c]]);
    ("pipe", unknown ~attrs:[KeepsSpecified] [drop "pipefd" [w_deep]]);
    ("waitpid", unknown ~attrs:[KeepsSpecified] [drop "pid" []; drop "wstatus" [w]; drop "options" []]);
    ("strerror_r", unknown ~attrs:[KeepsSpecified] [drop "errnum" []; drop "buff" [w]; drop "buflen" []]);
    ("umask", unknown ~attrs:[KeepsSpecified] [drop "mask" []]);
    ("openlog", unknown ~attrs:[KeepsSpecified] [drop "ident" [r; k]; drop "option" []; drop "facility" []]);
    ("times", unknown ~attrs:[KeepsSpecified] [drop "buf" [w]]);
    ("mmap", unknown ~attrs:[KeepsSpecified] [drop "addr" []; drop "length" []; drop "prot" []; drop "flags" []; drop "fd" []; drop "offset" []]);
    ("munmap", unknown ~attrs:[KeepsSpecified] [drop "addr" []; drop "length" []]);
    ("getline", unknown ~attrs:[KeepsSpecified] [drop "lineptr" [r_deep; w_deep]; drop "n" [r; w]; drop "stream" [r_deep; w_deep]]);
    ("getwline", unknown ~attrs:[KeepsSpecified] [drop "lineptr" [r_deep; w_deep]; drop "n" [r; w]; drop "stream" [r_deep; w_deep]]);
    ("getdelim", unknown ~attrs:[KeepsSpecified] [drop "lineptr" [r_deep; w_deep]; drop "n" [r; w]; drop "delimiter" []; drop "stream" [r_deep; w_deep]]);
    ("__getdelim", unknown ~attrs:[KeepsSpecified] [drop "lineptr" [r_deep; w_deep]; drop "n" [r; w]; drop "delimiter" []; drop "stream" [r_deep; w_deep]]);
    ("getwdelim", unknown ~attrs:[KeepsSpecified] [drop "lineptr" [r_deep; w_deep]; drop "n" [r; w]; drop "delimiter" []; drop "stream" [r_deep; w_deep]]);
    ("execlp", unknown ~attrs:[KeepsSpecified] (drop "file" [r] :: drop "arg" [r] :: VarArgs (drop' [r])));
    ("gai_strerror", unknown ~attrs:[KeepsSpecified] [drop "errcode" []]);
    ("getegid", unknown ~attrs:[KeepsSpecified] []);
    ("getgroups", unknown ~attrs:[KeepsSpecified] [drop "size" []; drop "list" [w]]);
    ("initgroups", unknown ~attrs:[KeepsSpecified] [drop "user" [r]; drop "group" []]);
    ("mknod", unknown ~attrs:[KeepsSpecified] [drop "pathname" [r]; drop "mode" []; drop "dev" []]);
    ("openat", unknown ~attrs:[KeepsSpecified] (drop "dirfd" [] :: drop "pathname" [r] :: drop "flags" [] :: VarArgs (drop "mode" [])));
    ("seteuid", unknown ~attrs:[KeepsSpecified] [drop "uid" []]);
    ("setgid", unknown ~attrs:[KeepsSpecified] [drop "gid" []]);
    ("setuid", unknown ~attrs:[KeepsSpecified] [drop "uid" []]);
    ("socketpair", unknown ~attrs:[KeepsSpecified] [drop "domain" []; drop "type" []; drop "protocol" []; drop "sv" [w]]);
    ("tcgetpgrp", unknown ~attrs:[KeepsSpecified] [drop "fd" []]);
  ]
[@@coverage off]

(** Pthread functions.

    The entries with {!LibraryDesc.KeepsSpecified} keep a pointer derived from
    an argument after they return only where it is marked [k], by POSIX: the
    new thread runs [pthread_create]'s [start_routine] with [arg];
    [pthread_join] returns [pthread_exit]'s [retval];
    [pthread_getspecific] returns [pthread_setspecific]'s [value]; and a
    thread's exit runs [pthread_key_create]'s [destructor]. The mutex,
    condition variable, lock, barrier and semaphore functions keep no pointer
    after they return, with one exception taken as not keeping: a held robust
    mutex is on its owner's list of robust mutexes, which only the owner's
    exit reads, to mark the mutexes it still holds. *)
let pthread_descs_list: (string * LibraryDesc.t) list = LibraryDsl.[
    ("pthread_create", special ~attrs:[KeepsSpecified] [__ "thread" [w]; drop "attr" [r]; __ "start_routine" [s; k]; __ "arg" [k]] @@ fun thread start_routine arg -> ThreadCreate { thread; start_routine; arg; multiple = false }); (* For precision purposes arg is not considered accessed here. Instead all accesses (if any) come from actually analyzing start_routine. *)
    ("pthread_exit", special ~attrs:[KeepsSpecified] [__ "retval" [k]] @@ fun retval -> ThreadExit { ret_val = retval }); (* Doesn't dereference the void* itself, but just passes to pthread_join. *)
    ("pthread_join", special ~attrs:[KeepsSpecified] [__ "thread" []; __ "retval" [w]] @@ fun thread retval -> ThreadJoin {thread; ret_var = retval});
    ("pthread_once", special ~attrs:[KeepsSpecified] [__ "once_control" []; __ "init_routine" []] @@ fun once_control init_routine -> Once {once_control; init_routine});
    ("pthread_kill", unknown ~attrs:[KeepsSpecified] [drop "thread" []; drop "sig" []]);
    ("pthread_equal", unknown ~attrs:[KeepsSpecified] [drop "t1" []; drop "t2" []]);
    ("pthread_cond_init", unknown ~attrs:[KeepsSpecified] [drop "cond" [w]; drop "attr" [r]]);
    ("__pthread_cond_init", unknown ~attrs:[KeepsSpecified] [drop "cond" [w]; drop "attr" [r]]);
    ("pthread_cond_signal", special ~attrs:[KeepsSpecified] [__ "cond" []] @@ fun cond -> Signal cond);
    ("__pthread_cond_signal", special ~attrs:[KeepsSpecified] [__ "cond" []] @@ fun cond -> Signal cond);
    ("pthread_cond_broadcast", special ~attrs:[KeepsSpecified] [__ "cond" []] @@ fun cond -> Broadcast cond);
    ("__pthread_cond_broadcast", special ~attrs:[KeepsSpecified] [__ "cond" []] @@ fun cond -> Broadcast cond);
    ("pthread_cond_wait", special ~attrs:[KeepsSpecified] [__ "cond" []; __ "mutex" []] @@ fun cond mutex -> Wait {cond; mutex});
    ("__pthread_cond_wait", special ~attrs:[KeepsSpecified] [__ "cond" []; __ "mutex" []] @@ fun cond mutex -> Wait {cond; mutex});
    ("pthread_cond_timedwait", special ~attrs:[KeepsSpecified] [__ "cond" []; __ "mutex" []; __ "abstime" [r]] @@ fun cond mutex abstime -> TimedWait {cond; mutex; abstime});
    ("pthread_cond_destroy", unknown ~attrs:[KeepsSpecified] [drop "cond" [f]]);
    ("__pthread_cond_destroy", unknown ~attrs:[KeepsSpecified] [drop "cond" [f]]);
    ("pthread_mutexattr_settype", special ~attrs:[KeepsSpecified] [__ "attr" []; __ "type" []] @@ fun attr typ -> MutexAttrSetType {attr; typ});
    ("pthread_mutex_init", special ~attrs:[KeepsSpecified] [__ "mutex" []; __ "attr" []] @@ fun mutex attr -> MutexInit {mutex; attr});
    ("pthread_mutex_destroy", unknown ~attrs:[KeepsSpecified] [drop "mutex" [f]]);
    ("pthread_mutex_lock", special ~attrs:[KeepsSpecified] [__ "mutex" []] @@ fun mutex -> Lock {lock = mutex; try_ = get_bool "sem.lock.fail"; write = true; return_on_success = false});
    ("__pthread_mutex_lock", special ~attrs:[KeepsSpecified] [__ "mutex" []] @@ fun mutex -> Lock {lock = mutex; try_ = get_bool "sem.lock.fail"; write = true; return_on_success = false});
    ("pthread_mutex_trylock", special ~attrs:[KeepsSpecified] [__ "mutex" []] @@ fun mutex -> Lock {lock = mutex; try_ = true; write = true; return_on_success = false});
    ("__pthread_mutex_trylock", special ~attrs:[KeepsSpecified] [__ "mutex" []] @@ fun mutex -> Lock {lock = mutex; try_ = true; write = true; return_on_success = false});
    ("pthread_mutex_unlock", special ~attrs:[KeepsSpecified] [__ "mutex" []] @@ fun mutex -> Unlock mutex);
    ("__pthread_mutex_unlock", special ~attrs:[KeepsSpecified] [__ "mutex" []] @@ fun mutex -> Unlock mutex);
    ("pthread_mutexattr_init", unknown ~attrs:[KeepsSpecified] [drop "attr" [w]]);
    ("pthread_mutexattr_getpshared", unknown ~attrs:[KeepsSpecified] [drop "attr" [r]; drop "pshared" [w]]);
    ("pthread_mutexattr_setpshared", unknown ~attrs:[KeepsSpecified] [drop "attr" [w]; drop "pshared" []]);
    ("pthread_mutexattr_getrobust", unknown ~attrs:[KeepsSpecified] [drop "attr" [r]; drop "pshared" [w]]);
    ("pthread_mutexattr_setrobust", unknown ~attrs:[KeepsSpecified] [drop "attr" [w]; drop "pshared" []]);
    ("pthread_mutexattr_destroy", unknown ~attrs:[KeepsSpecified] [drop "attr" [f]]);
    ("pthread_rwlock_init", unknown ~attrs:[KeepsSpecified] [drop "rwlock" [w]; drop "attr" [r]]);
    ("pthread_rwlock_destroy", unknown ~attrs:[KeepsSpecified] [drop "rwlock" [f]]);
    ("pthread_rwlock_rdlock", special ~attrs:[KeepsSpecified] [__ "rwlock" []] @@ fun rwlock -> Lock {lock = rwlock; try_ = get_bool "sem.lock.fail"; write = false; return_on_success = false});
    ("pthread_rwlock_tryrdlock", special ~attrs:[KeepsSpecified] [__ "rwlock" []] @@ fun rwlock -> Lock {lock = rwlock; try_ = true; write = false; return_on_success = false});
    ("pthread_rwlock_wrlock", special ~attrs:[KeepsSpecified] [__ "rwlock" []] @@ fun rwlock -> Lock {lock = rwlock; try_ = get_bool "sem.lock.fail"; write = true; return_on_success = false});
    ("pthread_rwlock_trywrlock", special ~attrs:[KeepsSpecified] [__ "rwlock" []] @@ fun rwlock -> Lock {lock = rwlock; try_ = true; write = true; return_on_success = false});
    ("pthread_rwlock_unlock", special ~attrs:[KeepsSpecified] [__ "rwlock" []] @@ fun rwlock -> Unlock rwlock);
    ("pthread_rwlockattr_init", unknown ~attrs:[KeepsSpecified] [drop "attr" [w]]);
    ("pthread_rwlockattr_destroy", unknown ~attrs:[KeepsSpecified] [drop "attr" [f]]);
    ("pthread_spin_init", unknown ~attrs:[KeepsSpecified] [drop "lock" [w]; drop "pshared" []]);
    ("pthread_spin_destroy", unknown ~attrs:[KeepsSpecified] [drop "lock" [f]]);
    ("pthread_spin_lock", special ~attrs:[KeepsSpecified] [__ "lock" []] @@ fun lock -> Lock {lock = lock; try_ = get_bool "sem.lock.fail"; write = true; return_on_success = false});
    ("pthread_spin_trylock", special ~attrs:[KeepsSpecified] [__ "lock" []] @@ fun lock -> Lock {lock = lock; try_ = true; write = true; return_on_success = false});
    ("pthread_spin_unlock", special ~attrs:[KeepsSpecified] [__ "lock" []] @@ fun lock -> Unlock lock);
    ("pthread_attr_init", unknown ~attrs:[KeepsSpecified] [drop "attr" [w]]);
    ("pthread_attr_destroy", unknown ~attrs:[KeepsSpecified] [drop "attr" [f]]);
    ("pthread_attr_getdetachstate", unknown ~attrs:[KeepsSpecified] [drop "attr" [r]; drop "detachstate" [w]]);
    ("pthread_attr_setdetachstate", unknown ~attrs:[KeepsSpecified] [drop "attr" [w]; drop "detachstate" []]);
    ("pthread_attr_getstacksize", unknown ~attrs:[KeepsSpecified] [drop "attr" [r]; drop "stacksize" [w]]);
    ("pthread_attr_setstacksize", unknown ~attrs:[KeepsSpecified] [drop "attr" [w]; drop "stacksize" []]);
    ("pthread_attr_getscope", unknown ~attrs:[KeepsSpecified] [drop "attr" [r]; drop "scope" [w]]);
    ("pthread_attr_setscope", unknown ~attrs:[KeepsSpecified] [drop "attr" [w]; drop "scope" []]);
    ("pthread_self", special ~attrs:[KeepsSpecified] [] ThreadSelf);
    ("pthread_sigmask", unknown ~attrs:[KeepsSpecified] [drop "how" []; drop "set" [r]; drop "oldset" [w]]);
    ("pthread_setspecific", unknown ~attrs:[KeepsSpecified; InvalidateGlobals] [drop "key" []; drop "value" [w_deep; k]]);
    ("pthread_getspecific", unknown ~attrs:[KeepsSpecified; InvalidateGlobals] [drop "key" []]);
    ("pthread_key_create", unknown ~attrs:[KeepsSpecified] [drop "key" [w]; drop "destructor" [s; k]]);
    ("pthread_key_delete", unknown ~attrs:[KeepsSpecified] [drop "key" [f]]);
    ("pthread_barrier_init", special ~attrs:[KeepsSpecified] [__ "barrier" []; __ "attr" []; __ "count" []] @@ fun barrier attr count -> BarrierInit {barrier; attr; count});
    ("pthread_barrier_wait", special ~attrs:[KeepsSpecified] [__ "barrier" []] @@ fun barrier -> BarrierWait barrier);
    ("pthread_cancel", unknown ~attrs:[KeepsSpecified] [drop "thread" []]);
    ("pthread_testcancel", unknown ~attrs:[KeepsSpecified] []);
    ("pthread_setcancelstate", unknown ~attrs:[KeepsSpecified] [drop "state" []; drop "oldstate" [w]]);
    ("pthread_setcanceltype", unknown ~attrs:[KeepsSpecified] [drop "type" []; drop "oldtype" [w]]);
    ("pthread_detach", unknown ~attrs:[KeepsSpecified] [drop "thread" []]);
    ("pthread_attr_setschedpolicy", unknown ~attrs:[KeepsSpecified] [drop "attr" [r; w]; drop "policy" []]);
    ("pthread_condattr_init", unknown ~attrs:[KeepsSpecified] [drop "attr" [w]]);
    ("pthread_condattr_setclock", unknown ~attrs:[KeepsSpecified] [drop "attr" [w]; drop "clock_id" []]);
    ("pthread_attr_setschedparam", unknown ~attrs:[KeepsSpecified] [drop "attr" [r; w]; drop "param" [r]]);
    ("pthread_setaffinity_np", unknown ~attrs:[KeepsSpecified] [drop "thread" []; drop "cpusetsize" []; drop "cpuset" [r]]);
    ("pthread_getaffinity_np", unknown ~attrs:[KeepsSpecified] [drop "thread" []; drop "cpusetsize" []; drop "cpuset" [w]]);
    (* Not recording read accesses to sem as these are thread-safe anyway not to clutter messages (as for mutexes) **)
    ("sem_init", special ~attrs:[KeepsSpecified] [__ "sem" []; __ "pshared" []; __ "value" []] @@ fun sem pshared value -> SemInit {sem; pshared; value});
    ("sem_wait", special ~attrs:[KeepsSpecified] [__ "sem" []] @@ fun sem -> SemWait {sem; try_ = false; timeout = None});
    ("sem_trywait", special ~attrs:[KeepsSpecified] [__ "sem" []] @@ fun sem -> SemWait {sem; try_ = true; timeout = None});
    ("sem_timedwait", special ~attrs:[KeepsSpecified] [__ "sem" []; __ "abs_timeout" [r]] @@ fun sem abs_timeout-> SemWait {sem; try_ = true; timeout = Some abs_timeout}); (* no write accesses to sem because sync primitive itself has no race *)
    ("sem_post", special ~attrs:[KeepsSpecified] [__ "sem" []] @@ fun sem -> SemPost sem);
    ("sem_destroy", special ~attrs:[KeepsSpecified] [__ "sem" []] @@ fun sem -> SemDestroy sem);
  ]
[@@coverage off]

(** GCC builtin functions.
    These are not builtin versions of functions from other lists.

    Every entry has {!LibraryDesc.KeepsSpecified}: by the GCC manual, none of
    these keeps a pointer derived from an argument after it returns. *)
let gcc_descs_list: (string * LibraryDesc.t) list = LibraryDsl.[
    ("__builtin_bswap16", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("__builtin_bswap32", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("__builtin_bswap64", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("__builtin_bswap128", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("__builtin_ctz", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("__builtin_ctzl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("__builtin_ctzll", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("__builtin_clz", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("__builtin_clzl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("__builtin_clzll", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("__builtin_object_size", unknown ~attrs:[KeepsSpecified] [drop "ptr" [r]; drop' []]);
    ("__builtin_prefetch", unknown ~attrs:[KeepsSpecified] (drop "addr" [] :: VarArgs (drop' [])));
    ("__builtin_expect", special ~attrs:[KeepsSpecified] [__ "exp" []; drop' []] @@ fun exp -> Identity exp); (* Identity, because just compiler optimization annotation. *)
    ("__builtin_unreachable", special' ~attrs:[KeepsSpecified] [] @@ fun () -> if get_bool "sem.builtin_unreachable.dead_code" then Abort else Unknown); (* https://github.com/sosy-lab/sv-benchmarks/issues/1296 *)
    ("__assert_rtn", special ~attrs:[KeepsSpecified] [drop "func" [r]; drop "file" [r]; drop "line" []; drop "exp" [r]] @@ Abort); (* MacOS's built-in assert *)
    ("__assert_fail", special ~attrs:[KeepsSpecified] [drop "assertion" [r]; drop "file" [r]; drop "line" []; drop "function" [r]] @@ Abort); (* gcc's built-in assert *)
    ("__assert", special ~attrs:[KeepsSpecified] [drop "assertion" [r]; drop "file" [r]; drop "line" []] @@ Abort); (* header says: The following is not at all used here but needed for standard compliance. *)
    ("__builtin_return_address", unknown ~attrs:[KeepsSpecified] [drop "level" []]);
    ("__builtin___sprintf_chk", unknown ~attrs:[KeepsSpecified] (drop "s" [w] :: drop "flag" [] :: drop "os" [] :: drop "fmt" [r] :: VarArgs (drop' [r])));
    ("__builtin___snprintf_chk", unknown ~attrs:[KeepsSpecified] (drop "s" [w] :: drop "maxlen" [] :: drop "flag" [] :: drop "os" [] :: drop "fmt" [r] :: VarArgs (drop' [r])));
    ("__builtin___vsprintf_chk", unknown ~attrs:[KeepsSpecified] [drop "s" [w]; drop "flag" []; drop "os" []; drop "fmt" [r]; drop "ap" [r_deep]]); (* TODO: what to do with a va_list type? is r_deep correct? *)
    ("__builtin___vsnprintf_chk", unknown ~attrs:[KeepsSpecified] [drop "s" [w]; drop "maxlen" []; drop "flag" []; drop "os" []; drop "fmt" [r]; drop "ap" [r_deep]]); (* TODO: what to do with a va_list type? is r_deep correct? *)
    ("__builtin___printf_chk", unknown ~attrs:[KeepsSpecified] (drop "flag" [] :: drop "format" [r] :: VarArgs (drop' [r])));
    ("__builtin___vprintf_chk", unknown ~attrs:[KeepsSpecified] [drop "flag" []; drop "format" [r]; drop "ap" [r_deep]]); (* TODO: what to do with a va_list type? is r_deep correct? *)
    ("__builtin___fprintf_chk", unknown ~attrs:[KeepsSpecified] (drop "stream" [r_deep; w_deep] :: drop "flag" [] :: drop "format" [r] :: VarArgs (drop' [r])));
    ("__builtin___vfprintf_chk", unknown ~attrs:[KeepsSpecified] [drop "stream" [r_deep; w_deep]; drop "flag" []; drop "format" [r]; drop "ap" [r_deep]]);
    ("__builtin_add_overflow", unknown ~attrs:[KeepsSpecified] [drop "a" []; drop "b" []; drop "c" [w]]);
    ("__builtin_sadd_overflow", unknown ~attrs:[KeepsSpecified] [drop "a" []; drop "b" []; drop "c" [w]]);
    ("__builtin_saddl_overflow", unknown ~attrs:[KeepsSpecified] [drop "a" []; drop "b" []; drop "c" [w]]);
    ("__builtin_saddll_overflow", unknown ~attrs:[KeepsSpecified] [drop "a" []; drop "b" []; drop "c" [w]]);
    ("__builtin_uadd_overflow", unknown ~attrs:[KeepsSpecified] [drop "a" []; drop "b" []; drop "c" [w]]);
    ("__builtin_uaddl_overflow", unknown ~attrs:[KeepsSpecified] [drop "a" []; drop "b" []; drop "c" [w]]);
    ("__builtin_uaddll_overflow", unknown ~attrs:[KeepsSpecified] [drop "a" []; drop "b" []; drop "c" [w]]);
    ("__builtin_sub_overflow", unknown ~attrs:[KeepsSpecified] [drop "a" []; drop "b" []; drop "c" [w]]);
    ("__builtin_ssub_overflow", unknown ~attrs:[KeepsSpecified] [drop "a" []; drop "b" []; drop "c" [w]]);
    ("__builtin_ssubl_overflow", unknown ~attrs:[KeepsSpecified] [drop "a" []; drop "b" []; drop "c" [w]]);
    ("__builtin_ssubll_overflow", unknown ~attrs:[KeepsSpecified] [drop "a" []; drop "b" []; drop "c" [w]]);
    ("__builtin_usub_overflow", unknown ~attrs:[KeepsSpecified] [drop "a" []; drop "b" []; drop "c" [w]]);
    ("__builtin_usubl_overflow", unknown ~attrs:[KeepsSpecified] [drop "a" []; drop "b" []; drop "c" [w]]);
    ("__builtin_usubll_overflow", unknown ~attrs:[KeepsSpecified] [drop "a" []; drop "b" []; drop "c" [w]]);
    ("__builtin_mul_overflow", unknown ~attrs:[KeepsSpecified] [drop "a" []; drop "b" []; drop "c" [w]]);
    ("__builtin_smul_overflow", unknown ~attrs:[KeepsSpecified] [drop "a" []; drop "b" []; drop "c" [w]]);
    ("__builtin_smull_overflow", unknown ~attrs:[KeepsSpecified] [drop "a" []; drop "b" []; drop "c" [w]]);
    ("__builtin_smulll_overflow", unknown ~attrs:[KeepsSpecified] [drop "a" []; drop "b" []; drop "c" [w]]);
    ("__builtin_umul_overflow", unknown ~attrs:[KeepsSpecified] [drop "a" []; drop "b" []; drop "c" [w]]);
    ("__builtin_umull_overflow", unknown ~attrs:[KeepsSpecified] [drop "a" []; drop "b" []; drop "c" [w]]);
    ("__builtin_umulll_overflow", unknown ~attrs:[KeepsSpecified] [drop "a" []; drop "b" []; drop "c" [w]]);
    ("__builtin_add_overflow_p", unknown ~attrs:[KeepsSpecified] [drop "a" []; drop "b" []; drop "c" []]);
    ("__builtin_sub_overflow_p", unknown ~attrs:[KeepsSpecified] [drop "a" []; drop "b" []; drop "c" []]);
    ("__builtin_mul_overflow_p", unknown ~attrs:[KeepsSpecified] [drop "a" []; drop "b" []; drop "c" []]);
    ("__builtin_popcount", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("__builtin_popcountl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("__builtin_popcountll", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("__atomic_store_n", unknown ~attrs:[KeepsSpecified] [drop "ptr" [w]; drop "val" []; drop "memorder" []]);
    ("__atomic_store", unknown ~attrs:[KeepsSpecified] [drop "ptr" [w]; drop "val" [r]; drop "memorder" []]);
    ("__atomic_load_n", unknown ~attrs:[KeepsSpecified] [drop "ptr" [r]; drop "memorder" []]);
    ("__atomic_load", unknown ~attrs:[KeepsSpecified] [drop "ptr" [r]; drop "ret" [w]; drop "memorder" []]);
    ("__atomic_clear", unknown ~attrs:[KeepsSpecified] [drop "ptr" [w]; drop "memorder" []]);
    ("__atomic_compare_exchange_n", unknown ~attrs:[KeepsSpecified] [drop "ptr" [r; w]; drop "expected" [r; w]; drop "desired" []; drop "weak" []; drop "success_memorder" []; drop "failure_memorder" []]);
    ("__atomic_compare_exchange", unknown ~attrs:[KeepsSpecified] [drop "ptr" [r; w]; drop "expected" [r; w]; drop "desired" [r]; drop "weak" []; drop "success_memorder" []; drop "failure_memorder" []]);
    ("__atomic_add_fetch", unknown ~attrs:[KeepsSpecified] [drop "ptr" [r; w]; drop "val" []; drop "memorder" []]);
    ("__atomic_sub_fetch", unknown ~attrs:[KeepsSpecified] [drop "ptr" [r; w]; drop "val" []; drop "memorder" []]);
    ("__atomic_and_fetch", unknown ~attrs:[KeepsSpecified] [drop "ptr" [r; w]; drop "val" []; drop "memorder" []]);
    ("__atomic_xor_fetch", unknown ~attrs:[KeepsSpecified] [drop "ptr" [r; w]; drop "val" []; drop "memorder" []]);
    ("__atomic_or_fetch", unknown ~attrs:[KeepsSpecified] [drop "ptr" [r; w]; drop "val" []; drop "memorder" []]);
    ("__atomic_nand_fetch", unknown ~attrs:[KeepsSpecified] [drop "ptr" [r; w]; drop "val" []; drop "memorder" []]);
    ("__atomic_fetch_add", unknown ~attrs:[KeepsSpecified] [drop "ptr" [r; w]; drop "val" []; drop "memorder" []]);
    ("__atomic_fetch_sub", unknown ~attrs:[KeepsSpecified] [drop "ptr" [r; w]; drop "val" []; drop "memorder" []]);
    ("__atomic_fetch_and", unknown ~attrs:[KeepsSpecified] [drop "ptr" [r; w]; drop "val" []; drop "memorder" []]);
    ("__atomic_fetch_xor", unknown ~attrs:[KeepsSpecified] [drop "ptr" [r; w]; drop "val" []; drop "memorder" []]);
    ("__atomic_fetch_or", unknown ~attrs:[KeepsSpecified] [drop "ptr" [r; w]; drop "val" []; drop "memorder" []]);
    ("__atomic_fetch_nand", unknown ~attrs:[KeepsSpecified] [drop "ptr" [r; w]; drop "val" []; drop "memorder" []]);
    ("__atomic_test_and_set", unknown ~attrs:[KeepsSpecified] [drop "ptr" [r; w]; drop "memorder" []]);
    ("__atomic_thread_fence", unknown ~attrs:[KeepsSpecified] [drop "memorder" []]);
    ("__sync_bool_compare_and_swap", unknown ~attrs:[KeepsSpecified] [drop "ptr" [r; w]; drop "oldval" []; drop "newval" []]);
    ("__sync_fetch_and_add", unknown ~attrs:[KeepsSpecified] (drop "ptr" [r; w] :: drop "value" [] :: VarArgs (drop' [])));
    ("__sync_fetch_and_sub", unknown ~attrs:[KeepsSpecified] (drop "ptr" [r; w] :: drop "value" [] :: VarArgs (drop' [])));
    ("__builtin_va_copy", unknown ~attrs:[KeepsSpecified] [drop "dest" [w]; drop "src" [r]]);
    ("alloca", special ~attrs:[KeepsSpecified] [__ "size" []] @@ fun size -> Alloca size);
    ("__builtin_alloca", special ~attrs:[KeepsSpecified] [__ "size" []] @@ fun size -> Alloca size);
    ("__builtin_vsnprintf", unknown ~attrs:[KeepsSpecified] [drop "str" [w]; drop "size" []; drop "format" [r]; drop "ap" [r_deep]]);
    ("__builtin___vsnprintf", unknown ~attrs:[KeepsSpecified] [drop "str" [w]; drop "size" []; drop "format" [r]; drop "ap" [r_deep]]); (* TODO: does this actually exist?! *)
    ("__builtin_va_arg", unknown ~attrs:[KeepsSpecified] [drop "ap" [r_deep]; drop "T" []; drop "lhs" [w]]); (* cil: "__builtin_va_arg is special: in CIL, the left hand side is stored as the last argument" *)
    ("__builtin_va_start", unknown ~attrs:[KeepsSpecified] [drop "ap" [r_deep]]); (* cil: "When we parse builtin_{va,stdarg}_start, we drop the second argument" *)
    ("__builtin_va_end", unknown ~attrs:[KeepsSpecified] [drop "ap" [r_deep]]);
    ("__builtin_va_arg_pack_len", unknown ~attrs:[KeepsSpecified] []);
  ]
[@@coverage off]

(** GNU C library functions.

    Every entry but the RPC and XDR functions, [yp_get_default_domain],
    [__nss_configure_lookup], [getaddrinfo_a], which keeps [list] and [sevp]
    until the requests complete, and [fopencookie], which keeps [cookie] for
    the stream's functions, has {!LibraryDesc.KeepsSpecified}. By the glibc
    manual, none of these keeps a pointer derived from an argument after it
    returns. *)
let glibc_desc_list: (string * LibraryDesc.t) list = LibraryDsl.[
    ("fputs_unlocked", unknown ~attrs:[KeepsSpecified] [drop "s" [r]; drop "stream" [w]]);
    ("feof_unlocked", unknown ~attrs:[KeepsSpecified] [drop "stream" [r_deep; w_deep]]);
    ("ferror_unlocked", unknown ~attrs:[KeepsSpecified] [drop "stream" [r_deep; w_deep]]);
    ("fwrite_unlocked", unknown ~attrs:[KeepsSpecified] [drop "buffer" [r]; drop "size" []; drop "count" []; drop "stream" [r_deep; w_deep]]);
    ("clearerr_unlocked", unknown ~attrs:[KeepsSpecified] [drop "stream" [w]]); (* TODO: why only w? *)
    ("__fpending", unknown ~attrs:[KeepsSpecified] [drop "stream" [r_deep]]);
    ("futimesat", unknown ~attrs:[KeepsSpecified] [drop "dirfd" []; drop "pathname" [r]; drop "times" [r]]);
    ("error", unknown ~attrs:[KeepsSpecified] ((drop "status" []) :: (drop "errnum" []) :: (drop "format" [r]) :: (VarArgs (drop' [r]))));
    ("warn", unknown ~attrs:[KeepsSpecified] (drop "format" [r] :: VarArgs (drop' [r])));
    ("gettext", unknown ~attrs:[KeepsSpecified] [drop "msgid" [r]]);
    ("euidaccess", unknown ~attrs:[KeepsSpecified] [drop "pathname" [r]; drop "mode" []]);
    ("rpmatch", unknown ~attrs:[KeepsSpecified] [drop "response" [r]]);
    ("getpagesize", unknown ~attrs:[KeepsSpecified] []);
    ("__fgets_alias", unknown ~attrs:[KeepsSpecified] [drop "__s" [w]; drop "__n" []; drop "__stream" [r_deep; w_deep]]);
    ("__fgets_chk", unknown ~attrs:[KeepsSpecified] [drop "__s" [w]; drop "__size" []; drop "__n" []; drop "__stream" [r_deep; w_deep]]);
    ("__fread_alias", unknown ~attrs:[KeepsSpecified] [drop "__ptr" [w]; drop "__size" []; drop "__n" []; drop "__stream" [r_deep; w_deep]]);
    ("__fread_chk", unknown ~attrs:[KeepsSpecified] [drop "__ptr" [w]; drop "__ptrlen" []; drop "__size" []; drop "__n" []; drop "__stream" [r_deep; w_deep]]);
    ("__fread_chk_warn", unknown ~attrs:[KeepsSpecified] [drop "buffer" [w]; drop "os" []; drop "size" []; drop "count" []; drop "stream" [r_deep; w_deep]]);
    ("fread_unlocked", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "buffer" [w]; drop "size" []; drop "count" []; drop "stream" [r_deep; w_deep]]);
    ("__fread_unlocked_alias", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "__ptr" [w]; drop "__size" []; drop "__n" []; drop "__stream" [r_deep; w_deep]]);
    ("__fread_unlocked_chk", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "__ptr" [w]; drop "__ptrlen" []; drop "__size" []; drop "__n" []; drop "__stream" [r_deep; w_deep]]);
    ("__fread_unlocked_chk_warn", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "__ptr" [w]; drop "__ptrlen" []; drop "__size" []; drop "__n" []; drop "__stream" [r_deep; w_deep]]);
    ("__read_chk", unknown ~attrs:[KeepsSpecified] [drop "__fd" []; drop "__buf" [w]; drop "__nbytes" []; drop "__buflen" []]);
    ("__read_alias", unknown ~attrs:[KeepsSpecified] [drop "__fd" []; drop "__buf" [w]; drop "__nbytes" []]);
    ("__readlink_chk", unknown ~attrs:[KeepsSpecified] [drop "path" [r]; drop "buf" [w]; drop "len" []; drop "buflen" []]);
    ("__readlink_alias", unknown ~attrs:[KeepsSpecified] [drop "path" [r]; drop "buf" [w]; drop "len" []]);
    ("__overflow", unknown ~attrs:[KeepsSpecified] [drop "f" [r]; drop "ch" []]);
    ("__ctype_get_mb_cur_max", unknown ~attrs:[KeepsSpecified] []);
    ("__maskrune", unknown ~attrs:[KeepsSpecified] [drop "c" []; drop "f" []]);
    ("__xmknod", unknown ~attrs:[KeepsSpecified] [drop "ver" []; drop "path" [r]; drop "mode" []; drop "dev" [r; w]]);
    ("yp_get_default_domain", unknown [drop "outdomain" [w]]);
    ("__nss_configure_lookup", unknown [drop "db" [r]; drop "service_line" [r]]);
    ("xdr_string", unknown [drop "xdrs" [r_deep; w_deep]; drop "sp" [r; w]; drop "maxsize" []]);
    ("xdr_enum", unknown [drop "xdrs" [r_deep; w_deep]; drop "ep" [r; w]]);
    ("xdr_u_int", unknown [drop "xdrs" [r_deep; w_deep]; drop "up" [r; w]]);
    ("xdr_opaque", unknown [drop "xdrs" [r_deep; w_deep]; drop "cp" [r; w]; drop "cnt" []]);
    ("xdr_free", unknown [drop "proc" [s]; drop "objp" [f_deep]]);
    ("svcerr_noproc", unknown [drop "xprt" [r_deep; w_deep]]);
    ("svcerr_decode", unknown [drop "xprt" [r_deep; w_deep]]);
    ("svcerr_systemerr", unknown [drop "xprt" [r_deep; w_deep]]);
    ("svc_sendreply", unknown [drop "xprt" [r_deep; w_deep]; drop "outproc" [s]; drop "out" [r]]);
    ("shutdown", unknown ~attrs:[KeepsSpecified] [drop "socket" []; drop "how" []]);
    ("getaddrinfo_a", unknown [drop "mode" []; drop "list" [w_deep]; drop "nitems" []; drop "sevp" [r; w; s]]);
    ("__uflow", unknown ~attrs:[KeepsSpecified] [drop "file" [r; w]]);
    ("getservbyname_r", unknown ~attrs:[KeepsSpecified] [drop "name" [r]; drop "proto" [r]; drop "result_buf" [w_deep]; drop "buf" [w]; drop "buflen" []; drop "result" [w]]);
    ("strsep", unknown ~attrs:[KeepsSpecified] [drop "stringp" [r_deep; w]; drop "delim" [r]]);
    ("strcasestr", unknown ~attrs:[KeepsSpecified] [drop "haystack" [r]; drop "needle" [r]]);
    ("inet_aton", unknown ~attrs:[KeepsSpecified] [drop "cp" [r]; drop "inp" [w]]);
    ("fopencookie", unknown [drop "cookie" []; drop "mode" [r]; drop "io_funcs" [s_deep]]); (* doesn't access cookie but passes it to io_funcs *)
    ("mempcpy", special ~attrs:[KeepsSpecified] [__ "dest" [w]; __ "src" [r]; __ "n" []] @@ fun dest src n -> Memcpy { dest; src; n; });
    ("__builtin___mempcpy_chk", special ~attrs:[KeepsSpecified] [__ "dest" [w]; __ "src" [r]; __ "n" []; drop "os" []] @@ fun dest src n -> Memcpy { dest; src; n; });
    ("rawmemchr", unknown ~attrs:[KeepsSpecified] [drop "s" [r]; drop "c" []]);
    ("memrchr", unknown ~attrs:[KeepsSpecified] [drop "s" [r]; drop "c" []; drop "n" []]);
    ("memmem", unknown ~attrs:[KeepsSpecified] [drop "haystack" [r]; drop "haystacklen" []; drop "needle" [r]; drop "needlelen" [r]]);
    ("getifaddrs", unknown ~attrs:[KeepsSpecified] [drop "ifap" [w]]);
    ("freeifaddrs", unknown ~attrs:[KeepsSpecified] [drop "ifa" [f_deep]]);
    ("atoq", unknown ~attrs:[KeepsSpecified] [drop "nptr" [r]]);
    ("strchrnul", unknown ~attrs:[KeepsSpecified] [drop "s" [r]; drop "c" []]);
    ("getdtablesize", unknown ~attrs:[KeepsSpecified] []);
    ("daemon", unknown ~attrs:[KeepsSpecified] [drop "nochdir" []; drop "noclose" []]);
    ("putw", unknown ~attrs:[KeepsSpecified] [drop "w" []; drop "stream" [r_deep; w_deep]]);
    (* RPC library start *)
    ("clntudp_create", unknown [drop "addr" [r]; drop "prognum" []; drop "versnum" []; drop "wait" [r]; drop "sockp" [w]]);
    ("clntudp_bufcreate", unknown [drop "addr" [r]; drop "prognum" []; drop "versnum" []; drop "wait" [r]; drop "sockp" [w]; drop "sendsize" []; drop "recosize" []]);
    ("svctcp_create", unknown [drop "sock" []; drop "send_buf_size" []; drop "recv_buf_size" []]);
    ("authunix_create_default", unknown []);
    ("clnt_broadcast", unknown [drop "prognum" []; drop "versnum" []; drop "procnum" []; drop "inproc" [r; c]; drop "in" [w]; drop "outproc" [r; c]; drop "out" [w]; drop "eachresult" [c]]);
    ("clnt_sperrno", unknown [drop "stat" []]);
    ("pmap_unset", unknown [drop "prognum" []; drop "versnum" []]);
    ("svcudp_create", unknown [drop "sock" []]);
    ("svc_register", unknown [drop "xprt" [r_deep; w_deep]; drop "prognum" []; drop "versnum" []; drop "dispatch" [r; w; c]; drop "protocol" []]);
    ("svc_run", unknown []); (* TODO: make new special kind "NoReturn" for this: the following node will be dead (like Abort), but the program doesn't exit (so it shouldn't be Abort) *)
    (* RPC library end *)
    ("getgrouplist", unknown ~attrs:[KeepsSpecified] [drop "user" [r]; drop "group" []; drop "groups" [w]; drop "ngroups" [r; w]]);
    ("innetgr", unknown ~attrs:[KeepsSpecified] [drop "netgroup" [r]; drop "host" [r]; drop "user" [r]; drop "domain" [r]]);
    ("lchmod", unknown ~attrs:[KeepsSpecified] [drop "path" [r]; drop "mode" []]);
    ("lseek64", unknown ~attrs:[KeepsSpecified] [drop "fd" []; drop "offset" []; drop "whence" []]);
    ("lutimes", unknown ~attrs:[KeepsSpecified] [drop "filename" [r]; drop "times" [r]]);
    ("mallinfo2", unknown ~attrs:[KeepsSpecified] []);
    ("strlcat", unknown ~attrs:[KeepsSpecified] [drop "dst" [r; w]; drop "src" [r]; drop "dstsize" []]);
    ("strlcpy", unknown ~attrs:[KeepsSpecified] [drop "dst" [w]; drop "src" [r]; drop "dstsize" []]);
    ("chroot", unknown ~attrs:[KeepsSpecified] [drop "path" [r]]);
    ("getpass", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "prompt" [r]]);
    ("setgroups", unknown ~attrs:[KeepsSpecified] [drop "size" []; drop "list" [r]]);
  ]
[@@coverage off]

(** Linux userspace functions.

    Every entry but [prctl], [ptrace], [ioctl] and the [fts_] functions has
    {!LibraryDesc.KeepsSpecified}. By the Linux man-pages, these keep a pointer
    derived from an argument after they return only where it is marked [k]:
    [epoll_ctl]'s [event], whose [data] [epoll_wait] returns. *)
let linux_userspace_descs_list: (string * LibraryDesc.t) list = LibraryDsl.[
    (* ("prctl", unknown [drop "option" []; drop "arg2" []; drop "arg3" []; drop "arg4" []; drop "arg5" []]); *)
    ("prctl", unknown (drop "option" [] :: VarArgs (drop' []))); (* man page has 5 arguments, but header has varargs and real-world programs may call with <5 *)
    ("__ctype_tolower_loc", unknown ~attrs:[KeepsSpecified] []);
    ("__ctype_toupper_loc", unknown ~attrs:[KeepsSpecified] []);
    ("endutxent", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] []);
    ("epoll_create", unknown ~attrs:[KeepsSpecified] [drop "size" []]);
    ("epoll_ctl", unknown ~attrs:[KeepsSpecified] [drop "epfd" []; drop "op" []; drop "fd" []; drop "event" [w; k_deep]]);
    ("epoll_wait", unknown ~attrs:[KeepsSpecified] [drop "epfd" []; drop "events" [w]; drop "maxevents" []; drop "timeout" []]);
    ("__error", unknown ~attrs:[KeepsSpecified] []);
    ("__errno", unknown ~attrs:[KeepsSpecified] []);
    ("__errno_location", unknown ~attrs:[KeepsSpecified] []);
    ("__h_errno_location", unknown ~attrs:[KeepsSpecified] []);
    ("__printf_chk", unknown ~attrs:[KeepsSpecified] (drop "flag" [] :: drop "format" [r] :: VarArgs (drop' [r])));
    ("__fprintf_chk", unknown ~attrs:[KeepsSpecified] (drop "stream" [r_deep; w_deep] :: drop "flag" [] :: drop "format" [r] :: VarArgs (drop' [r])));
    ("__vfprintf_chk", unknown ~attrs:[KeepsSpecified] [drop "stream" [r_deep; w_deep]; drop "flag" []; drop "format" [r]; drop "ap" [r_deep]]);
    ("sysinfo", unknown ~attrs:[KeepsSpecified] [drop "info" [w_deep]]);
    ("__xpg_basename", unknown ~attrs:[KeepsSpecified] [drop "path" [r]]);
    ("ptrace", unknown (drop "request" [] :: VarArgs (drop' [r_deep; w_deep]))); (* man page has 4 arguments, but header has varargs and real-world programs may call with <4 *)
    ("madvise", unknown ~attrs:[KeepsSpecified] [drop "addr" []; drop "length" []; drop "advice" []]);
    ("mremap", unknown ~attrs:[KeepsSpecified] (drop "old_address" [] :: drop "old_size" [] :: drop "new_size" [] :: drop "flags" [] :: VarArgs (drop "new_address" [])));
    ("msync", unknown ~attrs:[KeepsSpecified] [drop "addr" []; drop "len" []; drop "flags" []]);
    ("inotify_init1", unknown ~attrs:[KeepsSpecified] [drop "flags" []]);
    ("inotify_add_watch", unknown ~attrs:[KeepsSpecified] [drop "fd" []; drop "pathname" [r]; drop "mask" []]);
    ("inotify_rm_watch", unknown ~attrs:[KeepsSpecified] [drop "fd" []; drop "wd" []]);
    ("fts_open", unknown [drop "path_argv" [r_deep]; drop "options" []; drop "compar" [s]]); (* TODO: use Call instead of Spawn *)
    ("fts_read", unknown [drop "ftsp" [r_deep; w_deep]]);
    ("fts_close", unknown [drop "ftsp" [f_deep]]);
    ("mount", unknown ~attrs:[KeepsSpecified] [drop "source" [r]; drop "target" [r]; drop "filesystemtype" [r]; drop "mountflags" []; drop "data" [r]]);
    ("umount", unknown ~attrs:[KeepsSpecified] [drop "target" [r]]);
    ("umount2", unknown ~attrs:[KeepsSpecified] [drop "target" [r]; drop "flags" []]);
    ("statfs", unknown ~attrs:[KeepsSpecified] [drop "path" [r]; drop "buf" [w]]);
    ("fstatfs", unknown ~attrs:[KeepsSpecified] [drop "fd" []; drop "buf" [w]]);
    ("cfmakeraw", unknown ~attrs:[KeepsSpecified] [drop "termios" [r; w]]);
    ("process_vm_readv", unknown ~attrs:[KeepsSpecified] [drop "pid" []; drop "local_iov" [w_deep]; drop "liovcnt" []; drop "remote_iov" []; drop "riovcnt" []; drop "flags" []]);
    ("__libc_current_sigrtmax", unknown ~attrs:[KeepsSpecified] []);
    ("__libc_current_sigrtmin", unknown ~attrs:[KeepsSpecified] []);
    ("__xstat", unknown ~attrs:[KeepsSpecified] [drop "ver" []; drop "path" [r]; drop "stat_buf" [w]]);
    ("__lxstat", unknown ~attrs:[KeepsSpecified] [drop "ver" []; drop "path" [r]; drop "stat_buf" [w]]);
    ("__fxstat", unknown ~attrs:[KeepsSpecified] [drop "ver" []; drop "fildes" []; drop "stat_buf" [w]]);
    ("__ctype_b_loc", unknown ~attrs:[KeepsSpecified] []);
    ("_IO_getc", unknown ~attrs:[KeepsSpecified] [drop "f" [r_deep; w_deep]]);
    ("fallocate", unknown ~attrs:[KeepsSpecified] [drop "fd" []; drop "mode" []; drop "offset" []; drop "len" []]);
    ("ioctl", unknown (drop "fd" [] :: drop "request" [] :: VarArgs (drop' [r_deep; w_deep])));
  ]
[@@coverage off]

let big_kernel_lock = AddrOf (Cil.var (Cilfacade.create_var (makeGlobalVar "[big kernel lock]" voidType)))
let console_sem = AddrOf (Cil.var (Cilfacade.create_var (makeGlobalVar "[console semaphore]" voidType)))

(** Linux kernel functions. *)
let linux_kernel_descs_list: (string * LibraryDesc.t) list = LibraryDsl.[
    ("down_trylock", special [__ "sem" []] @@ fun sem -> Lock { lock = sem; try_ = true; write = true; return_on_success = true });
    ("down_read", special [__ "sem" []] @@ fun sem -> Lock { lock = sem; try_ = get_bool "sem.lock.fail"; write = false; return_on_success = true });
    ("down_write", special [__ "sem" []] @@ fun sem -> Lock { lock = sem; try_ = get_bool "sem.lock.fail"; write = true; return_on_success = true });
    ("up", special [__ "sem" []] @@ fun sem -> Unlock sem);
    ("up_read", special [__ "sem" []] @@ fun sem -> Unlock sem);
    ("up_write", special [__ "sem" []] @@ fun sem -> Unlock sem);
    ("mutex_init", unknown [drop "mutex" []]);
    ("__mutex_init", unknown [drop "lock" []; drop "name" [r]; drop "key" [r]]);
    ("mutex_lock", special [__ "lock" []] @@ fun lock -> Lock { lock = lock; try_ = get_bool "sem.lock.fail"; write = true; return_on_success = true });
    ("mutex_trylock", special [__ "lock" []] @@ fun lock -> Lock { lock = lock; try_ = true; write = true; return_on_success = true });
    ("mutex_lock_interruptible", special [__ "lock" []] @@ fun lock -> Lock { lock = lock; try_ = get_bool "sem.lock.fail"; write = true; return_on_success = true });
    ("mutex_unlock", special [__ "lock" []] @@ fun lock -> Unlock lock);
    ("spin_lock_init", unknown [drop "lock" []]);
    ("__spin_lock_init", unknown [drop "lock" []]);
    ("spin_lock", special [__ "lock" []] @@ fun lock -> Lock { lock = lock; try_ = get_bool "sem.lock.fail"; write = true; return_on_success = true });
    ("_spin_lock", special [__ "lock" []] @@ fun lock -> Lock { lock = lock; try_ = get_bool "sem.lock.fail"; write = true; return_on_success = true });
    ("_spin_lock_bh", special [__ "lock" []] @@ fun lock -> Lock { lock = lock; try_ = get_bool "sem.lock.fail"; write = true; return_on_success = true });
    ("spin_trylock", special [__ "lock" []] @@ fun lock -> Lock { lock = lock; try_ = true; write = true; return_on_success = true });
    ("_spin_trylock", special [__ "lock" []] @@ fun lock -> Lock { lock = lock; try_ = true; write = true; return_on_success = true });
    ("spin_unlock", special [__ "lock" []] @@ fun lock -> Unlock lock);
    ("_spin_unlock", special [__ "lock" []] @@ fun lock -> Unlock lock);
    ("_spin_unlock_bh", special [__ "lock" []] @@ fun lock -> Unlock lock);
    ("spin_lock_irqsave", special [__ "lock" []; drop "flags" []] @@ fun lock -> Lock { lock; try_ = get_bool "sem.lock.fail"; write = true; return_on_success = true });
    ("_spin_lock_irqsave", special [__ "lock" []] @@ fun lock -> Lock { lock; try_ = get_bool "sem.lock.fail"; write = true; return_on_success = true });
    ("_spin_trylock_irqsave", special [__ "lock" []; drop "flags" []] @@ fun lock -> Lock { lock; try_ = true; write = true; return_on_success = true });
    ("spin_unlock_irqrestore", special [__ "lock" []; drop "flags" []] @@ fun lock -> Unlock lock);
    ("_spin_unlock_irqrestore", special [__ "lock" []; drop "flags" []] @@ fun lock -> Unlock lock);
    ("raw_spin_unlock", special [__ "lock" []] @@ fun lock -> Unlock lock);
    ("_raw_spin_unlock_irqrestore", special [__ "lock" []; drop "flags" []] @@ fun lock -> Unlock lock);
    ("_raw_spin_lock", special [__ "lock" []] @@ fun lock -> Lock { lock = lock; try_ = get_bool "sem.lock.fail"; write = true; return_on_success = true });
    ("_raw_spin_lock_flags", special [__ "lock" []; drop "flags" []] @@ fun lock -> Lock { lock = lock; try_ = get_bool "sem.lock.fail"; write = true; return_on_success = true });
    ("_raw_spin_lock_irqsave", special [__ "lock" []] @@ fun lock -> Lock { lock = lock; try_ = get_bool "sem.lock.fail"; write = true; return_on_success = true });
    ("_raw_spin_lock_irq", special [__ "lock" []] @@ fun lock -> Lock { lock = lock; try_ = get_bool "sem.lock.fail"; write = true; return_on_success = true });
    ("_raw_spin_lock_bh", special [__ "lock" []] @@ fun lock -> Lock { lock = lock; try_ = get_bool "sem.lock.fail"; write = true; return_on_success = true });
    ("_raw_spin_unlock_bh", special [__ "lock" []] @@ fun lock -> Unlock lock);
    ("_read_lock", special [__ "lock" []] @@ fun lock -> Lock { lock = lock; try_ = get_bool "sem.lock.fail"; write = false; return_on_success = true });
    ("_read_unlock", special [__ "lock" []] @@ fun lock -> Unlock lock);
    ("_raw_read_lock", special [__ "lock" []] @@ fun lock -> Lock { lock = lock; try_ = get_bool "sem.lock.fail"; write = false; return_on_success = true });
    ("__raw_read_unlock", special [__ "lock" []] @@ fun lock -> Unlock lock);
    ("_write_lock", special [__ "lock" []] @@ fun lock -> Lock { lock = lock; try_ = get_bool "sem.lock.fail"; write = true; return_on_success = true });
    ("_write_unlock", special [__ "lock" []] @@ fun lock -> Unlock lock);
    ("_raw_write_lock", special [__ "lock" []] @@ fun lock -> Lock { lock = lock; try_ = get_bool "sem.lock.fail"; write = true; return_on_success = true });
    ("__raw_write_unlock", special [__ "lock" []] @@ fun lock -> Unlock lock);
    ("spinlock_check", special [__ "lock" []] @@ fun lock -> Identity lock);  (* Identity, because we don't want lock internals. *)
    ("_lock_kernel", special [drop "func" [r]; drop "file" [r]; drop "line" []] @@ Lock { lock = big_kernel_lock; try_ = false; write = true; return_on_success = true });
    ("_unlock_kernel", special [drop "func" [r]; drop "file" [r]; drop "line" []] @@ Unlock big_kernel_lock);
    ("acquire_console_sem", special [] @@ Lock { lock = console_sem; try_ = false; write = true; return_on_success = true });
    ("release_console_sem", special [] @@ Unlock console_sem);
    ("misc_deregister", unknown [drop "misc" [r_deep]]);
    ("__bad_percpu_size", special [] Abort); (* these do not have definitions so the linker will fail if they are actually called *)
    ("__bad_size_call_parameter", special [] Abort);
    ("__xchg_wrong_size", special [] Abort);
    ("__cmpxchg_wrong_size", special [] Abort);
    ("__xadd_wrong_size", special [] Abort);
    ("__put_user_bad", special [] Abort);
    ("kmalloc", special [__ "size" []; drop "flags" []] @@ fun size -> Malloc size);
    ("__kmalloc", special [__ "size" []; drop "flags" []] @@ fun size -> Malloc size);
    ("kzalloc", special [__ "size" []; drop "flags" []] @@ fun size -> Calloc {count = Cil.one; size});
    ("usb_alloc_urb", special [__ "iso_packets" []; drop "mem_flags" []] @@ fun iso_packets -> Malloc MyCFG.unknown_exp);
    ("usb_submit_urb", unknown [drop "urb" [r_deep; w_deep; c_deep]; drop "mem_flags" []]); (* old comment: first argument is written to but according to specification must not be read from anymore *)
    ("dev_driver_string", unknown [drop "dev" [r_deep]]);
    ("idr_pre_get", unknown [drop "idp" [r_deep]; drop "gfp_mask" []]);
    ("printk", unknown (drop "fmt" [r] :: VarArgs (drop' [r])));
    ("kmem_cache_create", unknown [drop "name" [r]; drop "size" []; drop "align" []; drop "flags" []; drop "ctor" [r; c]]);
  ]
[@@coverage off]

(** Goblint functions.

    Every entry has {!LibraryDesc.KeepsSpecified}; [__goblint_globalize] keeps
    [ptr], since it makes what [ptr] points to global. *)
let goblint_descs_list: (string * LibraryDesc.t) list = LibraryDsl.[
    ("__goblint_unknown", unknown ~attrs:[KeepsSpecified] [drop' [w]]);
    ("__goblint_check", special ~attrs:[KeepsSpecified] [__ "exp" []] @@ fun exp -> Assert { exp = stripOuterBoolCast exp; check = true; refine = false });
    ("__goblint_assume", special ~attrs:[KeepsSpecified] [__ "exp" []] @@ fun exp -> Assert { exp = stripOuterBoolCast exp; check = false; refine = true });
    ("__goblint_assert", special ~attrs:[KeepsSpecified] [__ "exp" []] @@ fun exp -> Assert { exp = stripOuterBoolCast exp; check = true; refine = get_bool "sem.assert.refine" });
    ("__goblint_globalize", special ~attrs:[KeepsSpecified] [__ "ptr" [k]] @@ fun ptr -> Globalize ptr);
    ("__goblint_split_begin", unknown ~attrs:[KeepsSpecified] [drop "exp" []]);
    ("__goblint_split_end", unknown ~attrs:[KeepsSpecified] [drop "exp" []]);
    ("__goblint_bounded", special ~attrs:[KeepsSpecified] [__ "exp"[]] @@ fun exp -> Bounded { exp });
    ("__goblint_assume_join", unknown ~attrs:[KeepsSpecified] [drop "tid" []]);
  ]
[@@coverage off]

(** zstd functions.
    Only used with extraspecials. *)
let zstd_descs_list: (string * LibraryDesc.t) list = LibraryDsl.[
    ("ZSTD_customMalloc", special [__ "size" []; drop "customMem" [r]] @@ fun size -> Malloc size);
    ("ZSTD_customCalloc", special [__ "size" []; drop "customMem" [r]] @@ fun size -> Calloc { size; count = Cil.one });
    ("ZSTD_customFree", special [__ "ptr" [f]; drop "customMem" [r]] @@ fun ptr -> Free ptr);
  ]
[@@coverage off]

(** math functions.
    Functions and builtin versions of function and macros defined in math.h.

    Every entry has {!LibraryDesc.KeepsSpecified}: none keeps a pointer
    derived from an argument. [nan] reads the string it is given, and [frexp],
    [modf] and [remquo] write through the pointer they are given. *)
let math_descs_list: (string * LibraryDesc.t) list = LibraryDsl.[
    ("__builtin_nan", special ~attrs:[KeepsSpecified] [__ "str" []] @@ fun str -> Math { fun_args = (Nan (FDouble, str)) });
    ("nan", special ~attrs:[KeepsSpecified] [__ "str" []] @@ fun str -> Math { fun_args = (Nan (FDouble, str)) });
    ("__builtin_nanf", special ~attrs:[KeepsSpecified] [__ "str" []] @@ fun str -> Math { fun_args = (Nan (FFloat, str)) });
    ("nanf", special ~attrs:[KeepsSpecified] [__ "str" []] @@ fun str -> Math { fun_args = (Nan (FFloat, str)) });
    ("__builtin_nanl", special ~attrs:[KeepsSpecified] [__ "str" []] @@ fun str -> Math { fun_args = (Nan (FLongDouble, str)) });
    ("nanl", special ~attrs:[KeepsSpecified] [__ "str" []] @@ fun str -> Math { fun_args = (Nan (FLongDouble, str)) });
    ("__builtin_inf", special ~attrs:[KeepsSpecified] [] @@ Math { fun_args = Inf FDouble});
    ("__builtin_huge_val", special ~attrs:[KeepsSpecified] [] @@ Math { fun_args = Inf FDouble}); (* we assume the target format can represent infinities *)
    ("__builtin_inff", special ~attrs:[KeepsSpecified] [] @@ Math { fun_args = Inf FFloat});
    ("__builtin_huge_valf", special ~attrs:[KeepsSpecified] [] @@ Math { fun_args = Inf FFloat}); (* we assume the target format can represent infinities *)
    ("__builtin_infl", special ~attrs:[KeepsSpecified] [] @@ Math { fun_args = Inf FLongDouble});
    ("__builtin_huge_vall", special ~attrs:[KeepsSpecified] [] @@ Math { fun_args = Inf FLongDouble});  (* we assume the target format can represent infinities *)
    ("__builtin_isfinite", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Isfinite x) });
    ("__finite", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Isfinite x) });
    ("__finitef", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Isfinite x) });
    ("__finitel", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Isfinite x) });
    ("__builtin_isinf", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Isinf x) });
    ("__isinf", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Isinf x) });
    ("__isinff", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Isinf x) });
    ("__isinfl", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Isinf x) });
    ("__builtin_isinf_sign", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Isinf x) });
    ("__builtin_isnan", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Isnan x) });
    ("__isnan", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Isnan x) });
    ("__isnanf", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Isnan x) });
    ("__isnanl", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Isnan x) });
    ("__builtin_isnormal", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Isnormal x) });
    ("__builtin_signbit", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Signbit x) });
    ("__signbit", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Signbit x) });
    ("__signbitf", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Signbit x) });
    ("__signbitl", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Signbit x) });
    ("__builtin_fabs", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Fabs (FDouble, x)) });
    ("__builtin_fabsf", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Fabs (FFloat, x)) });
    ("__builtin_fabsl", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Fabs (FLongDouble, x)) });
    ("__builtin_isgreater", special ~attrs:[KeepsSpecified] [__ "x" []; __ "y" []] @@ fun x y -> Math { fun_args = (Isgreater (x,y)) });
    ("__builtin_isgreaterequal", special ~attrs:[KeepsSpecified] [__ "x" []; __ "y" []] @@ fun x y -> Math { fun_args = (Isgreaterequal (x,y)) });
    ("__builtin_isless", special ~attrs:[KeepsSpecified] [__ "x" []; __ "y" []] @@ fun x y -> Math { fun_args = (Isless (x,y)) });
    ("__builtin_islessequal", special ~attrs:[KeepsSpecified] [__ "x" []; __ "y" []] @@ fun x y -> Math { fun_args = (Islessequal (x,y)) });
    ("__builtin_islessgreater", special ~attrs:[KeepsSpecified] [__ "x" []; __ "y" []] @@ fun x y -> Math { fun_args = (Islessgreater (x,y)) });
    ("__builtin_isunordered", special ~attrs:[KeepsSpecified] [__ "x" []; __ "y" []] @@ fun x y -> Math { fun_args = (Isunordered (x,y)) });
    ("ceil", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Ceil (FDouble, x)) });
    ("ceilf", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Ceil (FFloat, x)) });
    ("ceill", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Ceil (FLongDouble, x)) });
    ("floor", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Floor (FDouble, x)) });
    ("floorf", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Floor (FFloat, x)) });
    ("floorl", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Floor (FLongDouble, x)) });
    ("fabs", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Fabs (FDouble, x)) });
    ("fabsf", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Fabs (FFloat, x)) });
    ("fabsl", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Fabs (FLongDouble, x)) });
    ("fmax", special ~attrs:[KeepsSpecified] [__ "x" []; __ "y" []] @@ fun x y -> Math { fun_args = (Fmax (FDouble, x, y)) });
    ("fmaxf", special ~attrs:[KeepsSpecified] [__ "x" []; __ "y" []] @@ fun x y -> Math { fun_args = (Fmax (FFloat, x, y)) });
    ("fmaxl", special ~attrs:[KeepsSpecified] [__ "x" []; __ "y" []] @@ fun x y -> Math { fun_args = (Fmax (FLongDouble, x, y)) });
    ("fmin", special ~attrs:[KeepsSpecified] [__ "x" []; __ "y" []] @@ fun x y -> Math { fun_args = (Fmin (FDouble, x, y)) });
    ("fminf", special ~attrs:[KeepsSpecified] [__ "x" []; __ "y" []] @@ fun x y -> Math { fun_args = (Fmin (FFloat, x, y)) });
    ("fminl", special ~attrs:[KeepsSpecified] [__ "x" []; __ "y" []] @@ fun x y -> Math { fun_args = (Fmin (FLongDouble, x, y)) });
    ("__builtin_acos", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Acos (FDouble, x)) });
    ("acos", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Acos (FDouble, x)) });
    ("acosf", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Acos (FFloat, x)) });
    ("acosl", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Acos (FLongDouble, x)) });
    ("__builtin_asin", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Asin (FDouble, x)) });
    ("asin", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Asin (FDouble, x)) });
    ("asinf", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Asin (FFloat, x)) });
    ("asinl", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Asin (FLongDouble, x)) });
    ("__builtin_atan", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Atan (FDouble, x)) });
    ("atan", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Atan (FDouble, x)) });
    ("atanf", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Atan (FFloat, x)) });
    ("atanl", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Atan (FLongDouble, x)) });
    ("__builtin_atan2", special ~attrs:[KeepsSpecified] [__ "y" []; __ "x" []] @@ fun y x -> Math { fun_args = (Atan2 (FDouble, y, x)) });
    ("atan2", special ~attrs:[KeepsSpecified] [__ "y" []; __ "x" []] @@ fun y x -> Math { fun_args = (Atan2 (FDouble, y, x)) });
    ("atan2f", special ~attrs:[KeepsSpecified] [__ "y" []; __ "x" []] @@ fun y x -> Math { fun_args = (Atan2 (FFloat, y, x)) });
    ("atan2l", special ~attrs:[KeepsSpecified] [__ "y" []; __ "x" []] @@ fun y x -> Math { fun_args = (Atan2 (FLongDouble, y, x)) });
    ("__builtin_cos", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Cos (FDouble, x)) });
    ("cos", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Cos (FDouble, x)) });
    ("cosf", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Cos (FFloat, x)) });
    ("cosl", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Cos (FLongDouble, x)) });
    ("__builtin_sin", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Sin (FDouble, x)) });
    ("sin", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Sin (FDouble, x)) });
    ("sinf", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Sin (FFloat, x)) });
    ("sinl", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Sin (FLongDouble, x)) });
    ("__builtin_tan", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Tan (FDouble, x)) });
    ("tan", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Tan (FDouble, x)) });
    ("tanf", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Tan (FFloat, x)) });
    ("tanl", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Tan (FLongDouble, x)) });
    ("acosh", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("acoshf", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("acoshl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("asinh", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("asinhf", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("asinhl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("atanh", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("atanhf", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("atanhl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("cosh", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("coshf", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("coshl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("sinh", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("sinhf", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("sinhl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("tanh", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("tanhf", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("tanhl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("cbrt", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("cbrtf", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("cbrtl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("copysign", unknown ~attrs:[KeepsSpecified] [drop "x" []; drop "y" []]);
    ("copysignf", unknown ~attrs:[KeepsSpecified] [drop "x" []; drop "y" []]);
    ("copysignl", unknown ~attrs:[KeepsSpecified] [drop "x" []; drop "y" []]);
    ("erf", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("erff", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("erfl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("erfc", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("erfcf", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("erfcl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("exp", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("expf", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("expl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("exp2", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("exp2f", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("exp2l", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("expm1", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("expm1f", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("expm1l", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("fdim", unknown ~attrs:[KeepsSpecified] [drop "x" []; drop "y" []]);
    ("fdimf", unknown ~attrs:[KeepsSpecified] [drop "x" []; drop "y" []]);
    ("fdiml", unknown ~attrs:[KeepsSpecified] [drop "x" []; drop "y" []]);
    ("fma", unknown ~attrs:[KeepsSpecified] [drop "x" []; drop "y" []; drop "z" []]);
    ("fmaf", unknown ~attrs:[KeepsSpecified] [drop "x" []; drop "y" []; drop "z" []]);
    ("fmal", unknown ~attrs:[KeepsSpecified] [drop "x" []; drop "y" []; drop "z" []]);
    ("fmod", unknown ~attrs:[KeepsSpecified] [drop "x" []; drop "y" []]);
    ("fmodf", unknown ~attrs:[KeepsSpecified] [drop "x" []; drop "y" []]);
    ("fmodl", unknown ~attrs:[KeepsSpecified] [drop "x" []; drop "y" []]);
    ("frexp", unknown ~attrs:[KeepsSpecified] [drop "arg" []; drop "exp" [w]]);
    ("frexpf", unknown ~attrs:[KeepsSpecified] [drop "arg" []; drop "exp" [w]]);
    ("frexpl", unknown ~attrs:[KeepsSpecified] [drop "arg" []; drop "exp" [w]]);
    ("hypot", unknown ~attrs:[KeepsSpecified] [drop "x" []; drop "y" []]);
    ("hypotf", unknown ~attrs:[KeepsSpecified] [drop "x" []; drop "y" []]);
    ("hypotl", unknown ~attrs:[KeepsSpecified] [drop "x" []; drop "y" []]);
    ("ilogb", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("ilogbf", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("ilogbl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("ldexp", unknown ~attrs:[KeepsSpecified] [drop "arg" []; drop "exp" []]);
    ("ldexpf", unknown ~attrs:[KeepsSpecified] [drop "arg" []; drop "exp" []]);
    ("ldexpl", unknown ~attrs:[KeepsSpecified] [drop "arg" []; drop "exp" []]);
    ("lgamma", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "x" []]);
    ("lgammaf", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "x" []]);
    ("lgammal", unknown ~attrs:[KeepsSpecified; ThreadUnsafe] [drop "x" []]);
    ("log", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("logf", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("logl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("log10", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("log10f", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("log10l", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("log1p", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("log1pf", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("log1pl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("log2", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("log2f", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("log2l", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("logb", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("logbf", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("logbl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("rint", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("rintf", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("rintl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("lrint", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("lrintf", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("lrintl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("llrint", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("llrintf", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("llrintl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("round", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("roundf", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("roundl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("lround", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("lroundf", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("lroundl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("llround", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("llroundf", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("llroundl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("modf", unknown ~attrs:[KeepsSpecified] [drop "arg" []; drop "iptr" [w]]);
    ("modff", unknown ~attrs:[KeepsSpecified] [drop "arg" []; drop "iptr" [w]]);
    ("modfl", unknown ~attrs:[KeepsSpecified] [drop "arg" []; drop "iptr" [w]]);
    ("nearbyint", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("nearbyintf", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("nearbyintl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("nextafter", unknown ~attrs:[KeepsSpecified] [drop "from" []; drop "to" []]);
    ("nextafterf", unknown ~attrs:[KeepsSpecified] [drop "from" []; drop "to" []]);
    ("nextafterl", unknown ~attrs:[KeepsSpecified] [drop "from" []; drop "to" []]);
    ("nexttoward", unknown ~attrs:[KeepsSpecified] [drop "from" []; drop "to" []]);
    ("nexttowardf", unknown ~attrs:[KeepsSpecified] [drop "from" []; drop "to" []]);
    ("nexttowardl", unknown ~attrs:[KeepsSpecified] [drop "from" []; drop "to" []]);
    ("pow", unknown ~attrs:[KeepsSpecified] [drop "base" []; drop "exponent" []]);
    ("powf", unknown ~attrs:[KeepsSpecified] [drop "base" []; drop "exponent" []]);
    ("powl", unknown ~attrs:[KeepsSpecified] [drop "base" []; drop "exponent" []]);
    ("remainder", unknown ~attrs:[KeepsSpecified] [drop "x" []; drop "y" []]);
    ("remainderf", unknown ~attrs:[KeepsSpecified] [drop "x" []; drop "y" []]);
    ("remainderl", unknown ~attrs:[KeepsSpecified] [drop "x" []; drop "y" []]);
    ("remquo", unknown ~attrs:[KeepsSpecified] [drop "x" []; drop "y" []; drop "quo" [w]]);
    ("remquof", unknown ~attrs:[KeepsSpecified] [drop "x" []; drop "y" []; drop "quo" [w]]);
    ("remquol", unknown ~attrs:[KeepsSpecified] [drop "x" []; drop "y" []; drop "quo" [w]]);
    ("scalbn", unknown ~attrs:[KeepsSpecified] [drop "arg" []; drop "exp" []]);
    ("scalbnf", unknown ~attrs:[KeepsSpecified] [drop "arg" []; drop "exp" []]);
    ("scalbnl", unknown ~attrs:[KeepsSpecified] [drop "arg" []; drop "exp" []]);
    ("scalbln", unknown ~attrs:[KeepsSpecified] [drop "arg" []; drop "exp" []]);
    ("scalblnf", unknown ~attrs:[KeepsSpecified] [drop "arg" []; drop "exp" []]);
    ("scalblnl", unknown ~attrs:[KeepsSpecified] [drop "arg" []; drop "exp" []]);
    ("sqrt", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Sqrt (FDouble, x)) });
    ("sqrtf", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Sqrt (FFloat, x)) });
    ("sqrtl", special ~attrs:[KeepsSpecified] [__ "x" []] @@ fun x -> Math { fun_args = (Sqrt (FLongDouble, x)) });
    ("tgamma", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("tgammaf", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("tgammal", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("trunc", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("truncf", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("truncl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("j0", unknown ~attrs:[KeepsSpecified] [drop "x" []]); (* GNU C Library special function *)
    ("j1", unknown ~attrs:[KeepsSpecified] [drop "x" []]); (* GNU C Library special function *)
    ("jn", unknown ~attrs:[KeepsSpecified] [drop "n" []; drop "x" []]); (* GNU C Library special function *)
    ("y0", unknown ~attrs:[KeepsSpecified] [drop "x" []]); (* GNU C Library special function *)
    ("y1", unknown ~attrs:[KeepsSpecified] [drop "x" []]); (* GNU C Library special function *)
    ("yn", unknown ~attrs:[KeepsSpecified] [drop "n" []; drop "x" []]); (* GNU C Library special function *)
    ("fegetround", unknown ~attrs:[KeepsSpecified] []);
    ("fesetround", unknown ~attrs:[KeepsSpecified] [drop "round" []]); (* Our float domain is rounding agnostic *)
    ("__builtin_fpclassify", unknown ~attrs:[KeepsSpecified] [drop "nan" []; drop "infinite" []; drop "normal" []; drop "subnormal" []; drop "zero" []; drop "x" []]); (* TODO: We could do better here *)
    ("__builtin_fpclassifyf", unknown ~attrs:[KeepsSpecified] [drop "nan" []; drop "infinite" []; drop "normal" []; drop "subnormal" []; drop "zero" []; drop "x" []]);
    ("__builtin_fpclassifyl", unknown ~attrs:[KeepsSpecified] [drop "nan" []; drop "infinite" []; drop "normal" []; drop "subnormal" []; drop "zero" []; drop "x" []]);
    ("__fpclassify", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("__fpclassifyd", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("__fpclassifyf", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
    ("__fpclassifyl", unknown ~attrs:[KeepsSpecified] [drop "x" []]);
  ]
[@@coverage off]

let verifier_atomic_var = Cilfacade.create_var (makeGlobalVar "[__VERIFIER_atomic]" voidType)
let verifier_atomic = AddrOf (Cil.var (Cilfacade.create_var verifier_atomic_var))

(** SV-COMP functions.
    Just the ones that require special handling and cannot be stubbed.

    Every entry has {!LibraryDesc.KeepsSpecified}: none keeps a pointer
    derived from an argument. *)
let svcomp_descs_list: (string * LibraryDesc.t) list = LibraryDsl.[
    ("__VERIFIER_atomic_begin", special ~attrs:[KeepsSpecified] [] @@ Lock { lock = verifier_atomic; try_ = false; write = true; return_on_success = true });
    ("__VERIFIER_atomic_end", special ~attrs:[KeepsSpecified] [] @@ Unlock verifier_atomic);
    ("__VERIFIER_nondet_loff_t", unknown ~attrs:[KeepsSpecified] []); (* cannot give it in sv-comp.c without including stdlib or similar *)
    ("__VERIFIER_nondet_int", unknown ~attrs:[KeepsSpecified] []);  (* declare invalidate actions to prevent invalidating globals when extern in regression tests *)
    ("__VERIFIER_nondet_size_t", unknown ~attrs:[KeepsSpecified] []); (* cannot give it in sv-comp.c without including stdlib or similar *)
    ("__VERIFIER_nondet_memory", unknown ~attrs:[KeepsSpecified] [drop "mem" [w]; drop "size" []]); (* instead of using reference implementation from SV-COMP rules in sv-comp.c, this avoids supertop warnings *)
    ("__VERIFIER_assert", special ~attrs:[KeepsSpecified] [__ "exp" []] @@ fun exp -> Assert { exp; check = true; refine = get_bool "sem.assert.refine" }); (* only used if definition missing (e.g. in evalAssert transformed output) or extraspecial *)
    ("reach_error", special ~attrs:[KeepsSpecified] [] @@ Abort); (* only used if definition missing (e.g. in evalAssert transformed output) or extraspecial *)
  ]
[@@coverage off]

let rtnl_lock = AddrOf (Cil.var (Cilfacade.create_var (makeGlobalVar "[rtnl_lock]" voidType)))

(** LDV Klever functions. *)
let klever_descs_list: (string * LibraryDesc.t) list = LibraryDsl.[
    ("pthread_create_N", special [__ "thread" [w]; drop "attr" [r]; __ "start_routine" [s]; __ "arg" []] @@ fun thread start_routine arg -> ThreadCreate { thread; start_routine; arg; multiple = true });
    ("pthread_join_N", special [__ "thread" []; __ "retval" [w]] @@ fun thread retval -> ThreadJoin {thread; ret_var = retval});
    ("ldv_mutex_model_lock", special [__ "lock" []; drop "sign" []] @@ fun lock -> Lock { lock; try_ = get_bool "sem.lock.fail"; write = true; return_on_success = true });
    ("ldv_mutex_model_unlock", special [__ "lock" []; drop "sign" []] @@ fun lock -> Unlock lock);
    ("ldv_spin_model_lock", unknown [drop "sign" []]);
    ("ldv_spin_model_unlock", unknown [drop "sign" []]);
    ("rtnl_lock", special [] @@ Lock { lock = rtnl_lock; try_ = false; write = true; return_on_success = true });
    ("rtnl_unlock", special [] @@ Unlock rtnl_lock);
    ("__rtnl_unlock", special [] @@ Unlock rtnl_lock);
    (* ddverify *)
    ("sema_init", unknown [drop "sem" []; drop "val" []]);
  ]
[@@coverage off]

let ncurses_descs_list: (string * LibraryDesc.t) list = LibraryDsl.[
    ("echo", unknown []);
    ("noecho", unknown []);
    ("wattrset", unknown [drop "win" [r_deep; w_deep]; drop "attrs" []]);
    ("endwin", unknown []);
    ("wgetch", unknown [drop "win" [r_deep; w_deep]]);
    ("wget_wch", unknown [drop "win" [r_deep; w_deep]; drop "wch" [w]]);
    ("unget_wch", unknown [drop "wch" []]);
    ("wmove", unknown [drop "win" [r_deep; w_deep]; drop "y" []; drop "x" []]);
    ("waddch", unknown [drop "win" [r_deep; w_deep]; drop "ch" []]);
    ("waddnstr", unknown [drop "win" [r_deep; w_deep]; drop "str" [r]; drop "n" []]);
    ("waddnwstr", unknown [drop "win" [r_deep; w_deep]; drop "wstr" [r]; drop "n" []]);
    ("wattr_on", unknown [drop "win" [r_deep; w_deep]; drop "attrs" []; drop "opts" []]); (* opts argument currently not used *)
    ("wattr_off", unknown [drop "win" [r_deep; w_deep]; drop "attrs" []; drop "opts" []]); (* opts argument currently not used *)
    ("wrefresh", unknown [drop "win" [r_deep; w_deep]]);
    ("mvprintw", unknown (drop "win" [r_deep; w_deep] :: drop "y" [] :: drop "x" [] :: drop "fmt" [r] :: VarArgs (drop' [r])));
    ("initscr", unknown []);
    ("curs_set", unknown [drop "visibility" []]);
    ("wtimeout", unknown [drop "win" [r_deep; w_deep]; drop "delay" []]);
    ("start_color", unknown []);
    ("use_default_colors", unknown []);
    ("wclear", unknown [drop "win" [r_deep; w_deep]]);
    ("wclrtoeol", unknown [drop "win" [r_deep; w_deep]]);
    ("can_change_color", unknown []);
    ("init_color", unknown [drop "color" []; drop "red" []; drop "green" []; drop "blue" []]);
    ("init_pair", unknown [drop "pair" []; drop "f" [r]; drop "b" [r]]);
    ("wbkgd", unknown [drop "win" [r_deep; w_deep]; drop "ch" []]);
    ("keyname", unknown [drop "c" []]);
    ("newterm", unknown [drop "type" [r]; drop "outfd" [r_deep; w_deep]; drop "infd" [r_deep; w_deep]]);
    ("cbreak", unknown []);
    ("nonl", unknown []);
    ("keypad", unknown [drop "win" [r_deep; w_deep]; drop "bf" []]);
    ("set_escdelay", unknown [drop "size" []]);
    ("printw", unknown (drop "fmt" [r] :: VarArgs (drop' [r])));
    ("werase", unknown [drop "win" [r_deep; w_deep]]);
  ]
[@@coverage off]

let pcre_descs_list: (string * LibraryDesc.t) list = LibraryDsl.[
    ("pcre_compile", unknown [drop "pattern" [r]; drop "options" []; drop "errptr" [w]; drop "erroffset" [w]; drop "tableptr" [r]]);
    ("pcre_compile2", unknown [drop "pattern" [r]; drop "options" []; drop "errorcodeptr" [w]; drop "errptr" [w]; drop "erroffset" [w]; drop "tableptr" [r]]);
    ("pcre_config", unknown [drop "what" []; drop "where" [w]]);
    ("pcre_exec", unknown [drop "code" [r_deep]; drop "extra" [r_deep]; drop "subject" [r]; drop "length" []; drop "startoffset" []; drop "options" []; drop "ovector" [w]; drop "ovecsize" []]);
    ("pcre_study", unknown [drop "code" [r_deep]; drop "options" []; drop "errptr" [w]]);
    ("pcre_version", unknown []);
  ]
[@@coverage off]

let zlib_descs_list: (string * LibraryDesc.t) list = LibraryDsl.[
    ("inflate", unknown [drop "strm" [r_deep; w_deep]; drop "flush" []]);
    ("inflateInit2", unknown [drop "strm" [r_deep; w_deep]; drop "windowBits" []]);
    ("inflateInit2_", unknown [drop "strm" [r_deep; w_deep]; drop "windowBits" []; drop "version" [r]; drop "stream_size" []]);
    ("inflateEnd", unknown [drop "strm" [f_deep]]);
    ("deflate", unknown [drop "strm" [r_deep; w_deep]; drop "flush" []]);
    ("deflateInit2", unknown [drop "strm" [r_deep; w_deep]; drop "level" []; drop "method" []; drop "windowBits" []; drop "memLevel" []; drop "strategy" []]);
    ("deflateInit2_", unknown [drop "strm" [r_deep; w_deep]; drop "level" []; drop "method" []; drop "windowBits" []; drop "memLevel" []; drop "strategy" []; drop "version" [r]; drop "stream_size" []]);
    ("deflateEnd", unknown [drop "strm" [f_deep]]);
    ("zlibVersion", unknown []);
    ("zError", unknown [drop "err" []]);
    ("gzopen", unknown [drop "path" [r]; drop "mode" [r]]);
    ("gzdopen", unknown [drop "fd" []; drop "mode" [r]]);
    ("gzread", unknown [drop "file" [r_deep; w_deep]; drop "buf" [w]; drop "len" []]);
    ("gzclose", unknown [drop "file" [f_deep]]);
    ("uncompress", unknown [drop "dest" [w]; drop "destLen" [r; w]; drop "source" [r]; drop "sourceLen" []]);
    ("compress2", unknown [drop "dest" [w]; drop "destLen" [r; w]; drop "source" [r]; drop "sourceLen" []; drop "level" []]);
  ]
[@@coverage off]

let liblzma_descs_list: (string * LibraryDesc.t) list = LibraryDsl.[
    ("lzma_code", unknown [drop "strm" [r_deep; w_deep]; drop "action" []]);
    ("lzma_auto_decoder", unknown [drop "strm" [r_deep; w_deep]; drop "memlimit" []; drop "flags" []]);
    ("lzma_alone_decoder", unknown [drop "strm" [r_deep; w_deep]; drop "memlimit" []]);
    ("lzma_stream_decoder", unknown [drop "strm" [r_deep; w_deep]; drop "memlimit" []; drop "flags" []]);
    ("lzma_alone_encoder", unknown [drop "strm" [r_deep; w_deep]; drop "options" [r_deep]]);
    ("lzma_easy_encoder", unknown [drop "strm" [r_deep; w_deep]; drop "preset" []; drop "check" []]);
    ("lzma_end", unknown [drop "strm" [r_deep; w_deep; f_deep]]);
    ("lzma_version_string", unknown []);
    ("lzma_lzma_preset", unknown [drop "options" [w_deep]; drop "preset" []]);
  ]
[@@coverage off]

let legacy_libs_misc_list: (string * LibraryDesc.t) list = LibraryDsl.[
    ("__open_alias", unknown (drop "path" [r] :: drop "oflag" [] :: VarArgs (drop' [r])));
    ("__open_2", unknown [drop "file" [r]; drop "oflag" []]);
    ("__open_too_many_args", unknown []);
    (* bzlib *)
    ("BZ2_bzBuffToBuffCompress", unknown [drop "dest" [w]; drop "destLen" [r; w]; drop "source" [r]; drop "sourceLen" []; drop "blockSize100k" []; drop "verbosity" []; drop "workFactor" []]);
    ("BZ2_bzBuffToBuffDecompress", unknown [drop "dest" [w]; drop "destLen" [r; w]; drop "source" [r]; drop "sourceLen" []; drop "small" []; drop "verbosity" []]);
    (* opensssl blowfish *)
    ("BF_cfb64_encrypt", unknown [drop "in" [r]; drop "out" [w]; drop "length" []; drop "schedule" [r]; drop "ivec" [r; w]; drop "num" [r; w]; drop "enc" []]);
    ("BF_set_key", unknown [drop "key" [w]; drop "len" []; drop "data" [r]]);
    (* libintl *)
    ("textdomain", unknown [drop "domainname" [r]]);
    ("bindtextdomain", unknown [drop "domainname" [r]; drop "dirname" [r]]);
    ("dcgettext", unknown [drop "domainname" [r]; drop "msgid" [r]; drop "category" []]);
    (* TODO: the __extinline suffix was added by CIL in the old times in some cases, but is now switched off for like 10 years *)
    ("strtoul__extinline", unknown [drop "nptr" [r]; drop "endptr" [w]; drop "base" []]);
    ("atoi__extinline", unknown [drop "nptr" [r]]);
    ("stat__extinline", unknown [drop "pathname" [r]; drop "statbuf" [w]]);
    ("lstat__extinline", unknown [drop "pathname" [r]; drop "statbuf" [w]]);
    ("fstat__extinline", unknown [drop "fd" []; drop "buf" [w]]);
    (* only in knot *)
    ("PL_NewHashTable", unknown [drop "n" []; drop "keyHash" [r]; drop "keyCompare" [r]; drop "valueCompare" [r]; drop "allocOps" [r]; drop "allocPriv" [r]]); (* TODO: should have call instead of read *)
    ("assert_failed", unknown [drop "file" [r]; drop "line" []; drop "func" [r]; drop "exp" [r]]);
  ]
[@@coverage off]

let libraries = Hashtbl.of_list [
    ("c", c_descs_list @ math_descs_list);
    ("posix", posix_descs_list);
    ("pthread", pthread_descs_list);
    ("gcc", gcc_descs_list);
    ("glibc", glibc_desc_list);
    ("linux-userspace", linux_userspace_descs_list);
    ("linux-kernel", linux_kernel_descs_list);
    ("goblint", goblint_descs_list);
    ("sv-comp", svcomp_descs_list);
    ("klever", klever_descs_list);
    ("ncurses", ncurses_descs_list);
    ("zstd", zstd_descs_list);
    ("pcre", pcre_descs_list);
    ("zlib", zlib_descs_list);
    ("liblzma", liblzma_descs_list);
    ("legacy", legacy_libs_misc_list);
  ]

let libraries =
  Hashtbl.map (fun library descs_list ->
      let descs_tbl = Hashtbl.create 113 in
      List.iter (fun (name, desc) ->
          Hashtbl.modify_opt name (function
              | None -> Some desc
              | Some _ -> failwith (Format.sprintf "Library function %s specified multiple times in library %s" name library)
            ) descs_tbl
        ) descs_list;
      descs_tbl
    ) libraries

let _all_library_descs: (string, LibraryDesc.t) Hashtbl.t =
  Hashtbl.fold (fun _ descs_tbl acc ->
      Hashtbl.merge (fun name desc1 desc2 ->
          match desc1, desc2 with
          | Some _, Some _ -> failwith (Format.sprintf "Library function %s specified in multiple libraries" name)
          | (Some _ as desc), None
          | None, (Some _ as desc) -> desc
          | None, None -> assert false
        ) acc descs_tbl
    ) libraries (Hashtbl.create 0)

let activated_library_descs: (string, LibraryDesc.t) Hashtbl.t ResettableLazy.t =
  let union =
    Hashtbl.merge (fun _ desc1 desc2 ->
        match desc1, desc2 with
        | (Some _ as desc), None
        | None, (Some _ as desc) -> desc
        | _, _ -> assert false
      )
  in
  ResettableLazy.from_fun (fun () ->
      GobConfig.get_string_list "lib.activated"
      |> List.unique
      |> List.map (Hashtbl.find libraries)
      |> List.fold_left union (Hashtbl.create 0)
    )

let reset_lazy () =
  ResettableLazy.reset activated_library_descs

let lib_funs = ref (Set.String.of_list ["__raw_read_unlock"; "__raw_write_unlock"; "spin_trylock"])
let add_lib_funs funs = lib_funs := List.fold_left (Fun.flip Set.String.add) !lib_funs funs
let use_special fn_name = Set.String.mem fn_name !lib_funs

let kernel_safe_uncalled = Set.String.of_list ["__inittest"; "init_module"; "__exittest"; "cleanup_module"]
let kernel_safe_uncalled_regex = List.map Str.regexp ["__check_.*"]
let is_safe_uncalled fn_name =
  Set.String.mem fn_name kernel_safe_uncalled ||
  List.exists (fun r -> Str.string_match r fn_name 0) kernel_safe_uncalled_regex


let unknown_desc f ~nowarn : LibraryDesc.t =
  let accs args : (LibraryDesc.Access.t * 'a list) list = [
    ({ kind = Read; deep = true; }, if GobConfig.get_bool "sem.unknown_function.read.args" then args else []);
    ({ kind = Write; deep = true; }, if GobConfig.get_bool "sem.unknown_function.invalidate.args" then args else []);
    ({ kind = Free; deep = true; }, []); (* TODO: why no option? *)
    ({ kind = Call; deep = true; }, if get_bool "sem.unknown_function.call" then args else []);
    ({ kind = Spawn; deep = true; }, if get_bool "sem.unknown_function.spawn" then args else []);
  ]
  in
  let attrs: LibraryDesc.attr list =
    if GobConfig.get_bool "sem.unknown_function.invalidate.globals" then
      [InvalidateGlobals]
    else
      []
  in
  (* TODO: remove hack when all classify are migrated *)
  if not nowarn && not (CilType.Varinfo.equal f dummyFunDec.svar) && not (use_special f.vname) then (
    M.msg_final Error ~category:Imprecise ~tags:[Category Unsound] "Function definition missing";
    M.error ~category:Imprecise ~tags:[Category Unsound] "Function definition missing for %s" f.vname
  );
  {
    attrs;
    accs;
    special = fun _ -> Unknown;
  }

let find ?(nowarn=false) f =
  let name = f.vname in
  match Hashtbl.find_option (ResettableLazy.force activated_library_descs) name with
  | Some desc -> desc
  | None -> unknown_desc ~nowarn f

let is_special fv =
  if use_special fv.vname then
    true
  else
    match Cilfacade.find_varinfo_fundec fv with
    | _ -> false
    | exception Not_found -> true
