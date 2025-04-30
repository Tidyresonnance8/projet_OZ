 
functor
import
   Project2025
   OS
   System
   Property
   PartitionToTimedList
export 
   mix: Mix
define
   % Get the full path of the program
   CWD = {Atom.toString {OS.getCWD}}#"/"

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %helpers (meme helpers que dans PartitionToTimedList)
   declare
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
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   %1er trouver l'octave O de la note:
   %Si O > 4 --> transposee vers le bas jusqu'a qu'on arrive a A4
   %Si O < 4 --> transposee vers le haut jusqu'a qu'on arrive a A4
   %utiliser accumulateur pour garder en comte le nb de demi-ton
   %declare
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
   Note_7 = note(name:c octave:6 sharp:false duration:1.0 instrument:none)

   {Browse {Hauteur Note_1}}
   {Browse {Hauteur Note_2}}
   {Browse {Hauteur Note_3}}
   {Browse {Hauteur Note_4}}
   {Browse {Hauteur Note_5}}
   {Browse {Hauteur Note_6}}
   {Browse {Hauteur Note_7}}
   declare
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

   L_e = {ECHSNote Note_1}
   {Browse {IsList L_e}} %doit retourner 44100

   %todo: ECHSChord + Ensuite 





            





    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun {Mix P2T Music}
      % TODO
      {Project2025.readFile CWD#'wave/animals/cow.wav'}
   end

end