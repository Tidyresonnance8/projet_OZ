
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


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Transformations
    

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
end

