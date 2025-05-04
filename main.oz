%Prénom:Jean-Louis | Nom:Peffer | Noma:72232300
%Prénom:Isaac | Nom:Yamdjieu Tahadie | Noma:07152201
functor
import
    Project2025
    PartitionToTimedList
    Mix
    Tests
    Application
    OS
    System
    Property
define
    % Get the full path of the program
    CWD = {Atom.toString {OS.getCWD}}#"/"
    
    % Get the arguments of the program. By default tests are set to false and music is "example.dj.oz"
    Args = {Application.getArgs record('test'(single type:bool default:false optional:true)
                                        'music'(single type:string default:'example.dj.oz')
                                        )}
    
    % Load the music
    Music = {Project2025.load CWD#Args.'music'}

    if Args.'test' == true then 
        % Launch tests
        {Tests.test Mix.mix PartitionToTimedList.partitionToTimedList}
    else
        % Calls your code, prints the result and outputs the result to `out.wav`.
        {System.show {Project2025.run Mix.mix PartitionToTimedList.partitionToTimedList Music 'out.wav'}}

    end

end