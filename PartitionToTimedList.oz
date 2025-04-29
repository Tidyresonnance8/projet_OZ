 
 functor
 import
    Project2025
    System
    Property
 export 
    partitionToTimedList: PartitionToTimedList
 define
    %helpers
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fun {IsNote Pi}
        case Pi of silence then true 
        [] Name#Octave then {Member Name [a b c d e f g]} 
        [] S then
            if {String.isAtom S} then 
                String_name = {Atom.toString Pi}
            in   
                case String_name of N|_ then {Member [N] ["a" "b" "c" "d" "e" "f" "g"]}  %car "a" --> [97] et donc utilisez {Member [N] ..}
                [] N then {Member [N] ["a" "b" "c" "d" "e" "f" "g"]}
                else 
                    false 
                end 
            else false end 
        end 
    end

    %helper pour determiner si une <partition> item est un accord
    fun {IsChord Pi}
        A = {NewCell false}
        fun {IsChordA Pi A}
            for N in Pi do 
                if {IsNote N} == false then A := false
                else A := true end 
            end
            @A
        end
    in
        if {Length Pi} == 1 then false 
        else {IsChordA Pi A} end  
    end

    %helper pour determiner si une <partition item> est une extended note 
    fun {IsExtendedNote Pi}
        case Pi of silence(duration:_) then true
        [] note(...) then true 
        else false end
    end

    %helper pour determiner si une <partition item> est un extended chord 
    fun {IsExtendedChord Pi}
        A = {NewCell false}
        fun {IsExtendedChordA Pi A}
            for N in Pi do 
                if {IsExtendedNote N} == false then A := false
                else A := true end 
            end
            @A
        end
    in
        if {Length Pi} == 1 then false 
        else {IsExtendedChordA Pi A} end  
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    % Translate a note to the extended notation.
    fun {NoteToExtended Note}
        case Note
        of nil then nil 
        [] note(...) then Note
        [] silence(duration: _) then Note
        [] silence then silence(duration:1.0)
        [] Name#Octave then note(name:Name octave:Octave sharp:true duration:1.0 instrument:none)
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

    % Translate chord to the extended notation
    fun {ChordToExtended Chord}
        A = {NewCell nil}
    in 
        if {IsChord Chord} then
            for Notes in Chord do 
                A := {NoteToExtended Notes}|@A
            end
            A := {Reverse @A}
            @A
        elseif Chord == nil then nil  
        else {Exception.failure failure(invalidChord:Chord)} end
    end

    %{Browse {ChordToExtended [a0 b#4 c#7]}}

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %helper--> a effacer avant de rendre
    /* 
    declare
    fun {IsNote Pi}
        case Pi of silence then true 
        [] Name#Octave then {Member Name [a b c d e f g]} 
        [] S then
            if {String.isAtom S} then 
                String_name = {Atom.toString Pi}
            in   
                case String_name of N|_ then {Member [N] ["a" "b" "c" "d" "e" "f" "g"]}  %car "a" --> [97] et donc utilisez {Member [N] ..}
                [] N then {Member [N] ["a" "b" "c" "d" "e" "f" "g"]}
                else 
                    false 
                end 
            else false end 
        end 
    end
    {Browse {IsNote c6}}
     
    declare
    fun {IsChord Pi}
        A = {NewCell false}
        fun {IsChordA Pi A}
            for N in Pi do 
                if {IsNote N} == false then A := false
                else A := true end 
            end
            @A
        end
    in
        if {Length Pi} == 1 then false 
        else {IsChordA Pi A} end  
    end
    Chord = [a0]
    {Browse {IsChord Chord}}
    declare
    fun {IsExtendedNote Pi}
        case Pi of silence(duration:_) then true
        [] note(...) then true 
        else false end
    end
    Extended_1 = note(name:a octave:6 sharp:true duration:1.0 instrument:none)
    Extended_2 = silence(duration: 3.0)
    {Browse {IsExtendedNote Extended_2}}
    declare
    fun {IsExtendedChord Pi}
        A = {NewCell false}
        fun {IsExtendedChordA Pi A}
            for N in Pi do 
                if {IsExtendedNote N} == false then A := false
                else A := true end 
            end
            @A
        end
    in
        if {Length Pi} == 1 then false 
        else {IsExtendedChordA Pi A} end  
    end
    
    Extended_1 = note(name:a octave:6 sharp:true duration:1.0 instrument:none)
    Extended_2 = note(name:b octave:6 sharp:true duration:1.0 instrument:none)
    Extended_3 = note(name:c octave:6 sharp:true duration:1.0 instrument:none)
    
    {Browse {IsExtendedChord [Extended_1]}}*/

    fun {PartitionToTimedList Partition}
        
        nil
    end
    
    fun {Duration Second Partition}
        TotalDuration = {NewCell 0.0}
        for I in Partition do
            if {IsList I} then
                case I of H|T then 
                    TotalDuration := @TotalDuration + H.duration
                else skip end
            else
                case I of note(duration:D) then
                    TotalDuration := @TotalDuration + D
                [] silence(duration:D) then
                    TotalDuration := @TotalDuration + D
                [] rest(duration:D) then
                    TotalDuration := @TotalDuration + D
                else skip end
            end
        end
        Ratio = if @TotalDuration == 0.0 then 1.0 else Second / @TotalDuration end
        NouvellePartition = {List.map  Partition fun {$ I} 
            if {IsList I} then
                case I of H|T then 
                    H.duration = H.duration * Ratio
                else skip end
            else
                case I of note(duration:D) then
                    I.duration = D * Ratio
                [] silence(duration:D) then
                    I.duration = D * Ratio
                [] rest(duration:D) then
                    I.duration = D * Ratio
                else skip end
            end}
        end
    in
        NouvellePartition
    end
    {Browse {Duration 2.0 [a0 b1 c#2 d#3 e silence]}}
    {Browse {Duration 2.0 [a0 b1 c#2 d#3 e silence]}}











       
    
    fun {Stretch Factor Partition}
        FlatList = {PartitionToTimedList Partition}
        Accumulator = nil
        for J in FlatList do
            case J of note(name:N octave:O sharp:S duration:D instrument:I) then
                Accumulator := note(name:N octave:O sharp:S duration:D*Factor instrument:I) | Accumulator
            [] silence(duration:D) then
                Accumulator := silence(duration:D*Factor) | Accumulator
            [] rest(duration:D) then
                Accumulator := rest(duration:D*Factor) | Accumulator
            [] ChordList then
                NewChordAccumulator = nil
                for chord in ChordList do
                    NewChordAccumulator := note(name:chord.name octave:chord.octave sharp:chord.sharp duration:chord.duration*Factor instrument:chord.instrument) | NewChordAccumulator
                end
                Accumulator :=  NewChordAccumulator | Accumulator
            end
        end
        {List.reverse Accumulator}
    end
    

    fun {Drone NoteOrChord Amount}
        fun {ExtendedSound N}
            case N of note(name:Name octave:Octave sharp:Sharp duration:Duration instrument:Instrument) then
                [note(name:Name octave:Octave sharp:Sharp duration:Duration instrument:Instrument)]
            [] silence(duration:D) then
                [silence(duration:D)]
            [] rest(duration:D) then
                {NoteToExtended rest(duration:D)}
            [] ChordList then
                NewChordAccumulator = {NewCell nil}
                for chord in ChordList do
                    NewChordAccumulator := note(name:chord.name octave:chord.octave sharp:chord.sharp duration:chord.duration instrument:chord.instrument) | @NewChordAccumulator
                end
                [{List.reverse @NewChordAccumulator}]
            end
        end
    
        
        fun {Repetition N X}
            if X == 0 then nil
            else N|{Repetition N X-1}
            end
        end
        SonEtendu = {ExtendedSound NoteOrChord}
    in 
        {Repetition SonEtendu Amount}
    end
    
    fun{Mute Amount}
        fun {MakeSilences N}
            if N == 0 then nil
            else silence(duration:1.0) | {MakeSilences N-1}
            end
        end
    in
        {MakeSilences Amount}
    end

    % convertissons un nom et un bool en index chromatique
    %fun {NoteToChromaticIndex Name Sharp}
       % case Name of a then 0
       % [] b then 2
        %[] c then 4
        %[] d then 5
        %[] e then 7
        %[] f then 9
        %[] g then 11
        %end + if Sharp == true then 1 else 0 end
    %end

    % convertissons un index chromatique en Name#sharp
    %fun {ChromaticIndexToNote Index Sharp}
     %   case Index of 0 then c#false
      %  [] 1 then c#true
      %  [] 2 then d#false
      %  [] 3 then d#true
      %  [] 4 then e#false
      %  [] 5 then f#false
      %  [] 6 then f#true
      %  [] 7 then g#false
      %  [] 8 then g#true
      %  [] 9 then a#false
      %  [] 10 then a#true
      %  [] 11 then b#false
      %  end + if Sharp == true then 1 else 0 end
    %end

    
    %fun{Transpose Semitones Partition}
     %   FlatList = {PartitionToTimedList Partition}
     %   local cellule in
     %       cellule = {NewCell nil}
      %      for I in FlatList do
      %          case I of note(...) then
      %              BaseIndex = {NoteToChromaticIndex I.name I.sharp}
      %              NewIndex = BaseIndex + Semitones
      %              if NewIndex < 0 then
       %                 NewIndex = 12 + NewIndex
        %            end
        %            if NewIndex > 11 then
        %                NewIndex = NewIndex - 12
        %            end
        %            I.name = {ChromaticIndexToNote NewIndex I.sharp}
        %            I.sharp = if NewIndex == 0 then false else true end
        %            I.duration = I.duration * Semitones
         %           I.instrument = I.instrument * Semitones
         %       [] silence(duration: _) then
         %           BaseIndex = {NoteToChromaticIndex I.name I.sharp}
          %          NewIndex = BaseIndex + Semitones
          %          if NewIndex < 0 then
          %              NewIndex = 12 + NewIndex
          %          end
          %          if NewIndex > 11 then
          %              NewIndex = NewIndex - 12
          %          end
          %          I.name = {ChromaticIndexToNote NewIndex I.sharp}
          %          I.sharp = if NewIndex == 0 then false else true end
          %      [] _|_ then
          %          if {IsNote I} == false then
          %              cellule := {NoteToExtended I} | @cellule
          %          end
          %      [] nil then
          %          cellule := nil | @cellule
          %      [] silence then
          %          cellule := silence(duration:1.0) | @cellule
          %      [] Name#Octave then
          %          cellule := note(name:Name octave:Octave sharp:true duration:1.0 instrument:none) | @cellule
          %      [] Atom then
          %          case {AtomToString Atom}
          %          of [_] then
          %              cellule := note(name:Atom octave:4 sharp:false duration:1.0 instrument:none) | @cellule
          %          [] [N O] then
          %              cellule := note(name:{StringToAtom [N]}
          %                  octave:{StringToInt [O]}
          %                  sharp:false
          %                  duration:1.0
          %                  instrument: none) | @cellule
          %          end
          %      end
          %  end

           % cellule := {Reverse @cellule}
           % @cellule
        %end
    %end