# zig-turing
A Turing Machine implementation in Zig

## How to use

After building the executable, you can run it with the following command:

```bash
turing-zig <config_file>
```

Where `<config_file>` is a JSON file that contains the configuration of the Turing Machine. The configuration file is a JSON with the following entries:

* `states` is the number of states of the Turing Machine;
* `symbols` is the number of symbols of the Turing Machine;
* `rules` is a list of rules of the Turing Machine. Each rule is a JSON object with the following entries:
    * `state_in` is the state that the rule is applied to;
    * `symbol_in` is the symbol that the rule is applied to;
    * `state_out` is the state that the Turing Machine will go to;
    * `symbol_out` is the symbol that the Turing Machine will write;
    * `step` is the direction that the Turing Machine will move the head. It can be `LEFT`, `RIGHT` or `HALT` (to stop the Turing Machine);
* `starting_tape` is an array of symbols that represents the initial tape of the Turing Machine;
* `starting_tape_zero_index` is the index of the array above corresponding to the "zero" of the tape (aka, the starting position of the head). For example if `starting_tape = [0, 1, 0, 1]` and `starting_tape_zero_index = 1`, the tape will be `0 1 0 1` and the head will be pointing to the first `1`.	

Any tape cell that is not defined in the `starting_tape` array is initialized with the symbol `0`. The cursor always starts at the
position `0` of the tape, and in state `0`.

## Output

The machine will print out the tape and the state of the machine at each step. If the machine halts, it will print `HALT`. The tape is written as follows:

```
(-3) -> 1 1 1 1 [0]1 1  <- (2)
```

in which:
* the first number in parentheses is the starting index of the tape;
* the subsequent numbers are the symbols of the tape;
* the number preceded by the square brackets is the symbol under the head;
* the number inside the square brackets is the current state of the machine;
* the last number in parentheses is final index of the tape.