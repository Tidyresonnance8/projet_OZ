 
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
   %helpers (meme helpers que dans PartitionToTimedLis 
   fun {IsNote Pi}
      case Pi of silence then true
      [] silence(...) then true
      [] stretch(...) then false
      [] note(...) then true 
      [] H | T then false 
      [] Name#Octave then {Member Name [a b c d e f g]} 
      [] S then
          if {String.isAtom S} then 
              String_name = {AtomToString Pi}
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

   %helper pour transpose accord en [note(...) note(...) ...]
   fun {TransposeChord Pi Semi}
      case Pi of nil then nil
      [] note(name:Note octave:O sharp:Bol duration:D instrument:I)|P 
      then {TransposeNote {MapNote Note Bol} O Semi D I}|{TransposeChord P Semi}
      end 
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
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

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %Helpers pour l'echantillonnage

   %helper pour determiner la hauteur d'une note etendue 
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

   %helper pour determiner la frequence d'echanttillonnage 
   fun {Frcpd H}
      {Pow 2.0 ({IntToFloat H}/12.0)}*(440.0)
   end

   %helper pour cree un echantillons
   fun {A_i F I}
      local Pi in 
      Pi = 3.141592653589793238462643383279502884197
      (1.0/2.0)*{Sin (((2.0*Pi)*F*I)/44100.0)}
      end
   end 
   
   %helper Pour echantillonner une note 
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
         
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   fun {Mix P2T Music}
      % TODO
      %{Project2025.readFile CWD#'wave/animals/cow.wav'}
      %Avec appel recursive (dans l'enonce ils disent que c trop stricte mais je ne comprend pas trop)
      case Music of nil then nil 
      [] samples(Samples)|MusicPart then {Append Samples {Mix P2T MusicPart}}
      [] partition(Partition)|MusicPart then {Append {ECHSPartition Partition P2T} {Mix P2T MusicPart}}
      [] repeat(amount:N Music)|MusicPart then {Append {Repeat N Music P2T} {Mix P2T MusicPart}}
      %[] wave(Filename)|MusicPart then {Append {Wave Filename} {Mix P2T MusicPart}}
      [] merge(Musics_W_I)|MusicPart then {Append {Merge Musics_W_I P2T} {Mix P2T MusicPart}}
      [] loop(seconds:S Music)|MusicPart then {Append {Loop S Music P2T} {Mix P2T MusicPart}}
      [] clip(low:Sample_low high:Sample_high Music)|MusicPart then {Append {Clip Sample_low Sample_high P2T Music} {Mix P2T MusicPart}}
      [] echo(delay:D decay:F repeat:N Music)|MusicPart then {Append {Echo D F N Music P2T} {Mix P2T MusicPart}} 
      [] fade(start:Start finish:Finish Music)|MusicPart then {Append {Fade Start Finish Music P2T} {Mix P2T MusicPart}}
      [] cut(start:Start finish:Finish Music)|MusicPart then {Append {Cut Start Finish Music P2T} {Mix P2T MusicPart}}
      else nil end 
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %Helpers Echo

   %permet de cree une liste de silence a rajoutez au debut de samples (pour echo)
   fun {Zero N}
      if N =< 0 then nil
      else 0.0|{Zero (N-1)}
      end
   end

   fun {AddSilenceInit Samples Delay}
      local Len Res1 Res2 in 
         Len = {FloatToInt Delay*44100.0}
         thread Res1 = {Zero Len} end 
         thread Res2 = {Append Res1 Samples} end 
         Res2
      end 
   end
   
   fun {EchoIntensities Decay Repeat_i}
      {Pow Decay {IntToFloat Repeat_i}}
   end 

   fun {Delays Delay Repeat_i}
      {IntToFloat Repeat_i}*Delay
   end 
   
   fun {MakeEchos Delay Decay Repeat Original}
      local MakeEchosRec Res in 
         fun {MakeEchosRec DelayRec DecayRec RepeatRec OriginalRec}
            if RepeatRec > Repeat then nil 
            else {EchoIntensities DecayRec RepeatRec}#[samples({AddSilenceInit OriginalRec {Delays DelayRec RepeatRec}})]|
                 {MakeEchosRec DelayRec DecayRec RepeatRec+1 OriginalRec}
            end 
         end 
         thread Res = {MakeEchosRec Delay Decay 1 Original} end
         Res 
      end 
   end
   
   fun {Echo Delay Decay Repeat Music P2T}
      local OSamples Res ToMerge in 
         OSamples = {Mix P2T Music}
         ToMerge = {Append [1.0#[samples(OSamples)]] {MakeEchos Delay Decay Repeat OSamples}}
         thread Res = {Merge ToMerge P2T} end 
         Res 
      end 
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   /* 
   fun {Wave Filename} 
      {Project2025.readFile CWD#Filename}
   end */

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %helpers pour Merge

   %helper pour determiner la liste de plus grande taille parmi une Liste de Liste 
   fun {FindBL ListofList}
      local Currentbiggest FindBLRec in 
         Currentbiggest = {NewCell 0}
         
         fun {FindBLRec LofL}
            case LofL of nil then @Currentbiggest
            [] L1|T andthen {Length L1} > @Currentbiggest then Currentbiggest := {Length L1} {FindBLRec T}
            [] L1|T andthen {Length L1} =< @Currentbiggest then {FindBLRec T}
            end 
         end 

         {FindBLRec ListofList}
      end 
   end 

   %helper pour rajouter du silence a la fin du Sample/List ActualList qui on une taille plus petite que BigL
   fun {AddSilence ActualList BigL}
      local SilenceLen SilenceList in
         SilenceLen = BigL - {Length ActualList}
         SilenceList = {Map {MakeList SilenceLen} fun {$ X} 0.0 end}
         {Append ActualList SilenceList}
      end
   end
   
   %helper qui permet de convertir le format MusicWithIntensities ::= nil | Float#<music> '|' <MusicWithIntensities> 
   %en format ListOfSamples ::= nil | <sample>|<ListOfSamples>
   fun {CreateLofLWI MWI P2T}
      local Res CreateLofLWIRec in 
         fun {CreateLofLWIRec MTI}
            case MTI of nil then nil 
            [] F#M|T then {Map {Mix P2T M} fun{$ X} X*F end}|{CreateLofLWIRec T}
            end 
         end 

         thread Res = {CreateLofLWIRec MWI} end 
         Res 
      end 
   end
   
   %ici ListofList est deja convertie en CreateLofLWI
   %helper qui permet de rajoutez du silence a la fin de samples de ListOfList ::= nil | <sample>|<ListOfSamples> qui n'ont pas la meme longueur que les autres samples
   fun {AddSilenceToLofL ListofList}
      local Larggest Res AddSilenceToLofLRec in
         Larggest = {FindBL ListofList}

         fun {AddSilenceToLofLRec LofL}
            case LofL of nil then nil 
            [] L1|T andthen {Length L1} < Larggest then {AddSilence L1 Larggest}|{AddSilenceToLofLRec T}
            [] L1|T andthen {Length L1} == Larggest then L1|{AddSilenceToLofLRec T}
            end 
         end 

         thread Res = {AddSilenceToLofLRec ListofList} end 
         Res 
      end 
   end

   fun {Merge MWI P2T}
      local ListofList ResLen Res in
         ListofList = {AddSilenceToLofL {CreateLofLWI MWI P2T}}
         ResLen = {FindBL ListofList}
         Res = {SumLists ListofList ResLen}
         Res
      end 
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun {Clip Low High P2T Music}
      local Ech Res ClipRec in 
         Ech = {Mix P2T Music}

         fun {ClipRec EchRec}
            case EchRec of nil then nil
            [] E|S then 
               if E < Low then Low|{ClipRec S}
               elseif E > High then High|{ClipRec S}
               else E|{ClipRec S} end
            end  
         end 

         if Low > High then Ech 
         else 
            thread Res = {ClipRec Ech} end 
            Res 
         end 
      end 
   end 

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   fun {Loop D Music P2T}
      local Ech NewLen Res NewList LoopRec in 
         NewLen = {FloatToInt D*44100.0}
         Ech = {Mix P2T Music}
         NewList = {MakeList NewLen}

         fun {LoopRec A Original}
            if A =< 0 then nil 
            else 
               case Original of nil then {LoopRec A Ech}
               [] S|T then S|{LoopRec A-1 T}
               end 
            end 
         end 
         thread Res = {LoopRec NewLen Ech} end 
         Res 
      end 
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   fun {Repeat N Music P2T}
      local Samples RepeatRec Res in 
         Samples = {Mix P2T Music}

         fun {RepeatRec Count S}
            if Count =< 0 then nil
            else {Append Samples {RepeatRec (Count-1) Samples}} end 
         end

         thread Res = {RepeatRec N Samples} end 
         Res
      end 
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   % fonction à appliquer sur cut
   %permet de rétirer un échantillon de la liste
   fun {DropSamples N L}
      if N =< 0 then L
      else
         case L of nil then nil 
         [] H|T then {DropSamples (N-1) T} end
      end
   end
   %permet de prendre un échantillon
   
   fun {TakeSamples N L}
      if N =< 0 then nil
      else case L of H|T then H|{TakeSamples (N-1) T}
            else nil end
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
   
   fun {Cut Start Finish Music P2T}
      local
         Debut = {FloatToInt (Start * 44100.0)}
         Fin = {FloatToInt (Finish * 44100.0)}-1
         LesEchantillons = {Mix P2T Music}
         Duree = {IntToFloat {Length LesEchantillons}}/44100.0
         ApresDebut = {DropSamples Debut LesEchantillons}
         Echantillon = {TakeSamples (Fin - Debut) ApresDebut}
         Manque = (Fin - Debut) - {Length Echantillon}
         Silence = {Zero Manque+1}
      in
         if (Finish - Start) > Duree then {Append Echantillon Silence}
         else
            Echantillon
         end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   % permet d'appliquer un facteur à tous les échantillons
   fun {SumAll Lists}
      fun {SumAux I}
         
         {FoldR Lists fun {$ List Acc}{Nth List I} + Acc end 0.0}
         
      end
   in
      if Lists == nil then nil
         
      else {Map {List.number 1 {Length Lists.1} 1} SumAux}
         
      end
   end
   
   fun {Fade Start Finish Music P2T}
      local Samples TotalSamples Debut Fin Mask Duree in

         Samples = {Mix P2T Music}
         TotalSamples = {Length Samples}
         Duree = {IntToFloat TotalSamples}*44100.0
         Debut = {FloatToInt (Start * 44100.0)}+1 
         Fin = {FloatToInt (Finish * 44100.0)}+1
         if Duree < (Start + Finish) then Samples  
         else
            Mask = {BuildMask Debut Fin TotalSamples}
            {MultList Samples Mask}
         end
      end
   end
    
   fun {BuildMask Debut Fin TotalSamples}
      FadeIn = {Build Debut fun {$ I} {IntToFloat I} / {IntToFloat (Debut - 1)} end}
      FadeOut = {Build Fin fun {$ I} 1.0 - ({IntToFloat I} / {IntToFloat (Fin - 1)}) end}
      MiddleLen = TotalSamples - Debut - Fin
      Middle = if MiddleLen > 0 then {Build MiddleLen fun {$ I} 1.0 end} else nil end
   in
      {Append FadeIn {Append Middle FadeOut}}
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %{Browse {Fade 0.000113378 0.000113378 [samples([1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0])] PartitionToTimedList}}
   %{Browse {Fade 0.5 0.5 [partition([a b])] PartitionToTimedList}}
   %{Browse {Fade 0.5 0.5 [partition([silence(duration:1.5)])] PartitionToTimedList}}
   %{Browse {Fade 0.5 0.5 [partition([a b c d e f g])] PartitionToTimedList}}
   
   %{Browse {Fade 0.5 1.0 [partition([a b])] PartitionToTimedList}}
   %{Browse {Mix PartitionToTimedList [partition([a])]}}
   /*
   % On construit une “musique” minimale : une partition [a] (la note A4 d’une seconde)
      Music = [partition([a])]

   % On applique un fondu de 0.5 s en entrée et de 0.5 s en sortie
      FadeSamples = {Fade 0.5 0.5 Music PartitionToTimedList}

   in
   % Affiche les 5 premiers échantillons après le fade-in
      {Browse {TakeSamples 5 FadeSamples}}
   % Affiche les 5 derniers échantillons avant le fade-out
      {Browse {TakeSamples 5 {List.reverse FadeSamples}}}
   end*/

   
   /*
      fun {Ones N}
         if N == 0 then nil else 1.0|{Ones N-1} end
      end

      % Test avec 10 samples (durée équivalente: 10/44100 ≈ 0.00022676 sec)
      Music = [samples({Ones 10})] 
      Start = 2.0/44100.0 % Fade-in sur 2 samples
      Finish = 3.0/44100.0 % Fade-out sur 3 samples
      FadeSamples = {Fade Start Finish Music PartitionToTimedList}
   in
      {Browse FadeSamples} */
   % Résultat attendu : [0.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 0.5 0.0]
   /*local
      TakeSamples
      Music = [partition([a])] % Note A4 de 1 seconde
      FadeSamples = {Fade 0.5 0.5 Music PartitionToTimedList}
   in
      {Browse {TakeSamples 5 FadeSamples}} % Début : [0.0 0.0002 0.0004 ...]
      {Browse {TakesSamples 5 {Reverse FadeSamples}}} % Fin : [0.0004 0.0002 0.0 ...]
   end*/
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %a effacer
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
   
   fun {PartitionToTimedList Partition} 
      %case sur partition pour different cas: <note>|<chord>|<extended note>|<extended chord>|<transformation
      case Partition of nil then nil
      %completer pour transformations
      [] duration(second:S SubPartition)|P then
            {Append {PartitionToTimedList {Duration S SubPartition}} {PartitionToTimedList P}}
      [] stretch(factor:F SubPartition)|P then
            {Append {PartitionToTimedList {Stretch F SubPartition}} {PartitionToTimedList P}}
      [] drone(sound:S amount:A)|P then
            {Append {PartitionToTimedList {Drone S A}} {PartitionToTimedList P}}
      [] mute(amount:A)|P then
            {Append {PartitionToTimedList {Mute A}} {PartitionToTimedList P}}
      [] transpose(semi:S SubPartition)|P then
            {Append {PartitionToTimedList {Transpose S SubPartition}} {PartitionToTimedList P}}
      [] Pi|P andthen {IsNote Pi} == true then {NoteToExtended Pi} | {PartitionToTimedList P} 
      [] Pi|P andthen {IsChord Pi} == true then {ChordToExtended Pi} | {PartitionToTimedList P}
      [] Pi|P then
            if ({IsExtendedChord Pi} == true) then Pi | {PartitionToTimedList P}
            elseif ({IsExtendedChord Pi} == false) then {Exception.failure failure(invalidChord:Pi)} end 
      else {Exception.failure failure(invalidArgument:Partition)}
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