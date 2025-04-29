
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
define
    %helpers
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    declare 
    fun {IsNote Pi}
        case Pi of silence then true
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

    /* 
    fun {ExtendedChordTime Pi}
        A = {NewCell false}
        B = {NewCell true}
        Prev_duration = {NewCell 0}
        Current_duration = {NewCell 0}
        proc {ExtendedChordTimeA Pi}
            {Browse nil}
        end
    in 
        nil
    end */
            
                

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
            elseif @B == false then false
            else true end
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
    %Note tjr compris entre 0 et 1100
    %Semi < 0
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

    %helper pour transpose note en int equivalent en note(...)

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
    /* 
    local OriginalNote IntNote TranspNote in
        OriginalNote = note(name:a octave:4 sharp:false duration:1.0 instrument:none)
        IntNote = {MapNote OriginalNote.name OriginalNote.sharp}
        TranspNote = {TransposeNote IntNote OriginalNote.octave ~2700 OriginalNote.duration OriginalNote.instrument}
        {Browse OriginalNote}
        {Browse TranspNote} %should display note(name:f octave:2 sharp:true duration:1.0 instrument:none)

    end*/





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
        [] Pi|P andthen {IsNote Pi} == true then {NoteToExtended Pi} | {PartitionToTimedList P}
        [] Pi|P andthen {IsChord Pi} == true then {ChordToExtended Pi} | {PartitionToTimedList P}
        [] Pi|P andthen {IsExtendedChord Pi} == true then Pi | {PartitionToTimedList P}
        %completer pour transformations
        else nil
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Transformations
    declare
    %transpose
    fun {Transpose Semi Partition}
        local P TransposeInter in 
            P = {PartitionToTimedList Partition}
            fun {TransposeInter Semi ExtendedPart}
                case ExtendedPart of nil then nil 
                [] note(name:Note octave:O sharp:Bol duration:D instrument:I)|Pi then
                    {TransposeNote {MapNote Note Bol} O Semi D I}|{TransposeInter Semi Pi}
                end
            end 
            {TransposeInter Semi P}
        end 
    end
    /* 
    Note_1 = note(name:a octave:4 sharp:false duration:1.0 instrument:none)
    Note_2 = note(name:b octave:5 sharp:false duration:1.0 instrument:none)
    Note_3 = note(name:c octave:5 sharp:true duration:1.0 instrument:none)

    Extended_notesPartition = [Note_1 Note_2 Note_3]
    {Browse {Transpose 100 Extended_notesPartition}} */

    %duration
    declare
    fun {Duration Second Partition}
        TotalDuration = {NewCell 0.0}
        for I in Partition do
            if {IsList I} then
                for Note in I do
                    TotalDuration := @TotalDuration + Note.duration
                end
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
                {List.map I fun {$ Note}
                    note(name:Note.name octave:Note.octave sharp:Note.sharp duration:(Note.durationRatio) instrument:Note.instrument) end}
            else
                case I of
                    note(name:N octave:O sharp:S duration:D instrument:Inst) then
                        note(name:N octave:O sharp:S duration:(D*Ratio) instrument:Inst)
                [] silence(duration:D) then
                        silence(duration:(D*Ratio))
                [] rest(duration:D) then
                        rest(duration:(D*Ratio))
                else I
                end
            end
        end}
    in
        NouvellePartition
    end
    {Browse {Duration 2.0 [a0 b1 c#2 d#3 e silence]}}
    {Browse {Duration 2.0 [a0 b1 c#2 d#3 e silence]}}


    %stretch
    declare
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

    declare
    fun {Drone NoteOrChord Amount}
        fun {ExtendedSound N}
            case N of note(name:Name octave:Octave sharp:Sharp duration:Duration instrument:Instrument) then
                [note(name:Name octave:Octave sharp:Sharp duration:Duration instrument:Instrument)]
            [] silence(duration:D) then
                [silence(duration:D)]
            [] rest(duration:D) then
                [rest(duration:D)]
            [] ChordList then
                local
                    NewChordAccumulator
                in
                    NewChordAccumulator = {NewCell nil}
                    for chord in ChordList do
                        NewChordAccumulator := note(name:chord.name octave:chord.octave sharp:chord.sharp duration:chord.duration instrument:chord.instrument) | @NewChordAccumulator
                    end
                    [{List.reverse @NewChordAccumulator}]
                end
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

    declare
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

