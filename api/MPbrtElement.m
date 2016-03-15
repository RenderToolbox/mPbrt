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
            
            parser = inputParser();
            parser.addRequired('identifier', @ischar);
            props = properties('MPbrtElement');
            for pp = 1:numel(props)
                prop = props{pp};
                if strcmp('identifier', prop)
                    continue;
                end
                parser.addParameter(prop, '');
            end
            parser.parse(identifier, varargin{:});
            
            % assign properties from the parser, including idenentifier
            fields = fieldnames(parser.Results);
            for ff = 1:numel(fields)
                field = fields{ff};
                if ismember(field, parser.UsingDefaults)
                    continue;
                end
                self.(field) = parser.Results.(field);
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
    end
end