A va_list points to the arguments of the call, which no invariant may name:

  $ goblint --enable witness.yaml.enabled --set witness.yaml.invariant-types '["location_invariant"]' --enable ana.int.interval 80-va-list-invariant.c
  [Info][Assumption] va_arg reads one of the arguments passed in place of "...", at a type of the same kind (integer or pointer, floating-point, structure or union) (80-va-list-invariant.c:9:12-9:35)
  [Info][Assumption] va_arg reads one of the arguments passed in place of "...", at a type of the same kind (integer or pointer, floating-point, structure or union) (80-va-list-invariant.c:10:12-10:35)
  [Info][Assumption] va_arg reads one of the arguments passed in place of "...", at a type of the same kind (integer or pointer, floating-point, structure or union) (80-va-list-invariant.c:19:7-19:25)
  [Info][Deadcode] Logical lines of code (LLoC) summary:
    live: 17
    dead: 0
    total lines: 17
  [Info][Witness] witness generation summary:
    location invariants: 36
    loop invariants: 0
    flow-insensitive invariants: 0
    total generation entries: 1
  [Info][Assumption] va_arg reads one of the arguments passed in place of "...", at a type of the same kind (integer or pointer, floating-point, structure or union)
  $ yamlWitnessStrip < witness.yml
  - entry_type: invariant_set
    content:
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 8
          column: 2
          function: sum
        value: n == 2
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 9
          column: 3
          function: sum
        value: n == 2
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 10
          column: 3
          function: sum
        value: 3 <= x.a
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 10
          column: 3
          function: sum
        value: n == 2
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 10
          column: 3
          function: sum
        value: x.a <= 4
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 11
          column: 2
          function: sum
        value: 3 <= x.a
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 11
          column: 2
          function: sum
        value: 3 <= y.a
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 11
          column: 2
          function: sum
        value: n == 2
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 11
          column: 2
          function: sum
        value: x.a <= 4
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 11
          column: 2
          function: sum
        value: y.a <= 4
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 12
          column: 3
          function: sum
        value: 3 <= x.a
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 12
          column: 3
          function: sum
        value: 3 <= y.a
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 12
          column: 3
          function: sum
        value: n == 2
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 12
          column: 3
          function: sum
        value: x.a <= 4
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 12
          column: 3
          function: sum
        value: y.a <= 4
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 17
          column: 2
          function: first
        value: n == 2
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 18
          column: 3
          function: first
        value: n == 2
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 19
          column: 3
          function: first
        value: n == 2
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 20
          column: 2
          function: first
        value: 5 <= i
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 20
          column: 2
          function: first
        value: i <= 6
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 20
          column: 2
          function: first
        value: n == 2
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 21
          column: 3
          function: first
        value: 5 <= i
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 21
          column: 3
          function: first
        value: i <= 6
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 21
          column: 3
          function: first
        value: n == 2
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 26
          column: 3
          function: main
        value: x.a == 3
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 26
          column: 3
          function: main
        value: y.a == 4
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 27
          column: 3
          function: main
        value: 6 <= r
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 27
          column: 3
          function: main
        value: r <= 8
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 27
          column: 3
          function: main
        value: x.a == 3
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 27
          column: 3
          function: main
        value: y.a == 4
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 28
          column: 3
          function: main
        value: 6 <= f
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 28
          column: 3
          function: main
        value: 6 <= r
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 28
          column: 3
          function: main
        value: f <= 7
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 28
          column: 3
          function: main
        value: r <= 8
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 28
          column: 3
          function: main
        value: x.a == 3
        format: c_expression
    - invariant:
        type: location_invariant
        location:
          file_name: 80-va-list-invariant.c
          line: 28
          column: 3
          function: main
        value: y.a == 4
        format: c_expression
