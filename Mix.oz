 
functor
import
   Project2025
   OS
   System
   Property
export 
   mix: Mix
   echsPartition: ECHSPartition

define
   % Get the full path of the program
   CWD = {Atom.toString {OS.getCWD}}#"/"

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %helpers (meme helpers que dans PartitionToTimedList)
   
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
      Prev_duration = {NewCell 0.0}
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
      {ExtendedChordTimeA Pi}
      if @B == false then false 
      else true end 
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
      case Pi of note(...)|P then false 
      else 
         {IsChordA Pi}
         if {Length Pi} == 1 then false
         %elseif {IsExtendedChord Pi} == false then false  %attention peux causer un bug 
         elseif @B == false then false
         else true end
      end 
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

   in  
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
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   %helpers pour Mix
   fun {Hauteur ENote}
      local Nint Octave HauteurA Ref OctaveRef in
         Nint = {MapNote ENote.name ENote.sharp}
         Octave = ENote.octave
         Ref = {MapNote a false}
         OctaveRef = 4 

         %CurrentNote --> a,b,c,d,e,f,g ou diese equivalente
         %CurrentNote.octave -->int
         %Acc --> nb de demi-ton 
         fun {HauteurA CurrentNote CurrentOctave Acc}
            case (CurrentNote.name)#(CurrentNote.sharp)#CurrentOctave of a#false#4 then Acc
            else 
               if CurrentOctave > OctaveRef then 
                  {HauteurA
                  ({TransposeNote {MapNote CurrentNote.name CurrentNote.sharp} CurrentNote.octave ~100 ENote.duration ENote.instrument}) 
                  ({TransposeNote {MapNote CurrentNote.name CurrentNote.sharp} CurrentNote.octave ~100 ENote.duration ENote.instrument}).octave Acc+1}
               elseif CurrentOctave == OctaveRef andthen  {MapNote CurrentNote.name CurrentNote.sharp} > Ref then 
                  {HauteurA
                  ({TransposeNote {MapNote CurrentNote.name CurrentNote.sharp} CurrentNote.octave ~100 ENote.duration ENote.instrument}) 
                  ({TransposeNote {MapNote CurrentNote.name CurrentNote.sharp} CurrentNote.octave ~100 ENote.duration ENote.instrument}).octave Acc+1}
               elseif CurrentOctave == OctaveRef andthen {MapNote CurrentNote.name CurrentNote.sharp} < Ref then
                  {HauteurA
                  ({TransposeNote {MapNote CurrentNote.name CurrentNote.sharp} CurrentNote.octave 100 ENote.duration ENote.instrument}) 
                  ({TransposeNote {MapNote CurrentNote.name CurrentNote.sharp} CurrentNote.octave 100 ENote.duration ENote.instrument}).octave Acc-1}
               else
                  {HauteurA
                  ({TransposeNote {MapNote CurrentNote.name CurrentNote.sharp} CurrentNote.octave 100 ENote.duration ENote.instrument}) 
                  ({TransposeNote {MapNote CurrentNote.name CurrentNote.sharp} CurrentNote.octave 100 ENote.duration ENote.instrument}).octave Acc-1}
               end 
            end 
         end 

         {HauteurA ENote Octave 0}
      end 
   end
   /* 
   %Test pour a#4 -->doit retourner 1
   Note_1 = note(name:a octave:4 sharp:true duration:1.0 instrument:none)
   
   %Test pour b4 -->doit retourner 2
   Note_2 = note(name:b octave:4 sharp:false duration:1.0 instrument:none)

   %Test pour c5 -->doit retourner 3
   Note_3 = note(name:c octave:5 sharp:false duration:1.0 instrument:none)

   %Test pour g#4 -->doit retourner -1
   Note_4 = note(name:g octave:4 sharp:true duration:1.0 instrument:none)

   %Test pour c4 --> doit retourner -9
   Note_5 = note(name:c octave:4 sharp:false duration:1.0 instrument:none)

   %test pour c3 --> doit retourner -21
   Note_6 = note(name:c octave:3 sharp:false duration:1.0 instrument:none)
   
   %test pour c6 --> doit retourner 15
   Note_7 = note(name:c octave:6 sharp:false duration:1.0 instrument:none)*/

   %{Browse {Hauteur Note_1}}
   %{Browse {Hauteur Note_2}}
   %{Browse {Hauteur Note_3}}
   %{Browse {Hauteur Note_4}}
   %{Browse {Hauteur Note_5}}
   %{Browse {Hauteur Note_6}}
   %{Browse {Hauteur Note_7}}
   fun {Frcpd H}
      {Pow 2.0 ({IntToFloat H}/12.0)}*(440.0)
   end

   fun {A_i F I}
      local Pi in 
      Pi = 3.141592653589793
      (1.0/2.0)*{Sin (((2.0*Pi)*F*I)/44100.0)}
      end
   end 
   
   %Avec Accumullateur
   fun {ECHSNote ENote}
      local H F D N L_a_i ECHSA Res in 
         thread H = {Hauteur ENote} end 
         F = {Frcpd H}
         D = ENote.duration
         N = {FloatToInt D*44100.0}

         fun {ECHSA I Acc}
            if Acc > (N-1) then nil 
            else {A_i F I}|{ECHSA I+1.0 Acc+1} end 
         end 

         thread Res = {ECHSA 0.0 0} end
         Res
      end 
   end

   %helper pour additionner les elements de 2 list (doit etre de meme taille)
 
   fun {SumList L1 L2}
      case L1#L2 of nil#nil then nil 
      [] (H1|T1)#(H2|T2) then 
         if (H1+H2) =< 1.0 andthen (H1+H2) >= ~1.0 then  (H1+H2)|{SumList T1 T2}
         elseif (H1+H2) >= 1.0 then 1.0|{SumList T1 T2}
         elseif (H1+H2) =< ~1.0 then ~1.0|{SumList T1 T2} end 
      end 
   end
   
   %helper pour additionner les vecteur d'echatillons de chaque note pour 1 accord --> retourne une liste d'echantillons

   fun {SumLists ListofList Len}
      local Start SumListsRec Res in 
         Start = {Map {MakeList Len} fun {$ X} 0.0 end}
         
         fun {SumListsRec ListofList Init Acc}
            case ListofList of L1|T andthen Init == 0 then {SumListsRec T 1 {SumList Acc L1}}
            [] L2|T andthen Init \= 0 then {SumListsRec T 1 {SumList Acc L2}}
            [] nil then Acc 
            end 
         end 

        thread Res = {SumListsRec ListofList 0 Start} end
        Res
      end 
   end

   %helper pour convertir un accord en une list de liste d'echantillons de chaque notes
   fun {ListOfECH EChord}
      case EChord of nil then nil 
      [] N|T then {ECHSNote N}|{ListOfECH T}
      end 
   end 
   
   %Helper qui transforme un accord ettendue en une liste d'echantillons 
   fun {ECHSChord EChord}
      local Len ListofList in 
         ListofList = {ListOfECH EChord}
         Len = {Length ListofList.1}

         {SumLists ListofList Len}
      end 
   end
   
   fun {ECHSsilence S}
      local D N ECHSA Res in 
         D = S.duration
         N = {FloatToInt D*44100.0}

         fun {ECHSA I Acc}
            if Acc > (N-1) then nil 
            else 0.0|{ECHSA I+1.0 Acc+1} end 
         end 

         thread Res = {ECHSA 0.0 0} end
         Res
      end 
   end
   





   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   %P2T a --> effacer avant de rendre 
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


   fun {ECHSPartition Partition P2T}
      local FlatPartition ECHSPartitionRec Res in 
         FlatPartition ={P2T Partition}

         fun {ECHSPartitionRec Fp}
            case Fp of nil then nil
            [] silence(duration:D)|P then {Append {ECHSsilence silence(duration:D)} {ECHSPartitionRec P}}
            [] Pi|P andthen {IsNote Pi} == true then {Append {ECHSNote Pi} {ECHSPartitionRec P}}
            [] Pi|P andthen {IsExtendedChord Pi} == true then {Append {ECHSChord Pi} {ECHSPartitionRec P}}
            end 
         end 
         thread Res = {ECHSPartitionRec FlatPartition} end 
         Res
      end 
   end
   %test 
   %{Browse {ECHSPartition [a] PartitionToTimedList}} 
         
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   fun {Mix P2T Music}
      % TODO
      %{Project2025.readFile CWD#'wave/animals/cow.wav'}
      %Avec appel recursive (dans l'enonce ils disent que c trop stricte mais je ne comprend pas trop)
      case Music of nil then nil 
      [] samples(Samples)|MusicPart then {Append Samples {Mix P2T MusicPart}}
      [] partition(Partition)|MusicPart then {Append {ECHSPartition Partition P2T} {Mix P2T MusicPart}} 
      [] wave(Filename)|MusicPart then nil
      [] merge(Musics_W_I)|MusicPart then nil
      [] loop(seconds:S Music)|MusicPart then nil
      [] clip(low:Sample_low high:Sample_high Music) then nil 
      [] echo(delay:D decay:F repeat:N Music)|MusicPart then nil 
      [] fade(start:Start finish:Finish Music)|MusicPart then nil
      [] cut(start:Start finish:Finish )|MusicPart then nil
      else nil end 
   end


   
   %test rapide mix 
   %{Browse {Length {Mix PartitionToTimedList [partition([a])]}}}
   
   % fonction à appliquer sur cut
   %permet de rétirer un échantillon de la liste
   fun {DropSamples N L}
      if N =< 0 then L
      else {DropSamples (N-1) {List.tail L}}
      end
   end
   %permet de prendre un échantillon
   fun {TakeSamples N L}
      if N =< 0 then nil
      else case L of H|T then H|{TakeSamples (N-1) T} end
      end
   end
   %permet le silence grace  au zéro 
   fun {Zero N}
      if N =< 0 then nil
      else 0.0|{Zero (N-1)}
      end
   end
   
   %permet de calculer la multiplication entre de listes
   fun {MultList L1 L2}
      case L1#L2 of nil#nil then nil 
      [] (H1|T1)#(H2|T2) then (H1*H2)|{MultList T1 T2} end
   end 
   %contruire une liste de n éléments
   fun {Build N F}
      fun {Aux I}
         if I >= N then nil
         else {F I}|{Aux (I+1)}
         end
      end
   in
      {Aux 0}
   end
   

   
   fun {Repeat N  Music}
      if N =< 0 then nil
      else {Append Music {Repeat (N-1) Music}}
      end
   end

   
   fun {Cut Start Finish Music P2T}
      local
         Debut = {FloatToInt (Start * 44100.0)}
         Fin = {FloatToInt (Finish * 44100.0)}
         LesEchantillons = {Mix P2T Music}
         ApresDebut = {DropSamples Debut LesEchantillons}
         Echantillon = {TakeSamples (Fin - Debut) ApresDebut}
         Manque = (Fin - Debut) - {Length Echantillon}
         Silence = {Zero Manque}
      in
         if Manque =< 0 then Echantillon
         else {Append Echantillon Silence}
         end
      end
   end
   
   % permet d'appliquer un facteur à tous les échantillons
   fun {Facteur Samples Factor}
      case Samples of H|T then (H * Factor)|{Facteur T Factor} end
   end

   /* 
   fun {Echo Delay Decay Repeat Music P2T}
      local 
         DelaySamples
         OriginalMusic
         Decayed
         Silence
         EchoI
         EchoSamples
      in
         OriginalMusic = {Mix P2T Music}
         DelaySamples = {FloatToInt (Delay * 44100.0)}
         EchoSamples =  [OriginalMusic]
         for I in 1..Repeat do
            Decayed = {Facteur OriginalMusic {Pow Decay I}}
            Silence = {Zero (DelaySamples*I)}
            EchoI = {Append Silence Decayed}
            EchoSamples = {Append EchoSamples EchoI}
         end
         {Merge EchoSamples}
      end
   end */

   
   fun {Fade Start Finish Music P2T}
      local
         FadeOutApplied
         FadeInApplied
         FadeInFactors
         FadeOutFactors
         FadeInPart
         Rest
         MiddlePart
         FadeOutPart
         Samples
         Longueur
         Debut
         Fin
      in
         Debut = {FloatToInt (Start * 44100.0)}
         Fin   = {FloatToInt (Finish * 44100.0)}
         Samples = {Mix P2T Music}
         Longueur = {Length Samples}
         if Longueur < Debut + Fin then
            Samples
         else
            FadeInFactors = {Build Debut fun {$ I} {IntToFloat I} / {IntToFloat Debut}
               end}
            FadeOutFactors = {Build Fin fun {$ I} 1.0 - ({IntToFloat I} / {IntToFloat Fin})
               end}
            FadeInPart = {TakeSamples Samples Debut}
            Rest     = {DropSamples Samples Debut}
            MiddlePart = {TakeSamples Rest (Longueur - Debut - Fin)}
            FadeOutPart= {DropSamples Rest (Longueur - Debut - Fin)}
            FadeInApplied  = {MultList FadeInPart FadeInFactors}
            FadeOutApplied = {MultList FadeOutPart FadeOutFactors}
            {Append FadeInApplied {Append MiddlePart FadeOutApplied}}
         end
      end
   end
   
end