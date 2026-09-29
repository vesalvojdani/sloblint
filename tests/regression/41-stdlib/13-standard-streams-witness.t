No location invariant mentions f, g or the standard streams.

  $ goblint --enable witness.yaml.enabled --set witness.yaml.invariant-types '["location_invariant"]' 13-standard-streams-witness.c > /dev/null 2>&1
  $ yamlWitnessStrip < witness.yml | grep 'value:'
        value: x == 1
        value: x == 1
