classdef MPbrtContainer < MPbrtNode
    % Holder for nested nodes inside Begin/End syntax.
    %   The idea here is to build up containers and elements in a nested
    %   fashion.  When printing, we delimit the nested things with
    %   Begin/End syntax as well as indenting.  We can also add, find, and
    %   remove nested elements.
    
    properties
        % Collection of nested containers or elements.
        nested = {};
        
        % Whether to print the node name after the Begin line.
        beginWithName = false;
    end
    
    methods
        function self = MPbrtContainer(identifier, varargin)
            % Make a new PBRT scene container.
            %   The PBRT identifier, like World or Attribute is required.
            %   Other fields may be set as named parameters.  For example:
            %       MPbrtElement(identifier, ...
            %           'name', 'foo', ...
            %           'comment', bar, ...
            %           'indent', '    ')
            
            parser = inputParser();
            parser.addRequired('identifier', @ischar);
            props = properties('MPbrtContainer');
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
            %   Print this container and its nested nodes.  Delimit this
            %   container and its contents with Begin/End and indenting.
            
            self.printSurrounded(fid, workingIndent, '# ', self.name, '\n');
            self.printSurrounded(fid, workingIndent, '# ', self.comment, '\n');
            
            if isempty(self.name) || ~self.beginWithName
                beginSuffix = 'Begin\n';
            else
                beginSuffix = ['Begin "' self.name '"\n'];
            end
            self.printSurrounded(fid, workingIndent, '', self.identifier, beginSuffix);
            
            nestedIndent = [workingIndent self.indent];
            for nn = 1:numel(self.nested)
                self.nested{nn}.print(fid, nestedIndent);
            end
            
            self.printSurrounded(fid, workingIndent, '', self.identifier, 'End\n');
            fprintf(fid, '\n');
        end
        
        function index = append(self, node)
            % Append a node nested under this container.
            %   Returns the index where the new node was appended.
            
            if ~isa(node, 'MPbrtNode')
                index = [];
                return;
            end
            
            index = numel(self.nested) + 1;
            self.nested{index} = node;
        end
        
        function existing = find(self, identifier, varargin)
            % Find a node nested under this container.
            %   existing = find(self, identifier) recursively searches this
            %   container and nested nodes for a node that has the given
            %   identifier.  The first node found is returned, if any.  If
            %   no node was found, returns [].
            %
            %   find( ... 'name', name) restricts the search to nodes that
            %   have the given identifier, and whose name matches or
            %   contains the given name.
            %
            %   find( ... 'remove', remove) specifies whether to remove the
            %   node that was found from its container (true), or not
            %   (false).  The default is false, don't remove the node.
            
            parser = inputParser();
            parser.addRequired('identifier', @ischar);
            parser.addParameter('name', '', @ischar);
            parser.addParameter('remove', false, @islogical);
            parser.parse(identifier, varargin{:});
            identifier = parser.Results.identifier;
            name = parser.Results.name;
            remove = parser.Results.remove;
            
            % is it this container?
            if strcmp(self.identifier, identifier) ...
                    && (isempty(name) || ~isempty(strfind(self.name, name)))
                existing = self;
                return;
            end
            
            % depth-first search of nested nodes
            for nn = 1:numel(self.nested)
                node = self.nested{nn};
                
                % look for a direct child [and remove it]
                if strcmp(node.identifier, identifier) ...
                        && (isempty(name) || ~isempty(strfind(node.name, name)))
                    existing = node;
                    if remove
                        self.nested(nn) = [];
                    end
                    return;
                end
                
                % look for a deeper descendant
                if isa(node, 'MPbrtContainer')
                    existing = node.find(identifier, varargin{:});
                    if ~isempty(existing)
                        return;
                    end
                end
            end
            
            % never found a match
            existing = [];
        end
    end
end
