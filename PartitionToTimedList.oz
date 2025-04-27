 
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



    fun {Duration Second Partition}
        Applatir = {PartitionToTimedList Partition}
        for I in Applatir do
            if I = note(...) then
                Totalduration = Second + I.duration

            if I = silence(duration: _) then
                Totalduration = Second + I.duration
            end
        
        Ratio = if Totalduration = 0.0 then 1.0 else second/Totalduration end

        Applatir2 = {Map Applatir {NoteToExtended I}}
        for I in Applatir2 do
            if I = note(...) then
                I.duration = I.duration * Ratio
            end

            if I = silence(duration: _) then
                I.duration = I.duration * Ratio
            end
        end
    end    
    
    fun {Stretch Factor Partition}
        FlatList = {PartitionToTimedList Partition}
        for I in FlatList do
            if I = note(...) then
                I.duration = I.duration * Factor
            elseif I = silence(duration: _) then
                I.duration = I.duration * Factor
            elseif I = rest(duration: _) then
                I.duration = I.duration * Factor
            end
        end  
    end
    
    fun {Drone NoteOrChord Amount}
        fun {ExtendedSound N}
            case N of silence(duration:_) then silence(duration:_)
            [] note(...) then note(...)
            [] AtomeNote then {NoteToExtended AtomeNote}
            [] ChordList then {Map chordList fun {$ NoteInChord}
                {NoteToExtended NoteInChord}
                end}
            end
        end
    
        sonEtendue = {ExtendedSound NoteOrChord}
        fun {Repetition N X}
            if X == 0 then nil
            else N|{Repetition N X-1}
            end
        end
    in 
        {Repetition SonEtendue Amount}
    end
    
    fun{Mute Amount}
    
    FlatList = {PartitionToTimedList Partition}
    for I in FlatList do
        if I = silence(duration: _) then
            I.duration = I.duration * Amount
        elseif I = note(...) then
            I.duration = I.duration * Amount
        end
    end

    % convertissons un nom et un bool en index chromatique
    fun {NoteToChromaticIndex Name Sharp}
        case Name of a then 0
        [] b then 2
        [] c then 4
        [] d then 5
        [] e then 7
        [] f then 9
        [] g then 11
        end + if Sharp == true then 1 else 0 end
    end

    % convertissons un index chromatique en Name#sharp
    fun {ChromaticIndexToNote Index Sharp}
        case Index of 0 then c#false
        [] 1 then c#true
        [] 2 then d#false
        [] 3 then d#true
        [] 4 then e#false
        [] 5 then f#false
        [] 6 then f#true
        [] 7 then g#false
        [] 8 then g#true
        [] 9 then a#false
        [] 10 then a#true
        [] 11 then b#false
        end + if Sharp == true then 1 else 0 end
    end

    
    fun{Transpose Semitones Partition}
        FlatList = {PartitionToTimedList Partition}
        local cellule in
            cellule = {NewCell nil}
            for I in FlatList do
                case I of note(...) then
                    BaseIndex = {NoteToChromaticIndex I.name I.sharp}
                    NewIndex = BaseIndex + Semitones
                    if NewIndex < 0 then
                        NewIndex = 12 + NewIndex
                    end
                    if NewIndex > 11 then
                        NewIndex = NewIndex - 12
                    end
                    I.name = {ChromaticIndexToNote NewIndex I.sharp}
                    I.sharp = if NewIndex == 0 then false else true end
                    I.duration = I.duration * Semitones
                    I.instrument = I.instrument * Semitones
                [] silence(duration: _) then
                    BaseIndex = {NoteToChromaticIndex I.name I.sharp}
                    NewIndex = BaseIndex + Semitones
                    if NewIndex < 0 then
                        NewIndex = 12 + NewIndex
                    end
                    if NewIndex > 11 then
                        NewIndex = NewIndex - 12
                    end
                    I.name = {ChromaticIndexToNote NewIndex I.sharp}
                    I.sharp = if NewIndex == 0 then false else true end
                [] _|_ then
                    if {IsNote I} == false then
                        cellule := {NoteToExtended I} | @cellule
                    end
                [] nil then
                    cellule := nil | @cellule
                [] silence then
                    cellule := silence(duration:1.0) | @cellule
                [] Name#Octave then
                    cellule := note(name:Name octave:Octave sharp:true duration:1.0 instrument:none) | @cellule
                [] Atom then
                    case {AtomToString Atom}
                    of [_] then
                        cellule := note(name:Atom octave:4 sharp:false duration:1.0 instrument:none) | @cellule
                    [] [N O] then
                        cellule := note(name:{StringToAtom [N]}
                            octave:{StringToInt [O]}
                            sharp:false
                            duration:1.0
                            instrument: none) | @cellule
                    end
                end
            end

            cellule := {Reverse @cellule}
            @cellule
        end
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
end

