
functor
import
    Project2025
    System
    Property
export
    isNote: IsNote
    isChord: IsChord
    isExtendedNote: IsExtendedNote
    isExtendedChord: IsExtendedChord
    noteToExtended: NoteToExtended
    chordToExtended: ChordToExtended
    partitionToTimedList: PartitionToTimedList
    transpose: Transpose
    duration: Duration
    stretch: Stretch
    drone: Drone
    mute: Mute
    
define
    %helpers
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %declare
    fun {IsNote Pi}
        case Pi of silence then true
        [] silence(...) then true
        [] note(...) then true 
        [] H | T then false 
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

    %helper pour determiner si les notes d'un accord on toute les meme duree
    fun {ExtendedChordTime Pi}
        A = {NewCell false}
        B = {NewCell true}
        Prev_duration = {NewCell 0}
        proc {ExtendedChordTimeA Pi}
            case Pi of nil then A := true
            [] note(name:N octave:O sharp:Sharp duration:Duration instrument:Instrument)|P then Prev_duration := Duration
            end 

            for N in Pi do 
                case N of note(name:N octave:O sharp:Sharp duration:Duration instrument:Instrument) andthen Duration == @Prev_duration then A:= true 
                else B:= false end  
            end 
        end
    in 
        nil
    end 
            
                
    
    %helper pour determiner si une <partition> item est un accord
    fun {IsChord Pi}
        A = {NewCell false}
        B = {NewCell true}
        proc {IsChordA Pi}
            for N in Pi do 
                if {IsNote N} == false then B := false
                else A := true end 
            end
            
        end
    in
        {IsChordA Pi}
        if {Length Pi} == 1 then false  
        elseif @B == false then false
        else true end
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
        B = {NewCell true}
        proc {IsExtendedChordA Pi}
            for N in Pi do 
                if {IsExtendedNote N} == false then B := false
                else A := true end 
            end
        end
    in
        case Pi of note(...) then false
        else 
            {IsExtendedChordA Pi}
            if {Length Pi} =< 1 then false
            elseif {ExtendedChordTime Pi} == false then false
            elseif @B == false then false
            else true end
        end  
    end

    %helper pour changer la duration d'un accord

    fun {ChangeDChord EChord Ratio}
        case EChord of nil then nil 
        [] note(name:Note octave:O sharp:Bol duration:D instrument:I)|Ns then 
            note(name:Note octave:O sharp:Bol duration:D*Ratio instrument:I)|{ChangeDChord Ns Ratio}
        end 
    end 

    %Helper pour determiner la duration totale d'une Flat partition

    fun {TotalDuration Fp}
        fun {TotalDurationA Fp A}
            case Fp of nil then A 
            [] silence(duration:D)|Pi then {TotalDurationA Pi A+D}
            [] note(name:Note octave:O sharp:Bol duration:D instrument:I)|Pi then {TotalDurationA Pi A+D}
            %case ou on a un accord  
            [] L|Pi andthen {IsExtendedChord L} == true then {TotalDurationA Pi A+{TotalDurationChord L}}
            else 0.0 end 
        end 
    in 
        {TotalDurationA Fp 0.0}
    end

    %Helper pour determiner la duration d'un accord

    fun {TotalDurationChord EChord}
        case EChord of nil then 0.0 
        [] note(name:Note octave:O sharp:Bol duration:D instrument:I)|_ then D %car toutes les notes dans 1 accord on la meme duration
        end 
    end

    %Helper pour convertir une note en int equivalent
    
    fun {MapNote Note Sharp}
        case Note#Sharp of c#false then 0
        [] c#true then 100
        [] d#false then 200
        [] d#true then 300
        [] e#false then 400
        [] f#false then 500
        [] f#true then 600
        [] g#false then 700
        [] g#true then 800
        [] a#false then 900
        [] a#true then 1000
        [] b#false then 1100
        end
    end

    %Helper pour convertir int > 0 en note equivalent
    
    fun {MapintPos Int}
        case Int of 0 then c#false
        [] 100 then c#true
        [] 200 then d#false
        [] 300 then d#true
        [] 400 then e#false
        [] 500 then f#false
        [] 600 then f#true
        [] 700 then g#false
        [] 800 then g#true
        [] 900 then a#false
        [] 1000 then a#true
        [] 1100 then b#false
        end 
    end

    %Helper pour convertir int <= 0 en note equivalent
     
    fun {MapintNeg Int}
        case Int of 0 then c#false
        [] ~100 then b#false
        [] ~200 then a#true
        [] ~300 then a#false
        [] ~400 then g#true
        [] ~500 then g#false
        [] ~600 then f#true
        [] ~700 then f#false
        [] ~800 then e#false
        [] ~900 then d#true
        [] ~1000 then d#false
        [] ~1100 then c#true
        else {MapintPos Int}
        end 
    end

    %helper pour determiner le nb d'octave a augmenter (HowManyOUp)

    fun {HowManyOUp Transposednote}
        fun {HowManyOA Transposednote A}
            if (Transposednote < 1200) then A
            else {HowManyOA Transposednote-1200 A+1}
            end 
        end 
    in 
        {HowManyOA Transposednote 0}
    end

    %helper pour determiner le nb d'octave a diminuer (HowManyODown)
    % Note tjr compris entre 0 et 1100
    % Semi < 0
    fun {HowManyODown Note Semi}
        fun {HowManyODA Note CurrentSemi A}
            if (Note + CurrentSemi < 0) then {HowManyODA Note CurrentSemi+1200 A+1}
            else A
            end 
        end 
    in 
        %cas ou -semi > 0 et -semi <= 1100
        case (Note + Semi) >= 0 of true then 0
        % cas ou -semi > 1100
        else {HowManyODA Note Semi 0}
        end 
    end

    %helper pour transpose note en int_equivalent en note(...)

    fun {TransposeNote Nint Octave Semi Duration Instrument}
        New_note = (Nint + Semi) mod 1200
        Octave_Up = {HowManyOUp (Nint + Semi)}
        Octave_Down = {HowManyODown Nint Semi}
        New_octave_Up = Octave + Octave_Up
        New_octave_Down = {Abs Octave - Octave_Down}

    in  %rajoutez case si semi < 0 (deja implementer pour semi >= 0)
        case Semi >= 0 of true then 
            case {MapintPos New_note} of N#Sharp then  
                note(name:N octave:New_octave_Up sharp:Sharp duration:Duration instrument:Instrument)
            end
        else
            case {MapintNeg New_note} of N#Sharp then  
                note(name:N octave:New_octave_Down sharp:Sharp duration:Duration instrument:Instrument)
            end
        end 

    end
    
    fun {TransposeChord Pi Semi}
        case Pi of nil then nil
        [] note(name:Note octave:O sharp:Bol duration:D instrument:I)|P 
        then {TransposeNote {MapNote Note Bol} O Semi D I}|{TransposeChord P Semi}
        end 
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

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    fun {PartitionToTimedList Partition} 
        %case sur partition pour different cas: <note>|<chord>|<extended note>|<extended chord>|<transformation
        case Partition of nil then nil
        %completer pour transformations
        [] duration(second:S partition:SubPartition)|P then
            {Append {PartitionToTimedList {Duration S SubPartition}} {PartitionToTimedList P}}
        [] stretch(factor:F partition:SubPartition)|P then
            {Append {PartitionToTimedList {Stretch F SubPartition}} {PartitionToTimedList P}}
        [] drone(sound:S amount:A)|P then
            {Append {PartitionToTimedList {Drone S A}} {PartitionToTimedList P}}
        [] mute(amount:A)|P then
            {Append {PartitionToTimedList {Mute A}} {PartitionToTimedList P}}
        [] transpose(semi:S partition:SubPartition)|P then
            {Append {PartitionToTimedList {Transpose S SubPartition}} {PartitionToTimedList P}}
        [] Pi|P andthen {IsNote Pi} == true then {NoteToExtended Pi} | {PartitionToTimedList P}
            %[] Pi|P andthen {IsNote Pi} == false then {Exception.failure failure(invalidNote:Pi)}|nil --> trouver autre endroit 
        [] Pi|P andthen {IsChord Pi} == true then {ChordToExtended Pi} | {PartitionToTimedList P}
        [] Pi|P andthen {IsExtendedChord Pi} == true then Pi | {PartitionToTimedList P}
        else nil 
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Transformations
    
    %transpose
    fun {Transpose Semi Partition}
        local P TransposeInter in 
            P = {PartitionToTimedList Partition}
            fun {TransposeInter Semi ExtendedPart}
                case ExtendedPart of nil then nil 
                [] note(name:Note octave:O sharp:Bol duration:D instrument:I)|Pi then
                    {TransposeNote {MapNote Note Bol} O Semi D I}|{TransposeInter Semi Pi}
                [] silence(...)|Pi then silence(...)|{TransposeInter Semi Pi}
                [] L|Pi andthen {IsExtendedChord L} == true then {TransposeChord L Semi}|{TransposeInter Semi Pi}
                %rajoutez cas Ou Pi est un extended_chord 
                end
            end 
            {TransposeInter Semi*100 P}
        end 
    end
    
    %Duration

    fun {Duration Second Partition}
        local FlatPartition Ratio TD DurationInter in 
            FlatPartition = {PartitionToTimedList Partition}
            TD = {TotalDuration FlatPartition}

            if TD == 0.0 then Ratio = 1.0
            else Ratio = Second/TD end

            fun {DurationInter Fp}
                case Fp of nil then nil 
                [] silence(duration:D)|P then silence(duration:(D*Ratio))|{DurationInter P}
                [] note(name:Note octave:O sharp:Bol duration:D instrument:I)|P then 
                    note(name:Note octave:O sharp:Bol duration:D*Ratio instrument:I)|{DurationInter P}
                [] L|P andthen {IsExtendedChord L} == true then {ChangeDChord L Ratio}|{DurationInter P}
                end
            end 
            
            {DurationInter FlatPartition}
        end
    end

    %stretch
    
    fun {Stretch Factor Partition}
        local
            FlatList
            Accumulator
        in
            FlatList = {PartitionToTimedList Partition}
            Accumulator = {NewCell nil}
            for J in FlatList do
                case J of note(name:N octave:O sharp:S duration:D instrument:I) then
                    Accumulator := note(name:N octave:O sharp:S duration:D*Factor instrument:I) | @Accumulator
                [] silence(duration:D) then
                    Accumulator := silence(duration:D*Factor) | @Accumulator
                [] rest(duration:D) then
                    Accumulator := rest(duration:D*Factor) | @Accumulator
                [] ChordList then
                    local
                        NewChordAccumulator
                    in
                        NewChordAccumulator = {NewCell nil}
                        for chord in ChordList do
                            NewChordAccumulator := note(name:chord.name octave:chord.octave sharp:chord.sharp duration:chord.duration*Factor instrument:chord.instrument) | @NewChordAccumulator
                        end
                        Accumulator :=  {List.reverse @NewChordAccumulator} | @Accumulator
                    end
                end
            end
            {List.reverse @Accumulator}
        end
    end
    
    %Drone

    %Amout > 0 
    fun {Drone NoteOrChord Amount}
        local ExtendedNote ExtendedChord DroneA in  
            fun {DroneA NoteOrChord A Acc}
                if A =< 0 then Acc
                else {DroneA NoteOrChord A-1 NoteOrChord|Acc} end 
            end

            if {IsNote NoteOrChord} == true then 
                ExtendedNote = {NoteToExtended NoteOrChord}
                {DroneA ExtendedNote Amount nil}
            elseif {IsChord NoteOrChord} == true then 
                ExtendedChord = {ChordToExtended NoteOrChord}
                {DroneA ExtendedChord Amount nil}
            elseif {IsExtendedChord NoteOrChord} == true then 
                ExtendedChord = NoteOrChord
                {DroneA ExtendedChord Amount nil}
            else {Exception.failure failure(invalidNoteOrChord:NoteOrChord)} end
        end 
    end

    %Mute
    
    fun{Mute Amount}
        fun {MakeSilences N}
            if N == 0 then nil
            else silence(duration:1.0) | {MakeSilences N-1}
            end
        end
    in
        {MakeSilences Amount}
    end
end

