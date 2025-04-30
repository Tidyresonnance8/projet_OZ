 
 functor
 import
    Project2025
    OS
    System
    Property
 export 
    mix: Mix
 define
   % Get the full path of the program
   CWD = {Atom.toString {OS.getCWD}}#"/"

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    fun {Mix P2T Music}
        % TODO
        {Project2025.readFile CWD#'wave/animals/cow.wav'}
    end

  































































































































































































































































































































































































































































































































































































































































   declare
   % fonction à appliquer sur cut
   %permet de rétirer un échantillon de la liste
   fun {RetireSamples N L}
      if N =< 0 then L
      else {RetireSamples (N-1) {List.tail L}}
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
   %permet de faire un append entre deux listes
   fun {Append L1 L2}
      if L1 == nil then L2
      else case L1 of H|T then H|{Append T L2} end
      end
   end


   declare
   fun {Repeat N  Music}
      if N =< 0 then nil
      else {Append Music {Repeat (N-1) Music}}
      end
   end

   declare
   fun {Cut Start Finish Music}
      local
         Debut = {FloatToInt (Start * 44100.0)}
         Fin = {FloatToInt (Finish * 44100.0)}
         LesEchantillons = {Mix P2T Music}
         ApresDebut = {RetireSamples Debut LesEchantillons}
         Echantillon = {TakeSamples (Fin - Debut) ApresDebut}
         Manque = (Fin - Debut) - {List.length Echantillon}
         Silence = {Zero Manque}
      in
         if Manque =< 0 then Echantillon
         else {Append Echantillon Silence}
         end
      end
   end
   declare
   % permet d'appliquer un facteur à tous les échantillons
   fun {Facteur Samples Factor}
      case Samples of H|T then (H * Factor)|{Facteur T Factor} end
   end

   fun {Echo Delay Decay Repeat Music}
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
   end

   fun {Fade Start Finish Music}
      Original_part = {Mix P2T Music}
      Debut = {FloatToInt (Start * 44100.0)}
      Fin = {FloatToInt (Finish * 44100.0)}  
      



      



end