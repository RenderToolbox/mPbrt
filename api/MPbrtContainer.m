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
        
        function isGivenNode = nodePosition(self, node)
            % Check if the given node is nested in this container.
            %   Returns a logical array the same size as self.nested, true
            %   where the given node appears in self.nested, if at all.
            % find the first occurence of the node, if any
            
            % no trick, just compare against each nested object
            % nNested = numel(self.nested);
            % isGivenNode = false(1, nNested);
            % for nn = 1:nNested
            %    isGivenNode(nn) = node == self.nested{nn};
            % end
            
            % Faster version
            isGivenNode = node == self.nested;
        end
        
        function index = prepend(self, node)
            % Prepend a node nested under this container.
            %   If the node is already nested in this container, it will be
            %   moved to the front.  Returns the index where the new node
            %   was appended, which will always be 1, or [] if there was an
            %   error.
            
            if ~isa(node, 'MPbrtNode')
                index = [];
                return;
            end
            
            index = 1;
            isGivenNode = self.nodePosition(node);
            self.nested = cat(2, {node}, self.nested(~isGivenNode));
        end
        
        function index = append(self, node)
            % Append a node nested under this container.
            %   If the node is already nested in this container, it will be
            %   moved to the back.  Returns the index where the new node
            %   was appended, or [] if there was an
            %   error.
            
            if ~isa(node, 'MPbrtNode')
                index = [];
                return;
            end
            
            isGivenNode = self.nodePosition(node);
            if any(isGivenNode)
                self.nested = cat(2, self.nested(~isGivenNode), {node});
            else
                self.nested{end+1} = node;
            end
            index = numel(self.nested);
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
                    && (isempty(name) || ~isempty(regexp(self.name, name, 'once')))
                existing = self;
                return;
            end
            
            % depth-first search of nested nodes
            for nn = 1:numel(self.nested)
                node = self.nested{nn};
                
                % look for a direct child [and remove it]
                if strcmp(node.identifier, identifier) ...
                        && (isempty(name) || ~isempty(regexp(node.name, name,'once')))
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
