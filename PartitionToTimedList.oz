 
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
    fun {IsNote Pi}
        case Pi of silence then true
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
        if {Length Pi} =< 1 then false 
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
        % TODO

        %case sur partition pour different cas: <note>|<chord>|<extended note>|<extended chord>|<transformation
        case Partition of nil then nil
        [] Pi|P andthen {IsNote Pi} == true then {NoteToExtended Pi} | {PartitionToTimedList P}
        [] L|P andthen {IsChord L} == true then {ChordToExtended L} | {PartitionToTimedList P}
        [] Pi|P andthen {IsExtendedNote Pi} == true then Pi | {PartitionToTimedList P}
        [] Pi|P andthen {IsExtendedChord Pi} == true then Pi | {PartitionToTimedList P}
        %completer pour transformations
        else nil
        end 
    end
    % a effacer avant de rendre 
    /* 
    local Cmaj4 Dmin5 P2 Test in
        Cmaj4 = [a0 e b1]
        Dmin5 = [c#2 d#3 e]
        P2 = [Cmaj4 Dmin5]
        fun {Test P}
            case P of nil then nil 
            [] L|T andthen {IsChord L} then {ChordToExtended L} | {Test T}
            end
        end
        {Browse {Test P2}}
    end*/
    /*
    Cmin4 = [c d#4 g]
    P1 = [a0 b1 c#2 d#3 e silence]
    Cmaj4 = [a0 e b1]
    Dmin5 = [c#2 d#3 e]
    {Browse {IsNote Dmin5}}
    P2 = [Cmaj4 Dmin5 a0 b1 c#4 silence]
    {Browse {PartitionToTimedList P2}}*/
end