  $ goblint --enable warn.deterministic 35-union-members-race-type.c 2>&1 | grep -A 4 "Race\]"
  [Warning][Race] Memory location (struct A).x (race with conf. 100):
    write with thread:[main, t_fun@35-union-members-race-type.c:21:3-21:40] (conf. 100)  (exp: & tmp->x) (35-union-members-race-type.c:14:3-14:17)
    write with thread:[main], mhp:{created={[main, t_fun@35-union-members-race-type.c:21:3-21:40]}} (conf. 100)  (exp: & tmp->x) (35-union-members-race-type.c:22:3-22:17)
  [Warning][Race] Memory location u.a1.x (race with conf. 110): (35-union-members-race-type.c:9:10-9:11)
    write with thread:[main], mhp:{created={[main, t_fun@35-union-members-race-type.c:21:3-21:40]}} (conf. 100)  (exp: & tmp->x) (35-union-members-race-type.c:22:3-22:17)
    write with thread:[main, t_fun@35-union-members-race-type.c:21:3-21:40] (conf. 110)  (exp: & u.a1.x) (35-union-members-race-type.c:15:3-15:13)
  [Warning][Race] Memory location u.a2.x (race with conf. 110): (35-union-members-race-type.c:9:10-9:11)
    write with thread:[main, t_fun@35-union-members-race-type.c:21:3-21:40] (conf. 100)  (exp: & tmp->x) (35-union-members-race-type.c:14:3-14:17)
    write with thread:[main], mhp:{created={[main, t_fun@35-union-members-race-type.c:21:3-21:40]}} (conf. 100)  (exp: & tmp->x) (35-union-members-race-type.c:22:3-22:17)
    write with thread:[main, t_fun@35-union-members-race-type.c:21:3-21:40] (conf. 110)  (exp: & u.a1.x) (35-union-members-race-type.c:15:3-15:13)
    write with thread:[main], mhp:{created={[main, t_fun@35-union-members-race-type.c:21:3-21:40]}} (conf. 110)  (exp: & u.a2.x) (35-union-members-race-type.c:23:3-23:13)
  [Info][Race] Memory locations race summary:
    safe: 0
    vulnerable: 0
    unsafe: 3
    total memory locations: 3
