classdef MPbrtScene < handle
    % Top-level container for a PBRT scene.
    %   The scene contains various elements at the "overall" level and
    %   various other elements at the "world" level.  Elements can be
    %   added, found, and removed from either place.  The whole scene can
    %   be printed to file, starting with the overall elements, followed by
    %   the world elements.
    
    properties
        % A container for "overall" elements.
        overall;
        
        % A container for "world" elements.
        world;
    end
    
    methods
        function self = MPbrtScene()
            self.overall = MPbrtContainer('', '');
            self.overall.indent = '';
            
            self.world = MPbrtContainer('World', '');
            self.world.indent = '';
        end
        
        function printToFile(self, outputFile)
            % Write this scene to the given file.
            %   Writes out the overall and world contents of this scene to
            %   a text file located at the given outputFile.
            %
            %   outputFile may be a string file path or a file descriptor.
            %
            %   Throws an error if there was a problem.
            
            fid = [];
            try
                if isnumeric(outputFile)
                    fid = outputFile;
                else
                    fid = fopen(outputFile, 'w');
                end
                
                self.overall.print(fid, '');
                self.world.print(fid, '');
                
            catch err
                if ~isempty(fid) && fid > 2
                    fclose(fid);
                end
                rethrow(err);
            end
            
            if ~isempty(fid) && fid > 2
                fclose(fid);
            end
            
        end
    end
end