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
        
        % "Short list" of identifiers for non-world elements.
        overallIdentifiers = {'Camera', ...
            'Sampler', ...
            'Film', ...
            'PixelFilter', ...
            'Renderer', ...
            'SurfaceIntegrator', ...
            'VolumeIntegrator', ...
            'Accelerator', ...
            'TransformTimes'};
    end
    
    methods
        function self = MPbrtScene()
            self.overall = MPbrtContainer('', 'indent', '');
            self.world = MPbrtContainer('World', 'indent', '');
        end
        
        function index = append(self, node)
            % Add the given node to the scene.
            %   Convenience method for adding a node to the scene.  Makes a
            %   best effort to append to the self.overall or self.world,
            %   based on the given node.identifier and the "short list" of
            %   non-world identitiders in self.overallIdentifiers.
            
            if any(strcmp(self.overallIdentifiers, node.identifier))
                index = self.overall.append(node);
            else
                index = self.world.append(node);
            end
        end
        
        function existing = find(self, identifier, varargin)
            % Search the scene for an existing node.
            %   Convenience method for searching self.overall and
            %   self.world in turn.  See MPbrtContainer.find().
            existing = self.overall.find(identifier, varargin{:});
            if isempty(existing)
                existing = self.world.find(identifier, varargin{:});
            end
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
                
                if ~isempty(self.world.nested)
                    self.world.print(fid, '');
                end
                
            catch err
                % close the file, even if there's an error
                %   too bad we can't have a try/catch/finally block!
                if ~isempty(fid) && fid > 2
                    fclose(fid);
                end
                rethrow(err);
            end
            
            % close the file on success
            if ~isempty(fid) && fid > 2
                fclose(fid);
            end
            
        end
    end
end