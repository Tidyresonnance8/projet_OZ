functor
import
   Project2025
   Mix
   OS
   System
   Property
   PartitionToTimedList
export
   test: Test
define
   PassedTests = {Cell.new 0}
   TotalTests  = {Cell.new 0}

   FiveSamples = 0.00011337868 % Duration to have only five samples

   % Takes a list of samples, round them to 4 decimal places and multiply them by
   % 10000. Use this to compare list of samples to avoid floating-point rounding
   % errors.
   fun {Normalize Samples}
      {Map Samples fun {$ S} {IntToFloat {FloatToInt S*10000.0}} end}
   end

   proc {Assert Cond Msg}
      TotalTests := @TotalTests + 1
      if {Not Cond} then
         {System.show Msg}
      else
         PassedTests := @PassedTests + 1
      end
   end

   proc {AssertEquals A E Msg}
      TotalTests := @TotalTests + 1
      if A \= E then
         {System.show Msg}
         {System.show actual(A)}
         {System.show expect(E)}
      else
         PassedTests := @PassedTests + 1
      end
   end

   fun {NoteToExtended Note}
      case Note
      of note(...) then
         Note
      [] silence(duration: _) then
         Note
      [] _|_ then
         {Map Note NoteToExtended}
      [] nil then
         nil
      [] silence then
         silence(duration:1.0)
      [] Name#Octave then
         note(name:Name octave:Octave sharp:true duration:1.0 instrument:none)
      [] Atom then
         case {AtomToString Atom}
         of [_] then
            note(name:Atom octave:4 sharp:false duration:1.0 instrument:none)
         [] [N O] then
            note(name:{StringToAtom [N]}
               octave:{StringToInt [O]}
               sharp:false
               duration:1.0
               instrument: none)
         end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % TEST PartitionToTimedNotes

   proc {TestNotes P2T}
      %test valid notes
      P1 = [a0 b1 c#2 d#3 e silence]
      E1 = {Map P1 NoteToExtended}
      P2 = [e6 d5 c#4 g#3 e silence]
      E2 = {Map P2 NoteToExtended}
      P3 = [f g a b silence]
      E3 = {Map P3 NoteToExtended}
      P4 = [f#5 g#4 a#2 b silence]
      E4 = {Map P4 NoteToExtended}
   in
      {AssertEquals {P2T P1} E1 "TestNotes"}
      {AssertEquals {P2T P2} E2 "TestNotes"}
      {AssertEquals {P2T P3} E3 "TestNotes"}
      {AssertEquals {P2T P4} E4 "TestNotes"}
      
   end

   proc {TestChords P2T}
      Cmin4 = [c d#4 g]
      Cmaj4 = [c e g]
      Dmin5 = [d5 f5 a5]
      DSharpmin = [d#5 f#5 a#5]
      P2 = [Cmin4 Cmaj4 Dmin5 DSharpmin]
      E2 = {Map P2 PartitionToTimedList.chordToExtended}

   in
      {AssertEquals {P2T P2} E2 "TestChords"}
      
   end

   proc {TestIdentity P2T} 
      % test that extended notes and chord go from input to output unchanged

      %test pour extended notes:
      Note_1 = note(name:a octave:4 sharp:false duration:1.0 instrument:none)
      Note_2 = note(name:b octave:5 sharp:false duration:1.0 instrument:none)
      Note_3 = note(name:c octave:5 sharp:true duration:1.0 instrument:none)

      Extended_notesPartition = [Note_1 Note_2 Note_3]

      %test pour extended chords 
      Note_4 = note(name:f octave:5 sharp:true duration:1.0 instrument:none)
      Note_5 = note(name:g octave:5 sharp:false duration:1.0 instrument:none)

      Extended_chordsPartition = [[Note_2 Note_3 Note_1] [Note_5 Note_4 Note_1] [Note_4 Note_2 Note_5]]

      %test melange 

      ExtendedPartition = [Note_1 [Note_2 Note_3 Note_1] Note_3 [Note_5 Note_4 Note_1] Note_2 [Note_4 Note_2 Note_5] silence(duration:1.0)]
   in 
      {AssertEquals {P2T Extended_notesPartition} Extended_notesPartition "TestIdentity"}
      {AssertEquals {P2T Extended_chordsPartition} Extended_chordsPartition "TestIdentity"}
      {AssertEquals {P2T ExtendedPartition} ExtendedPartition "TestIdentity"}

   end

   proc {TestDuration P2T}
      % test de duration sur plusieurs notes
      P1 = [duration(second:6.0 [a0 b0 c0])]
      E1 = [note(name:a octave:0 sharp:false duration:2.0 instrument:none)
            note(name:b octave:0 sharp:false duration:2.0 instrument:none)
            note(name:c octave:0 sharp:false duration:2.0 instrument:none)]
      % test de duration sur une note
      P2 = [duration(second:3.0 [c])]
      E2 = [note(name:c octave:4 sharp:false duration:3.0 instrument:none)]
      % test de duration avec silence
      P3 = [duration(second:2.0 [a4 silence])]
      E3 = [note(name:a octave:4 sharp:false duration:1.0 instrument:none)
            silence(duration:1.0)]
      % test de duration sur un accord
      P4 = [duration(second:4.0 [[a b]])]
      E4 = [[note(name:a octave:4 sharp:false duration:4.0 instrument:none)
            note(name:b octave:4 sharp:false duration:4.0 instrument:none)]]
   in
      {AssertEquals {P2T P1} E1 "TestDuration"}
      {AssertEquals {P2T P2} E2 "TestDuration"}
      {AssertEquals {P2T P3} E3 "TestDuration"}
      {AssertEquals {P2T P4} E4 "TestDuration"} 
   end

   proc {TestStretch P2T}
      % test de stretch sur deux note
      P1 = [stretch(factor:3.0 [a0 b0])]
      E1 = [note(name:a octave:0 sharp:false duration:3.0 instrument:none)
            note(name:b octave:0 sharp:false duration:3.0 instrument:none)]
      % test de stretch sur une note
      P2 = [stretch(factor:2.0 [c])]
      E2 = [note(name:c octave:4 sharp:false duration:2.0 instrument:none)]
      % test de stretch sur plusieurs notes déjà prolongées
      P3 = [stretch(factor:1.5 [note(name:a octave:4 sharp:false duration:1.0 instrument:none) note(name:b octave:4 sharp:false duration:2.0 instrument:none)])]
      E3 = [note(name:a octave:4 sharp:false duration:1.5 instrument:none)
            note(name:b octave:4 sharp:false duration:3.0 instrument:none)]
      % test de stretch sur un accord
      P4 = [stretch(factor:2.0 [note(name:a octave:4 sharp:false duration:1.0 instrument:none) note(name:b octave:4 sharp:false duration:1.0 instrument:none)])]   
      E4 = [note(name:a octave:4 sharp:false duration:2.0 instrument:none)
            note(name:b octave:4 sharp:false duration:2.0 instrument:none)]
   in
      {AssertEquals {P2T P1} E1 "TestStretch"}
      {AssertEquals {P2T P2} E2 "TestStretch"}
      {AssertEquals {P2T P3} E3 "TestStretch"}
      {AssertEquals {P2T P4} E4 "TestStretch"}  
   end

   proc {TestDrone P2T}
      % test de drone sur une note
      P1 = [drone(sound:c amount:2)]
      E1 = [note(name:c octave:4 sharp:false duration:1.0 instrument:none)
            note(name:c octave:4 sharp:false duration:1.0 instrument:none)]
      % test de drone avec un silence
      P2 = [drone(sound:d amount:2) silence(duration:2.0)]
      E2 = [note(name:d octave:4 sharp:false duration:1.0 instrument:none) note(name:d octave:4 sharp:false duration:1.0 instrument:none)
            silence(duration:2.0)]
      % test de drone avec une note dièse
      P3 = [drone(sound:c#4 amount:2)]
      E3 = [note(name:c octave:4 sharp:true duration:1.0 instrument:none)
            note(name:c octave:4 sharp:true duration:1.0 instrument:none)]
      % test de drone sur drone
      P4 = [drone(sound:e amount:2) drone(sound:d amount:3)]
      E4 = [note(name:e octave:4 sharp:false duration:1.0 instrument:none) note(name:e octave:4 sharp:false duration:1.0 instrument:none)
            note(name:d octave:4 sharp:false duration:1.0 instrument:none) note(name:d octave:4 sharp:false duration:1.0 instrument:none) 
            note(name:d octave:4 sharp:false duration:1.0 instrument:none)]
      
      %test de drone sur un accord 
      Cmaj4 = [c e g]
      P5 = [drone(sound:Cmaj4 amount:3)]
      E5 = [[note(name:c octave:4 sharp:false duration:1.0 instrument:none) 
            note(name:e octave:4 sharp:false duration:1.0 instrument:none) 
            note(name:g octave:4 sharp:false duration:1.0 instrument:none)]
            [note(name:c octave:4 sharp:false duration:1.0 instrument:none) 
            note(name:e octave:4 sharp:false duration:1.0 instrument:none) 
            note(name:g octave:4 sharp:false duration:1.0 instrument:none)]
            [note(name:c octave:4 sharp:false duration:1.0 instrument:none) 
            note(name:e octave:4 sharp:false duration:1.0 instrument:none) 
            note(name:g octave:4 sharp:false duration:1.0 instrument:none)]]
   in
      {AssertEquals {P2T P1} E1 "TestDrone"}
      {AssertEquals {P2T P2} E2 "TestDrone"}
      {AssertEquals {P2T P3} E3 "TestDrone"}
      {AssertEquals {P2T P4} E4 "TestDrone"}
      {AssertEquals {P2T P5} E5 "TestDrone"}
   end

   proc {TestMute P2T}
      % test de mute sur une note
      P1 = [c mute(amount:1) d]
      E1 = [note(name:c octave:4 sharp:false duration:1.0 instrument:none)
            silence(duration:1.0)
            note(name:d octave:4 sharp:false duration:1.0 instrument:none)]
      % on mute sur plusieurs notes
      P2 = [a mute(amount:3) b]
      E2 = [note(name:a octave:4 sharp:false duration:1.0 instrument:none)
            silence(duration:1.0)
            silence(duration:1.0)
            silence(duration:1.0)
            note(name:b octave:4 sharp:false duration:1.0 instrument:none)]
      % on mute seul dans une partition
      P3 = [mute(amount:2)]
      E = [silence(duration:1.0) silence(duration:1.0)]
      % on  mute à l'intérieur d'une transformation duration
      P4 = [duration(second:2.0 [a mute(amount:2)])]
      E4 = [note(name:a octave:4 sharp:false duration:(2.0/3.0) instrument:none)
            silence(duration:(2.0/3.0)) silence(duration:(2.0/3.0))]
   in
      {AssertEquals {P2T P1} E1 "TestMute"}
      {AssertEquals {P2T P2} E2 "TestMute"}
      {AssertEquals {P2T P3} E "TestMute"}
      {AssertEquals {P2T P4} E4 "TestMute"}
   end

   proc {TestTranspose P2T}
      %test pour partition contenue juste de extended_notes et la transposition n'augmente pas l'octave
      Note_1 = note(name:a octave:4 sharp:false duration:1.0 instrument:none)
      Note_2 = note(name:g octave:5 sharp:false duration:1.0 instrument:none)
      Note_3 = note(name:c octave:5 sharp:true duration:1.0 instrument:none)
      Original_part = [Note_1 Note_2 Note_3]

      %Note transpose de 2 semi
      Transp_part1 = {P2T [transpose(semi:2 Original_part)]}
      Note_1_t = note(name:b octave:4 sharp:false duration:1.0 instrument:none)
      Note_2_t = note(name:a octave:5 sharp:false duration:1.0 instrument:none)
      Note_3_t = note(name:d octave:5 sharp:true duration:1.0 instrument:none)
      Transp_part1_check = [Note_1_t Note_2_t Note_3_t]

      %Note transpose de -2
      Transp_part2 = {P2T [transpose(semi:~2 Original_part)]}
      Note_1_t2 = note(name:g octave:4 sharp:false duration:1.0 instrument:none)
      Note_2_t2 = note(name:f octave:5 sharp:false duration:1.0 instrument:none)
      Note_3_t2 = note(name:b octave:4 sharp:false duration:1.0 instrument:none)
      Transp_part2_check2 = [Note_1_t2 Note_2_t2 Note_3_t2]

      %test pour voir si toute les notes possibles son transpose d'une octave vers le haut
      Transp_part3 = {P2T [transpose(semi:12 [c c#4 d d#4 e f f#4 g g#4 a a#4 b])]}
      Transp_part3_check3 = [note(name:c octave:5 sharp:false duration:1.0 instrument:none) 
      note(name:c octave:5 sharp:true duration:1.0 instrument:none) note(name:d octave:5 sharp:false duration:1.0 instrument:none)
      note(name:d octave:5 sharp:true duration:1.0 instrument:none) note(name:e octave:5 sharp:false duration:1.0 instrument:none)
      note(name:f octave:5 sharp:false duration:1.0 instrument:none) note(name:f octave:5 sharp:true duration:1.0 instrument:none)
      note(name:g octave:5 sharp:false duration:1.0 instrument:none) note(name:g octave:5 sharp:true duration:1.0 instrument:none)
      note(name:a octave:5 sharp:false duration:1.0 instrument:none) note(name:a octave:5 sharp:true duration:1.0 instrument:none) note(name:b octave:5 sharp:false duration:1.0 instrument:none)]

      %test pour voir si toute les notes possibles son transpose de 4 octave vers le haut
      Transp_part4 = {P2T [transpose(semi:48 [c c#4 d d#4 e f f#4 g g#4 a a#4 b])]}
      Transp_part4_check4 = [note(name:c octave:8 sharp:false duration:1.0 instrument:none) 
      note(name:c octave:8 sharp:true duration:1.0 instrument:none) note(name:d octave:8 sharp:false duration:1.0 instrument:none)
      note(name:d octave:8 sharp:true duration:1.0 instrument:none) note(name:e octave:8 sharp:false duration:1.0 instrument:none)
      note(name:f octave:8 sharp:false duration:1.0 instrument:none) note(name:f octave:8 sharp:true duration:1.0 instrument:none)
      note(name:g octave:8 sharp:false duration:1.0 instrument:none) note(name:g octave:8 sharp:true duration:1.0 instrument:none)
      note(name:a octave:8 sharp:false duration:1.0 instrument:none) note(name:a octave:8 sharp:true duration:1.0 instrument:none) 
      note(name:b octave:8 sharp:false duration:1.0 instrument:none)]

      %test pour voir si toute les notes possibles son transpose d'une octave vers le bas
      Transp_part6 = {P2T [transpose(semi:~12 [c c#4 d d#4 e f f#4 g g#4 a a#4 b])]}
      Transp_part6_check6 = [note(name:c octave:3 sharp:false duration:1.0 instrument:none) 
      note(name:c octave:3 sharp:true duration:1.0 instrument:none) note(name:d octave:3 sharp:false duration:1.0 instrument:none)
      note(name:d octave:3 sharp:true duration:1.0 instrument:none) note(name:e octave:3 sharp:false duration:1.0 instrument:none)
      note(name:f octave:3 sharp:false duration:1.0 instrument:none) note(name:f octave:3 sharp:true duration:1.0 instrument:none)
      note(name:g octave:3 sharp:false duration:1.0 instrument:none) note(name:g octave:3 sharp:true duration:1.0 instrument:none)
      note(name:a octave:3 sharp:false duration:1.0 instrument:none) note(name:a octave:3 sharp:true duration:1.0 instrument:none) note(name:b octave:3 sharp:false duration:1.0 instrument:none)]

      %test pour voir si toute les notes possibles son transpose de 4 octave vers le bas
      Transp_part7 = {P2T [transpose(semi:~48 [c c#4 d d#4 e f f#4 g g#4 a a#4 b])]}
      Transp_part7_check7 = [note(name:c octave:0 sharp:false duration:1.0 instrument:none) 
      note(name:c octave:0 sharp:true duration:1.0 instrument:none) note(name:d octave:0 sharp:false duration:1.0 instrument:none)
      note(name:d octave:0 sharp:true duration:1.0 instrument:none) note(name:e octave:0 sharp:false duration:1.0 instrument:none)
      note(name:f octave:0 sharp:false duration:1.0 instrument:none) note(name:f octave:0 sharp:true duration:1.0 instrument:none)
      note(name:g octave:0 sharp:false duration:1.0 instrument:none) note(name:g octave:0 sharp:true duration:1.0 instrument:none)
      note(name:a octave:0 sharp:false duration:1.0 instrument:none) note(name:a octave:0 sharp:true duration:1.0 instrument:none) 
      note(name:b octave:0 sharp:false duration:1.0 instrument:none)]

      %test tranpose sur partition d'un accord simple
      Transp_part5 = {P2T [transpose(semi:2 [[note(name:c octave:4 sharp:false duration:1.0 instrument:none) 
      note(name:d octave:4 sharp:true duration:1.0 instrument:none) note(name:g octave:4 sharp:false duration:1.0 instrument:none)]])]} 
      Transp_part5_check5 = [[note(name:d octave:4 sharp:false duration:1.0 instrument:none) 
      note(name:f octave:4 sharp:false duration:1.0 instrument:none) 
      note(name:a octave:4 sharp:false duration:1.0 instrument:none)]]

   in
      {AssertEquals Transp_part1 Transp_part1_check "Test_transpose"}
      {AssertEquals Transp_part2 Transp_part2_check2 "Test_transpose"}
      {AssertEquals Transp_part3 Transp_part3_check3 "Test_transpose"}
      {AssertEquals Transp_part4 Transp_part4_check4 "Test_transpose"}
      {AssertEquals Transp_part5 Transp_part5_check5 "Test_transpose"}
      {AssertEquals Transp_part6 Transp_part6_check6 "Test_transpose"}
      {AssertEquals Transp_part7 Transp_part7_check7 "Test_transpose"}
      
   end

   proc {TestP2TChaining P2T}
      %test avec toute les transformations possibles:
      %Test simples
      Note_1 = note(name:a octave:4 sharp:false duration:1.0 instrument:none)
      Note_2 = note(name:b octave:5 sharp:false duration:1.0 instrument:none)
      Note_3 = note(name:c octave:5 sharp:false duration:1.0 instrument:none)

      Note_1_c = note(name:a octave:4 sharp:false duration:1.0 instrument:none)
      Note_2_c = note(name:g octave:5 sharp:false duration:1.0 instrument:none)
      Note_3_c = note(name:c octave:5 sharp:true duration:1.0 instrument:none)
      Original_part = [Note_1_c Note_2_c Note_3_c]
      
   
   
      P1 = [a b5 c5 [a b5 c5] silence duration(second:6.0 [a0 b0 c0]) stretch(factor:3.0 [a0 b0]) drone(sound:c#4 amount:2) mute(amount:3) transpose(semi:2 Original_part)]
      E1 = [Note_1 Note_2 Note_3 [Note_1 Note_2 Note_3] silence(duration:1.0) note(name:a octave:0 sharp:false duration:2.0 instrument:none)
      note(name:b octave:0 sharp:false duration:2.0 instrument:none) note(name:c octave:0 sharp:false duration:2.0 instrument:none) 
      note(name:a octave:0 sharp:false duration:3.0 instrument:none) note(name:b octave:0 sharp:false duration:3.0 instrument:none)
      note(name:c octave:4 sharp:true duration:1.0 instrument:none) note(name:c octave:4 sharp:true duration:1.0 instrument:none)
      silence(duration:1.0)
      silence(duration:1.0)
      silence(duration:1.0)
      note(name:b octave:4 sharp:false duration:1.0 instrument:none)
      note(name:a octave:5 sharp:false duration:1.0 instrument:none)
      note(name:d octave:5 sharp:true duration:1.0 instrument:none)]
   in
      {AssertEquals {P2T P1} E1 "testP2Tchaining"}

   end

   proc {TestEmptyChords P2T}
     skip
   end
      
   proc {TestP2T P2T}
      {TestNotes P2T}
      {TestChords P2T}
      {TestIdentity P2T}
      {TestDuration P2T} 
      {TestStretch P2T} 
      {TestDrone P2T} 
      {TestMute P2T} 
      {TestTranspose P2T}
      {TestP2TChaining P2T}
      {TestEmptyChords P2T}   
      {AssertEquals {P2T nil} nil 'nil partition'}
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % TEST Mix

   proc {TestSamples P2T Mix}
      E1 = [0.1 ~0.2 0.3]
      M1 = [samples(E1)]
   in
      {AssertEquals {Mix P2T M1} E1 'TestSamples: simple'}
   end
   
   proc {TestPartition P2T Mixarg}
      %Test 1
      %File1 = "wave/partition.wav"
      M1 = [partition([g])]
      Mixed1 = {Mixarg P2T M1}
      %A = {Project2025.run Mix P2T M1 File1} 
      %B = {Project2025.readFile File1} %A mettre dans le rapport "erreur sur comparaison de float meme avec normalize"
      
      %Test 2 +longue partition
      M2 = [partition([a5 b6 c7 g#5 f#5 d d#2 g e0 f#3 c#2 a#4 f])]
      Mixed2 = {Mixarg P2T M2}

      %Test 3 partition avec accord
      Cmin4 = [c d#4 g]
      Cmaj4 = [c e g]
      Dmin5 = [d5 f5 a5]
      DSharpmin = [d#5 f#5 a#5]
      P2 = [Cmin4 Cmaj4 Dmin5 DSharpmin]

      M3 = [partition(P2)]
      Mixed3 = {Mixarg P2T M3}

      %Test 4 partition avec transformations
      P3 = [duration(second:2.0 [a mute(amount:2)]) transpose(semi:12 [c c#4 d d#4 e f f#4 g g#4 a a#4 b]) drone(sound:e amount:2) drone(sound:d amount:3)]
      M4 = [partition(P3)]
      Mixed4 = {Mixarg P2T M4}
      
   in 
      %{AssertEquals A ok "ok"}
      {AssertEquals {Normalize Mixed1} {Normalize {Mix.echsPartition [g] P2T}} 'TestPartition: simple'}
      {AssertEquals {Normalize Mixed2} {Normalize {Mix.echsPartition [a5 b6 c7 g#5 f#5 d d#2 g e0 f#3 c#2 a#4 f] P2T}} 'TestPartition: longue'}
      {AssertEquals {Normalize Mixed3} {Normalize {Mix.echsPartition P2 P2T}} 'TestPartition: longue'}
      {AssertEquals {Normalize Mixed4} {Normalize {Mix.echsPartition P3 P2T}} 'TestPartition: transformations'}
      
   end
   
   proc {TestWave P2T Mix}
      
      File1 = "wave/test.wav"
      A = {Project2025.writeFile File1 [0.1 ~0.2 0.3]}
      S1 = {Mix P2T [wave(File1)]}
      %S2 = {Project2025.load CWD#}

      File2 = "wave/test2.wav"
      B = {Project2025.writeFile File2 [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9]}
      S2 = {Mix P2T [wave(File2)]}
      %S2 = {Project2025.readFile CWD#'wave/test2.wav'}

   in  
      {AssertEquals A ok "ok"}
      {AssertEquals B ok "ok"}
      {AssertEquals {Normalize S1} {Normalize [0.1 ~0.2 0.3]} 'TestWave'}
      {AssertEquals {Normalize S2} {Normalize [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9]} 'TestWave'}
   end

   proc {TestMerge P2T Mix} %
      %test avec Intensite au dessus de 1.0
      %teste avec samples de meme taille
      M1 = [0.1 0.2 ~0.3 0.4]
      MWI_1 = 2.0#[samples(M1)]
      MWI_2 = 0.5#[samples(M1)]
      MWI_3 = 1.0#[samples(M1)]
      Arg = [merge([MWI_1 MWI_2 MWI_3])]

      %Car clip au dessus de 1.0 et en dessous de ~1.0
      E1 = [0.35 0.7 ~1.0 1.0]

      %test sans clips M1 = [0.1 0.2 ~0.3 0.4]
      M2 = [0.01 0.02 ~0.03 0.04]
      MWI2_1 = 2.0#[samples(M2)]
      MWI2_2 = 0.5#[samples(M2)]
      MWI2_3 = 1.0#[samples(M2)]
      Arg2 = [merge([MWI2_1 MWI2_2 MWI2_3])]

      E2 = [0.035 0.07 ~0.105 0.14]

      %test avec intensite compris entre 0 et 1
      MWI3_1 = 0.75#[samples(M2)]
      MWI3_2 = 0.5#[samples(M2)]
      MWI3_3 = 1.0#[samples(M2)]
      Arg3 = [merge([MWI3_1 MWI3_2 MWI3_3])]

      E3 = [0.0225 0.045 ~0.0675 0.09]

      %test avec samples de taille taille differente 
      M3 = [0.01 0.02 ~0.03 0.04 0.05 0.01]
      M4 = [0.01 0.02 ~0.03 0.04 0.0 ~0.4 0.06 0.07]

      MWI4_1 = 0.75#[samples(M2)]
      MWI4_2 = 0.5#[samples(M3)]
      MWI4_3 = 1.0#[samples(M4)]
      Arg4 = [merge([MWI4_1 MWI4_2 MWI4_3])]

      E4 = [0.0225 0.045 ~0.0675 0.09 0.025 ~0.395 0.06 0.07]
   in
      {AssertEquals {Normalize {Mix P2T Arg}} {Normalize E1} "testMerge"}
      {AssertEquals {Normalize {Mix P2T Arg2}} {Normalize E2} "testMerge"}
      {AssertEquals {Normalize {Mix P2T Arg3}} {Normalize E3} "testMerge"}
      {AssertEquals {Normalize {Mix P2T Arg4}} {Normalize E4} "testMerge"}

   end

   proc {TestReverse P2T Mix}
      skip

   end

   proc {TestRepeat P2T Mix}
      %Répétition normale 3 fois
      M1 = [0.1 0.2 ~0.3]
      Arg1 = [repeat(amount:3 music:[samples(M1)])]
      E1 = [0.1 0.2 ~0.3 0.1 0.2 ~0.3 0.1 0.2 ~0.3]

      % Répétition avec un seul échantillon
      M2 = [0.5]
      Arg2 = [repeat(amount:4 music:[samples(M2)])]
      E2 = [0.5 0.5 0.5 0.5]

      %pour une liste vide
      M3 = nil
      Arg3 = [repeat(amount:5 music:[samples(M3)])]
      E3 = nil

      %répétition pour un grand nombre d'échantillons
      %M4 = [1.0 ~1.0]
      %Arg4 = [repeat(amount:1000 music:[samples(M4)])]
      %E4 = {Flatten {List.make 1000 M4}}

      %Echantillon avec valeurs limites
      M5 = [1.0 ~1.0 0.0]
      Arg5 = [repeat(amount:2 music:[samples(M5)])]
      E5 = {Append M5 M5}
   in
      {AssertEquals {Normalize {Mix P2T Arg1}} {Normalize E1} "testRepeat"}
      %{AssertEquals {Normalize {Mix P2T Arg2}} {Normalize E2} "testRepeat"}
      %{AssertEquals {Normalize {Mix P2T Arg3}} {Normalize E3} "testRepeat"}
      %{Assert {IsList {Mix P2T Arg4}} "TestRepeat 4"}
      %{AssertEquals {Normalize {Mix P2T Arg5}} {Normalize E5} "testRepeat"}

   end

   proc {TestLoop P2T Mix} %
      %Loop pour duree 2*taille M1
      M1 = [0.1 0.2 ~0.3 0.4 0.5]
      M_1 = [samples(M1)]

      Arg = [loop(seconds:2.0*FiveSamples M_1)]

      E1 = [0.1 0.2 ~0.3 0.4 0.5 0.1 0.2 ~0.3 0.4 0.5]

      %Loop pour duree 3*taille M1
   
      Arg2 = [loop(seconds:3.0*FiveSamples M_1)]

      E2 = [0.1 0.2 ~0.3 0.4 0.5 0.1 0.2 ~0.3 0.4 0.5 0.1 0.2 ~0.3 0.4 0.5]

      %Loop avec tronquations
      M3 = [0.1 0.2 ~0.3 0.4 0.5 0.1 0.2 ~0.3 0.4 0.5]
      M_3 = [samples(M3)]

      Arg3 = [loop(seconds:0.5*(2.0*FiveSamples) M_3)]

      E3 = [0.1 0.2 ~0.3 0.4 0.5]

      %Loop avec Partition 
      Arg4 = [loop(seconds:4.0 [partition([a b])])]
      S = {Mix P2T Arg4}
      E_len = (44100*2)*2
      A_len = {Length S}

      %Loop avec Partition tronque 
      Arg5 = [loop(seconds:1.0 [partition([a b])])]
      S1 = {Mix P2T Arg5}
      E_len1 = 44100
      A_len1 = {Length S1}
   
   in 
      {AssertEquals {Normalize {Mix P2T Arg}} {Normalize E1} "testLoop"}
      {AssertEquals {Normalize {Mix P2T Arg2}} {Normalize E2} "testLoop"}
      {AssertEquals {Normalize {Mix P2T Arg3}} {Normalize E3} "testLoop"}
      {AssertEquals A_len E_len "testLoop"}
      {AssertEquals A_len1 E_len1 "testLoop"}
      
   end

   proc {TestClip P2T Mix} %
      %test avec clip positive 
      M1 = [0.1 0.2 ~0.3 0.4 0.5]
      M_1 = [samples(M1)]

      Arg = [clip(low:0.1 high:0.2 M_1)]

      E1 = [0.1 0.2 0.1 0.2 0.2]

      %test avec clip negative
      Arg2 = [clip(low:~1.0 high:~0.2 M_1)]

      E2 = [~0.2 ~0.2 ~0.3 ~0.2 ~0.2]

      %test avec low > high
      Arg3 = [clip(low:1.0 high:~0.2 M_1)]

      %test avec samples au dessus des limites d'echantillons 
      M2 = [1.5 ~1.5 6.0 ~6.0]
      M_2 = [samples(M2)]
      Arg4 = [clip(low:~1.0 high:1.0 M_2)]
      E3 = [1.0 ~1.0 1.0 ~1.0]
   in
      {AssertEquals {Normalize {Mix P2T Arg}} {Normalize E1} "testClip"}
      {AssertEquals {Normalize {Mix P2T Arg2}} {Normalize E2} "testClip"}
      {AssertEquals {Normalize {Mix P2T Arg3}} {Normalize M1} "testClip"}
      {AssertEquals {Normalize {Mix P2T Arg4}} {Normalize E3} "testClip"}

   end

   proc {TestEcho P2T Mix} %
      %Avec repeat de 2 
      Original = [samples([0.1 0.1 0.1 0.1])]
      Echo1 = [samples([0.0 0.1 0.1 0.1 0.1])]
      Echo2 = [samples([0.0 0.0 0.1 0.1 0.1 0.1])]

      Arg1 = [echo(delay:(1.0/44100.0) decay:0.9 repeat:2 Original)]
      E1 = {Mix P2T [merge([1.0#Original 0.9#Echo1 0.81#Echo2])]}

      %Avec repeat de 3
      Echo3 = [samples([0.0 0.0 0.0 0.1 0.1 0.1 0.1])] 
      Arg2 = [echo(delay:(1.0/44100.0) decay:0.9 repeat:3 Original)]

      E2 = {Mix P2T [merge([1.0#Original 0.9#Echo1 0.81#Echo2 0.729#Echo3])]}

   in 
      {AssertEquals {Normalize {Mix P2T Arg1}} {Normalize E1} "testEcho"}
      {AssertEquals {Normalize {Mix P2T Arg2}} {Normalize E2} "testEcho"}
   end

   proc {TestFade P2T Mix}
      skip
   end

   proc {TestCut P2T Mix}
      skip
   end

   proc {TestMix P2T Mix}
      %{TestSamples P2T Mix}
      %{TestPartition P2T Mix}
      %{TestWave P2T Mix}
      %{TestMerge P2T Mix}
      {TestRepeat P2T Mix}
      %{TestLoop P2T Mix}
      %{TestClip P2T Mix}
      %{TestEcho P2T Mix}
      %{TestFade P2T Mix}
      %{TestCut P2T Mix}
      {AssertEquals {Mix P2T nil} nil 'nil music'}
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   proc {Test Mix P2T}
      {Property.put print print(width:100)}
      {Property.put print print(depth:100)}
      {System.show 'tests have started'}
      {TestP2T P2T}
      {System.show 'P2T tests have run'}
      {TestMix P2T Mix}
      {System.show 'Mix tests have run'}
      {System.show test(passed:@PassedTests total:@TotalTests)}
   end
end