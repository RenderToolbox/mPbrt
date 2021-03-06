classdef MPbrtElement < MPbrtNode
    % Data for a PBRT statement.
    %   The idea here is to hold the data we need in order to print a PBRT
    %   statement.  All statements begin with a PBRT identifier.  Some are
    %   single line statements where the identifier is followed by a number
    %   of values.  For example,
    %       LookAt 0 10 100   0 -1 0 0 1 0
    %
    %   Others are multi-line statements where the identifier is followed
    %   by a type and a parameter list.  For example,
    %       Film "image"
    %         "string filename" ["simple.exr"]
    %         "integer xresolution" [200]
    %         "integer yresolution" [200]
    %
    %   And a few, like Texture and MakeNamedMaterial, are a funny
    %   combination of the first two.
    %
    %   MPbrtElement can handle all these cases, depending on which
    %   properties are filled in or omitted.
    
    properties
        % Single value or cell array to print after the identifier.
        value;
        
        % Type hint for printing the value element's value.
        valueType = '';
        
        % String PBRT type like "trianglemesh" or "perspective".
        type;
        
        % Struct array of parameters to print after the type.
        parameters;
    end
    
    methods
        function self = MPbrtElement(identifier, varargin)
            % Make a new PBRT scene element.
            %   The PBRT identifier, like Shape or Camera is required.
            %   Other fields may be set as named parameters.  For example:
            %       MPbrtElement(identifier, ...
            %           'name', 'foo', ...
            %           'comment', bar, ...
            %           'indent', '    ')
            
            % would like to use inputParser() to check that identifier is a
            % string, and that varargin contains actual properties of this
            % class.  But this can be a performance bottleneck.  So, for
            % performance reasons, let's let er rip!
            
            self.identifier = identifier;
            
            nVarargin = numel(varargin);
            for vv = 1:2:nVarargin
                fieldName = varargin{vv};
                value = varargin{vv+1};
                self.(fieldName) = value;
            end
        end
        
        function print(self, fid, workingIndent)
            % Required method from MPbrtNode.
            %   Print this element and value and/or parameters.
            self.printSurrounded(fid, workingIndent, '# ', self.name, '\n');
            self.printSurrounded(fid, workingIndent, '# ', self.comment, '\n');
            
            self.printSurrounded(fid, workingIndent, '', self.identifier, ' ');
            self.printValue(fid, self.value, self.valueType);
            self.printValue(fid, self.type, 'string');
            self.printSurrounded(fid, workingIndent, '', '\n', '');
            
            paramIndent = [workingIndent self.indent];
            for pp = 1:numel(self.parameters)
                p = self.parameters(pp);
                fprintf(fid, '%s"%s %s" ', paramIndent, p.type, p.name);
                self.printValue(fid, p.value, p.type);
                fprintf(fid, '\n');
            end
        end
        
        function printToFile(self, outputFile)
            % Write this element all by itself to the given file.
            %
            %   This is good for producing PBRT "Include" files.
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
                
                self.print(fid, '');
                
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
        
        function p = setParameter(self, name, type, value)
            % Add or update a parameter with the given name.
            %   If this element already contains a parameter with the given
            %   name, it will be updated with the given type and value.
            %   Otherwise, a new parameter will be added.
            
            p = MPbrtElement.parameter(name, type, value);
            if isempty(self.parameters)
                self.parameters = p;
                return;
            end
            
            % locate any existing parameter?
            isName = strcmp(name, {self.parameters.name});
            if any(isName)
                index = find(isName, 1, 'first');
            else
                index = numel(self.parameters) + 1;
            end
            
            % insert or append to struct array
            self.parameters(index) = p;
        end
        
        function [value, type] = getParameter(self, name)
            % Locate a parameter with the given name.
            %   If a parameter with the given name exists, finds and
            %   returns its value and type.  Otherwise returns [].
            
            if isempty(self.parameters)
                value = [];
                type = [];
                return;
            end
            
            isName = strcmp(name, {self.parameters.name});
            if any(isName)
                index = find(isName, 1, 'first');
                value = self.parameters(index).value;
                type = self.parameters(index).type;
            else
                value = [];
                type = [];
            end
        end
    end
    
    methods (Static)
        function p = parameter(name, type, value)
            % Make a standard element parameter struct element.
            %   The given name must be a PBRT parameter name like
            %   "xresolution", or "L".
            %   The given type must be a PBRT value type like "float" or
            %   "spectrum".
            %   The given value must be literal string or numeric value.
            p = struct( ...
                'name', name, ...
                'type', type, ...
                'value', value);
        end
        
        function element = comment(comment, varargin)
            % Utility to make a printable comment with no other data.
            element = MPbrtElement('', 'comment', comment, varargin{:});
        end
        
        function element = transformation(identifier, value, varargin)
            % Utility to make a PBRT transformation element
            if any(strcmp({'ConcatTransform', 'Transform'}, identifier))
                % valueType will be chosen from Matlab variable type
                valueType = '';
            elseif isnumeric(value)
                % don't put transformation value in brackets
                valueType = 'raw';
            else
                % valueType will be chosen from Matlab variable type
                valueType = '';
            end
            element = MPbrtElement(identifier, ...
                'value', value, ...
                'valueType', valueType, ...
                varargin{:});
        end
        
        function element = texture(name, pixelType, textureType, varargin)
            % Utility to make a pbrt Texture.
            element = MPbrtElement('Texture', ...
                'name', name, ...
                'value', {name, pixelType}, ...
                'type', textureType, ...
                varargin{:});
        end
        
        function element = makeNamedMaterial(name, type, varargin)
            % Utility to declare a named material.
            element = MPbrtElement('MakeNamedMaterial', ...
                'name', name, ...
                'value', {name, 'string type'}, ...
                'type', type, ...
                varargin{:});
        end
        
        function element = namedMaterial(name, varargin)
            % Utility to invoke a previous named material.
            element = MPbrtElement('NamedMaterial', ...
                'value', name, ...
                varargin{:});
        end
        
    end
end