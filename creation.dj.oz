local
    Tune = [e6 d6 a5 f5 d5 c6 b a#5 g g a#4 b]
    Refr_1 = [stretch(factor:0.5 [e6]) stretch(factor:0.15 [d6]) stretch(factor:0.5 [a5]) stretch(factor:0.45 [f5])
            stretch(factor:0.5 [e6]) stretch(factor:0.15 [d6]) stretch(factor:0.5 [a5]) stretch(factor:0.45 [f5])]
    Repeat_refr2 = repeat(amount:2 [partition(Refr_1)])
    Refr_2 = [stretch(factor:0.5 [c6]) stretch(factor:0.15 [a#5]) stretch(factor:0.5 [f5]) stretch(factor:0.45 [d5])
              stretch(factor:0.5 [c6]) stretch(factor:0.5 [a#5]) stretch(factor:0.6 [f5])
              stretch(factor:0.5 [a#5]) stretch(factor:0.15 [a5]) stretch(factor:0.5 [f5]) stretch(factor:0.45 [d5])
              stretch(factor:1.2 [a#4]) stretch(factor:0.5 [a]) stretch(factor:0.5 [a#4]) stretch(factor:0.5 [c5])
              stretch(factor:0.5 [d5]) stretch(factor:0.5 [e5]) stretch(factor:0.5 [f5]) stretch(factor:0.5 [g5]) 
              stretch(factor:0.5 [a5])]
    Partition_part1 = {Flatten Refr_1}
    Partition_part2 = {Flatten Refr_2}
    Chord1 = [d a d5 f5 a5]
    Chord2 = [g3 d g a#4 d5]
    Chord3 = [a#3 f a#4 d5]
    Chord4 = [a3 a c5 e5]

    ChordPart = [stretch(factor:2.4 [Chord1]) stretch(factor:2.4 [Chord2]) stretch(factor:2.4 [Chord3]) stretch(factor:2.4 [Chord4])
                stretch(factor:2.4 [Chord1]) stretch(factor:2.4 [Chord2]) stretch(factor:2.4 [Chord3]) stretch(factor:2.4 [Chord4])]
    Partition_part3 = {Flatten ChordPart}
in
    %
    [repeat(amount:2 [partition(Partition_part1) partition(Partition_part2)]) merge([0.125#[partition(Partition_part3)]])]
end