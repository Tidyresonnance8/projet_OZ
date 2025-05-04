%Prénom:Jean-Louis | Nom:Peffer | Noma:72232300
%Prénom:Isaac | Nom:Yamdjieu Tahadie | Noma:07152201
local
    Tune = [b b c5 d5 d5 c5 b a g g a b]
    End1 = [stretch(factor:1.5 [b]) stretch(factor:0.5 [a]) stretch(factor:2.0 [a])]
    End2 = [stretch(factor:1.5 [a]) stretch(factor:0.5 [g]) stretch(factor:2.0 [g])]
    Interlude = [a a b g a stretch(factor:0.5 [b c5])
                     b g a stretch(factor:0.5 [b c5])
                 b a g a stretch(factor:2.0 [d]) ]
 
    Partition = {Flatten [Tune End1 Tune End2 Interlude Tune End2]}
in
    %Ode to joy transposed 2 octaves + haut avec merg + loop + cut + fade in et fade out
    [merge([1.0#[partition(Partition)] 0.25#[loop(seconds:60.0 [fade(start:3.0 finish:20.0 [cut(start:5.0 finish:30.0 [partition([transpose(semi:24 Partition)])])])])]])]
end
