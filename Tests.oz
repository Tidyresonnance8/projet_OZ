functor
import
   Project2025
   Mix
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
      P1 = [duration(second:6.0 partition:[a0 b0 c0])]
      E1 = [note(name:a octave:0 sharp:false duration:2.0 instrument:none)
            note(name:b octave:0 sharp:false duration:2.0 instrument:none)
            note(name:c octave:0 sharp:false duration:2.0 instrument:none)]
      % test de duration sur une note
      P2 = [duration(second:3.0 partition:[c])]
      E2 = [note(name:c octave:4 sharp:false duration:3.0 instrument:none)]
      % test de duration avec silence
      P3 = [duration(second:2.0 partition:[a4 silence])]
      E3 = [note(name:a octave:4 sharp:false duration:1.0 instrument:none)
            silence(duration:1.0)]
      % test de duration sur un accord
      P4 = [duration(second:4.0 partition:[a b])]
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
      P1 = [stretch(factor:3.0 partition:[a0 b0])]
      E1 = [note(name:a octave:0 sharp:false duration:3.0 instrument:none)
            note(name:b octave:0 sharp:false duration:3.0 instrument:none)]
      % test de stretch sur une note
      P2 = [stretch(factor:2.0 partition:[c])]
      E2 = [note(name:c octave:4 sharp:false duration:2.0 instrument:none)]
      % test de stretch sur plusieurs notes déjà prolongées
      P3 = [stretch(factor:1.5 partition:[note(name:a octave:4 sharp:false duration:1.0 instrument:none)
            note(name:b octave:4 sharp:false duration:2.0 instrument:none)])]
      E3 = [note(name:a octave:4 sharp:false duration:1.5 instrument:none)
            note(name:b octave:4 sharp:false duration:3.0 instrument:none)]
      % test de stretch sur un accord
      P4 = [stretch(factor:2.0 partition:[note(name:a octave:4 sharp:false duration:1.0 instrument:none)
            note(name:b octave:4 sharp:false duration:1.0 instrument:none)])]   
      E4 = [[note(name:a octave:4 sharp:false duration:2.0 instrument:none)
            note(name:b octave:4 sharp:false duration:2.0 instrument:none)]]
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
            note(name:e octave:4 sharp:false duration:1.0 instrument:none)
            note(name:g octave:4 sharp:false duration:1.0 instrument:none)]
      % test de drone avec un silence
      P2 = [drone(sound:d amount:1) silence(duration:2.0)]
      E2 = [[note(name:d octave:4 sharp:false duration:1.0 instrument:none)
            note(name:f# octave:4 sharp:false duration:1.0 instrument:none)]
            silence(duration:2.0)]
      % test de drone avec une note dièse
      P3 = [drone(sound:c# amount:1)]
      E3 = [[note(name:c# octave:4 sharp:true duration:1.0 instrument:none)
            note(name:e octave:4 sharp:false duration:1.0 instrument:none)]]
      % test de drone sur drone
      P4 = [drone(sound:e amount:1) drone(sound:d amount:0)]
      E4 = [[note(name:e octave:4 sharp:false duration:1.0 instrument:none)
            note(name:g octave:4 sharp:false duration:1.0 instrument:none)]
            [note(name:d octave:4 sharp:false duration:1.0 instrument:none)]]
   in
      {AssertEquals {P2T P1} E1 "TestDrone"}
      {AssertEquals {P2T P2} E2 "TestDrone"}
      {AssertEquals {P2T P3} E3 "TestDrone"}
      {AssertEquals {P2T P4} E4 "TestDrone"}
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
      P4 = [duration(second:2.0 partition:[a mute(amount:2)])]
      E4 = [note(name:a octave:4 sharp:false duration:2.0 instrument:none)
            silence(duration:2.0) silence(duration:2.0)]
   in
      {AssertEquals {P2T P1} E1 "TestMute"}
      {AssertEquals {P2T P2} E2 "TestMute"}
      {AssertEquals {P2T P3} E "TestMute"}
      {AssertEquals {P2T P4} E4 "TestMute"}
   end

   proc {TestTranspose P2T}
      skip
   end

   proc {TestP2TChaining P2T}
      skip
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
   
   proc {TestPartition P2T Mix}
      skip
   end
   
   proc {TestWave P2T Mix}
      skip
   end

   proc {TestMerge P2T Mix}
      skip
   end

   proc {TestReverse P2T Mix}
      skip
   end

   proc {TestRepeat P2T Mix}
      skip
   end

   proc {TestLoop P2T Mix}
      skip
   end

   proc {TestClip P2T Mix}
      skip
   end

   proc {TestEcho P2T Mix}
      skip
   end

   proc {TestFade P2T Mix}
      skip
   end

   proc {TestCut P2T Mix}
      skip
   end

   proc {TestMix P2T Mix}
      {TestSamples P2T Mix}
      {TestPartition P2T Mix}
      {TestWave P2T Mix}
      {TestMerge P2T Mix}
      {TestRepeat P2T Mix}
      {TestLoop P2T Mix}
      {TestClip P2T Mix}
      {TestEcho P2T Mix}
      {TestFade P2T Mix}
      {TestCut P2T Mix}
      {AssertEquals {Mix P2T nil} nil 'nil music'}
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   proc {Test Mix P2T}
      {Property.put print print(width:100)}
      {Property.put print print(depth:100)}
      {System.show 'tests have started'}
      {TestP2T P2T}
      {System.show 'P2T tests have run'}
      %{TestMix P2T Mix}
      %{System.show 'Mix tests have run'}
      {System.show test(passed:@PassedTests total:@TotalTests)}
   end
end